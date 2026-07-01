# modules/rds/main.tf

# ─── DB SUBNET GROUP ─────────────────────────────────────────────────
# Tells Aurora which subnets it can place instances in.
# Always use the isolated database subnets — never the app or public subnets.

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Database subnet group for Aurora cluster"
  subnet_ids  = var.database_subnet_ids

  tags = { Name = "${var.project_name}-${var.environment}-db-subnet-group" }
}

# ─── CLUSTER PARAMETER GROUP ─────────────────────────────────────────
# Database engine configuration. These params apply to the entire cluster.

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-aurora-params"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL 8.0 cluster parameter group"

  # Enable slow query logging — essential for performance tuning
  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  # Log queries taking longer than 1 second
  parameter {
    name  = "long_query_time"
    value = "1"
  }

  # Enable general query log for dev (disable in prod for performance)
  parameter {
    name  = "general_log"
    value = var.environment == "dev" ? "1" : "0"
  }

  tags = { Name = "${var.project_name}-${var.environment}-aurora-params" }
}


# ─── AURORA CLUSTER ──────────────────────────────────────────────────
# The cluster is the logical container — it holds the shared storage volume
# and the cluster endpoint (writer) and reader endpoint.

resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.04.0"
  database_name      = var.db_name
  master_username    = var.db_master_username
  master_password    = var.db_master_password

  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [var.rds_security_group_id]

  # Availability zones for instance placement
  availability_zones = var.availability_zones

  # Automated backups — 7 days retention
  backup_retention_period = var.backup_retention_days
  preferred_backup_window = "03:00-04:00" # 3-4 AM UTC — low traffic

  # Maintenance window — weekly, also low traffic
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  # Encrypt data at rest using AWS-managed KMS key
  storage_encrypted = true

  # Enable deletion protection in prod; allow destroy in dev
  deletion_protection = var.environment == "prod" ? true : false

  # Skip final snapshot in dev to allow easy terraform destroy
  skip_final_snapshot       = var.environment == "dev" ? true : false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"

  # Enable Enhanced Monitoring (sends metrics every 60 seconds)
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  # Allow minor version upgrades during maintenance window
  allow_major_version_upgrade = false

  tags = { Name = "${var.project_name}-${var.environment}-aurora" }

  lifecycle {
    ignore_changes = [availability_zones]
  }
}


# ─── AURORA CLUSTER INSTANCES ────────────────────────────────────────
# Aurora separates storage (cluster) from compute (instances).
# Instance 0 = writer, instances 1+ = readers.
# count = 2 gives you 1 writer + 1 reader — enough for dev.
# Set count = 3 in prod for 1 writer + 2 readers.

resource "aws_rds_cluster_instance" "main" {
  count              = var.environment == "prod" ? 3 : 2
  identifier         = "${var.project_name}-${var.environment}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  # Distribute instances across AZs
  availability_zone = var.availability_zones[count.index]

  # Enhanced monitoring — sends OS-level metrics to CloudWatch
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  # Enable performance insights for query-level visibility
  performance_insights_enabled = true

  # Allow minor version auto-upgrades during maintenance
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-${count.index == 0 ? "writer" : "reader-${count.index}"}"
  }
}

# ─── IAM ROLE FOR ENHANCED MONITORING ────────────────────────────────

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

