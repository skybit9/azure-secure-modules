variable "subscription_id" {
  description = "Target Azure subscription ID."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Existing Log Analytics workspace that receives diagnostics."
  type        = string
}
