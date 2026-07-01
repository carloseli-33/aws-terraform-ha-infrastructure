variable "project_name" { type = string }
variable "environment" { type = string }
variable "terraform_user_name" {
  description = "IAM username of the Terraform deployment user"
  type        = string
  default     = "terraform-ha-project"
}
