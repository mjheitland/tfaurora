project                   = "tfaurora"
region                    = "eu-central-1"
bucket                    = "tfstate-tfaurora-094033154904-eu-central-1"

dms_instance_type         = "dms.t3.medium"

source_engine_name        = "aurora"
source_database_name      = "mydb1"
source_database_username  = "root"
source_database_password  = "Lisboa.1mh"
source_database_host      = "tfaurora-example-1"
source_port               = "5432"

target_engine_name        = "aurora"
target_database_name      = "mydb1"
target_database_username  = "root"
target_database_password  = "Lisboa.1mh"
target_database_host      = "tfaurora2-example-1"
target_port               = "5432"
