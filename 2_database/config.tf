#--- 3_database/config.tf ---

terraform {
  required_version = "~> 0.14"
  required_providers {
    aws = ">= 3.2.0"
    template = "~> 2.1.2"
  }
  backend "s3" {
    key = "2_database.tfstate"
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}
