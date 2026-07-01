# modules/elasticache/variables.tf

variable "project_name" { type = string }
variable "environment" { type = string }
variable "database_subnet_ids" { type = list(string) }
variable "redis_security_group_id" { type = string }
variable "availability_zones" { type = list(string) }

variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of nodes (min 2 for Multi-AZ failover)"
  type        = number
  default     = 2
}

variable "redis_port" {
  type    = number
  default = 6379
}
