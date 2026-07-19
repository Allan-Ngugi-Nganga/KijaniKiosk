terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
}

data "aws_ami" "ubuntu" {
    most_recent = true 

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] 

}

resource "aws_security_group" "my_cool_firewall" {
  name        = "kijanikiosk-api-sg"
  description = "Security group for KijaniKiosk API"
}

resource "aws_vpc_security_group_egress_rule" "outgoing" {
  security_group_id = aws_security_group.my_cool_firewall.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.my_cool_firewall.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.my_cool_firewall.id
  cidr_ipv4         = "196.207.178.12/32" 
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

locals {
  servers = {
    api = {
      instance_type = "t3.micro"
    }
    payments = {
      instance_type = "t3.micro"
    }
    logs = {
      instance_type = "t3.micro" 
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name                   = each.key
  environment            = "staging"
  ami_id                 = data.aws_ami.ubuntu.id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = [aws_security_group.my_cool_firewall.id]
  key_name               = "kijanikiosk-key"
}

# resource "aws_instance" "kk_api" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "t3.micro"
#   tags          = { Name = "kijanikiosk-api-staging" }
# }