output "ui" {
  sensitive = false
  value     = "http://${azurerm_public_ip.YugaByte_Public_IP.0.ip_address}:7000"
}
output "ssh_user" {
  sensitive = false
  value = "${var.ssh_user}"
}
output "ssh_key" {
  sensitive = false
  value     = "${var.ssh_private_key}"
}