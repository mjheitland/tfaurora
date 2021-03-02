#--- 4_dms/dms.tf

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

data "terraform_remote_state" "tf_database" {
  backend = "s3"
  config = {
    bucket = var.bucket
    key = "2_database.tfstate"
    region = var.region
  }
}

data "local_file" "dms_replication_task_settings" {
  filename = "${path.module}/resources/dms_replication_task_settings.tmpl"
}

data "local_file" "dms_table_mappings" {
  filename = "${path.module}/resources/dms_table_mappings_1.json"
}

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


#--- DMS

variable "source_database_host" {
  type        = string
  description = "Database host to migrate"
}

variable "source_engine_name" {
  type        = string
  description = "Source database type, e.g. 'aurora'"
}

variable "source_database_name" {
  type        = string
  description = "Source database"
}

variable "source_database_username" {
  type        = string
  description = "Source database user"
}

variable "source_database_password" {
  type        = string
  description = "Source database password"
}

variable "source_port" {
  type        = number
  description = "Source database port"
}

variable "target_database_host" {
  type        = string
  description = "Target database host"
}

variable "target_engine_name" {
  type        = string
  description = "Target database type, e.g. 'aurora'"
}

variable "target_database_name" {
  type        = string
  description = "Target database name"
}

variable "target_database_username" {
  type        = string
  description = "Target database user"
}

variable "target_database_password" {
  type        = string
  description = "Target database password"
}

variable "target_port" {
  type        = number
  description = "Target database port"
}

variable "ssl_mode" {
  type        = string
  description = "Enable SSL encryption"
  default     = "none"
}

variable "storage_size" {
  type        = string
  default     = "30"
  description = "Replication task storage"
}

variable "publicly_accessible" {
  type        = bool
  description = "True if you want DMS instance to be accessible publicly"
  default     = false
}

variable "dms_instance_type" {
  type        = string
  description = "Migration instance type"
}

variable "dms_extra_connection_attributes" {
  type        = string
  description = "Connection attributes"
  default     = ""
}


#-------------
#--- Resources
#-------------

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_dms_replication_subnet_group" "dms_replication_subnet_group" {
  replication_subnet_group_description = "Replication subnet group for ${var.project}"
  replication_subnet_group_id          = "dms-subnet-group-${random_id.id.hex}"

  subnet_ids = data.terraform_remote_state.tf_network.outputs.aws_subnet_ids # data.aws_subnet_ids.all.ids

  tags = {
    Name        = "${var.project}_dms_replication_subnet_group"
    project     = var.project
  }
}

resource "aws_dms_replication_instance" "dms_replication_instance" {
  allocated_storage           = var.storage_size
  apply_immediately           = true
  auto_minor_version_upgrade  = true
  publicly_accessible         = var.publicly_accessible
  replication_instance_class  = var.dms_instance_type
  replication_instance_id     = "dms-replication-instance-${random_id.id.hex}"
  replication_subnet_group_id = aws_dms_replication_subnet_group.dms_replication_subnet_group.id

  tags = {
    Name        = "${var.project}_dms_replication_instance"
    project     = var.project
  }

  vpc_security_group_ids = [
    data.terraform_remote_state.tf_network.outputs.sg_jumpbox,
    data.terraform_remote_state.tf_database.outputs.sg_app_servers,
    data.terraform_remote_state.tf_database.outputs.sg_app_servers_2 # comment this line out if you are setting up only one db!
  ]  
}

resource "aws_dms_endpoint" "dms_source_endpoint" {
  endpoint_id                 = "dms-source-endpoint-${random_id.id.hex}"
  endpoint_type               = "source"
  engine_name                 = var.source_engine_name
  extra_connection_attributes = var.dms_extra_connection_attributes
  server_name                 = var.source_database_host
  database_name               = var.source_database_name
  username                    = var.source_database_username
  password                    = var.source_database_password
  port                        = var.source_port
  ssl_mode                    = var.ssl_mode

  tags = {
    Name        = "${var.project}_dms_source_endpoint"
    project     = var.project
  }
}


resource "aws_dms_endpoint" "dms_target_endpoint" {
  endpoint_id                 = "dms-target-endpoint-${random_id.id.hex}"
  endpoint_type               = "target"
  engine_name                 = var.target_engine_name
  extra_connection_attributes = var.dms_extra_connection_attributes
  server_name                 = var.target_database_host
  database_name               = var.target_database_name
  username                    = var.target_database_username
  password                    = var.target_database_password
  port                        = var.target_port
  ssl_mode                    = var.ssl_mode

  tags = {
    Name        = "${var.project}_dms_target_endpoint"
    project     = var.project
  }
}

resource "aws_dms_replication_task" "dms_replication_task" {
  migration_type           = "full-load"
  replication_instance_arn = aws_dms_replication_instance.dms_replication_instance.replication_instance_arn
  replication_task_id      = "dms-replication-task-${random_id.id.hex}"

  source_endpoint_arn = aws_dms_endpoint.dms_source_endpoint.endpoint_arn
  target_endpoint_arn = aws_dms_endpoint.dms_target_endpoint.endpoint_arn

  table_mappings            = data.local_file.dms_table_mappings.content
  replication_task_settings = data.local_file.dms_replication_task_settings.content

  tags = {
    Name        = "${var.project}_dms_replication_task"
    project     = var.project
  }
}