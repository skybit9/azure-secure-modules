variable "name_prefix" {
  description = "Short prefix used to build all resource names, lowercase alphanumeric only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.name_prefix))
    error_message = "name_prefix must be 2 to 12 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment identifier. Drives naming and policy strictness."
  type        = string

  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "environment must be one of: dev, stg, prd."
  }
}

variable "location" {
  description = "Azure region for all resources in this module."
  type        = string
  default     = "canadacentral"
}

variable "vnet_address_space" {
  description = "Address space assigned to the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "vnet_address_space must contain at least one CIDR block."
  }
}

variable "subnets" {
  description = "Map of subnets. Each subnet gets a dedicated NSG with a default deny inbound posture. allow_rules are additive and evaluate before the deny catch all."

  type = map(object({
    address_prefixes                  = list(string)
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Enabled")
    delegation_service                = optional(string, null)
    allow_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_ranges    = list(string)
      source_address_prefix      = string
      destination_address_prefix = optional(string, "*")
    })), [])
  }))

  validation {
    condition = alltrue([
      for s in values(var.subnets) : alltrue([
        for r in s.allow_rules : !(r.direction == "Inbound" && contains(["*", "0.0.0.0/0", "Internet"], r.source_address_prefix))
      ])
    ])
    error_message = "Inbound allow rules must not source from any address. Use a named CIDR or a service tag other than Internet."
  }

  validation {
    condition = alltrue([
      for s in values(var.subnets) : alltrue([
        for r in s.allow_rules : !(r.direction == "Inbound" && length(setintersection(toset(r.destination_port_ranges), toset(["22", "3389"]))) > 0)
      ])
    ])
    error_message = "Direct SSH (22) and RDP (3389) inbound rules are blocked. Use Azure Bastion instead."
  }
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace that receives diagnostics and flow logs."
  type        = string
}

variable "log_analytics_workspace_guid" {
  description = "Workspace GUID (customer id) of the Log Analytics workspace. Required for traffic analytics."
  type        = string
  default     = null
}

variable "network_watcher_name" {
  description = "Name of the existing Network Watcher used for NSG flow logs."
  type        = string
  default     = null
}

variable "network_watcher_resource_group" {
  description = "Resource group holding the Network Watcher. Azure provisions NetworkWatcherRG automatically."
  type        = string
  default     = "NetworkWatcherRG"
}

variable "flow_log_storage_account_id" {
  description = "Storage account resource ID that stores raw NSG flow logs. Null disables flow logs."
  type        = string
  default     = null
}

variable "flow_log_retention_days" {
  description = "Retention in days for NSG flow logs. Audit evidence baseline is 90 days."
  type        = number
  default     = 90

  validation {
    condition     = var.flow_log_retention_days >= 90
    error_message = "flow_log_retention_days must be 90 or greater to satisfy the audit evidence baseline."
  }
}

variable "enable_traffic_analytics" {
  description = "Enable traffic analytics on flow logs. Requires log_analytics_workspace_guid."
  type        = bool
  default     = true
}

variable "enable_ddos_protection" {
  description = "Attach a DDoS Network Protection plan. Costly, so keep false outside production."
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "Resource ID of an existing DDoS protection plan. Required when enable_ddos_protection is true."
  type        = string
  default     = null

  validation {
    condition     = var.ddos_protection_plan_id == null || can(regex("^/subscriptions/", var.ddos_protection_plan_id))
    error_message = "ddos_protection_plan_id must be a full Azure resource ID."
  }
}

variable "tags" {
  description = "Governance tags applied to every resource. All four keys are mandatory."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["owner", "cost_center", "data_classification", "managed_by"] : contains(keys(var.tags), k)
    ])
    error_message = "tags must include owner, cost_center, data_classification and managed_by."
  }

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], lookup(var.tags, "data_classification", ""))
    error_message = "data_classification must be one of: public, internal, confidential, restricted."
  }
}
