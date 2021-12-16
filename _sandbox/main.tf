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


variable "subnet_cidr_block" {
    description = "CIDR block for the subnet"
    default = "10.0.10.0/24"
    type = string # string, number, bool
}

variable "cidr_blocks" {
    description = "CIDR blocks for VPC and subnets"
    # type = list(string)
    type = list(object({
        cidr_blocks = string
        name = string
    }))
}

variable avail_zone {

}

resource "aws_vpc" "development-vpc" {
    # cidr block = "10.0.0.0/16"
    cidr_blocks = var.cidr_blocks[0].cidr_block
    tags = {
        Name: "development"
        Name: var.cidr_blocks[0].name
        }
}

resource "aws_subnet" "dev-subnet-1" {
    pc_id = aws_vpc.development-vpc.id
    #cidr block = "10.0.10.08/24"
    # cidr block = var.subnet_cidr_block
    cidr_blocks = var.cidr_blocks[1].cidr_block
    availability zone = "eu-west-3a"
    tags = {
        # Name: "subnet-1-dev"
        Name: var.cidr_blocks[1].name
        }
}

output "dev-vpc-id" {
    value = aws_vpc.development-vpc.id
    # value = aws_vpc.development-vpc.name
}

output "dev-subnet-id" {
    value = aws_subnet.development-vpc.id
}

/*
terraform plan -auto-approve
terraform apply -var "subnet_cidr_block=10.0.30.0/24"
terraform apply -var-file terraform-dev.tfvars

*/