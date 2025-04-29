terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "tf_state_rg" {
  name     = "kubemicrodemo-terraform-storage-rg"
  location = var.location

  tags = {
    purpose = "terraform-state-storage"
  }
}

resource "azurerm_storage_account" "tf_state_sa" {
  name                     = "my_inner_storage"
  resource_group_name      = azurerm_resource_group.tf_state_rg.name
  location                 = azurerm_resource_group.tf_state_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    purpose = "terraform-state-storage"
  }
}

resource "azurerm_storage_container" "tf_state_container" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tf_state_sa.name
  container_access_type = "private"
} 