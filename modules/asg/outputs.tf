# modules/asg/outputs.tf

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  description = "Latest Launch Template version number"
  value       = aws_launch_template.app.latest_version
}

output "ec2_iam_role_arn" {
  description = "IAM Role ARN attached to EC2 instances"
  value       = aws_iam_role.ec2.arn
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for CloudWatch alarm notifications"
  value       = aws_sns_topic.alerts.arn
}
