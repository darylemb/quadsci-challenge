output "user_principal_names" {
  description = "Map of key → UPN for all provisioned AVD users."
  value       = { for k, u in azuread_user.this : k => u.user_principal_name }
}

output "user_object_ids" {
  description = "Map of key → Object ID for all provisioned AVD users."
  value       = { for k, u in azuread_user.this : k => u.object_id }
}
