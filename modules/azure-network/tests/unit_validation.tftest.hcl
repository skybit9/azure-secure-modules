# Native terraform test. Runs with: terraform test
# Plan only, no Azure credentials required for the validation assertions.

variables {
  name_prefix        = "indjt"
  environment        = "dev"
  location           = "canadacentral"
  vnet_address_space = ["10.20.0.0/16"]

  subnets = {
    app = {
      address_prefixes = ["10.20.1.0/24"]
    }
  }

  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-fake/providers/Microsoft.OperationalInsights/workspaces/law-fake"

  tags = {
    owner               = "indrajeet.shelar"
    cost_center         = "portfolio"
    data_classification = "internal"
    managed_by          = "terraform"
  }
}

run "every_subnet_gets_an_nsg_association" {
  command = plan

  assert {
    condition     = length(azurerm_subnet_network_security_group_association.this) == length(var.subnets)
    error_message = "Each subnet must have an NSG association. Unassociated NSGs are a standard audit finding."
  }
}

run "explicit_deny_all_inbound_exists" {
  command = plan

  assert {
    condition     = alltrue([for r in values(azurerm_network_security_rule.deny_all_inbound) : r.access == "Deny" && r.priority == 4096])
    error_message = "Every NSG must carry an explicit deny all inbound rule at priority 4096."
  }
}

run "rejects_public_inbound_rule" {
  command = plan

  variables {
    subnets = {
      app = {
        address_prefixes = ["10.20.1.0/24"]
        allow_rules = [{
          name                    = "bad-open-https"
          priority                = 200
          direction               = "Inbound"
          access                  = "Allow"
          protocol                = "Tcp"
          destination_port_ranges = ["443"]
          source_address_prefix   = "Internet"
        }]
      }
    }
  }

  expect_failures = [var.subnets]
}

run "rejects_rdp_inbound_rule" {
  command = plan

  variables {
    subnets = {
      app = {
        address_prefixes = ["10.20.1.0/24"]
        allow_rules = [{
          name                    = "bad-rdp"
          priority                = 201
          direction               = "Inbound"
          access                  = "Allow"
          protocol                = "Tcp"
          destination_port_ranges = ["3389"]
          source_address_prefix   = "10.20.9.0/24"
        }]
      }
    }
  }

  expect_failures = [var.subnets]
}

run "rejects_missing_governance_tags" {
  command = plan

  variables {
    tags = {
      owner = "indrajeet.shelar"
    }
  }

  expect_failures = [var.tags]
}

run "rejects_short_flow_log_retention" {
  command = plan

  variables {
    flow_log_retention_days = 30
  }

  expect_failures = [var.flow_log_retention_days]
}
