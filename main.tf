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
    region = "us-east-1"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block                     # "10.0.0.0/16"

  azs = [var.avail_zone]                        # ,"eu-west-1a", "eu-west-1b", "eu-west-1c"
  # private_subnets = ["10.0.1.0/24"]
  public_subnets  = [var.subnet_cidr_block]     #  "10.0.101.0/24"
  public_subnet_tags = { Name = "${var.env_prefix}-subnet-1" }

  #enable_nat_gateway = true
  #enable_vpn_gateway = true

  tags = {
      Name: "${var.env_prefix}-vpc"
      #Terraform = "true"
      #Environment = "dev"
  }
}

module "myapp_webserver" {
    source = "./modules/webserver"
    vpc_id = module.vpc.vpc_id                      # aws_vpc.myapp-vpc.id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    public_key_location = var.public_key_location
    instance_type = var.instance_type
    subnet_id = module.vpc.public_subnets[0]        # module.myapp_subnet.subnet.id
    avail_zone = var.avail_zone
    
}