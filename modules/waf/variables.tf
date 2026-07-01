variable "project_name" { type = string }
variable "environment" { type = string }

variable "rate_limit" {
  description = "Max requests per 5 minutes per IP"
  type        = number
  default     = 2000
}
