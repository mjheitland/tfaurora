#--- 3_compute/config.tf ---

terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = ">= 2.70.0"
  }
  backend "s3" {
    key = "3_compute.tfstate"
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}
