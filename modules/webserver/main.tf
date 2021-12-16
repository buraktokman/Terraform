# CREATE NEW SECURITY GROUP
resource "aws_security_group" "myapp_sg" {
    vpc_id = var.vpc_id
    name = "myapp-sg"

    ingress {                               # INCOMING RULE #1
        from_port = 22
        to_port = 22
        protocol = "tcp"
        # cidr_block = ["217.146.78.99/32"]   # WHO WILL ACCESS?
        cidr_blocks = var.my_ip
    }

    ingress {                               # INCOMING RULE #2
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {                               # OUTGOING RULE #1
        from_port = 0                      # any connection to leave
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name: "${var.env_prefix}-sg"
    }

}

# USE DEFAULT SG
resource "aws_default_security_group" "default_sg" {
    vpc_id = var.vpc_id                     #aws_vpc.myapp-vpc.id

    ingress {                               # INCOMING RULE #1
        from_port = 22
        to_port = 22
        protocol = "tcp"
        # cidr_block = ["217.146.78.99/32"]   # WHO WILL ACCESS?
        cidr_blocks = var.my_ip
    }

    ingress {                               # INCOMING RULE #2
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {                               # OUTGOING RULE #1
        from_port = 0                      # any connection to leave
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name: "${var.env_prefix}-default-sg"
    }

}

data "aws_ami" "latest_amazon_linux_image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "ssh_key" {
    key_name = "Test-Terraform"
    #public_key = var.my_public_key
    public_key = file(var.public_key_location)
}

# CREATE EC2 INSTANCE
resource "aws_instance" "myapp_server" {
    ami = data.aws_ami.latest_amazon_linux_image.id
    instance_type = var.instance_type

    subnet_id = var.subnet_id                       # aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp_sg.id]    #  aws_default_security_group.default_sg.id
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh_key.key_name

    user_data = file("entry-script.sh")

    tags = {
        Name: "${var.env_prefix}-server"
    }
}

