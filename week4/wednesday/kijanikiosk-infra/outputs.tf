output "server_ips" {
  value = {
    for name, server in module.app_servers : name => server.public_ip
  }
}