# Security Group for EC2 instances
resource "aws_security_group" "ec2" {
  name        = "bot-deception-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    description     = "SSH from Instance Connect Endpoint"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    # Reference the Instance Connect Endpoint security group directly
    # This ensures proper communication between the endpoint and EC2 instances
    security_groups = [aws_security_group.instance_connect_endpoint.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bot Trapper EC2 Security Group"
  }
}

# Security Group for Instance Connect Endpoint
resource "aws_security_group" "instance_connect_endpoint" {
  name        = "bot-deception-ice-sg"
  description = "Security group for Instance Connect Endpoint"
  vpc_id      = var.vpc_id

  # Instance Connect Endpoints don't need ingress rules
  # They only need egress rules to connect to EC2 instances

  egress {
    description = "SSH to EC2 instances in VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Use VPC CIDR to avoid circular dependency with EC2 security group
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "Bot Trapper Instance Connect Endpoint Security Group"
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2" {
  name = "bot-deception-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Bot Trapper EC2 Role"
  }
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "bot-deception-ec2-s3-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.website_bucket_name}-*",
          "arn:aws:s3:::${var.website_bucket_name}-*/*"
        ]
      }
    ]
  })
}

# Attach SSM managed policy for EC2 access
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "bot-deception-ec2-profile"
  role = aws_iam_role.ec2.name
}

# User Data Script
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    website_bucket_name = var.actual_website_bucket_name
  }))
}

# Launch Template
resource "aws_launch_template" "main" {
      name_prefix   = "bot-deception-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = local.user_data

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Bot Trapper Web Server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "bot-deception-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.alb_target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Bot Trapper ASG"
    propagate_at_launch = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 Instance Connect Endpoint for SSH access through AWS console
# This allows secure SSH access to private EC2 instances without requiring:
# - Public IP addresses on instances
# - Bastion hosts
# - VPN connections
resource "aws_ec2_instance_connect_endpoint" "main" {
  subnet_id          = var.private_subnet_ids[0]  # Use first private subnet
  security_group_ids = [aws_security_group.instance_connect_endpoint.id]

  tags = {
    Name = "Bot Trapper Instance Connect Endpoint"
  }
}

# Data source for Amazon Linux 2023 AMI (latest version, standard not ECS-optimized)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  # Exclude ECS-optimized AMIs to ensure Instance Connect is pre-installed
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
