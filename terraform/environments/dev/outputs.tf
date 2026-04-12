output "vnet_id" {
  value = module.networking.vnet_id
}

output "nat_gateway_public_ip" {
  description = "VM egress traffic appears from this IP."
  value       = module.networking.nat_gateway_public_ip
}

output "container_private_ip" {
  description = "ACI private IP — reachable from the dev VM over VNet."
  value       = module.container.container_private_ip
  sensitive   = true
}

output "vm_name" {
  value = module.devbox.vm_name
}

output "vm_private_ip" {
  description = "Dev VM private IP. Connect via AVD — no public IP."
  value       = module.devbox.vm_private_ip
  sensitive   = true
}

output "data_disk_id" {
  value = module.devbox.data_disk_id
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

# ── AVD ────────────────────────────────────────────────────────────────────────

output "avd_workspace_name" {
  description = "Name of the AVD Workspace."
  value       = module.avd.workspace_name
}

output "avd_webclient_url" {
  description = "URL to open in the browser to connect to the dev desktop."
  value       = module.avd.webclient_url
}

output "avd_app_group_id" {
  description = "Assign developers the 'Desktop Virtualization User' role on this resource."
  value       = module.avd.app_group_id
}

output "avd_user_upns" {
  description = "UPNs of all AVD users provisioned by Terraform."
  value       = module.avd_users.user_principal_names
}