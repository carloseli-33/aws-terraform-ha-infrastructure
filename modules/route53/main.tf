# ─── HOSTED ZONE ──────────────────────────────────────────────────────
# The hosted zone is the container for all DNS records for your domain.
# AWS gives you 4 name servers — you point your domain registrar to these.

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform — ${var.project_name} ${var.environment}"

  tags = { Name = "${var.project_name}-${var.environment}-zone" }
}

# ─── ACM CERTIFICATE VALIDATION RECORDS ───────────────────────────────
# These DNS records prove to AWS that you own the domain.
# Once created, ACM automatically validates the certificate.
# This completes the ACM work started in Phase 2.

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in var.acm_domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]

  allow_overwrite = true
}

# ─── ROOT DOMAIN → CLOUDFRONT ─────────────────────────────────────────
# A record alias for the root domain (myapp.com)
# Alias records are free and have no TTL — they update instantly

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# ─── WWW SUBDOMAIN → CLOUDFRONT ───────────────────────────────────────

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
