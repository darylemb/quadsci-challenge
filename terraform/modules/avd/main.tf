###############################################################################
# AVD Module — Azure Virtual Desktop (Personal Host Pool)
#
# Creates:
#   - Host Pool (Personal, Persistent assignment, AAD-joined)
#   - Registration Info   — token consumed by the session host DSC extension
#   - Application Group   — "Desktop" type (full desktop experience)
#   - Workspace           — the portal/client entry point for developers
#   - Workspace ↔ App Group association
#
# Session hosts (VMs) are registered via the devbox module using the token
# output from this module. No domain controller is required — authentication
# uses Azure Active Directory (Entra ID).
#
# Developer access flow:
#   Browser / Windows App → https://client.wvd.microsoft.com → this workspace
#   → AVD Reverse Connect (outbound 443 from VM, no inbound) → Desktop session
###############################################################################

resource "azurerm_virtual_desktop_host_pool" "this" {
  name                = "vdhp-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Personal: 1:1 VM-per-developer, state persists between sessions
  type                             = "Personal"
  load_balancer_type               = "Persistent"
  personal_desktop_assignment_type = "Automatic"

  # Enables the modern RDP Shortpath for managed networks (lower latency)
  preferred_app_group_type = "Desktop"

  tags = var.tags
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "this" {
  hostpool_id = azurerm_virtual_desktop_host_pool.this.id

  # 48-hour window for initial deployment. After the VM registers,
  # this value is irrelevant — ignore_changes prevents token regeneration
  # on every plan.
  expiration_date = timeadd(timestamp(), "48h")

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

resource "azurerm_virtual_desktop_application_group" "this" {
  name                = "vdag-desktop-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.this.id
  friendly_name = "Developer Desktop"

  tags = var.tags
}

resource "azurerm_virtual_desktop_workspace" "this" {
  name                = "vdws-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  friendly_name       = var.workspace_friendly_name

  tags = var.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  workspace_id         = azurerm_virtual_desktop_workspace.this.id
  application_group_id = azurerm_virtual_desktop_application_group.this.id
}