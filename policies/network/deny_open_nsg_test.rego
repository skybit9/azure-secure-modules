package main

# Fails: inbound allow sourced from the public internet.
test_denies_internet_sourced_inbound {
	deny[_] with input as {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"name": "bad",
		"change": {"after": {
			"name": "allow-any-https",
			"direction": "Inbound",
			"access": "Allow",
			"source_address_prefix": "Internet",
			"destination_port_ranges": ["443"],
		}},
	}]}
}

# Fails: RDP exposed even from a private range.
test_denies_rdp {
	deny[_] with input as {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"name": "bad",
		"change": {"after": {
			"name": "allow-rdp",
			"direction": "Inbound",
			"access": "Allow",
			"source_address_prefix": "10.0.0.0/24",
			"destination_port_ranges": ["3389"],
		}},
	}]}
}

# Passes: scoped inbound HTTPS from a named subnet.
test_allows_scoped_https {
	count([m | deny[m] with input as {"resource_changes": [{
		"type": "azurerm_network_security_rule",
		"name": "good",
		"change": {"after": {
			"name": "allow-https-from-gateway",
			"direction": "Inbound",
			"access": "Allow",
			"source_address_prefix": "10.90.1.0/24",
			"destination_port_ranges": ["443"],
		}},
	}]}]) == 0
}
