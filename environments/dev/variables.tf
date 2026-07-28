variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "name_prefix" {
  description = "Short naming prefix."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_address_space" {
  description = "VNet address space."
  type        = list(string)
}

variable "network_watcher_name" {
  description = "Name of the regional Network Watcher."
  type        = string
  default     = null
}

variable "tags" {
  description = "Governance tags."
  type        = map(string)
}
