
variable "project_name" { type = string }
variable "environment" { type = string }

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "50"
}

variable "alert_email" {
  description = "Email to receive budget alerts"
  type        = string
}

variable "alert_threshold_percent" {
  description = "Alert when spend reaches this % of budget"
  type        = number
  default     = 80
}
