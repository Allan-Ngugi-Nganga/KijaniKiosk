terraform {
    required_providers {
        local = {
            source = "hashicorp/local"
            version = "~>2.4"
        }

        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "local" {

}

provider "aws" {
    region = "us-east-1"

}

# data.tf (or add to main.tf)
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"]    # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "kk_api" {
  ami           = data.aws_ami.ubuntu_22_04.id    # Dynamic, not hardcoded
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  tags = {
    Name        = "kijanikiosk-api-staging"
    Environment = var.environment
  }
}

# resource "local_file" "test" {

# }