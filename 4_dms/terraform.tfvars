project                   = "tfaurora"
region                    = "eu-central-1"
bucket                    = "tfstate-tfaurora-094033154904-eu-central-1"

dms_instance_type         = "dms.t3.medium"
publicly_accessible       = false

source_engine_name        = "aurora-postgresql"
source_database_host      = "tfaurora-example-1.cbnlfy36tjpq.eu-central-1.rds.amazonaws.com"
source_database_name      = "mydb1"
source_database_username  = "root"
source_database_password  = "HilWelMicWal"
source_port               = "5432"

target_engine_name        = "aurora-postgresql"
target_database_host      = "tfaurora2-example-1"
target_database_name      = "mydb1"
target_database_username  = "root"
target_database_password  = "HilWelMicWal"
target_port               = "5432"
