###############################################################################
# Module: avd-users
# Creates Entra ID (Azure AD) users and assigns the RBAC roles needed to
# connect to an AVD Host Pool.
#
# Each user gets:
#   - "Desktop Virtualization User"  on the AVD Application Group
#   - "Virtual Machine User Login"   on the session host VM
#
# Note: if a user was previously created by the setup-avd-user.sh script,
# import it before applying:
#   terraform import 'module.avd_users.azuread_user.this["<key>"]' <object_id>
###############################################################################

# Discover the tenant's initial domain (e.g. contoso.onmicrosoft.com)
data "azuread_domains" "default" {
  only_initial = true
}

locals {
  domain = data.azuread_domains.default.domains[0].domain_name
}

resource "azuread_user" "this" {
  # Keys (username prefixes) are not secret — only passwords are.
  # nonsensitive(keys(...)) lets Terraform use them safely in for_each.
  for_each = toset(nonsensitive(keys(var.users)))

  user_principal_name   = "${each.key}@${local.domain}"
  display_name          = var.users[each.key].display_name
  password              = var.users[each.key].password
  force_password_change = false
}

resource "azurerm_role_assignment" "avd_desktop_user" {
  for_each = azuread_user.this

  principal_id         = each.value.object_id
  role_definition_name = "Desktop Virtualization User"
  scope                = var.app_group_id
}

resource "azurerm_role_assignment" "vm_login" {
  for_each = azuread_user.this

  principal_id         = each.value.object_id
  role_definition_name = "Virtual Machine User Login"
  scope                = var.vm_id
}
