module "observability" {
  source = "../.."

  name_prefix        = "example"
  environment        = "dev"
  location           = "canadacentral"
  log_retention_days = 90

  tags = {
    owner               = "platform-team"
    cost_center         = "example"
    data_classification = "internal"
    managed_by          = "terraform"
  }
}
