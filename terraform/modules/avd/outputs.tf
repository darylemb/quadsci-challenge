output "host_pool_id" {
  description = "Resource ID of the AVD Host Pool."
  value       = azurerm_virtual_desktop_host_pool.this.id
}

output "host_pool_name" {
  description = "Name of the AVD Host Pool. Required by the session host DSC extension."
  value       = azurerm_virtual_desktop_host_pool.this.name
}

output "registration_token" {
  description = "Registration token for session hosts. Passed to the devbox DSC extension via protected_settings."
  value       = azurerm_virtual_desktop_host_pool_registration_info.this.token
  sensitive   = true
}

output "app_group_id" {
  description = "Resource ID of the Desktop Application Group."
  value       = azurerm_virtual_desktop_application_group.this.id
}

output "workspace_id" {
  description = "Resource ID of the AVD Workspace."
  value       = azurerm_virtual_desktop_workspace.this.id
}

output "workspace_name" {
  description = "Name of the AVD Workspace."
  value       = azurerm_virtual_desktop_workspace.this.name
}

output "webclient_url" {
  description = "URL for the AVD web client. Developers can connect from any browser."
  value       = "https://client.wvd.microsoft.com/arm/webclient/"
}