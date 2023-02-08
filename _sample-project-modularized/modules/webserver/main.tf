# Create Security Security Group (firewall rules)
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = var.vpc_id
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
# Use default security group
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


# Filter AMI (Amazon Linux 2 AMI)
# https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Images:visibility=public-images
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name" # Filter the "name" attribute
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


# Create SSH key pair
resource "aws_key_pair" "ssh-key" {
    key_name = var.key_name
    # A key pair must already exist locally
    # public_key = var.my_public_key
    public_key = file(var.public_key_location)
}

# Provision EC2 instance
#     and deploy nginx Docker container
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
    
    availability_zone = var.avail_zone
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    associate_public_ip_address = true
    # Reference the key pair
    key_name = aws_key_pair.ssh-key.key_name
    # Metadata
    user_data = file("entry-script.sh")
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
        source = file("entry-script.sh")
        # have to scepecify the full path (including the file name)
        destination = "/home/ec2-user/entry-script.sh"
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
        destination = "/home/ec2-user/entry-script.sh"
    } */

    # Provisionder: to run commands
    # https://www.terraform.io/docs/provisioners/index.html
    provisioner "remote-exec" {
        # inline = [
        #     "export ENV=dev",
        #     "mkdir newdir",
        # ]
        # Script must already exist on the VM!
        script = file("entry-script.sh")
    }

    # Provisionder: invoke a local executable after the resource is created
    provisioner "local-exec" {
        command = "echo ${self.public_ip} > output.txt"
    }

    tags = {
        Name: "${var.env_prefix}-server"
    }
}