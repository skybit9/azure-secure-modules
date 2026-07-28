output "vnet_id" {
  description = "VNet resource ID."
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to resource ID."
  value       = module.network.subnet_ids
}

output "log_analytics_workspace_id" {
  description = "Workspace receiving all diagnostics."
  value       = module.observability.workspace_id
}

output "flow_logs_enabled" {
  description = "Compliance assertion: were NSG flow logs provisioned."
  value       = module.network.flow_logs_enabled
}
