# modules/elasticache/main.tf

# ─── SUBNET GROUP ────────────────────────────────────────────────────
# Like RDS, ElastiCache needs to know which subnets it can use.
# Use the same isolated database subnets — not the app subnets.

resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-redis-subnet-group"
  description = "ElastiCache Redis subnet group"
  subnet_ids  = var.database_subnet_ids

  tags = { Name = "${var.project_name}-${var.environment}-redis-subnet-group" }
}

# ─── PARAMETER GROUP ─────────────────────────────────────────────────

resource "aws_elasticache_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-redis-params"
  family = "redis7"

  # Enable active memory defragmentation
  parameter {
    name  = "activedefrag"
    value = "yes"
  }

  # Maximum memory policy — evict least recently used keys when memory is full
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = { Name = "${var.project_name}-${var.environment}-redis-params" }
}

# ─── ELASTICACHE REPLICATION GROUP ───────────────────────────────────
# A replication group is a cluster of Redis nodes.
# primary_endpoint_address = write endpoint
# reader_endpoint_address  = read endpoint (all replicas)

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "Redis cluster for session storage and caching"

  node_type            = var.node_type
  port                 = var.redis_port
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [var.redis_security_group_id]

  # Engine version
  engine_version = "7.0"

  # Number of replica nodes (total nodes = 1 primary + num_cache_nodes-1 replicas)
  num_cache_clusters = var.num_cache_nodes

  # Multi-AZ with automatic failover
  multi_az_enabled           = true
  automatic_failover_enabled = true

  # Distribute nodes across AZs
  preferred_cache_cluster_azs = slice(var.availability_zones, 0, var.num_cache_nodes)

  # Encrypt data at rest and in transit
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # Maintenance window
  maintenance_window = "sun:05:00-sun:06:00"

  # Snapshot for backup
  snapshot_retention_limit = 5
  snapshot_window          = "04:00-05:00"

  # Allow minor version upgrades
  auto_minor_version_upgrade = true

  tags = { Name = "${var.project_name}-${var.environment}-redis" }
}
