
variable "project_name" { type = string }
variable "environment" { type = string }

variable "domain_name" {
  description = "Root domain name (e.g. myapp.com)"
  type        = string
}

variable "subdomain" {
  description = "Subdomain prefix"
  type        = string
  default     = "www"
}

variable "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID (fixed AWS value)"
  type        = string
  default     = "Z2FDTNDATAQYW2" # This is always the same for CloudFront
}

variable "acm_domain_validation_options" {
  description = "Domain validation options from ACM certificate"
  type        = any
}
