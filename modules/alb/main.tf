# modules/alb/main.tf

# ─── S3 BUCKET FOR ALB ACCESS LOGS ──────────────────────────────────
# ALB can log every request to S3. Essential for debugging and compliance.

data "aws_elb_service_account" "main" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project_name}-${var.environment}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = { Name = "${var.project_name}-${var.environment}-alb-logs" }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    expiration { days = 90 }
    filter { prefix = "alb/" }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowALBLogging"
      Effect    = "Allow"
      Principal = { AWS = data.aws_elb_service_account.main.arn }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.alb_logs.arn}/alb/*"
    }]
  })
}

# ─── APPLICATION LOAD BALANCER ────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb"
    enabled = true
  }

  tags = { Name = "${var.project_name}-${var.environment}-alb" }

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# ─── TARGET GROUP ─────────────────────────────────────────────────────

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = var.health_check_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = 5
    interval            = var.health_check_interval
    matcher             = "200-299"
  }

  deregistration_delay = 60

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = { Name = "${var.project_name}-${var.environment}-app-tg" }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── HTTPS LISTENER ───────────────────────────────────────────────────

resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ─── HTTP LISTENER ────────────────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.certificate_arn == "" ? [1] : []
      content {
        target_group {
          arn    = aws_lb_target_group.app.arn
          weight = 1
        }
      }
    }
  }
}
