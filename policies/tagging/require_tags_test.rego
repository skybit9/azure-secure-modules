package main

test_denies_missing_governance_tags {
	deny[_] with input as {"resource_changes": [{
		"type": "azurerm_resource_group",
		"name": "rg",
		"change": {
			"actions": ["create"],
			"after": {"tags": {"owner": "platform-team"}},
		},
	}]}
}

test_allows_full_tag_set {
	count([m | deny[m] with input as {"resource_changes": [{
		"type": "azurerm_resource_group",
		"name": "rg",
		"change": {
			"actions": ["create"],
			"after": {"tags": {
				"owner": "platform-team",
				"cost_center": "example",
				"data_classification": "internal",
				"managed_by": "terraform",
			}},
		},
	}]}]) == 0
}
