# AWS Highly Available Infrastructure — Terraform

![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-Multi--AZ-FF9900?logo=amazon-aws&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)
![License](https://img.shields.io/badge/License-MIT-blue)

## Overview

Production-grade, highly available AWS infrastructure built entirely with
Terraform. Designed to eliminate single points of failure at every layer
of the stack — from networking through to the CDN edge.

This project demonstrates real-world DevOps skills:
modular Terraform, multi-AZ high availability, layered security,
observability, and cost-aware infrastructure design.

## Architecture

```
User → Route 53 → WAF → CloudFront → [S3 Assets / ALB]
                              ALB → EC2 Auto Scaling Group
                              EC2 → RDS Aurora MySQL (Multi-AZ)
                              EC2 → ElastiCache Redis (Multi-AZ)
                              EC2 → Secrets Manager
CloudWatch ← All services → Dashboard + Alarms → SNS → Email
```

## Stack

| Layer | Service | Details |
|-------|---------|---------|
| Networking | VPC | Multi-AZ, 9 subnets, Flow Logs |
| Compute | EC2 + ALB + ASG | Private subnets, IMDSv2, rolling deploy |
| Database | RDS Aurora MySQL 8.0 | Writer + 2 readers, encrypted |
| Cache | ElastiCache Redis 7.x | Multi-AZ failover, TLS |
| Storage | S3 | Versioned, encrypted, lifecycle rules |
| Secrets | Secrets Manager | Auto-generated, 30-day rotation |
| CDN | CloudFront | Global edge, OAC, cache behaviors |
| Security | WAF | OWASP rules, SQLi, rate limiting |
| DNS | Route 53 | Alias records, ACM validation |
| Observability | CloudWatch | Dashboard, alarms, SNS alerts |
| IaC | Terraform | Modular, remote state, version-pinned |

## Project Structure

```
.
├── modules/
│   ├── vpc/                # Networking foundation
│   ├── security-groups/    # ALB and app tier SGs
│   ├── acm/                # TLS certificate
│   ├── alb/                # Application Load Balancer
│   ├── asg/                # Auto Scaling Group + Launch Template
│   ├── db-security-groups/ # Database firewall rules
│   ├── secrets/            # Secrets Manager
│   ├── rds/                # Aurora MySQL cluster
│   ├── elasticache/        # Redis cluster
│   ├── s3-assets/          # Static asset storage
│   ├── waf/                # Web Application Firewall
│   ├── cloudfront/         # CDN distribution
│   ├── route53/            # DNS
│   ├── monitoring/         # CloudWatch dashboard + alarms
│   ├── iam-hardening/      # Least-privilege IAM
│   └── budgets/            # Cost alerts
├── main.tf                 # Root module
├── variables.tf            # Input declarations
├── outputs.tf              # Output values
├── versions.tf             # Provider + backend config
└── example.tfvars          # Reference variable values
```

## Phases

- [x] Phase 1 — VPC Foundation + Remote State Backend
- [x] Phase 2 — Compute (ALB + ASG + Security Groups + ACM)
- [x] Phase 3 — Data Layer (RDS Aurora + ElastiCache + S3 + Secrets Manager)
- [x] Phase 4 — Edge & DNS (CloudFront + WAF + Route 53)
- [x] Phase 5 — Observability & Security Hardening

## Cost Estimate

| Component | Monthly Cost |
|-----------|-------------|
| RDS Aurora (2x db.t3.medium) | ~$130 |
| NAT Gateway | ~$35 |
| ALB | ~$16 |
| EC2 (2x t3.micro) | ~$15 |
| ElastiCache Redis (2x cache.t3.micro) | ~$25 |
| WAF | ~$6 |
| CloudFront + S3 | ~$5 |
| Route 53 | ~$0.50 |
| **Total** | **~$233/month** |

> Infrastructure is not permanently running to avoid costs.
> Deploy with `terraform apply`, destroy with `terraform destroy`.

## Deployment

### Prerequisites
- Terraform >= 1.7.0
- AWS CLI >= 2.x
- AWS account with programmatic access

### Setup
```bash
# Configure AWS credentials
aws configure --profile terraform-ha-project
export AWS_PROFILE=terraform-ha-project

# Bootstrap remote state (one-time)
chmod +x scripts/bootstrap-backend.sh
./scripts/bootstrap-backend.sh

# Deploy
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# Destroy when done
terraform destroy -var-file=terraform.tfvars
```

## Author

**Carlos Elizondo** | DevOps Engineer | AWS Certified
Frisco, TX | [LinkedIn](https://linkedin.com/in/your-profile)

