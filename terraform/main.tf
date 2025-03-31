terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    # Configuration will be provided by GitHub Actions workflow
  }
}

# --- Backend Infrastructure Resources ---
# These resources create the storage for the Terraform remote state.
# Apply these first with a local backend, then configure the azurerm backend.

resource "azurerm_resource_group" "tf_state_rg" {
  # Using a separate name to avoid conflict if var.resource_group_name is the same
  name     = "kubemicrodemo-terraform-storage-rg" 
  location = var.location # Assumes var.location is defined and suitable
}

resource "azurerm_storage_account" "tf_state_sa" {
  name                     = "tfstatekubemicro" # Must be globally unique
  resource_group_name      = azurerm_resource_group.tf_state_rg.name
  location                 = azurerm_resource_group.tf_state_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally-redundant storage

  tags = {
    purpose = "terraform-remote-state"
    environment = var.environment
  }
}

resource "azurerm_storage_container" "tf_state_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tf_state_sa.name
  container_access_type = "private" # Keep state private
}

# --- End Backend Infrastructure Resources ---


provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Add Network Security Group for AKS
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.cluster_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = "MC_${var.resource_group_name}_${var.cluster_name}_${var.location}"

  security_rule {
    name                       = "allow_http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "443"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_nodeport"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "30000-32767"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
  }
}

# Create Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${var.cluster_name}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Update"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete"
    ]
  }
}

data "azurerm_client_config" "current" {}

# Enable Managed Identity for AKS to access Key Vault
resource "azurerm_key_vault_access_policy" "aks_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Store database credentials in Key Vault
resource "azurerm_key_vault_secret" "db_username" {
  name         = "db-username"
  value        = var.db_username
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = azurerm_key_vault.kv.id
}
