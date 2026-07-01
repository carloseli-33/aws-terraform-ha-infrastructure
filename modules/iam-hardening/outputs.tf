output "policy_arn" {
  description = "ARN of the least-privilege Terraform deployment policy"
  value       = aws_iam_policy.terraform_deploy.arn
}
