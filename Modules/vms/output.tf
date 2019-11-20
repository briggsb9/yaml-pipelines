output "vm_id" {
  value = values(azurerm_virtual_machine.vm)[*].id
}

output "ip_addresses" {
  value = values(azurerm_network_interface.nic)[*].private_ip_address
}
