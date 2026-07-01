# modules/db-security-groups/outputs.tf

output "rds_sg_id" {
  description = "Security Group ID for RDS Aurora"
  value       = aws_security_group.rds.id
}

output "redis_sg_id" {
  description = "Security Group ID for ElastiCache Redis"
  value       = aws_security_group.redis.id
}
