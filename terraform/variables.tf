variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "bot-deception-vpc"
}

variable "website_bucket_name" {
  description = "S3 bucket name for website source code"
  type        = string
  default     = "bot-deception-website-source"
}

variable "fake_webpage_bucket_name" {
  description = "S3 bucket name for fake webpages"
  type        = string
  default     = "bot-deception-fake-webpages"
}

variable "logging_bucket_name" {
  description = "S3 bucket name for CloudFront logs"
  type        = string
  default     = "bot-deception-cloudfront-logs"
}

variable "logging_bucket_domain_name" {
  description = "S3 bucket domain name for CloudFront logs"
  type        = string
  default     = "bot-deception-cloudfront-logs.s3.amazonaws.com"
}