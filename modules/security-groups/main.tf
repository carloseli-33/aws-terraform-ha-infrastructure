# modules/security-groups/main.tf

# ─── ALB SECURITY GROUP ──────────────────────────────────────────────
# Faces the internet. Accepts HTTPS and HTTP from anywhere.
# HTTP exists only to redirect to HTTPS (handled by ALB listener rule).

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Controls traffic to/from the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound (ALB to app instances)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-alb-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

# ─── APP / EC2 SECURITY GROUP ─────────────────────────────────────────
# Lives in private subnets. ONLY accepts traffic from the ALB SG.
# This is the key pattern — scope ingress to SG ID, not CIDR block.

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Controls traffic to EC2 instances in the app tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB only — never from internet directly"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Outbound to internet via NAT GW (yum, SSM, CloudWatch)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-app-sg" }

  lifecycle {
    create_before_destroy = true
  }
}
