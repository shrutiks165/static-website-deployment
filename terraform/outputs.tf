output "bucket_name" {
  description = "Name of the S3 bucket hosting the website files"
  value       = aws_s3_bucket.website.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID - needed for cache invalidation"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "The *.cloudfront.net URL where the site is publicly served"
  value       = aws_cloudfront_distribution.website.domain_name
}
