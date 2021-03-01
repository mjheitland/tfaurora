# General

project               = "tfaurora"
region                = "eu-central-1"
bucket                = "tfstate-tfaurora-094033154904-eu-central-1"


# Aurora database

name                  = "aurora-example"
engine                = "aurora-postgresql"
engine_version        = "12.4"
family                = "aurora-postgresql12"
replica_count         = 1
replica_scale_enabled = true
replica_scale_min     = 1
replica_scale_max     = 5
monitoring_interval   = 60
instance_type         = "db.t3.large" # "db.r4.large"
instance_type_replica = "db.t3.large"
apply_immediately     = true
skip_final_snapshot   = true
storage_encrypted     = true


# Aurora database 2

name_2                  = "aurora2-example"
engine_2                = "aurora-postgresql"
engine_version_2        = "12.4"
family_2                = "aurora-postgresql12"
replica_count_2         = 1
replica_scale_enabled_2 = true
replica_scale_min_2     = 1
replica_scale_max_2     = 5
monitoring_interval_2   = 60
instance_type_2         = "db.t3.large" # "db.r4.large"
instance_type_replica_2 = "db.t3.large"
apply_immediately_2     = true
skip_final_snapshot_2   = true
storage_encrypted_2     = true
