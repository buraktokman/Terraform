# CREATE SECURITY GROUP (use default)
resource "aws_security_group" "udemy-sg" {
# resource "aws_default_security_group" "udemy-sg" {
    name = "udemy-sg"
    vpc_id = var.vpc_id
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


# GET LATEST AMZ LINUX IMAGE
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        valaues = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        valaues = ["hvm"]
    }
}


resource "aws_key_pair" "ssh-key" {
    key_name = "server-ley"
    public_key = file()var.public_key_location #var.my_public_key
}


# CREATE EC2 INSTANCE
resource "aws_ec2_instance" "udemy-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id     # ami = "ami-0f9e9d9c"
    instance_type =  var.instance_type                  # "t2.micro"
    
    # USE LOCAL RESOURCE
    # subnet_id = "${aws_subnet.udemy-subnet-1.id}"
    # OR - USE SUBNET MODULE
    subnet_id = var.subnet_id

    vpc_security_groups_ids = [aws_security_group.udemy-sg.id] # ["${aws_security_group.udemy-sg.id}"]
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


