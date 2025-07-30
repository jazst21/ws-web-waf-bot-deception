output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.main.id
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2.arn
}

output "instance_connect_endpoint_id" {
  description = "ID of the Instance Connect Endpoint"
  value       = aws_ec2_instance_connect_endpoint.main.id
}

output "instance_connect_endpoint_dns_name" {
  description = "DNS name of the Instance Connect Endpoint"
  value       = aws_ec2_instance_connect_endpoint.main.dns_name
}
