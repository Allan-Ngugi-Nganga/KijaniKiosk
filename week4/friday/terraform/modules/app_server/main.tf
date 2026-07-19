resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name = var.server_name
  }
}

output "public_ip" {
  value = aws_instance.server.public_ip
}
