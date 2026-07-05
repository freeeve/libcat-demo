# Provider for the read-only lcatd cataloging demo (tasks/009). API Gateway v2 HTTP
# API custom domains use a REGIONAL ACM certificate in the API's own region, so unlike
# the static site's CloudFront cert this needs no separate us-east-1 alias -- one
# provider in var.region (default us-east-1) covers the Lambda, API, cert, and Route 53.
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}
