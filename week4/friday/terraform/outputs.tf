output "server_ips" {
  value = { for k, v in module.app_server : k => v.public_ip }
}