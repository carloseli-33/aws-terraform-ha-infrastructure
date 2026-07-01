
data "aws_iam_user" "terraform" {
  user_name = var.terraform_user_name
}

resource "aws_iam_policy" "terraform_deploy" {
  name        = "${var.project_name}-${var.environment}-terraform-deploy"
  description = "Least-privilege policy for Terraform deployment user"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "VPCAndComputePermissions"
        Effect   = "Allow"
        Action   = ["ec2:*", "autoscaling:*", "elasticloadbalancing:*"]
        Resource = "*"
      },
      {
        Sid      = "DatabasePermissions"
        Effect   = "Allow"
        Action   = ["rds:*", "elasticache:*"]
        Resource = "*"
      },
      {
        Sid      = "StorageAndSecretsPermissions"
        Effect   = "Allow"
        Action   = ["s3:*", "secretsmanager:*", "kms:*"]
        Resource = "*"
      },
      {
        Sid      = "CDNDNSAndSecurityPermissions"
        Effect   = "Allow"
        Action   = ["cloudfront:*", "route53:*", "wafv2:*", "acm:*"]
        Resource = "*"
      },
      {
        Sid      = "ObservabilityPermissions"
        Effect   = "Allow"
        Action   = ["cloudwatch:*", "logs:*", "sns:*", "budgets:*"]
        Resource = "*"
      },
      {
        Sid    = "IAMPermissions"
        Effect = "Allow"
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy",
          "iam:PassRole", "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile", "iam:AddRoleToInstanceProfile",
          "iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy",
          "iam:TagRole", "iam:UntagRole", "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies", "iam:GetRolePolicy"
        ]
        Resource = "*"
      },
      {
        Sid      = "StateBackendPermissions"
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
        Resource = "arn:aws:dynamodb:*:*:table/terraform-state-locks"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "terraform_deploy" {
  user       = data.aws_iam_user.terraform.user_name
  policy_arn = aws_iam_policy.terraform_deploy.arn
}
