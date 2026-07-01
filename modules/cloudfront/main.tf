# ─── ORIGIN ACCESS CONTROL (OAC) ─────────────────────────────────────
# OAC allows CloudFront to access S3 privately.
# The S3 bucket stays completely locked (no public access)
# but CloudFront can read from it using its service identity.
# This replaces the older Origin Access Identity (OAI) pattern.

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-${var.environment}-s3-oac"
  description                       = "OAC for S3 assets bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ─── S3 BUCKET POLICY FOR OAC ────────────────────────────────────────
# Allow CloudFront service principal to GetObject from the bucket.
# The condition ensures only YOUR distribution can read it —
# not any other CloudFront distribution.

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = var.s3_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "arn:aws:s3:::${var.s3_bucket_id}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
        }
      }
    }]
  })
}



# ─── CLOUDFRONT DISTRIBUTION ─────────────────────────────────────────

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} CDN"
  default_root_object = "index.html"
  price_class         = var.price_class

  # Attach WAF if ARN provided
  web_acl_id = var.web_acl_arn != "" ? var.web_acl_arn : null

  # Custom domain aliases (requires ACM cert)
  aliases = var.domain_aliases

  # ─── ORIGIN 1: S3 Assets ─────────────────────────────────────────
  origin {
    origin_id                = "S3Assets"
    domain_name              = var.s3_bucket_regional_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # ─── ORIGIN 2: ALB (App) ─────────────────────────────────────────
  origin {
    origin_id   = "ALBApp"
    domain_name = var.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ─── CACHE BEHAVIOR: /assets/* → S3 ─────────────────────────────
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    target_origin_id = "S3Assets"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = var.default_ttl
    max_ttl                = 31536000 # 1 year for static assets
    compress               = true
  }

  # ─── DEFAULT CACHE BEHAVIOR: /* → ALB ────────────────────────────
  default_cache_behavior {
    target_origin_id = "ALBApp"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "CloudFront-Forwarded-Proto"]
      cookies { forward = "all" }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0 # Don't cache dynamic app responses
    max_ttl                = 0
    compress               = true
  }

  # ─── SSL / TLS ────────────────────────────────────────────────────
  viewer_certificate {
    # Use custom cert if provided, otherwise use default CloudFront cert
    acm_certificate_arn            = var.certificate_arn != "" ? var.certificate_arn : null
    cloudfront_default_certificate = var.certificate_arn == "" ? true : false
    ssl_support_method             = var.certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  # ─── GEO RESTRICTION ─────────────────────────────────────────────
  restrictions {
    geo_restriction {
      restriction_type = "none" # Allow all countries
    }
  }

  # ─── CUSTOM ERROR RESPONSES ──────────────────────────────────────
  # Return index.html for 404s — supports single-page app routing
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  tags = { Name = "${var.project_name}-${var.environment}-cf" }
}
