provider "aws" {
  region = "eu-west-1"  
  profile = var.aws_profile

}
data "aws_caller_identity" "current" {}
resource "aws_s3_bucket" "cloudfront_bucket" {
  bucket = var.s3_bucket_name
  force_destroy = true 
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.cloudfront_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "OAC-for-S3"
  description                       = "OAC for CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.cloudfront_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  # aliases = [var.cloudfront_domain_name]
}

# resource "aws_s3_bucket_policy" "s3_policy" {
#   bucket = aws_s3_bucket.cloudfront_bucket.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Deny",
#         Principal = "*",
#         Action = "s3:GetObject",
#         Resource = "${aws_s3_bucket.cloudfront_bucket.arn}/*",
#         Condition = {
#           StringNotEquals = {
#             "aws:Referer" = aws_cloudfront_distribution.cdn.id
#           }
#         }
#       }
#     ]
#   })
# }
resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.cloudfront_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.cloudfront_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "signing_policy" {
  name        = "CloudFrontSignedURLPolicy"
  description = "IAM policy to allow creating CloudFront signed URLs and invalidations"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"     
        Action   = "cloudfront:CreateInvalidation"
       # Action   = "cloudfront:CreateSignedUrl",
        Resource = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}" //check account id
      },
    {
        Effect   = "Allow"
        Action   = [
          "cloudfront:ListDistributions",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig"
        ]
        Resource = "*"
      }
    ]
  })
}

