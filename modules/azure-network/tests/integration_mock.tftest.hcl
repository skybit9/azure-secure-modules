# Full apply path with zero Azure tenant. mock_provider fakes every API call,
# so this suite runs offline on a laptop and inside CI with no credentials.
# Run from the module directory: terraform test -test-directory=../../tests

mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock"
      guid = "11111111-1111-1111-1111-111111111111"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/virtualNetworks/vnet-mock/subnets/snet-mock"
    }
  }

  mock_resource "azurerm_network_security_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Network/networkSecurityGroups/nsg-mock"
    }
  }
}

variables {
  name_prefix        = "indjt"
  environment        = "dev"
  location           = "canadacentral"
  vnet_address_space = ["10.20.0.0/16"]

  subnets = {
    app = {
      address_prefixes  = ["10.20.1.0/24"]
      service_endpoints = ["Microsoft.KeyVault"]
      allow_rules = [{
        name                    = "allow-https-from-gateway"
        priority                = 200
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        destination_port_ranges = ["443"]
        source_address_prefix   = "10.20.2.0/24"
      }]
    }
    data = {
      address_prefixes = ["10.20.3.0/24"]
    }
  }

  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/law-mock"

  tags = {
    owner               = "indrajeet.shelar"
    cost_center         = "portfolio"
    data_classification = "internal"
    managed_by          = "terraform"
  }
}

run "apply_creates_full_topology" {
  command = apply

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected one subnet per entry in var.subnets."
  }

  assert {
    condition     = length(azurerm_network_security_group.this) == length(azurerm_subnet.this)
    error_message = "NSG count must match subnet count. Shared NSGs break segmentation review."
  }

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == length(azurerm_subnet.this)
    error_message = "Every subnet must be associated with its NSG."
  }
}

run "deny_rules_present_on_every_nsg" {
  command = apply

  assert {
    condition     = alltrue([for r in values(azurerm_network_security_rule.deny_all_inbound) : r.access == "Deny" && r.priority == 4096])
    error_message = "Explicit deny all inbound missing or mispriced."
  }

  assert {
    condition     = alltrue([for r in values(azurerm_network_security_rule.deny_internet_outbound) : r.destination_address_prefix == "Internet"])
    error_message = "Explicit deny to Internet outbound missing."
  }
}

run "diagnostics_cover_every_nsg" {
  command = apply

  assert {
    condition     = length(azurerm_monitor_diagnostic_setting.nsg) == length(azurerm_network_security_group.this)
    error_message = "Every NSG must ship diagnostics to Log Analytics."
  }
}

run "governance_tags_propagate" {
  command = apply

  assert {
    condition     = azurerm_resource_group.this.tags["data_classification"] == "internal"
    error_message = "Governance tags must propagate to the resource group."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["provisioner"] == "terraform"
    error_message = "Module provenance tag missing."
  }
}
