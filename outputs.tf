output "ec2_public_ip" {
    value = module.myapp_webserver.instance.public_ip
}
