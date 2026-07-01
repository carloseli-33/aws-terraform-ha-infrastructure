
variable "project_name" { type = string }
variable "environment" { type = string }

variable "alb_dns_name" {
  description = "ALB DNS name — CloudFront app origin"
  type        = string
}

variable "s3_bucket_regional_domain" {
  description = "S3 bucket regional domain — CloudFront assets origin"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID for OAC policy"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)"
  type        = string
  default     = ""
}

variable "domain_aliases" {
  description = "Custom domain aliases for the CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "web_acl_arn" {
  description = "WAF WebACL ARN to attach to CloudFront"
  type        = string
  default     = ""
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "default_ttl" {
  type    = number
  default = 86400
}
