/*
# CREDS
Console:  https://.signin.aws.amazon.com/console
User:     
Pass:     

# Use provider or environment variables
# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#environment-variables
export AWS_SECRET_ACCESS_KEY=
export AWS_ACCESS_KEY_ID=


# NOTES
resource: create new resources
data: pull data from existing resources
output: output after applying a resource

# FILES
terraform.tfvars: contains variables

# COMMANDS
terraform init (at the beginning of the project and whenver a new module is added/changed)
terraform plan
terraform apply
terraform apply -var "subnet_cidr_block=10.0.30.0/24"
terraform apply --auto-approve -var-file terraform-dev.tfvars
terraform destroy
terraform destroy -target aws_subnet.dev-subnet-2
terraform state list
terraform state show aws_vpc.dev-vpc

# GIT
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/buraktokman/Terraform.git
git remote add origin git@github.com:buraktokman/terraform
git push -origin master

git status
git branch -M main
# New branch: "modules"
git checkout -b feature/modules

# EC2
chmod 400 ~/.ssh/terraform-test.pem
ssh -i ~/.ssh/terraform-test.pem ec2-user@52.47.179.234

# SSH
cd ~
ssh-keygen
cat .ssh/id_rsa.pub

# ERRORS AND SOLUTIONS
"Failed to obtain provisioner schema"
Delete the `terraform` directory and lock file,
and then init again `terraform init -upgrade`

If you're on running it on Apple M1 chip, you might as well need to set this:
`export GODEBUG=asyncpreemptoff=1;`
*/


# ------ REMOTE STATE --------
terraform {
    required_version = ">= 4.53.0"
    backend "s3" {
        bucket = "myapp-terraform-state"
        key    = "myapp/state.tfstate"
        region = "us-east-1"
    }
}


# ------ PROVIDER ------------
/* provider "aws" {
    region = "us-east-1" # or use AWS_DEFAULT_REGION env var
    access_key = ""      # or use AWS_ACCESS_KEY_ID env var
    secret_key = ""      # or use AWS_SECRET_ACCESS_KEY env var
} */

# Use environment variables
provider "aws" {
  region = "us-east-1"
}


# ------ RESOURCES -----------


# VPC module
# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
    # Code location, code downloaded in "terraform init" step
    source = "terraform-aws-modules/vpc/aws"

    name = "my-vpc"
    cidr = var.vpc_cidr_block

    azs            = [var.avail_zone]
    public_subnets = [var.subnet_cidr_block]
    public_subnet_tags = {
        Name = "${var.env_prefix}-subnet-1"
    }

    tags = {
        Name = "${var.env_prefix}-vpc"
        Environment = "dev"
    }
}
# resource "aws_vpc" "myapp-vpc" {
#     cidr_block = var.vpc_cidr_block
#     tags = {
#         # Add "dev-" prefix to the name
#         Name: "${var.env_prefix}-vpc"
#     }
# }

# module "myapp-subnet" {
#     source      = "./modules/subnet"
#     vpc_id      = aws_vpc.myapp-vpc.id
#     avail_zone  = var.avail_zone
#     subnet_cidr_block      = var.subnet_cidr_block
#     default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
#     env_prefix  = var.env_prefix
# }



module "myapp-server" {
    source      = "./modules/webserver"
    vpc_id      = module.vpc.vpc_id
    my_ip       = var.my_ip
    key_name    = var.key_name
    image_name  = var.image_name
    public_key_location  = var.public_key_location
    private_key_location = var.private_key_location
    instance_type        = var.instance_type
    subnet_id   = module.vpc.public_subnets[0]
    avail_zone  = var.avail_zone
    env_prefix  = var.env_prefix
}
