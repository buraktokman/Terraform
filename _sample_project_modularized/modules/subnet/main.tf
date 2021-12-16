# CREATE CUSTOM SUBNET
resource "aws_subnet" "udemy-subnet-1" {
    vpc_id = var.vpc_id
    cidr_block = var.subnet_cidr_block # "10.0.10.08/24"
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

# USE DEFAULT ROUTE TABLE
resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = var.default_route_table_id.default_route_table_id
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
    vpc_id = var.vpc_id
    tags = {
        Name: "${var.env_prefix}-igw"
    }
}

# ASSOCIATE ROUTE TABLE WITH SUBNET
# resource "aws_route_table_association" "udemy-rtb-assoc" {
#     subnet_id = aws_subnet.udemy-subnet-1.id
#     route_table_id = aws_route_table.udemy-rt.id
# }

# 3 ------------------------------------------
# CREATE ROUTE TABLE
resource "aws_route_table" "udemy-rt" {
    vpc_id = var.vpc_id
    route {
        cidr_block = "0.0.0.0/0" # IGW - outside the VPC
        gateway_id = aws_internet_gateway.udemy-igw.id # 
    }
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}