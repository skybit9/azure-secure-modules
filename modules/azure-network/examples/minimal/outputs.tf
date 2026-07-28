output "vnet_id" {
  description = "Resource ID of the created virtual network."
  value       = module.network.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to resource ID."
  value       = module.network.subnet_ids
}
