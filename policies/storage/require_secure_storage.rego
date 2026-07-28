package main

# Storage accounts must enforce TLS 1.2 and refuse public blob access.
deny[msg] {
	resource := input.resource_changes[_]
	resource.type == "azurerm_storage_account"
	resource.change.after.min_tls_version != "TLS1_2"
	msg := sprintf("Storage account %q must set min_tls_version to TLS1_2.", [resource.name])
}

deny[msg] {
	resource := input.resource_changes[_]
	resource.type == "azurerm_storage_account"
	resource.change.after.allow_nested_items_to_be_public == true
	msg := sprintf("Storage account %q must not allow public blob access.", [resource.name])
}

# Flow log retention must meet the 90 day evidence baseline.
deny[msg] {
	resource := input.resource_changes[_]
	resource.type == "azurerm_network_watcher_flow_log"
	policy := resource.change.after.retention_policy[_]
	policy.days < 90
	msg := sprintf("Flow log %q retention is %d days. Minimum is 90.", [resource.name, policy.days])
}
