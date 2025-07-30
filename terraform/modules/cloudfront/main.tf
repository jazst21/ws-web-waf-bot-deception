# CloudFront VPC Origin for ALB Origin
resource "aws_cloudfront_vpc_origin" "alb_origin" {
  vpc_origin_endpoint_config {
    name                   = "alb-origin"
    arn                    = var.origin_alb_arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"
    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
}

# Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "fake_webpage_oac" {
  name                              = "fake-webpage-oac"
  description                       = "OAC for fake webpage S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Function for bot demo 1
resource "aws_cloudfront_function" "bot_demo_function" {
  name    = "bot-demo-function"
  runtime = "cloudfront-js-2.0"
  comment = "Function to redirect bots to timeout ALB with 70% probability"
  publish = true
  code    = <<-EOT
import cf from 'cloudfront';
async function handler(event) {
    var request = event.request;
    var headers = request.headers;
    
    // Check if bot is detected
    if (headers['x-amzn-waf-targeted-bot-detected'] && 
        headers['x-amzn-waf-targeted-bot-detected'].value === 'true') {
        
        // 70% probability to redirect to timeout origin
        if (Math.random() < 0.7) {
            cf.updateRequestOrigin({
                "domainName" : '${var.timeout_alb_dns_name}',
                "originAccessControlConfig": {
                    "enabled": false
                },
                "timeouts": {
                    "readTimeout": 30,
                    "connectionTimeout": 10
                },
                "connectionAttempts": 3
            });
            console.log('routed to timeout origin');
        }
    }
    
    return request;
}
EOT
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  # Origin for ALB (default) - using VPC Origin
  origin {
    domain_name = var.origin_alb_dns_name
    origin_id   = "alb-origin"
    
    vpc_origin_config {
      vpc_origin_id         = aws_cloudfront_vpc_origin.alb_origin.id
    }
  }

  # Origin for fake webpage S3
  origin {
    domain_name              = var.fake_webpage_bucket_domain_name
    origin_id                = "fake-webpage-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.fake_webpage_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Bot Trapper Demo CloudFront Distribution"

  # Logging configuration
  logging_config {
    include_cookies = false
    bucket          = var.logging_bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  # Default cache behavior (ALB origin)
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    viewer_protocol_policy = "redirect-to-https"

    # Use Cache Disabled policy
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    
    # Use ForwardAllHeaders origin request policy
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  }

  # Cache behavior for static assets
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use CacheOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    viewer_protocol_policy = "redirect-to-https"

    # Use CacheOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behavior {
    path_pattern     = "*.jpg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    viewer_protocol_policy = "redirect-to-https"

    # Use CacheOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  ordered_cache_behavior {
    path_pattern     = "*.png"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use CacheOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Cache behavior for /private/* paths (fake webpage S3)
  ordered_cache_behavior {
    path_pattern     = "/private/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "fake-webpage-s3"

    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    # Use CacheOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Cache behavior for /bot-demo-1 with CloudFront Function
  ordered_cache_behavior {
    path_pattern     = "/bot-demo-1"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb-origin"

    viewer_protocol_policy = "redirect-to-https"

    # Use Cache Disabled policy
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    
    # Use ForwardAllHeaders origin request policy
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    # Attach CloudFront Function
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.bot_demo_function.arn
    }
  }

  # Price class
  price_class = "PriceClass_All"

  # Geo restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use default CloudFront certificate instead of custom ACM certificate
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # WAF Web ACL
  web_acl_id = var.waf_web_acl_arn

  tags = {
    Name        = "bot-deception-distribution"
    Environment = "demo"
  }
} 