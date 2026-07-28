package main

# Every taggable resource must carry the four governance tags.
required_tags := ["owner", "cost_center", "data_classification", "managed_by"]

taggable_types := {
	"azurerm_resource_group",
	"azurerm_virtual_network",
	"azurerm_network_security_group",
	"azurerm_storage_account",
	"azurerm_log_analytics_workspace",
}

deny[msg] {
	resource := input.resource_changes[_]
	taggable_types[resource.type]
	resource.change.actions[_] != "delete"
	tag := required_tags[_]
	not resource.change.after.tags[tag]
	msg := sprintf("%s.%s is missing required tag %q.", [resource.type, resource.name, tag])
}
