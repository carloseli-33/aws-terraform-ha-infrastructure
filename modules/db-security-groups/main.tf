# modules/db-security-groups/main.tf

# ─── RDS AURORA SECURITY GROUP ───────────────────────────────────────
# Only the app tier EC2 instances can connect to MySQL.
# Scoped to the app SG ID — not a CIDR — so even VPN users can't reach it
# without going through an app instance first.

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Controls access to RDS Aurora cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from app tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-rds-sg" }

  lifecycle { create_before_destroy = true }
}

# ─── ELASTICACHE REDIS SECURITY GROUP ────────────────────────────────

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Controls access to ElastiCache Redis cluster"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from app tier only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.environment}-redis-sg" }

  lifecycle { create_before_destroy = true }
}
