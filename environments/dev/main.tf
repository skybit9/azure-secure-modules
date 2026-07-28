locals {
  environment = "dev"
}

module "observability" {
  source = "../../modules/azure-observability"

  name_prefix        = var.name_prefix
  environment        = local.environment
  location           = var.location
  log_retention_days = 90
  tags               = var.tags
}

module "network" {
  source = "../../modules/azure-network"

  name_prefix        = var.name_prefix
  environment        = local.environment
  location           = var.location
  vnet_address_space = var.vnet_address_space

  subnets = {
    app = {
      address_prefixes  = [cidrsubnet(var.vnet_address_space[0], 8, 1)]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
      allow_rules = [
        {
          name                    = "allow-https-from-gateway-subnet"
          priority                = 200
          direction               = "Inbound"
          access                  = "Allow"
          protocol                = "Tcp"
          destination_port_ranges = ["443"]
          source_address_prefix   = cidrsubnet(var.vnet_address_space[0], 8, 2)
        },
        {
          name                    = "allow-https-egress-to-azure-services"
          priority                = 210
          direction               = "Outbound"
          access                  = "Allow"
          protocol                = "Tcp"
          destination_port_ranges = ["443"]
          source_address_prefix   = "VirtualNetwork"
          # AzureCloud service tag keeps egress scoped instead of open internet.
          destination_address_prefix = "AzureCloud"
        }
      ]
    }

    gateway = {
      address_prefixes = [cidrsubnet(var.vnet_address_space[0], 8, 2)]
      allow_rules = [
        {
          name                    = "allow-appgw-manager"
          priority                = 100
          direction               = "Inbound"
          access                  = "Allow"
          protocol                = "Tcp"
          destination_port_ranges = ["65200-65535"]
          source_address_prefix   = "GatewayManager"
        }
      ]
    }

    data = {
      address_prefixes                  = [cidrsubnet(var.vnet_address_space[0], 8, 3)]
      service_endpoints                 = ["Microsoft.Storage"]
      private_endpoint_network_policies = "Enabled"
    }
  }

  log_analytics_workspace_id   = module.observability.workspace_id
  log_analytics_workspace_guid = module.observability.workspace_guid
  network_watcher_name         = var.network_watcher_name
  flow_log_storage_account_id  = module.observability.flow_log_storage_id
  flow_log_retention_days      = 90
  enable_traffic_analytics     = true
  enable_ddos_protection       = false

  tags = var.tags
}
