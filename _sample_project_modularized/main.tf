/*
Provision AWS infrastructure

1 - Create custom VPC
2 - Create custom subnet
3 - Create route table & internet gateway
4 - Provision EC2 instance
5 - Deploy nginx Docker container
6 - Create Security Group (firewall)
*/

terraform {
    required_version = ">= 0.12"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "3.52.0"
            }
    }
    /*backend "s3" {
      bucket = "myapp-bucket"
      key = "myapp/state.tfstate"
      region = "us-east-1"      #var.avail_zone
    }*/
    
}

provider "aws" {
    region = "eu-west-3"
    access key = ""
    secret_key = ""
}


# 1 ------------------------------------------
# CREATE CUSTOM VPC
resource "aws_vpc" "udemy-vpc" {
    cidr_blocks = var.vpc_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc" # var.cidr_blocks[0].name
    }
}


# 2 ------------------------------------------
# SUBNET MODULE
module "udemy-subnet" {
    # .tfvars -> variables.tf -> here
    source = "./modules/subnet"
    subnet_cidr_block = var.subnet_cidr_block
    avail_zone = var.avail_zone
    vpc_id = aws_vpc.udemy-vpc.id
    default_route_table_id = aws_vpc.udemy-vpc.default_route_table_id
}


# 5 ------------------------------------------
module "udemy-webserver" {
    source = "./modules/webserver"
    vpc_id = aws_vpc.udemy-vpc.id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    public_key_location = var.public_key_location
    instance_type = var.instance_type
    subnet_id = module.udemy-subnet.subnet.id
    avail_zone = var.avail_zone
}



