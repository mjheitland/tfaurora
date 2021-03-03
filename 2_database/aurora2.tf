#--- 3_database/database.tf

#-------------
#--- Variables
#-------------

#--- DB

variable "name_2" {
  description = "Name given resources"
  type        = string
}

variable "engine_2" {
  description = "Aurora database engine type, currently aurora, aurora-mysql or aurora-postgresql"
  type        = string
  default     = "aurora-postgresql"
}

variable "engine_version_2" {
  description = "Aurora database engine version."
  type        = string
  default     = "11.9"
}

variable "family_2" {
  description = "db family"
  type        = string
  default     = "aurora-postgresql11"
}

variable "replica_count_2" {
  description = "Number of reader nodes to create.  If `replica_scale_enable` is `true`, the value of `replica_scale_min` is used instead."
  type        = number
  default     = 1
}

variable "replica_scale_enabled_2" {
  description = "Whether to enable autoscaling for RDS Aurora (MySQL) read replicas"
  type        = bool
  default     = false
}

variable "replica_scale_min_2" {
  description = "Minimum number of replicas to allow scaling for"
  type        = number
  default     = 2
}

variable "replica_scale_max_2" {
  description = "Maximum number of replicas to allow scaling for"
  type        = number
  default     = 0
}

variable "monitoring_interval_2" {
  description = "The interval (seconds) between points when Enhanced Monitoring metrics are collected"
  type        = number
  default     = 0
}

variable "instance_type_2" {
  description = "Instance type to use at master instance. If instance_type_replica is not set it will use the same type for replica instances"
  type        = string
}

variable "instance_type_replica_2" {
  description = "Instance type to use at replica instance"
  type        = string
  default     = null
}

variable "apply_immediately_2" {
  description = "Determines whether or not any DB modifications are applied immediately, or during the maintenance window"
  type        = bool
  default     = false
}

variable "skip_final_snapshot_2" {
  description = "Should a final snapshot be created on cluster destroy"
  type        = bool
  default     = false
}

variable "storage_encrypted_2" {
  description = "Specifies whether the underlying storage layer should be encrypted"
  type        = bool
  default     = true
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
module "aurora2" {
  source                          = "../modules/aurora/"
  subnets                         = data.terraform_remote_state.tf_network.outputs.aws_subnet_ids # data.aws_subnet_ids.all.ids
  vpc_id                          = data.terraform_remote_state.tf_network.outputs.vpc1_id # data.aws_vpc.default.id
  db_parameter_group_name         = aws_db_parameter_group.aurora_db_postgres_parameter_group_2.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora_cluster_postgres_parameter_group_2.id

  name                            = var.name_2
  engine                          = var.engine_2
  engine_version                  = var.engine_version_2
  replica_count                   = var.replica_count_2
  replica_scale_enabled           = var.replica_scale_enabled_2
  replica_scale_min               = var.replica_scale_min_2
  replica_scale_max               = var.replica_scale_max_2
  monitoring_interval             = var.monitoring_interval_2
  instance_type                   = var.instance_type_2
  instance_type_replica           = var.instance_type_replica_2
  apply_immediately               = var.apply_immediately_2
  skip_final_snapshot             = var.skip_final_snapshot_2
  storage_encrypted               = var.storage_encrypted_2
  //  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

resource "aws_db_parameter_group" "aurora_db_postgres_parameter_group_2" {
  name        = "test-aurora2-db-postgres-parameter-group"
  family      = var.family_2
  description = "test-aurora2-db-postgres-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_postgres_parameter_group_2" {
  name        = "test-aurora2-postgres-cluster-parameter-group"
  family      = var.family_2
  description = "test-aurora2-postgres-cluster-parameter-group"
}

resource "aws_security_group" "app_servers_2" {
  name        = "app_servers_2"
  description = "Allow db traffic only from ec2 boxes with this security group"
  vpc_id      = data.terraform_remote_state.tf_network.outputs.vpc1_id # data.aws_vpc.default.id

  tags = { 
    Name = format("%s_app_servers_2", var.project)
    project = var.project
  }
}

# sg rule for db to allow only incoming traffic from sources attached to ec2 instances with app_servers_2 sg attachment.
resource "aws_security_group_rule" "allow_access_2" {
  type                     = "ingress"
  from_port                = module.aurora2.this_rds_cluster_port
  to_port                  = module.aurora2.this_rds_cluster_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_servers_2.id
  security_group_id        = module.aurora2.this_security_group_id
  description              = "limit incoming traffic to a special sg for app_servers"
}


#-----------
#--- Outputs
#-----------

output "rds_cluster_id_2" {
  description = "The ID of the cluster"
  value       = module.aurora2.this_rds_cluster_id
}

output "rds_cluster_resource_id_2" {
  description = "The Resource ID of the cluster"
  value       = module.aurora2.this_rds_cluster_resource_id
}

output "rds_cluster_endpoint_2" {
  description = "The cluster endpoint"
  value       = module.aurora2.this_rds_cluster_endpoint
}

output "rds_cluster_reader_endpoint_2" {
  description = "The cluster reader endpoint"
  value       = module.aurora2.this_rds_cluster_reader_endpoint
}

output "rds_cluster_database_name_2" {
  description = "Name for an automatically created database on cluster creation"
  value       = module.aurora2.this_rds_cluster_database_name
}

output "rds_cluster_master_password_2" {
  description = "The master password"
  value       = module.aurora2.this_rds_cluster_master_password
  sensitive   = true 
}

output "rds_cluster_port_2" {
  description = "The port"
  value       = module.aurora2.this_rds_cluster_port
}

output "rds_cluster_master_username_2" {
  description = "The master username"
  value       = module.aurora2.this_rds_cluster_master_username
}

output "rds_cluster_instance_endpoints_2" {
  description = "A list of all cluster instance endpoints"
  value       = module.aurora2.this_rds_cluster_instance_endpoints
}

output "rds_cluster_instance_ids_2" {
  description = "A list of all cluster instance ids"
  value       = module.aurora2.this_rds_cluster_instance_ids
}

output "sg_cluster_2" {
  description = "The security group ID of the cluster"
  value       = module.aurora2.this_security_group_id
}

output "sg_app_servers_2" {
  description = "The security group ID of the app servers - only ec2s with this sg can connect to the db!"
  value       = aws_security_group.app_servers_2.id
}

output "engine_2" {
  description = "Name of the RDS database engine (e.g. 'aurora-postgresql')"
  value       = var.engine_2
}

output "engine_version_2" {
  description = "Version number of the RDS database engine"
  value       = var.engine_version_2
}

output "instance_type_2" {
  description = "ec2 instance type of the primary database"
  value       = var.instance_type_2
}

output "instance_type_replica_2" {
  description = "ec2 instance type of the read replica database"
  value       = var.instance_type_replica_2
}