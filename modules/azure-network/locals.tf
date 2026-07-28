locals {
  # Single naming convention so every resource is greppable in the portal and in audit exports.
  base_name = "${var.name_prefix}-${var.environment}"

  # Tags merged with module provenance so an auditor can trace any resource back to this repo.
  common_tags = merge(var.tags, {
    module      = "azure-network"
    environment = var.environment
    provisioner = "terraform"
  })

  # Flow logs only make sense when both a Network Watcher and a storage sink are supplied.
  flow_logs_enabled = var.flow_log_storage_account_id != null && var.network_watcher_name != null

  # Flatten subnet allow rules into a single map keyed by subnet + rule name for for_each.
  nsg_rules = {
    for pair in flatten([
      for subnet_key, subnet in var.subnets : [
        for rule in subnet.allow_rules : {
          key        = "${subnet_key}-${rule.name}"
          subnet_key = subnet_key
          rule       = rule
        }
      ]
    ]) : pair.key => pair
  }
}
