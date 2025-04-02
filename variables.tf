variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "bucket-for-test-565632"
}
variable "cloudfront_domain_name" {
  description = "The custom domain name for CloudFront"
  type        = string
  default     = "ffdsf.test.com"
}
variable "aws_profile" {
  description = "The AWS profile to use"
  type        = string
  default     = "default"
}
