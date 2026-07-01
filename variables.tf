variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "ha-project"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for isolated database subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateways for private subnet outbound traffic"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (cost saving for dev; use false for prod)"
  type        = bool
  default     = true
}


# ─── PHASE 2 — COMPUTE VARIABLES ─────────────────────────────────────

variable "domain_name" {
  description = "Your domain name for ACM certificate (e.g. example.com)"
  type        = string
  # If you don't have a domain yet, leave this empty and we'll use HTTP only
  default = ""
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group"
  type        = string
  default     = "t3.micro" # Free-tier eligible; change to t3.small for prod
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
  default     = 2 # Always >= 2 for HA (never run prod on a single instance)
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Initial desired count — ASG will scale from here"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "ALB target group health check path"
  type        = string
  default     = "/"
}

variable "cpu_target_value" {
  description = "Target CPU % for Auto Scaling target tracking policy"
  type        = number
  default     = 60
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm SNS notifications"
  type        = string
  default     = ""
}



# ─── PHASE 3 — DATA LAYER VARIABLES ──────────────────────────────────

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_master_username" {
  description = "Master username for RDS Aurora cluster"
  type        = string
  default     = "admin"
}

variable "db_instance_class" {
  description = "RDS instance class for Aurora cluster members"
  type        = string
  default     = "db.t3.medium"
}

variable "db_backup_retention_days" {
  description = "Days to retain automated RDS backups"
  type        = number
  default     = 7
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes (min 2 for Multi-AZ)"
  type        = number
  default     = 2
}

variable "assets_bucket_name" {
  description = "Name for the S3 static assets bucket (must be globally unique)"
  type        = string
  default     = "" # Will be auto-generated using account ID if empty
}

variable "assets_lifecycle_days" {
  description = "Days before transitioning assets to S3 Standard-IA storage class"
  type        = number
  default     = 90
}


# ─── PHASE 4 — EDGE & DNS VARIABLES ──────────────────────────────────

# ─── PHASE 4 — EDGE & DNS VARIABLES ──────────────────────────────────

variable "subdomain" {
  description = "Subdomain prefix (e.g. 'www' gives www.myapp.com)"
  type        = string
  default     = "www"
}

variable "cloudfront_price_class" {
  description = "CloudFront price class — controls which edge locations are used"
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_default_ttl" {
  description = "Default cache TTL in seconds"
  type        = number
  default     = 86400
}

variable "waf_rate_limit" {
  description = "Max requests per 5 minutes per IP before WAF blocks"
  type        = number
  default     = 2000
}

variable "enable_waf" {
  description = "Whether to attach WAF WebACL to CloudFront"
  type        = bool
  default     = true
}

variable "monthly_budget_limit" {
  description = "Monthly AWS budget limit in USD"
  type        = string
  default     = "50"
}
