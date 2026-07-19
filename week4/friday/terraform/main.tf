data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "kijani_sg" {
  name        = "kijanikiosk-staging-sg"
  description = "Staging security group for KijaniKiosk infrastructure"

  # Rule for Challenge C: Allows incoming SSH configuration traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Dynamic ingress rule for application ports
  ingress {
    from_port   = 3000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  server_definitions = {
    api      = { name = "kijanikiosk-api", type = "t3.micro" }
    payments = { name = "kijanikiosk-payments", type = "t3.micro" }
    logs     = { name = "kijanikiosk-logs", type = "t3.micro" }
  }
}

# Reusable module call loop satisfying Requirement 1
module "app_server" {
  source   = "./modules/app_server"
  for_each = local.server_definitions

  server_name        = each.value.name
  instance_type      = each.value.type
  key_name           = var.key_name
  ami_id             = data.aws_ami.ubuntu.id
  security_group_ids = [aws_security_group.kijani_sg.id]
}