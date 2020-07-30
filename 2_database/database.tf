#--- 3_database/database.tf

#-------------
#--- Variables
#-------------

variable "project" {
  description = "project name is used as resource tag"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable bucket {
  description = "S3 bucket to store TF remote state"
  type        = string
}

variable "key_name" {
  description = "name of keypair to access ec2 instances"
  type        = string
  default     = "IrelandEKS"
}

variable "public_key_path" {
  description = "file path on deployment machine to public rsa key to access ec2 instances"
  type        = string
}


#------------------
#--- Data Providers
#------------------

data "terraform_remote_state" "tf_network" {
  backend = "s3"
  config = {
    bucket = var.bucket
    key = "1_network.tfstate"
    region = var.region
  }
}

######################################
# Data sources to get VPC and subnets
######################################
# data "aws_vpc" "default" {
#   default = true
# }
# 
# data "aws_subnet_ids" "all" {
#   vpc_id = data.aws_vpc.default.id
# }

#############
# RDS Aurora
#############
module "aurora" {
  source                          = "../modules/aurora/"
  name                            = "aurora-example"
  engine                          = "aurora-postgresql"
  engine_version                  = "10.5"
  publicly_accessible             = false
  subnets                         = data.terraform_remote_state.tf_network.outputs.aws_subnet_ids # data.aws_subnet_ids.all.ids
  vpc_id                          = data.terraform_remote_state.tf_network.outputs.vpc1_id # data.aws_vpc.default.id
  replica_count                   = 1
  replica_scale_enabled           = true
  replica_scale_min               = 1
  replica_scale_max               = 5
  monitoring_interval             = 60
  instance_type                   = "db.r4.large"
  apply_immediately               = true
  skip_final_snapshot             = true
  db_parameter_group_name         = aws_db_parameter_group.aurora_db_postgres96_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_cluster_postgres96_parameter_group.id
  storage_encrypted               = true
  //  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

resource "aws_db_parameter_group" "aurora_db_postgres96_parameter_group" {
  name        = "test-aurora-db-postgres10-parameter-group"
  family      = "aurora-postgresql10"
  description = "test-aurora-db-postgres10-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_postgres96_parameter_group" {
  name        = "test-aurora-postgres10-cluster-parameter-group"
  family      = "aurora-postgresql10"
  description = "test-aurora-postgres10-cluster-parameter-group"
}

resource "aws_security_group" "app_servers" {
  name        = "app-servers"
  description = "For application servers"
  vpc_id      = data.terraform_remote_state.tf_network.outputs.vpc1_id # data.aws_vpc.default.id
}

resource "aws_security_group_rule" "allow_access" {
  type                     = "ingress"
  from_port                = module.aurora.this_rds_cluster_port
  to_port                  = module.aurora.this_rds_cluster_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = module.aurora.this_security_group_id
  description              = "limit incoming traffic to a special sg for app_servers"
}


#-----------
#--- Outputs
#-----------

output "rds_cluster_id" {
  description = "The ID of the cluster"
  value       = module.aurora.this_rds_cluster_id
}

output "rds_cluster_resource_id" {
  description = "The Resource ID of the cluster"
  value       = module.aurora.this_rds_cluster_resource_id
}

output "rds_cluster_endpoint" {
  description = "The cluster endpoint"
  value       = module.aurora.this_rds_cluster_endpoint
}

output "rds_cluster_reader_endpoint" {
  description = "The cluster reader endpoint"
  value       = module.aurora.this_rds_cluster_reader_endpoint
}

output "rds_cluster_database_name" {
  description = "Name for an automatically created database on cluster creation"
  value       = module.aurora.this_rds_cluster_database_name
}

output "rds_cluster_master_password" {
  description = "The master password"
  value       = module.aurora.this_rds_cluster_master_password
}

output "rds_cluster_port" {
  description = "The port"
  value       = module.aurora.this_rds_cluster_port
}

output "rds_cluster_master_username" {
  description = "The master username"
  value       = module.aurora.this_rds_cluster_master_username
}

output "rds_cluster_instance_endpoints" {
  description = "A list of all cluster instance endpoints"
  value       = module.aurora.this_rds_cluster_instance_endpoints
}

output "rds_cluster_instance_ids" {
  description = "A list of all cluster instance ids"
  value       = module.aurora.this_rds_cluster_instance_ids
}

output "sg_cluster" {
  description = "The security group ID of the cluster"
  value       = module.aurora.this_security_group_id
}

output "sg_app_servers" {
  description = "The security group ID of the app servers - only ec2s with this sg can connect to the db!"
  value       = aws_security_group.app_servers.id
}