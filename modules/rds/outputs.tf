# modules/rds/outputs.tf

output "cluster_endpoint" {
  description = "Writer endpoint — use for INSERT, UPDATE, DELETE"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint — use for SELECT queries (load balanced)"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_identifier" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.main.cluster_identifier
}

output "database_name" {
  description = "Initial database name"
  value       = aws_rds_cluster.main.database_name
}

output "port" {
  description = "Database port"
  value       = aws_rds_cluster.main.port
}
