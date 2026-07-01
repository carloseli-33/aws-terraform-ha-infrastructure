# modules/db-security-groups/variables.tf

variable "project_name" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }

variable "app_security_group_id" {
  description = "App tier SG ID — only this SG can reach the database"
  type        = string
}
