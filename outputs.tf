output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}


# outputs.tf (root) — append Phase 2 outputs

# Phase 1 outputs remain unchanged...

output "alb_dns_name" {
  description = "ALB DNS name — use this to test your app before DNS is configured"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.alb.alb_arn
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.asg.asg_name
}

output "app_sg_id" {
  description = "App tier Security Group ID"
  value       = module.security_groups.app_sg_id
}

output "alb_sg_id" {
  description = "ALB Security Group ID"
  value       = module.security_groups.alb_sg_id
}


# outputs.tf (root) — append Phase 3 outputs

output "rds_writer_endpoint" {
  description = "Aurora writer endpoint"
  value       = module.rds.cluster_endpoint
}

output "rds_reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = module.rds.cluster_reader_endpoint
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = module.elasticache.primary_endpoint
}

output "assets_bucket_name" {
  description = "S3 assets bucket name"
  value       = module.s3_assets.bucket_name
}

output "db_secret_arn" {
  description = "Secrets Manager ARN for DB credentials"
  value       = module.secrets.db_password_secret_arn
}


