output "workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_guid" {
  description = "Customer GUID of the Log Analytics workspace, needed by traffic analytics."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "flow_log_storage_id" {
  description = "Resource ID of the flow log storage account."
  value       = azurerm_storage_account.flow_logs.id
}

output "resource_group_name" {
  description = "Name of the observability resource group."
  value       = azurerm_resource_group.this.name
}
