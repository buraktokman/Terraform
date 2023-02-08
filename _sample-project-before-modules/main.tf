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
terraform init
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

# EC2
chmod 400 ~/.ssh/terraform-test.pem
ssh -i ~/.ssh/terraform-test.pem ec2-user@52.47.179.234

# SSH
cd ~
ssh-keygen
cat .ssh/id_rsa.pub
*/


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


# ------ VARIABLES -----------
variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable key_name {}
variable key_file {}
variable user_data_script {}
variable public_key_location {}
variable private_key_location {}


# ------ RESOURCES -----------
# 1. Create VPC
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        # Add "dev-" prefix to the name
        Name: "${var.env_prefix}-vpc"
    }
}


# 2. Create subnet
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}


# 3. Create Internet Gateway
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

# 3.1 Use default route table
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-default-rtb"
    }
}
# --- OR ---
# 3.1 Creat new Route Table: target igw
/* resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}
3.2 Route table association
resource "aws_route_table_association" "myapp-rtb-association" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
} */


# 4. Create Security Security Group (firewall rules)
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
    # Incoming traffic
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Outgoing
    egress {
        from_port   = 0    # any
        to_port     = 0
        protocol    = "-1" # any
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-sg"
    }
}
# --- OR ---
# 4.1 Use default security group
/* resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id
    # Incoming traffic
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Outgoing
    egress {
        from_port   = 0    # any
        to_port     = 0
        protocol    = "-1" # any
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-default-sg"
    }
} */


# 5.1 Filter AMI (Amazon Linux 2 AMI)
# https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name" # Filter the "name" attribute
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}
# Check the returned data
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

# 5.2 Create SSH key pair
resource "aws_key_pair" "ssh-key" {
    key_name = var.key_name
    # A key pair must already exist locally
    # public_key = var.my_public_key
    public_key = file(var.public_key_location)
}

# 5.3 Provision EC2 instance
#     and deploy nginx Docker container
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
    
    availability_zone = var.avail_zone
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    associate_public_ip_address = true
    # Reference the key pair
    key_name = aws_key_pair.ssh-key.key_name
    # Metadata
    user_data = file(var.user_data_script)
    /* user_data = <<EOF
                    #!/bin/bash
                    sudo yum update -y && sudo yum install -y docker
                    sudo systemctl start docker
                    sudo usermod -aG docker ec2-user
                    docker run -p 8080:80 nginx # Run nginx container
                EOF */
    
    # ! CAUTION !
    # Provisioners are NOT recommended!
    #   - Breaks idempotency concept, TF doesn't know what you execute
    #   - Breaks current-desired state comparison
    # Alternative to "remote-exec"
    #   - Use configuration management tools (Ansible, Chef, Puppet)
    #   - Use user_data if possible
    # Alternative to "local-exec"
    #   - Use "local" provider

    # Connect via SSH
    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = file(var.private_key_location)
    }
    # Provisioner: to copy files to the VM
    provisioner "file" {
        source = var.user_data_script
        # have to scepecify the full path (including the file name)
        destination = "/home/ec2-user/entry-script-on-ec2.sh"
    }
    # Copy to multiple VMs (put the connection block inside)
    /* provisioner "file" {
        connection {
            type = "ssh"
            host = someotherserver.public_ip
            user = "ec2-user"
            private_key = file(var.private_key_location)
        }
        source = var.user_data_script
        destination = "/home/ec2-user/entry-script-on-ec2.sh"
    } */

    # Provisionder: to run commands
    # https://www.terraform.io/docs/provisioners/index.html
    provisioner "remove-exec" {
        # inline = [
        #     "export ENV=dev",
        #     "mkdir newdir",
        # ]
        # Script must already exist on the VM!
        script = file("entry-script-on-ec2")
    }

    # Provisionder: invoke a local executable after the resource is created
    provisioner "local-exec" {
        command = "echo ${self.public_ip} > output.txt"
    }

    tags = {
        Name: "${var.env_prefix}-server"
    }
}

# VM's IP address
output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}








# ------ _DEP ----------------
# variable "subnet_cidr_block" {
#   description = "CIDR block for the subnet"
# #   default     = "10.1.10.0/24" # (optional)
# }

# variable "vpc_cidr_block" {
#   description = "VPC CIDR block"
# }

# variable "cidr_blocks" {
#   description = "CIDR blocks"
# #   type = list(string)
#   type = list(object(
#     {
#       cidr_block = string
#       name = string
#     }
#   ))
# }



# variable "environment" {
#   description = "Deployment environment"
# }

# # ------ IAC -----------------
# # Create a VPC
# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
# # First one is resource type, second one is the name of the resource
# resource "aws_vpc" "development-vpc" {
#     # cidr_block = "10.1.0.0/16"
#     cidr_block = var.cidr_blocks[0].cidr_block
#     tags = {
#         # Name: "development-vpc"
#         Name: var.cidr_blocks[0].name
#         environment: "development"
#     }
# }

# resource "aws_subnet" "dev-subnet-1" {
#     vpc_id = aws_vpc.development-vpc.id
#     # cidr_block = "10.1.10.0/24"
#     cidr_block = var.cidr_blocks[1].cidr_block
#     availability_zone = var.avail_zone
#     tags = {
#         Name: var.cidr_blocks[1].name
#         # Name: "dev-subnet-1"
#     }
# }

# # Get default VPC
# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
# data "aws_vpc" "existing_vpc" {
#     default = true
# }

# # Create subnet in existing VPC
# resource "aws_subnet" "dev-subnet-2" {
#     vpc_id = data.aws_vpc.existing_vpc.id
#     cidr_block = "172.31.48.0/20"
#     availability_zone = "us-east-1a"
#     tags = {
#         Name: "dev-subnet-2"
#     }
# }

# output "dev-vpc-id" {
#     value = aws_vpc.development-vpc.id
# }

# output "dev-subnet-id" {
#     value = aws_subnet.dev-subnet-1.id
# }

