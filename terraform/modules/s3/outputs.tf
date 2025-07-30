output "website_bucket_name" {
  description = "Name of the website source bucket"
  value       = aws_s3_bucket.website_source.id
}

output "website_bucket_arn" {
  description = "ARN of the website source bucket"
  value       = aws_s3_bucket.website_source.arn
}

output "fake_webpage_bucket_name" {
  description = "Name of the fake webpage bucket"
  value       = aws_s3_bucket.fake_webpages.id
}

output "fake_webpage_bucket_arn" {
  description = "ARN of the fake webpage bucket"
  value       = aws_s3_bucket.fake_webpages.arn
}

output "fake_webpage_bucket_domain_name" {
  description = "Domain name of the fake webpage bucket"
  value       = aws_s3_bucket.fake_webpages.bucket_domain_name
}

output "cloudfront_logs_bucket_name" {
  description = "Name of the CloudFront logs bucket"
  value       = aws_s3_bucket.cloudfront_logs.id
}

output "cloudfront_logs_bucket_domain_name" {
  description = "Domain name of the CloudFront logs bucket"
  value       = aws_s3_bucket.cloudfront_logs.bucket_domain_name
}
