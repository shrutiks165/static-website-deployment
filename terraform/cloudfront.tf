# Origin Access Control (OAC) - this is the mechanism that lets CloudFront
# sign its requests to S3, proving to the bucket "this request really came
# from CloudFront." It replaces the older, deprecated OAI approach.
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # cheapest tier: US, Canada, Europe edge locations

  origin {
    # bucket_regional_domain_name (not the website endpoint) is required
    # when using OAC, since CloudFront talks to S3 via its REST API, not
    # the public website hosting endpoint.
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "s3-website-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-website-origin"
    viewer_protocol_policy = "redirect-to-https" # force HTTPS for every visitor

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600  # 1 hour - how long CloudFront caches a file by default
    max_ttl     = 86400 # 24 hours
  }

  # Since this is a single-page-app-friendly static site, route "not found"
  # paths back to a friendly error page instead of CloudFront's raw XML error.
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/error.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # use the *.cloudfront.net cert (no custom domain needed)
  }

  tags = {
    Name        = "${var.bucket_name}-cdn"
    Environment = var.environment
    Project     = "automated-static-website-deployment"
  }
}
