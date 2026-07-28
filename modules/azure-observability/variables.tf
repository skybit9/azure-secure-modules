variable "name_prefix" {
  description = "Short prefix used to build resource names, lowercase alphanumeric only."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.name_prefix))
    error_message = "name_prefix must be 2 to 12 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment identifier."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "canadacentral"
}

variable "log_retention_days" {
  description = "Log Analytics retention in days. 90 is the audit evidence baseline."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 90
    error_message = "log_retention_days must be 90 or greater."
  }
}

variable "flow_log_storage_replication" {
  description = "Replication type for the flow log storage account."
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Governance tags applied to every resource."
  type        = map(string)
}
