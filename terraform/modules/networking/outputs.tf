output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "aci_subnet_id" {
  description = "Resource ID of the ACI workload subnet."
  value       = azurerm_subnet.aci.id
}

output "vm_subnet_id" {
  description = "Resource ID of the dev VM subnet."
  value       = azurerm_subnet.vm.id
}

output "nat_gateway_public_ip" {
  description = "Public IP address used by the NAT Gateway for outbound traffic from snet-vm."
  value       = azurerm_public_ip.nat.ip_address
}