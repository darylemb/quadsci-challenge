output "arm_client_id" {
  description = "Client ID of the App Registration. Use as ARM_CLIENT_ID."
  value       = azuread_application.github_actions.client_id
}

output "arm_tenant_id" {
  description = "Tenant ID. Use as ARM_TENANT_ID."
  value       = var.tenant_id
  sensitive   = true
}

output "arm_subscription_id" {
  description = "Subscription ID. Use as ARM_SUBSCRIPTION_ID."
  value       = var.subscription_id
  sensitive   = true
}

output "service_principal_object_id" {
  description = "Object ID of the Service Principal."
  value       = azuread_service_principal.github_actions.object_id
}

