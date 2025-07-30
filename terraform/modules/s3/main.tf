# random string
resource "random_string" "bucket_suffix" {
  length  = 8      # 생성할 랜덤 문자열의 길이 (예: 8자리)
  special = false  # 특수 문자 포함 여부 (false = 숫자, 대소문자만 포함)
  upper   = false  # 대문자 포함 여부 (false = 소문자만 포함)
  numeric = true   # 숫자 포함 여부
}

# S3 bucket for website source code
resource "aws_s3_bucket" "website_source" {
  bucket        = "${var.website_bucket_name}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "Bot Deception Website Source"
  }
}

resource "aws_s3_bucket_versioning" "website_source" {
  bucket = aws_s3_bucket.website_source.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "website_source" {
  bucket = aws_s3_bucket.website_source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "website_source" {
  bucket = aws_s3_bucket.website_source.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "${var.logging_bucket_name}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "Bot Deception CloudFront Logs"
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Enable ACL for CloudFront logs bucket
resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]

  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "log-delivery-write"
}

# S3 bucket for fake webpages
resource "aws_s3_bucket" "fake_webpages" {
  bucket        = "${var.fake_webpage_bucket_name}-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "Bot Deception Fake Webpages"
  }
}

resource "aws_s3_bucket_versioning" "fake_webpages" {
  bucket = aws_s3_bucket.fake_webpages.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fake_webpages" {
  bucket = aws_s3_bucket.fake_webpages.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "fake_webpages" {
  bucket = aws_s3_bucket.fake_webpages.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

# Upload website source files to S3 (excluding node_modules)
resource "aws_s3_object" "website_files" {
  for_each = {
    for file in fileset("${path.root}/../../website", "**/*") : file => file
    if !can(regex("/$", file)) && !can(regex("^node_modules/", file)) # 디렉토리와 node_modules 제외
  }
  
  bucket = aws_s3_bucket.website_source.id
  key    = each.value
  source = "${path.root}/../../website/${each.value}"
  etag   = filemd5("${path.root}/../../website/${each.value}")

  depends_on = [aws_s3_bucket.website_source]
}
