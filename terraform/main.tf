terraform {
  backend "s3" {
    bucket = "terraform-933673036381"
    region = "us-east-1"
    key    = "cloudfront-spa.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

