# modules/alb/outputs.tf

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name to test the ALB directly (before Route 53 is wired)"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted Zone ID — needed for Route 53 alias record in Phase 4"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "Target Group ARN — the ASG registers instances here"
  value       = aws_lb_target_group.app.arn
}

output "http_listener_arn" {
  description = "HTTP listener ARN"
  value       = aws_lb_listener.http.arn
}

