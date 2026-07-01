# modules/security-groups/variables.tf

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  description = "VPC ID from the VPC module output"
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR — used to restrict internal traffic"
  type        = string
}
