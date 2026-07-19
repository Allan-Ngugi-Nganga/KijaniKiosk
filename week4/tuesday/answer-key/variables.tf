# variables.tf
variable "aws_region" {
  description = "AWS region to deploy infrastructure into"
  type        = string
  default     = "eu-west-1"    # Frankfurt - closest to Nairobi with EC2 free tier
}

variable "instance_type" {
  description = "EC2 instance type for KijaniKiosk application servers"
  type        = string
  default     = "t2.micro"    # Free tier eligible
  
   validation {
    condition     = startswith(var.instance_type, "t")
    error_message = "Instance type must start with 't' (free-tier eligible types)."
  }
}

variable "environment" {
  description = "Deployment environment: staging or production"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to attach to instances"
  type        = string
  # No default: this must be provided explicitly per environment
}