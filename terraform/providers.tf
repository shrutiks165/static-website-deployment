terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state backend. Terraform state must NOT be stored locally when
  # GitHub Actions is applying changes, because every run happens on a
  # fresh runner with no memory of previous runs. Uncomment and fill in
  # after you've manually created the state bucket (see README, Step 1).
  #
   backend "s3" {
     bucket = "cloudarchprep-tf-state-8821"
     key    = "static-website-deployment/terraform.tfstate"
     region = "ap-south-1"
   }
}

provider "aws" {
  region = var.aws_region
}
