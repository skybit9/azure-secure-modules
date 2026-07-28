locals {
  base_name   = "${var.name_prefix}-${var.environment}"
  common_tags = merge(var.tags, { module = "azure-observability", provisioner = "terraform" })
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.base_name}-observability"
  location = var.location
  tags     = local.common_tags
}

# Central workspace. Every module in this repo ships diagnostics here, no exceptions.
resource "azurerm_log_analytics_workspace" "this" {
  name                       = "law-${local.base_name}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  sku                        = "PerGB2018"
  retention_in_days          = var.log_retention_days
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  tags                       = local.common_tags
}

# Storage sink for raw NSG flow logs. Locked down hard because it holds network metadata.
resource "azurerm_storage_account" "flow_logs" {
  name                            = substr(replace("st${local.base_name}flow", "-", ""), 0, 24)
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = "Standard"
  account_replication_type        = var.flow_log_storage_replication
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  public_network_access_enabled   = true
  tags                            = local.common_tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices", "Logging", "Metrics"]
  }
}

# Diagnostics on the storage account itself. The evidence store needs its own evidence.
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "diag-${local.base_name}-flowstorage"
  target_resource_id         = "${azurerm_storage_account.flow_logs.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}
