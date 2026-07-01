# modules/acm/outputs.tf

output "certificate_arn" {
  description = "ARN of the validated ACM certificate"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_status" {
  description = "Current validation status of the certificate"
  value       = aws_acm_certificate.main.status
}
