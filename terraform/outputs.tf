output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "origin_alb_arn" {
  description = "ARN of the origin ALB"
  value       = module.alb.origin_alb_arn
}

output "timeout_alb_arn" {
  description = "ARN of the timeout ALB"
  value       = module.alb.timeout_alb_arn
}

output "origin_alb_dns_name" {
  description = "DNS name of the origin ALB"
  value       = module.alb.origin_alb_dns_name
}

output "timeout_alb_dns_name" {
  description = "DNS name of the timeout ALB"
  value       = module.alb.timeout_alb_dns_name
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = module.waf.web_acl_arn
}

output "website_bucket_name" {
  description = "Name of the website source bucket"
  value       = module.s3.website_bucket_name
}

output "fake_webpage_bucket_name" {
  description = "Name of the fake webpage bucket"
  value       = module.s3.fake_webpage_bucket_name
}

output "fake_webpage_bucket_arn" {
  description = "ARN of the fake webpage bucket"
  value       = module.s3.fake_webpage_bucket_arn
}

output "fake_webpage_bucket_domain_name" {
  description = "Domain name of the fake webpage bucket"
  value       = module.s3.fake_webpage_bucket_domain_name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.distribution_domain_name
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.cloudfront.distribution_arn
}

output "instance_connect_endpoint_id" {
  description = "ID of the Instance Connect Endpoint"
  value       = module.ec2.instance_connect_endpoint_id
}

output "instance_connect_endpoint_dns_name" {
  description = "DNS name of the Instance Connect Endpoint"
  value       = module.ec2.instance_connect_endpoint_dns_name
} 