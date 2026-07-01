# modules/s3-assets/outputs.tf

output "bucket_name" {
  description = "S3 assets bucket name"
  value       = aws_s3_bucket.assets.id
}

output "bucket_arn" {
  description = "S3 assets bucket ARN"
  value       = aws_s3_bucket.assets.arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name — used by CloudFront origin in Phase 4"
  value       = aws_s3_bucket.assets.bucket_regional_domain_name
}
