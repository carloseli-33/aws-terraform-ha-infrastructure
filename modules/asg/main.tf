# modules/asg/main.tf

# ─── IAM ROLE FOR EC2 INSTANCES ──────────────────────────────────────
# Allows instances to call AWS APIs without embedding credentials.
# SSM Agent: you can shell into instances without opening port 22.
# CloudWatch Agent: sends custom metrics and logs.

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach AWS-managed policies — no need to write these from scratch
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile — the wrapper that lets EC2 use an IAM role
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}


# ─── LATEST AMAZON LINUX 2023 AMI ────────────────────────────────────
# Using a data source means your ASG always gets the latest patched AMI
# on the next terraform apply — no manual AMI ID hunting.

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


# ─── LAUNCH TEMPLATE ─────────────────────────────────────────────────
# The blueprint every new EC2 instance is created from.
# Change this and update the ASG to rolling-replace your fleet.

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-app-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # Attach the IAM instance profile (SSM + CloudWatch access)
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  # Attach the app security group
  network_interfaces {
    associate_public_ip_address = false # Private subnet — no public IP
    security_groups             = [var.app_security_group_id]
    delete_on_termination       = true
  }

  # IMDSv2 — security best practice
  # Prevents SSRF attacks from reaching the EC2 metadata service
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 — tokens required
    http_put_response_hop_limit = 1
  }

  # Encrypt the root EBS volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # User data — runs once on first boot as root
  # This installs nginx and starts a simple health-check page
  user_data = base64encode(<<-EOT
    #!/bin/bash
    set -e

    # Update the system
    dnf update -y

    # Install nginx
    dnf install -y nginx

    # Install CloudWatch agent
    dnf install -y amazon-cloudwatch-agent

    # Create a simple index page that shows the instance ID
    INSTANCE_ID=$(curl -sf -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600' \
      -X PUT http://169.254.169.254/latest/api/token | \
      xargs -I{} curl -sf -H 'X-aws-ec2-metadata-token: {}' \
      http://169.254.169.254/latest/meta-data/instance-id)

    cat > /usr/share/nginx/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
    <head><title>HA Infrastructure Demo</title></head>
    <body style='font-family:Arial;text-align:center;padding:60px'>
      <h1>Highly Available AWS Infrastructure</h1>
      <p>Built with Terraform by Carlos</p>
      <p>Instance ID: <strong>$INSTANCE_ID</strong></p>
      <p>Refresh to see load balancing across instances!</p>
    </body>
    </html>
    HTML

    # Enable and start nginx
    systemctl enable nginx
    systemctl start nginx

    # Start CloudWatch agent with default config
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -s
  EOT
  )

  # When a new version of this template is created, use it for new instances
  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-${var.environment}-launch-template" }
}


# ─── AUTO SCALING GROUP ──────────────────────────────────────────────

resource "aws_autoscaling_group" "app" {
  name             = "${var.project_name}-${var.environment}-asg"
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Spread instances across all 3 private subnets (3 AZs)
  vpc_zone_identifier = var.private_subnet_ids

  # Connect to the ALB target group
  target_group_arns = [var.target_group_arn]

  # Use ALB health checks — not just EC2 status checks
  # This means an instance is replaced if nginx stops responding, not just if the VM crashes
  health_check_type         = "ELB"
  health_check_grace_period = 300 # Give new instances 5 min to boot before health checks

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Instance refresh — rolling replacement when launch template changes
  # Set min_healthy_percentage = 50 so at least half the fleet stays up during updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }
  # Wait for instances to pass ALB health checks before marking the ASG healthy
  wait_for_capacity_timeout = "10m"

  # Override instance tags (the ASG propagates these to every launched EC2)
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Role"
    value               = "app"
    propagate_at_launch = true
  }

  lifecycle {
    # Ignore changes to desired_capacity made by Auto Scaling policies
    # Without this, terraform apply would reset your instance count on every run
    ignore_changes = [desired_capacity]
  }
}



##################################

# ─── AUTO SCALING POLICY — CPU TARGET TRACKING ───────────────────────
# Target tracking is the simplest policy type: you specify the metric and target,
# AWS handles the math of how many instances to add or remove.

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-${var.environment}-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = var.cpu_target_value
    disable_scale_in = false
  }
}



# ─── SNS TOPIC FOR ALERTS ────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ─── CLOUDWATCH ALARMS ───────────────────────────────────────────────

# High CPU alarm — fires when avg CPU > 80% for 2 consecutive 5-minute periods
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ASG average CPU exceeded 80% for 10 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Low CPU alarm — fires when avg CPU < 10% (over-provisioned, scale in candidate)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 10
  alarm_description   = "ASG average CPU below 10% for 15 minutes — scale-in candidate"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ALB unhealthy host alarm — fires if any target is unhealthy
# Wire the target_group_arn as a dimension after output from alb module
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "One or more ALB targets are unhealthy"

  dimensions = {
    TargetGroup = var.target_group_arn
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
