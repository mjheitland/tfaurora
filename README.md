# tfaurora - create Aurora database and a ec2 db jumpbox to test the db connection

## Intro

Install Aurora with Terraform

## Layer 0 - Terraform Remote State (2 min)

Set up remote state for Terraform creating a bucket for the state and a DynamoDB table for locking<br>
(if you want to save TF state including this layer, run the commands twice and remove the comments for the backend in tfstate.tf on the second run)

Terraform code:
```
cd 0_tfstate

terraform init

terraform apply -auto-approve

terraform destroy -auto-approve
```

## Layer 1 - Network (3 min)

The following steps are done automatically if you deploy 1_network with Terraform:

* create a VPC "tfaurora_vpc" 

* create three public subnets across 3 AZs 

* create Internet Gateway and attach the public subnets

* create a route table to send the internet traffic to the internet gateway

* create a security group to allow ssh from a dedicated local box (change ip address to your local box)

Terraform code:
```
cd 1_network

terraform init -backend-config=../backend.config

terraform apply -auto-approve

terraform destroy -auto-approve
```

## Layer 2 - Aurora Database (8 min)

* create an Aurora database across all subnets

* security group for the Aurora cluster

* security group for app servers - only ec2 instances with this sg are allowed to connect to our database

These steps are done automatically if you deploy 2_database with Terraform:

```
cd 2_database

terraform init -backend-config=../backend.config

terraform apply -auto-approve

terraform destroy -auto-approve
```

*Note: In AWS console, click 'Modify' button to change master password for the db instance and select 'Apply immediately'*

## Layer 3 - Compute (1 min)

These steps are done automatically if you deploy 3_compute with Terraform:

* create a key pair "MyAuroraKey" in eu-central-1 and download the private key file "MyAuroraKey.pem"<br>
(with Terraform: use ssh-keygen if you do not have a private key in ~/.ssh/id_rsa)

* deploy one jump box in every subnet to allow database connection tests

```
cd 3_compute

terraform init -backend-config=../backend.config

terraform apply -auto-approve

terraform destroy -auto-approve
```

* Example to connect from jump box to Aurora database:

```
ssh ec2-user@52.57.67.220 # ip address of one of the jump boxes

# set host to one of the rds_cluster_instance_endpoints
psql \
   --host=aurora-example-1.cbnlfy36tjpq.eu-central-1.rds.amazonaws.com \
   --port=5432 \
   --username=root \
   --password \
   --dbname=postgres

CREATE DATABASE db1;

SELECT datname FROM pg_database;

...

To quit psql: \q or CTRL-d (could be CMD-d on Mac)
```

# Links

Origin of source code:

* [Code taken from Github](https://github.com/terraform-aws-modules/terraform-aws-rds-aurora)

These types of resources are supported:

* [RDS Cluster](https://www.terraform.io/docs/providers/aws/r/rds_cluster.html)
* [RDS Cluster Instance](https://www.terraform.io/docs/providers/aws/r/rds_cluster_instance.html)
* [DB Subnet Group](https://www.terraform.io/docs/providers/aws/r/db_subnet_group.html)
* [Application AutoScaling Policy](https://www.terraform.io/docs/providers/aws/r/appautoscaling_policy.html)
* [Application AutoScaling Target](https://www.terraform.io/docs/providers/aws/r/appautoscaling_target.html)

Additional Information:
* [Supported Postgres Versions](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts.General.DBVersions)

* [Connect to Aurora Database to test the connection](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToPostgreSQLInstance.html)

* [How to use psql to create and delete databses](https://dataguide.prisma.io/postgresql/create-and-delete-databases-and-tables)
