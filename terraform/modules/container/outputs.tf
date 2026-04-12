output "container_group_id" {
  description = "Resource ID of the container group."
  value       = azurerm_container_group.this.id
}

output "container_private_ip" {
  description = "Private IP address assigned to the container group inside the VNet."
  value       = azurerm_container_group.this.ip_address
}

output "container_name" {
  description = "Name of the container group."
  value       = azurerm_container_group.this.name
}
