output "resource_group_name" {
  value = azurerm_resource_group.tf_state_rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tf_state_sa.name
}

output "container_name" {
  value = azurerm_storage_container.tf_state_container.name
} 