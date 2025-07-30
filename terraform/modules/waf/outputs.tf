output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "allowed_ip_set_arn" {
  description = "ARN of the allowed IP set"
  value       = aws_wafv2_ip_set.allowed_ips.arn
}

output "blocked_ip_set_arn" {
  description = "ARN of the blocked IP set"
  value       = aws_wafv2_ip_set.blocked_ips.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.waf.name
}
