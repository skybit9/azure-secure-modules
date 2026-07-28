# Resource group holding the network foundation for one environment.
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.base_name}-network"
  location = var.location
  tags     = local.common_tags
}

# Virtual network. DDoS plan attaches only when explicitly enabled to control cost.
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.base_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  tags                = local.common_tags

  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  lifecycle {
    precondition {
      condition     = !var.enable_ddos_protection || var.ddos_protection_plan_id != null
      error_message = "ddos_protection_plan_id is required when enable_ddos_protection is true."
    }
  }
}

# Subnets. Private endpoint network policies stay enabled so NSGs apply to private endpoints.
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                              = "snet-${local.base_name}-${each.key}"
  resource_group_name               = azurerm_resource_group.this.name
  virtual_network_name              = azurerm_virtual_network.this.name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = each.value.service_endpoints
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegation_service != null ? [each.value.delegation_service] : []
    content {
      name = "delegation"
      service_delegation {
        name    = delegation.value
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      }
    }
  }
}
