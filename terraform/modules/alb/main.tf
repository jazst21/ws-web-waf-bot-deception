# Security Group for Origin ALB
resource "aws_security_group" "origin_alb" {
  name        = "bot-deception-origin-alb-sg"
  description = "Security group for origin ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bot Trapper Origin ALB Security Group"
  }
}

# Security Group for Timeout ALB
resource "aws_security_group" "timeout_alb" {
  name        = "bot-deception-timeout-alb-sg"
  description = "Security group for timeout ALB (no inbound rules)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bot Trapper Timeout ALB Security Group"
  }
}

# Origin ALB
resource "aws_lb" "origin" {
  name               = "bot-deception-origin-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.origin_alb.id]
  subnets            = var.private_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "Bot Trapper Origin ALB"
  }
}

# Timeout ALB
resource "aws_lb" "timeout" {
  name               = "bot-deception-timeout-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.timeout_alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "Bot Trapper Timeout ALB"
  }
}

# Target Group for Origin ALB
resource "aws_lb_target_group" "origin" {
  name     = "bot-deception-origin-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "Bot Trapper Origin Target Group"
  }
}

# Listener for Origin ALB
resource "aws_lb_listener" "origin" {
  load_balancer_arn = aws_lb.origin.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.origin.arn
  }
}

# Listener for Timeout ALB (redirects to amazon.com)
resource "aws_lb_listener" "timeout" {
  load_balancer_arn = aws_lb.timeout.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      host        = "www.amazon.com"
      path        = "/"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
