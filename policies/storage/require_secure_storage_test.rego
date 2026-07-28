package main

test_denies_weak_tls {
	deny[_] with input as {"resource_changes": [{
		"type": "azurerm_storage_account",
		"name": "st",
		"change": {"after": {
			"min_tls_version": "TLS1_0",
			"allow_nested_items_to_be_public": false,
		}},
	}]}
}

test_denies_public_blob {
	deny[_] with input as {"resource_changes": [{
		"type": "azurerm_storage_account",
		"name": "st",
		"change": {"after": {
			"min_tls_version": "TLS1_2",
			"allow_nested_items_to_be_public": true,
		}},
	}]}
}

test_denies_short_flow_log_retention {
	deny[_] with input as {"resource_changes": [{
		"type": "azurerm_network_watcher_flow_log",
		"name": "fl",
		"change": {"after": {"retention_policy": [{"enabled": true, "days": 30}]}},
	}]}
}
