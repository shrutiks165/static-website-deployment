variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket that will host the website (e.g. yourname-portfolio-site)"
  type        = string
  default     = "cloudarchprep-website-3392"
}

variable "environment" {
  description = "Environment tag applied to resources"
  type        = string
  default     = "prod"
}
