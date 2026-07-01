# modules/s3-assets/main.tf

data "aws_caller_identity" "current" {}

locals {
  # Auto-generate bucket name if not provided
  bucket_name = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-${var.environment}-assets-${data.aws_caller_identity.current.account_id}"
}

# ─── S3 BUCKET ───────────────────────────────────────────────────────

resource "aws_s3_bucket" "assets" {
  bucket        = local.bucket_name
  force_destroy = var.environment == "dev" ? true : false

  tags = { Name = local.bucket_name }
}

# ─── VERSIONING ──────────────────────────────────────────────────────
# Keep previous versions of files — allows rollback if a bad deploy
# overwrites a production asset.

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration { status = "Enabled" }
}

# ─── ENCRYPTION ──────────────────────────────────────────────────────

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ─── BLOCK PUBLIC ACCESS ─────────────────────────────────────────────
# Assets are served via CloudFront (Phase 4) — never directly from S3.
# Keep the bucket private and let CloudFront handle public access.

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ─── LIFECYCLE RULES ─────────────────────────────────────────────────
# Automatically move older versions to cheaper storage classes.
# This reduces storage costs significantly over time.

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "transition-old-versions"
    status = "Enabled"

    # Transition current versions after 90 days
    transition {
      days          = var.lifecycle_days
      storage_class = "STANDARD_IA"
    }

    # Expire non-current (old) versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    filter { prefix = "" }
  }
}

# ─── CORS CONFIGURATION ──────────────────────────────────────────────
# Allows your web app to fetch assets from S3 directly via browser.

resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"] # Tighten to your domain in Phase 4
    max_age_seconds = 3600
  }
}
