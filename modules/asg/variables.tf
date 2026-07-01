# modules/asg/variables.tf

variable "project_name" { type = string }
variable "environment" { type = string }

variable "private_subnet_ids" {
  description = "Private subnets for EC2 instances (never public subnets)"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security Group ID for app EC2 instances"
  type        = string
}

variable "target_group_arn" {
  description = "ALB Target Group ARN to attach instances to"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_target_value" {
  description = "CPU % target for auto scaling"
  type        = number
  default     = 60
}

variable "alert_email" {
  description = "SNS notification email for CloudWatch alarms"
  type        = string
  default     = ""
}
