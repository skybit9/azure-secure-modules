# Offline validation tests for the observability module.
# Run from this module directory: terraform test

mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.OperationalInsights/workspaces/law-mock"
      workspace_id = "22222222-2222-2222-2222-222222222222"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id                        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-mock/providers/Microsoft.Storage/storageAccounts/stmock"
      primary_blob_endpoint     = "https://stmock.blob.core.windows.net/"
      primary_connection_string = "mock"
    }
  }
}

variables {
  name_prefix = "example"
  environment = "dev"
  location    = "canadacentral"

  tags = {
    owner               = "platform-team"
    cost_center         = "example"
    data_classification = "internal"
    managed_by          = "terraform"
  }
}

run "evidence_store_is_hardened" {
  command = apply

  assert {
    condition     = azurerm_storage_account.flow_logs.min_tls_version == "TLS1_2"
    error_message = "Flow log storage must enforce a TLS 1.2 floor."
  }

  assert {
    condition     = azurerm_storage_account.flow_logs.allow_nested_items_to_be_public == false
    error_message = "Flow log storage must block anonymous blob access."
  }

  assert {
    condition     = azurerm_storage_account.flow_logs.shared_access_key_enabled == false
    error_message = "Flow log storage must require Entra ID auth, not shared keys."
  }
}

run "retention_meets_evidence_baseline" {
  command = apply

  assert {
    condition     = azurerm_log_analytics_workspace.this.retention_in_days >= 90
    error_message = "Workspace retention must meet the 90 day evidence baseline."
  }
}

run "rejects_short_retention" {
  command = plan

  variables {
    log_retention_days = 30
  }

  expect_failures = [var.log_retention_days]
}
