output "master-ui" {
  sensitive = false
  value     = "http://${azurerm_public_ip.YugaByte_Public_IP[0].ip_address}:7000"
}

output "tserver-ui" {
  sensitive = false
  value     = "http://${azurerm_public_ip.YugaByte_Public_IP[0].ip_address}:9000"
}

output "ssh_user" {
  sensitive = false
  value     = var.ssh_user
}

output "ssh_key" {
  sensitive = false
  value     = var.ssh_private_key
}

output "JDBC" {
  sensitive = false
  value     = "postgresql://postgres@${azurerm_public_ip.YugaByte_Public_IP[0].ip_address}:5433"
}

output "YSQL" {
  sensitive = false
  value     = "psql -U postgres -h ${azurerm_public_ip.YugaByte_Public_IP[0].ip_address} -p 5433"
}

output "YCQL" {
  sensitive = false
  value     = "cqlsh ${azurerm_public_ip.YugaByte_Public_IP[0].ip_address} 9042"
}

output "YEDIS" {
  sensitive = false
  value     = "redis-cli -h ${azurerm_public_ip.YugaByte_Public_IP[0].ip_address} -p 6379"
}

output "hosts" {
  value = "${azurerm_public_ip.YugaByte_Public_IP.*.ip_address}"
}
