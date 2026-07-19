variable "environment" {
  description = "The environment we are deploying to (e.g., staging, production)"
  type    = string
  default = "staging"
}

variable "instance_type" {
    description = "The size of the EC2 instance"
    type = string
    default = "t3.micro"

    validation {
        condition = var.instance_type == "t3.micro"
        error_message = "Instance type must be exactly 't3.micro' to ensure free-tier eligibility on this AWS account."

    }
}

variable "key_name" {
  description = "The name of the AWS SSH key pair to attach to the server"
  type        = string
}

variable "aws_region"{
    description = "Provider region"
    type = string
    default = "us-east-1"
}
