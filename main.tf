# ─── PHASE 1: VPC ─────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  enable_nat_gateway    = var.enable_nat_gateway
  single_nat_gateway    = var.single_nat_gateway
}

# ─── PHASE 2: SECURITY GROUPS ─────────────────────────────────────────

module "security_groups" {
  source = "./modules/security-groups"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
}

# ─── PHASE 2: ACM CERTIFICATE (optional — only if domain is set) ──────

module "acm" {
  source = "./modules/acm"
  count  = var.domain_name != "" ? 1 : 0

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.domain_name
}

# ─── PHASE 2: ALB ─────────────────────────────────────────────────────

module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_sg_id
  health_check_path     = var.health_check_path

  # Pass certificate ARN if ACM module ran, otherwise empty string
  certificate_arn = var.domain_name != "" ? module.acm[0].certificate_arn : ""
}

# ─── PHASE 2: AUTO SCALING GROUP ──────────────────────────────────────

module "asg" {
  source = "./modules/asg"

  project_name          = var.project_name
  environment           = var.environment
  private_subnet_ids    = module.vpc.private_subnet_ids
  app_security_group_id = module.security_groups.app_sg_id
  target_group_arn      = module.alb.target_group_arn
  instance_type         = var.instance_type
  min_size              = var.asg_min_size
  max_size              = var.asg_max_size
  desired_capacity      = var.asg_desired_capacity
  cpu_target_value      = var.cpu_target_value
  alert_email           = var.alert_email
}


# main.tf (root) — append Phase 3 below Phase 2 modules

# ─── PHASE 3: DATABASE SECURITY GROUPS ───────────────────────────────

module "db_security_groups" {
  source = "./modules/db-security-groups"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  app_security_group_id = module.security_groups.app_sg_id
}

# ─── PHASE 3: SECRETS MANAGER ─────────────────────────────────────────

module "secrets" {
  source = "./modules/secrets"

  project_name       = var.project_name
  environment        = var.environment
  db_name            = var.db_name
  db_master_username = var.db_master_username
}

# ─── PHASE 3: RDS AURORA ──────────────────────────────────────────────

module "rds" {
  source = "./modules/rds"

  project_name          = var.project_name
  environment           = var.environment
  database_subnet_ids   = module.vpc.database_subnet_ids
  rds_security_group_id = module.db_security_groups.rds_sg_id
  availability_zones    = var.availability_zones
  db_name               = var.db_name
  db_master_username    = var.db_master_username
  db_master_password    = module.secrets.db_password
  instance_class        = var.db_instance_class
  backup_retention_days = var.db_backup_retention_days
}

# ─── PHASE 3: ELASTICACHE REDIS ───────────────────────────────────────

module "elasticache" {
  source = "./modules/elasticache"

  project_name            = var.project_name
  environment             = var.environment
  database_subnet_ids     = module.vpc.database_subnet_ids
  redis_security_group_id = module.db_security_groups.redis_sg_id
  availability_zones      = var.availability_zones
  node_type               = var.redis_node_type
  num_cache_nodes         = var.redis_num_cache_nodes
}

# ─── PHASE 3: S3 ASSETS ───────────────────────────────────────────────

module "s3_assets" {
  source = "./modules/s3-assets"

  project_name   = var.project_name
  environment    = var.environment
  bucket_name    = var.assets_bucket_name
  lifecycle_days = var.assets_lifecycle_days
}

