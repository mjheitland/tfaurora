#-- 1_network/network.tf ---

#-----------------
#--- Data Provider
#-----------------

data "aws_availability_zones" "available" {}


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


#-------------
#--- Resources
#-------------

#--- VPC 

resource "aws_vpc" "vpc1" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { 
    Name = format("%s_vpc", var.project)
    project = var.project
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id

  tags = { 
    Name = format("%s_igw1", var.project)
    project = var.project
  }
}

resource "aws_subnet" "subpub1" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]
  
  tags = { 
    Name = format("%s_subpub1", var.project)
    project = var.project
  }
}

resource "aws_subnet" "subpub2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]
  
  tags = { 
    Name = format("%s_subpub2", var.project)
    project = var.project
  }
}


resource "aws_subnet" "subpub3" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[2]
  
  tags = { 
    Name = format("%s_subpub3", var.project)
    project = var.project
  }
}

# Public route table, allows all outgoing traffic to go the the internet gateway.
# https://www.terraform.io/docs/providers/aws/r/route_table.html?source=post_page-----1a7fb9a336e9----------------------
resource "aws_route_table" "rtpub1" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = format("%s_rtpub1", var.project)
    project = var.project
  }
}

# Main Route Tables Associations
## Forcing our Route Tables to be the main ones for our VPCs,
## otherwise AWS automatically will create a main Route Table
## for each VPC, leaving our own Route Tables as secondary
resource "aws_main_route_table_association" "rtpub1assoc" {
  vpc_id         = aws_vpc.vpc1.id
  route_table_id = aws_route_table.rtpub1.id
}

resource "aws_security_group" "sg_jumpbox" {
  name        = "sg_jumpbox"
  description = "Used for access to the public instances"
  vpc_id      = aws_vpc.vpc1.id
  ingress { # allow ssh
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # better to restrict to a specific ip of the box from where you are connecting to the jump box, e.g. ["54.239.6.185/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = format("%s_sg_jumpbox", var.project)
    project = var.project
  }
}


#-----------
#--- Outputs
#-----------

output "vpc1_id" {
  value = aws_vpc.vpc1.id
}
output "igw_id" {
  value = aws_internet_gateway.igw.id
}
output "subpub1_id" {
  value = aws_subnet.subpub1.*.id[0]
}
output "subpub2_id" {
  value = aws_subnet.subpub2.*.id[0]
}
output "subpub3_id" {
  value = aws_subnet.subpub3.*.id[0]
}
output "sg_jumpbox" {
  value = aws_security_group.sg_jumpbox.id
}
output "rtpub1_id" {
  value = aws_route_table.rtpub1.*.id[0]
}
output "rtpub1assoc_id" {
  value = aws_main_route_table_association.rtpub1assoc.id
}
output "aws_subnet_ids" {
  value = [
    aws_subnet.subpub1.*.id[0],
    aws_subnet.subpub2.*.id[0],
    aws_subnet.subpub3.*.id[0],
  ]
}

