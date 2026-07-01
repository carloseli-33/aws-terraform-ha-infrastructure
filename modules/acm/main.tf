
# Request the certificate
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"] # wildcard covers all subdomains
  validation_method         = "DNS"

  tags = { Name = "${var.project_name}-${var.environment}-cert" }

  lifecycle {
    # Create a new cert before destroying the old one
    # Critical — destroying first would break HTTPS on your ALB
    create_before_destroy = true
  }
}

# Output the DNS validation records so you can add them to Route 53 (Phase 4)
# or your external DNS provider manually for now
output "domain_validation_options" {
  description = "DNS records you must add to validate the certificate"
  value       = aws_acm_certificate.main.domain_validation_options
}

# Wait for validation to complete before allowing other resources to use the cert
# This resource will block until ACM confirms the certificate is issued
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn
  # validation_record_fqdns will be wired in from Route 53 in Phase 4
  # For now, validate manually via your DNS provider
}
