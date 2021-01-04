#--- 0_tfstate/config.tf ---

terraform {
  required_version = "~> 0.14"
  required_providers {
    aws = ">= 3.2.0"
  }
#  backend "s3" {
#    key = "0_tfstate.tfstate"
#  }
}

provider "aws" {
  region = var.region
  profile = "default"
}
