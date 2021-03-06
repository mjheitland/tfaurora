#--- 3_compute/config.tf ---

terraform {
  required_version = "~> 0.14"
  required_providers {
    aws = ">= 3.2.0"
  }
  backend "s3" {
    key = "4_dms.tfstate"
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}
