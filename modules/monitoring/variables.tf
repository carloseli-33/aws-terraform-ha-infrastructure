variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "rds_cluster_id" {
  type = string
}

variable "redis_cluster_id" {
  type = string
}

variable "cloudfront_distribution_id" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
