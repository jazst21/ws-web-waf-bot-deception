variable "origin_alb_dns_name" {
  description = "DNS name of the origin ALB"
  type        = string
}

variable "timeout_alb_dns_name" {
  description = "DNS name of the timeout ALB"
  type        = string
}

variable "fake_webpage_bucket_name" {
  description = "Name of the fake webpage S3 bucket"
  type        = string
}

variable "fake_webpage_bucket_domain_name" {
  description = "Domain name of the fake webpage S3 bucket"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  type        = string
}

variable "logging_bucket_name" {
  description = "Name of the S3 bucket for CloudFront logs"
  type        = string
}

variable "logging_bucket_domain_name" {
  description = "Domain name of the logging S3 bucket"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "origin_alb_arn" {
  description = "ARN of the origin ALB"
  type        = string
}

variable "timeout_alb_arn" {
  description = "ARN of the timeout ALB"
  type        = string
} 