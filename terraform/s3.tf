# The bucket that stores the actual website files
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Project     = "automated-static-website-deployment"
  }
}

# Public access is blocked entirely - nobody can reach this bucket directly
# over the internet. Only CloudFront (via Origin Access Control below) can
# read from it. This is the modern, secure replacement for the older
# "make the bucket public" approach.
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Tells S3 which file to serve as the homepage and which file to serve on
# a 404. This config isn't actually used for serving traffic (CloudFront
# talks to S3 as a REST API origin, not the website endpoint) but Terraform
# keeps it for reference/local testing and it's a cheap resource to have.
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket policy: only allow GetObject, and only when the request comes
# from OUR CloudFront distribution specifically (not just any CloudFront
# distribution in existence). This is enforced by the AWS:SourceArn condition.
data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
