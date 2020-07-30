#-- 3_compute/compute.tf ---

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

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
      name   = "root-device-type"
      values = ["ebs"]
    }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }  
}  


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

variable "bucket" {
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

resource "aws_key_pair" "keypair" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

data "template_file" "userdata" {
  template = file("${path.module}/userdata.tpl")
  vars = {
    subnet = "element(data.terraform_remote_state.tf_network.outputs.aws_subnet_ids, count.index)"
  }
}

resource "aws_instance" "jumpbox" {
  count = length(data.terraform_remote_state.tf_network.outputs.aws_subnet_ids)

  instance_type           = "t3.micro"
  ami                     = data.aws_ami.amazon_linux_2.id
  key_name                = aws_key_pair.keypair.id
  subnet_id               = sort(data.terraform_remote_state.tf_network.outputs.aws_subnet_ids)[count.index]
  vpc_security_group_ids  = [
                              data.terraform_remote_state.tf_network.outputs.sg_jumpbox,
                              data.terraform_remote_state.tf_database.outputs.sg_app_servers
                            ]
  user_data               = data.template_file.userdata.*.rendered[0]
  tags = { 
    Name = format("%s_jumpbox_%d", var.project, count.index)
    project = var.project
  }
}


#-----------
#--- Outputs
#-----------

output "keypair_id" {
  value = join(", ", aws_key_pair.keypair.*.id)
}

output "jumpbox_ids" {
  value = join(", ", aws_instance.jumpbox.*.id)
}

output "jumpbox_public_ips" {
  value = join(", ", aws_instance.jumpbox.*.public_ip)
}
