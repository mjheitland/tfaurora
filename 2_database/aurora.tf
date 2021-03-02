#--- 3_database/database.tf

#-------------
#--- Variables
#-------------

#--- General

variable "project" {
  description = "project name is used as resource tag"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "bucket" {
  description = "S3 bucket to store TF remote state"
  type        = string
}

variable "name" {
  description = "Name given resources"
  type        = string
}

#--- DB

variable "engine" {
  description = "Aurora database engine type, currently aurora, aurora-mysql or aurora-postgresql"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version" {
  description = "Aurora database engine version."
  type        = string
  default     = "11.9"
}

variable "family" {
  description = "db family"
  type        = string
  default     = "aurora-postgresql11"
}

variable "replica_count" {
  description = "Number of reader nodes to create.  If `replica_scale_enable` is `true`, the value of `replica_scale_min` is used instead."
  type        = number
  default     = 1
}

variable "replica_scale_enabled" {
  description = "Whether to enable autoscaling for RDS Aurora (MySQL) read replicas"
  type        = bool
  default     = false
}

variable "replica_scale_min" {
  description = "Minimum number of replicas to allow scaling for"
  type        = number
  default     = 2
}

variable "replica_scale_max" {
  description = "Maximum number of replicas to allow scaling for"
  type        = number
  default     = 0
}

variable "monitoring_interval" {
  description = "The interval (seconds) between points when Enhanced Monitoring metrics are collected"
  type        = number
  default     = 0
}

variable "instance_type" {
  description = "Instance type to use at master instance. If instance_type_replica is not set it will use the same type for replica instances"
  type        = string
}

variable "instance_type_replica" {
  description = "Instance type to use at replica instance"
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Determines whether or not any DB modifications are applied immediately, or during the maintenance window"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Should a final snapshot be created on cluster destroy"
  type        = bool
  default     = false
}

variable "storage_encrypted" {
  description = "Specifies whether the underlying storage layer should be encrypted"
  type        = bool
  default     = true
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
  subnets                         = data.terraform_remote_state.tf_network.outputs.aws_subnet_ids # data.aws_subnet_ids.all.ids
  vpc_id                          = data.terraform_remote_state.tf_network.outputs.vpc1_id # data.aws_vpc.default.id
  db_parameter_group_name         = aws_db_parameter_group.aurora_db_postgres_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_cluster_postgres_parameter_group.id

  name                            = var.name
  engine                          = var.engine
  engine_version                  = var.engine_version
  replica_count                   = var.replica_count
  replica_scale_enabled           = var.replica_scale_enabled
  replica_scale_min               = var.replica_scale_min
  replica_scale_max               = var.replica_scale_max
  monitoring_interval             = var.monitoring_interval
  instance_type                   = var.instance_type
  instance_type_replica           = var.instance_type_replica
  apply_immediately               = var.apply_immediately
  skip_final_snapshot             = var.skip_final_snapshot
  storage_encrypted               = var.storage_encrypted
  //  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

resource "aws_db_parameter_group" "aurora_db_postgres_parameter_group" {
  name        = "test-aurora-db-postgres-parameter-group"
  family      = var.family
  description = "test-aurora-db-postgres-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_postgres_parameter_group" {
  name        = "test-aurora-postgres-cluster-parameter-group"
  family      = var.family
  description = "test-aurora-postgres-cluster-parameter-group"
}

resource "aws_security_group" "app_servers" {
  name        = "app_servers"
  description = "Allow db traffic only from ec2 boxes with this security group"
  vpc_id      = data.terraform_remote_state.tf_network.outputs.vpc1_id # data.aws_vpc.default.id

  tags = { 
    Name = format("%s_app_servers", var.project)
    project = var.project
  }
}

# sg rule for db to allow only incoming traffic from sources attached to ec2 instances with app_servers sg attachment.
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
  sensitive   = true 
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