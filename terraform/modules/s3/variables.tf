variable "website_bucket_name" {
  description = "Name of the S3 bucket for website source code"
  type        = string
}

variable "fake_webpage_bucket_name" {
  description = "Name of the S3 bucket for fake webpages"
  type        = string
}

variable "logging_bucket_name" {
  description = "Name of the S3 bucket for CloudFront logs"
  type        = string
  default     = "bot-deception-cloudfront-logs"
}
