# AWS Highly Available Infrastructure — Terraform

![Terraform](https://img.shields.io/badge/Terraform-1.7+-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Multi--AZ-FF9900?logo=amazon-aws)
![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen)

## Infrastructure Cost Notice

This project deploys real AWS infrastructure. To avoid ongoing charges
during portfolio review, infrastructure is not permanently running.

**To deploy:**
```bash
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

**To destroy after reviewing:**
```bash
terraform destroy -var-file=terraform.tfvars
```

**Estimated monthly cost if running 24/7:** ~$70/month (Phase 1+2)

## Overview
Production-grade, highly available AWS infrastructure built entirely
with Terraform. Designed to eliminate single points of failure across
every layer of the stack.

## Architecture
- **Networking**: Multi-AZ VPC (3 AZs), public/private subnets, NAT Gateways
- **Compute**: Application Load Balancer + Auto Scaling Group (EC2)
- **Database**: RDS Aurora MySQL Multi-AZ cluster with read replicas
- **Cache**: ElastiCache Redis cluster
- **Edge**: CloudFront CDN + S3 static assets
- **DNS**: Route 53 with health-check failover
- **Security**: ACM TLS, WAF, least-privilege IAM, Security Groups
- **Observability**: CloudWatch dashboards, alarms, Auto Scaling policies

## Project Structure
```
.
├── environments/       # Per-environment variable files
│   ├── dev/
│   └── prod/
├── modules/            # Reusable Terraform modules
│   ├── vpc/
│   ├── alb/
│   ├── asg/
│   ├── rds/
│   └── .../
├── main.tf             # Root module — wires everything together
├── variables.tf        # Input variable declarations
├── outputs.tf          # Output value declarations
└── versions.tf         # Provider and Terraform version constraints
```

## Phases
- [x] Phase 1 — VPC Foundation + Remote State Backend
- [ ] Phase 2 — Compute (ALB + ASG)
- [ ] Phase 3 — Data Layer (RDS + ElastiCache + S3)
- [ ] Phase 4 — Edge & DNS (CloudFront + Route 53)
- [ ] Phase 5 — Observability & Security Hardening

