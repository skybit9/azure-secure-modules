# VNet diagnostics. Without this there is no record of what the network did.
resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-vnet-${local.base_name}"
  target_resource_id         = azurerm_virtual_network.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_metric {
    category = "AllMetrics"
  }
}

# NSG diagnostics capture rule counter events, which prove a deny rule actually fired.
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  for_each = var.subnets

  name                       = "diag-nsg-${local.base_name}-${each.key}"
  target_resource_id         = azurerm_network_security_group.this[each.key].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# NSG flow logs plus traffic analytics. This is the artifact an auditor asks for by name.
resource "azurerm_network_watcher_flow_log" "this" {
  for_each = local.flow_logs_enabled ? var.subnets : {}

  name                      = "fl-${local.base_name}-${each.key}"
  network_watcher_name      = var.network_watcher_name
  resource_group_name       = var.network_watcher_resource_group
  target_resource_id        = azurerm_network_security_group.this[each.key].id
  storage_account_id        = var.flow_log_storage_account_id
  enabled                   = true
  version                   = 2
  tags                      = local.common_tags

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics && var.log_analytics_workspace_guid != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_guid
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_id
      interval_in_minutes   = 10
    }
  }
}
