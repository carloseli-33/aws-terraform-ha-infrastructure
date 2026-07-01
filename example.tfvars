# example.tfvars  (commit this)
# Copy to terraform.tfvars and fill in your values

aws_region   = "us-east-1"
project_name = "ha-project"
environment  = "dev"

vpc_cidr              = "10.0.0.0/16"
availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

enable_nat_gateway = true
single_nat_gateway = true # Set false in prod for true HA


# Append to example.tfvars

# Phase 2 — Compute
domain_name          = "" # e.g. myapp.example.com — leave empty to skip ACM
instance_type        = "t3.micro"
asg_min_size         = 2
asg_max_size         = 6
asg_desired_capacity = 2
health_check_path    = "/"
cpu_target_value     = 60
alert_email          = "your@email.com"


# Phase 3 — Data Layer
db_name                  = "appdb"
db_master_username       = "admin"
db_instance_class        = "db.t3.medium"
db_backup_retention_days = 7
redis_node_type          = "cache.t3.micro"
redis_num_cache_nodes    = 2
assets_bucket_name       = "" # auto-generated
assets_lifecycle_days    = 90


# Phase 4 — Edge & DNS
domain_name            = ""        # e.g. myapp.com
subdomain              = "www"
cloudfront_price_class = "PriceClass_100"
cloudfront_default_ttl = 86400
waf_rate_limit         = 2000
enable_waf             = true
