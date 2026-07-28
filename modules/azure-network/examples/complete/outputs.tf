output "vnet_id" {
  description = "Resource ID of the created virtual network."
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to resource ID."
  value       = module.network.subnet_ids
}

output "nsg_ids" {
  description = "Map of subnet name to NSG resource ID."
  value       = module.network.nsg_ids
}

output "flow_logs_enabled" {
  description = "Compliance assertion that flow logs were provisioned."
  value       = module.network.flow_logs_enabled
}
