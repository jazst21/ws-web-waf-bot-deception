terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Random ID for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# VPC
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name = var.vpc_name
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["${var.region}a", "${var.region}b"]
}

# ALB
module "alb" {
  source = "./modules/alb"
  
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
}

# S3 Buckets (먼저 생성)
module "s3" {
  source = "./modules/s3"
  
  website_bucket_name = "${var.website_bucket_name}-${random_id.suffix.hex}"
  fake_webpage_bucket_name = "${var.fake_webpage_bucket_name}-${random_id.suffix.hex}"
  logging_bucket_name = "${var.logging_bucket_name}-${random_id.suffix.hex}"
}

# Auto Scaling Group (S3 생성 후)
module "ec2" {
  source = "./modules/ec2"
  
  vpc_id = module.vpc.vpc_id
  vpc_cidr = "10.0.0.0/16"
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_target_group_arn = module.alb.origin_target_group_arn
  alb_security_group_id = module.alb.origin_security_group_id
  website_bucket_name = var.website_bucket_name
  actual_website_bucket_name = module.s3.website_bucket_name
}

# S3 Bucket Policy for EC2 access to website source bucket
resource "aws_s3_bucket_policy" "website_source_ec2_access" {
  bucket = module.s3.website_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEC2RoleAccess"
        Effect    = "Allow"
        Principal = {
          AWS = module.ec2.iam_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3.website_bucket_arn,
          "${module.s3.website_bucket_arn}/*"
        ]
      }
    ]
  })

  depends_on = [module.s3, module.ec2]
}

# AWS WAF
module "waf" {
  source = "./modules/waf"
}

# Lambda for generating fake webpages
module "lambda" {
  source = "./modules/lambda"
  
  fake_webpage_bucket_name = module.s3.fake_webpage_bucket_name
}

# Trigger Lambda to generate fake webpages
resource "aws_lambda_invocation" "generate_fake_pages" {
  function_name = module.lambda.function_name
  
  input = jsonencode({
    action = "generate_pages"
  })
  
  depends_on = [
    module.lambda,
    module.s3
  ]
}

# CloudFront Distribution with default TLS certificate
module "cloudfront" {
  source = "./modules/cloudfront"
  
  # Remove domain_name and certificate_arn - use default CloudFront domain
  origin_alb_dns_name = module.alb.origin_alb_dns_name
  timeout_alb_dns_name = module.alb.timeout_alb_dns_name
  fake_webpage_bucket_name = module.s3.fake_webpage_bucket_name
  fake_webpage_bucket_domain_name = module.s3.fake_webpage_bucket_domain_name
  waf_web_acl_arn = module.waf.web_acl_arn
  logging_bucket_name = module.s3.cloudfront_logs_bucket_name
  logging_bucket_domain_name = module.s3.cloudfront_logs_bucket_domain_name
  vpc_id = module.vpc.vpc_id
  origin_alb_arn = module.alb.origin_alb_arn
  timeout_alb_arn = module.alb.timeout_alb_arn
} 