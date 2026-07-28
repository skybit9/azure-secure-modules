output "resource_group_name" {
  description = "Name of the network resource group."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "Resource ID of the network resource group."
  value       = azurerm_resource_group.this.id
}

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet short name to subnet resource ID."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "nsg_ids" {
  description = "Map of subnet short name to NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "flow_logs_enabled" {
  description = "Whether NSG flow logs were provisioned. Useful as a compliance assertion in tests."
  value       = local.flow_logs_enabled
}
