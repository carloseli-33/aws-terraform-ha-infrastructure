# modules/acm/variables.tf

variable "domain_name" {
  description = "Primary domain name for the certificate"
  type        = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}
