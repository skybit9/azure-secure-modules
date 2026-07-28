variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "canadacentral"
}

variable "network_watcher_name" {
  description = "Regional Network Watcher name, required for NSG flow logs."
  type        = string
  default     = "NetworkWatcher_canadacentral"
}
