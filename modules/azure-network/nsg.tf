# One NSG per subnet. Shared NSGs blur blast radius and fail segmentation review.
resource "azurerm_network_security_group" "this" {
  for_each = var.subnets

  name                = "nsg-${local.base_name}-${each.key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

# Explicit deny catch all at priority 4096. Azure has an implicit deny but auditors want it visible.
resource "azurerm_network_security_rule" "deny_all_inbound" {
  for_each = var.subnets

  name                        = "deny-all-inbound"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this[each.key].name
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

# Explicit deny for internet bound egress. Callers open specific egress via allow_rules.
resource "azurerm_network_security_rule" "deny_internet_outbound" {
  for_each = var.subnets

  name                        = "deny-internet-outbound"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this[each.key].name
  priority                    = 4095
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
}

# Caller supplied allow rules. Variable validation blocks any inbound rule sourced from Internet.
resource "azurerm_network_security_rule" "allow" {
  for_each = local.nsg_rules

  name                        = each.value.rule.name
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_key].name
  priority                    = each.value.rule.priority
  direction                   = each.value.rule.direction
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  source_port_range           = each.value.rule.source_port_range
  destination_port_ranges     = each.value.rule.destination_port_ranges
  source_address_prefix       = each.value.rule.source_address_prefix
  destination_address_prefix  = each.value.rule.destination_address_prefix
}

# Association is what actually enforces the NSG. An unassociated NSG is a common audit finding.
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
