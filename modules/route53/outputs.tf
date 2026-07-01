# modules/route53/outputs.tf

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Name servers to configure at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "domain_url" {
  description = "Full URL for the root domain"
  value       = "https://${var.domain_name}"
}
