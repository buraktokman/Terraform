# Check the returned data
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

# Output the VM
output "instance" {
    value = aws_instance.myapp-server#.public_ip
}