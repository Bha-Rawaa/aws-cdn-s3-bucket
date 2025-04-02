output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.cloudfront_bucket.bucket
}
output "aws_profile" {
  value = var.aws_profile
}
# Add CloudFront Distribution ID
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

# Add CloudFront ARN
output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.cdn.arn
}
