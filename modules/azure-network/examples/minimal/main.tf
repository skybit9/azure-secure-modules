module "network" {
  source = "../.."

  name_prefix        = "example"
  environment        = "dev"
  location           = "canadacentral"
  vnet_address_space = ["10.90.0.0/16"]

  subnets = {
    app = {
      address_prefixes = ["10.90.1.0/24"]
    }
  }

  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = {
    owner               = "platform-team"
    cost_center         = "example"
    data_classification = "internal"
    managed_by          = "terraform"
  }
}
