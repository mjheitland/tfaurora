#--- 3_compute/config.tf ---

terraform {
  required_version = "~> 0.13"
  required_providers {
    aws = ">= 3.2.0"
  }
  backend "s3" {
    key = "3_compute.tfstate"
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}
