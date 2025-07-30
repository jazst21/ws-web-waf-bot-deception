output "origin_alb_arn" {
  description = "ARN of the origin ALB"
  value       = aws_lb.origin.arn
}

output "origin_alb_dns_name" {
  description = "DNS name of the origin ALB"
  value       = aws_lb.origin.dns_name
}

output "origin_alb_zone_id" {
  description = "Zone ID of the origin ALB"
  value       = aws_lb.origin.zone_id
}

output "timeout_alb_arn" {
  description = "ARN of the timeout ALB"
  value       = aws_lb.timeout.arn
}

output "timeout_alb_dns_name" {
  description = "DNS name of the timeout ALB"
  value       = aws_lb.timeout.dns_name
}

output "timeout_alb_zone_id" {
  description = "Zone ID of the timeout ALB"
  value       = aws_lb.timeout.zone_id
}

output "origin_target_group_arn" {
  description = "ARN of the origin target group"
  value       = aws_lb_target_group.origin.arn
}

output "origin_security_group_id" {
  description = "ID of the origin ALB security group"
  value       = aws_security_group.origin_alb.id
}

output "timeout_security_group_id" {
  description = "ID of the timeout ALB security group"
  value       = aws_security_group.timeout_alb.id
}
