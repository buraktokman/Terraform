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


variable vpc_cidr_blocks {}
variable subnet_cidr_blocks {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
variable public_key_location {}
variable private_key_location {}


# 1 ------------------------------------------
# CREATE CUSTOM VPC
resource "aws_vpc" "udemy-vpc" {
    cidr_blocks = var.vpc_cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc" # var.cidr_blocks[0].name
    }
}


# 2 ------------------------------------------
# CREATE CUSTOM SUBNET
resource "aws_subnet" "udemy-subnet-1" {
    vpc_id = aws_vpc.udemy-vpc.id
    cidr_block = var.subnet_cidr_block # "10.0.10.08/24"
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}


# 3 ------------------------------------------
# CREATE ROUTE TABLE
resource "aws_route_table" "udemy-rt" {
    vpc_id = aws_vpc.udemy-vpc.id
    route {
        cidr_block = "0.0.0.0/0" # IGW - outside the VPC
        gateway_id = aws_internet_gateway.udemy-igw.id # 
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

# USE DEFAULT ROUTE TABLE
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.udemy-vpc.default_route_table_id
    route {
        cidr_block = "0.0.0.0/0" # IGW - outside the VPC
        gateway_id = aws_internet_gateway.udemy-igw.id # 
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

# CREATE INTERNET GATEWAY
resource "aws_internet_gateway" "udemy-igw" {
    vpc_id = aws_vpc.udemy-vpc.id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

# ASSOCIATE ROUTE TABLE WITH SUBNET
# resource "aws_route_table_association" "udemy-rtb-assoc" {
#     subnet_id = aws_subnet.udemy-subnet-1.id
#     route_table_id = aws_route_table.udemy-rt.id
# }


# 4 ------------------------------------------
# CREATE SECURITY GROUP (use default)
# resource "aws_security_group" "udemy-sg" {
resource "aws_default_security_group" "udemy-sg" {
    # name = "udemy-sg"
    vpc_id = aws_vpc.udemy-vpc.id
    description = "Allow SSH and HTTP access"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = var.my_ip[0] # ["217.146.78.97/32", "0.0.0.0/0", "::/0"]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0                 # ANY PORT
        protocol = "-1"             # ANY PROTOCOL
        cidr_blocks = ["0.0.0.0/0"] # ANY IP
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-sg"
    }
}


# 5 ------------------------------------------
# GET LATEST AMZ LINUX IMAGE
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        valaues = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        valaues = ["hvm"]
    }
}

output "aws_ami_id" {
    valus = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
    valus = aws_instance.udemy-server
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-ley"
    public_key = file()var.public_key_location #var.my_public_key
}

# CREATE EC2 INSTANCE
resource "aws_ec2_instance" "udemy-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id     # ami = "ami-0f9e9d9c"
    instance_type =  var.instance_type                  # "t2.micro"
    
    subnet_id = "${aws_subnet.udemy-subnet-1.id}"
    vpc_security_groups_ids = aws_default_security_group.default-sg.id # ["${aws_security_group.udemy-sg.id}"]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name # "server-key-pair"

    # PASS DATA TO AWS
    user_data = file("entry-scritp.sh")
    # user_data = <<EOF
    #                 #!/bin/bash
    #                 yum update -y && sudo yum install -y docker
    #                 sudo systemcyl start docker
    #                 sudo usermod -aG docker
    #                 docker run -p 8080:80 nginx
    #             EOF
    
    # PROVISION INSTANCE
    connection {
        type = "ssh"
        host = self.ec2_public_ip
        user = "ec2-user"
        private_key = file(var.private_key_location)
    }
    # CONNECT VIA SSH
    provisioner "file" {
        source = "entry-script.sh"
        destination = "/home/ec2-user/entry-script-on-ec2.sh"
    }
    # EXECUTE REMOTE CMD
    provisioner "remote-exec" {
        # inline = [
        #     "export ENV=dev",
        #     "mkdir newdir"
        # ]
        # OR
        script = file("entry-script-on-ec2.sh") # file must exists on server!
    }
    # EXECUTE LOCAL CMD
    provisioner "local-exec" {
        command = "echo ${self.public_ip} > output.txt"        
    }

    tags {
        Name = "${var.env_prefix}-dev-server"
    }
}  


# 6 ------------------------------------------
# DEPLOY NGINX DOCKER CONTAINER





