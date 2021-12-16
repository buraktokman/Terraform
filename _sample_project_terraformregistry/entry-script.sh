#!/bin/bash
yum update -y && sudo yum install -y docker
sudo systemcyl start docker
sudo usermod -aG docker
docker run -p 8080:80 nginx