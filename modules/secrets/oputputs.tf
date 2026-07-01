# modules/secrets/outputs.tf

output "db_password_secret_arn" {
  description = "ARN of the DB master password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password" {
  description = "Generated master password — passed to RDS module"
  value       = random_password.db_master.result
  sensitive   = true # Terraform masks this in plan/apply output
}

output "db_connection_secret_arn" {
  description = "ARN of the full connection string secret"
  value       = aws_secretsmanager_secret.db_connection.arn
}

output "db_master_username" {
  description = "Master username"
  value       = var.db_master_username
}
