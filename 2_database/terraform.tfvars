project               = "tfaurora"
region                = "eu-central-1"
bucket                = "tfstate-tfaurora-094033154904-eu-central-1"

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
