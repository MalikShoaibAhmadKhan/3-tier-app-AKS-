variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-gitops-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-gitops-cluster"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "aksgitops"
}

variable "node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the VMs in the node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Azure service principal client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Azure service principal client secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}
