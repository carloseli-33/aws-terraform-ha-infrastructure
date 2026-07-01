# modules/alb/variables.tf

variable "project_name" { type = string }
variable "environment" { type = string }

variable "vpc_id" {
  description = "VPC to place the ALB into"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the ALB (must span >= 2 AZs)"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security Group ID for the ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (empty = HTTP only)"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Path the ALB uses to health-check EC2 targets"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Seconds between ALB health checks"
  type        = number
  default     = 30
}

variable "health_check_threshold" {
  description = "Consecutive successes before marking target healthy"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Consecutive failures before marking target unhealthy"
  type        = number
  default     = 3
}
