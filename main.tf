provider "aws" {
  region = var.my_region
  access_key = var.my_access_key
  secret_key = var.my_secret_key
}

# 1 Create a VPC
resource "aws_vpc" "main-vpc" {
  cidr_block = var.vpc_cidr_block_var
  tags = {
    "Name" = "main-vpc"
  }
}

# 2 Create Internet Gateway
resource "aws_internet_gateway" "main-gw" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = "i-gw"
  }
}

# 3 Create custom route table
resource "aws_route_table" "main-route-table" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gw.id
  }
  tags = {
    Name = "my-rt"
  }
}

# 4 Create a subnet
resource "aws_subnet" "subnet-1" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = var.subnet_cidr_block
 #   map_public_ip_on_launch = true
    tags = {
      "Name" = "prd-subnet"
    }
}

# 5 Associate subnet with a route table
resource "aws_route_table_association" "asst-rtbl" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.main-route-table.id
}

# 6 Create security group to allow port 22,80,443
resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.main-vpc.id
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = var.allowed_ips
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.allowed_ips
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.allowed_ips
  } 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_web_traffic"
  }
}

# 7 Create network interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
 security_groups = [aws_security_group.allow_web_traffic.id] 
}

# 8 Create Elastic IP
resource "aws_eip" "PublicIP" {
  network_interface = aws_network_interface.web-server-nic.id
  vpc      = true
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.main-gw]
}

output "Server-Public-IP" {
    value = aws_eip.PublicIP.public_ip
}

# 9 Create ubuntu server and install docker and run nginx container
resource "aws_instance" "ec2-web-server" {
  ami = var.ami
  instance_type = "t2.micro"
  key_name = var.private_key
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get remove docker docker-engine docker.io containerd runc -y
              sudo apt-get update
              sudo apt-get install \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release -y
              sudo apt  install docker.io -y
              sudo snap install docker -y
              sudo apt install python3-pip -y
              pip3 install Flask
              pip3 install Flask-RESTful
              pip3 install pandas
              sudo apt-get install firewalld -y
              sudo systemctl enable firewalld
              sudo systemctl start firewalld
              sudo docker run --name nginx131 -p 80:80 -d nginx
              EOF
  connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = "${file("${var.key_path}/${var.private_key_name}")}"
  }

  provisioner "file" {
    source = "healthcheck.sh"
    destination = "~/healthcheck.sh"
  }
  provisioner "file" {
    source = "logsearch.py"
    destination = "~/logsearch.py"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir ~/tmp/",
      "chmod u+x ~/*",
      "nohup ./healthcheck.sh &"
    ]
  }
  tags = {
      Name = "Ubuntu-Docker"
  }
}