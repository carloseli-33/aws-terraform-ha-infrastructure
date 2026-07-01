# modules/rds/variables.tf

variable "project_name" { type = string }
variable "environment" { type = string }
variable "database_subnet_ids" { type = list(string) }
variable "rds_security_group_id" { type = string }
variable "db_name" { type = string }
variable "db_master_username" { type = string }
variable "db_master_password" {
  type      = string
  sensitive = true
}
variable "instance_class" {
  type    = string
  default = "db.t3.medium"
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "availability_zones" { type = list(string) }
