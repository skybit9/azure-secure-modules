# The example provisions its own workspace and flow log storage so it runs standalone.
module "observability" {
  source = "../../../azure-observability"

  name_prefix        = "example"
  environment        = "dev"
  location           = var.location
  log_retention_days = 90

  tags = local.tags
}

module "network" {
  source = "../.."

  name_prefix        = "example"
  environment        = "dev"
  location           = var.location
  vnet_address_space = ["10.90.0.0/16"]

  subnets = {
    # Public facing tier. Only the Azure gateway manager service tag may reach it.
    gateway = {
      address_prefixes = ["10.90.1.0/24"]
      allow_rules = [{
        name                    = "allow-appgw-manager"
        priority                = 100
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        destination_port_ranges = ["65200-65535"]
        source_address_prefix   = "GatewayManager"
      }]
    }

    # Application tier. Accepts HTTPS from the gateway subnet only.
    app = {
      address_prefixes  = ["10.90.2.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
      allow_rules = [
        {
          name                    = "allow-https-from-gateway"
          priority                = 200
          direction               = "Inbound"
          access                  = "Allow"
          protocol                = "Tcp"
          destination_port_ranges = ["443"]
          source_address_prefix   = "10.90.1.0/24"
        },
        {
          name                       = "allow-https-egress-azure"
          priority                   = 210
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_ranges    = ["443"]
          source_address_prefix      = "VirtualNetwork"
          destination_address_prefix = "AzureCloud"
        }
      ]
    }

    # Data tier. No inbound allow rules at all, reachable only through private endpoints.
    data = {
      address_prefixes                  = ["10.90.3.0/24"]
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

  tags = local.tags
}

locals {
  tags = {
    owner               = "platform-team"
    cost_center         = "example"
    data_classification = "confidential"
    managed_by          = "terraform"
  }
}
