# Define the AWS provider configuration.
provider "aws" {
  region = "eu-west-3"
  access_key = var.access_key
  secret_key = var.secret_key
}

variable "subnet_cidr_block" {
  description = "subnet cidr block"
  default = "10.0.10.0/24"
  type = string
}

resource "aws_key_pair" "example" {
  key_name   = "terraform-demo-abhi"  # Replace with your desired key name
  public_key = file("~/.ssh/id_rsa.pub")  # Replace with the path to your public key file
}

resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.0.0.0/16"
  # Tag for giving name to resources
  tags = {
    "Name" = "devlopment"
    "vpc_env": "dev"
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.dev-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-west-3a"
  map_public_ip_on_launch = true
  tags = {
    Name: "subnet-1-dev"
  }
}
#data source to check defualt vpc for create a subnet on it
data "aws_vpc" "existing_vpc" {
  default = true
}
resource "aws_subnet" "dev-subnet-2" {
  vpc_id = data.aws_vpc.existing_vpc.id
  cidr_block = "172.31.48.0/20"
  availability_zone = "eu-west-3a"
  tags = {
    "Name" = "subnet-2-dev"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.dev-vpc.id
}

resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.dev-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.dev-subnet-1.id
  route_table_id = aws_route_table.RT.id
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.dev-vpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_instance" "server" {
  ami                    = "ami-0261755bbcb8c4a84"
  instance_type          = "t2.micro"
  key_name      = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.dev-subnet-1.id

  connection {
    type        = "ssh"
    user        = "ubuntu"  # Replace with the appropriate username for your EC2 instance
    private_key = file("~/.ssh/id_rsa")  # Replace with the path to your private key
    host        = self.public_ip
  }

  # File provisioner to copy a file from local to the remote EC2 instance
  provisioner "file" {
    source      = "app.py"  # Replace with the path to your local file
    destination = "/home/ubuntu/app.py"  # Replace with the path on the remote instance
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from the remote instance'",
      "sudo apt update -y",  # Update package lists (for ubuntu)
      "sudo apt-get install -y python3-pip",  # Example package installation
      "cd /home/ubuntu",
      "sudo pip3 install flask",
      "sudo python3 app.py &",
    ]
  }
}
output "dev-vpc-id" {
  value = aws_vpc.dev-vpc.id
}
output "dev-subnet1-id" {
  value = aws_subnet.dev-subnet-1.availability_zone
}
output "dev-subnet2-id" {
  value = aws_subnet.dev-subnet-2.cidr_block
}

# 'Terraform destroy -target aws_subnet.dev-subnet-2' or 'remove aws_subnet block then apply' to remove
# Terraform State list shows the Resources in tf file
# Terraform state show aws_subnet.dev-subnet-1 will provide details of subnet
