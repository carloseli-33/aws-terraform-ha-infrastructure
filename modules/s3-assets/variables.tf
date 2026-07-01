# modules/s3-assets/variables.tf

variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "bucket_name" {
  type    = string
  default = ""
}

variable "lifecycle_days" {
  type    = number
  default = 90
}
