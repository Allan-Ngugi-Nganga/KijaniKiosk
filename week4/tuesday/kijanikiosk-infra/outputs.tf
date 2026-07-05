output "api_server_ip" {
  description = "The public IP address of the KijaniKiosk API server"
  value       = aws_instance.kijanikiosk_api.public_ip
}