output "workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = module.observability.workspace_id
}

output "workspace_guid" {
  description = "Customer GUID of the workspace, needed by traffic analytics."
  value       = module.observability.workspace_guid
}

output "flow_log_storage_id" {
  description = "Resource ID of the flow log storage account."
  value       = module.observability.flow_log_storage_id
}
