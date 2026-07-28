package main

# Blocks any NSG rule that allows inbound traffic from the public internet.
# Runs against a Terraform plan JSON via: conftest test plan.json

deny[msg] {
	resource := input.resource_changes[_]
	resource.type == "azurerm_network_security_rule"
	rule := resource.change.after
	rule.direction == "Inbound"
	rule.access == "Allow"
	open_source(rule.source_address_prefix)
	msg := sprintf("NSG rule %q allows inbound from %q. Public inbound is not permitted.", [rule.name, rule.source_address_prefix])
}

open_source("*")
open_source("0.0.0.0/0")
open_source("Internet")
open_source("Any")

# Blocks management ports regardless of source.
deny[msg] {
	resource := input.resource_changes[_]
	resource.type == "azurerm_network_security_rule"
	rule := resource.change.after
	rule.direction == "Inbound"
	rule.access == "Allow"
	port := rule.destination_port_ranges[_]
	management_port(port)
	msg := sprintf("NSG rule %q exposes management port %q. Use Azure Bastion instead.", [rule.name, port])
}

management_port("22")
management_port("3389")
management_port("*")
