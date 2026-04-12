output "vm_id" {
  description = "Resource ID of the dev VM."
  value       = azurerm_windows_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the dev VM."
  value       = azurerm_windows_virtual_machine.this.name
}

output "vm_private_ip" {
  description = "Private IP address of the dev VM."
  value       = azurerm_network_interface.this.private_ip_address
}

output "nic_id" {
  description = "Resource ID of the network interface."
  value       = azurerm_network_interface.this.id
}

output "data_disk_id" {
  description = "Resource ID of the persistent data disk."
  value       = azurerm_managed_disk.data.id
}