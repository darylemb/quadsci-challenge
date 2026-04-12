###############################################################################
# Bootstrap — Service Principal Setup
#
# One-time root module that creates an Azure AD App Registration, Service
# Principal, and RBAC roles. Run this locally with az login; the resulting
# client_id is what you use locally.
#
###############################################################################

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
  }

  # No backend block → state stored locally in terraform.tfstate
  # This is intentional: bootstrap is a one-time setup, not environment state.
}

# CLI auth — no use_oidc, no client_id, just az login
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# ── App Registration ───────────────────────────────────────────────────────────

resource "azuread_application" "github_actions" {
  display_name = var.app_name
}

# ── Service Principal ──────────────────────────────────────────────────────────

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

# ── RBAC: Contributor on subscription ─────────────────────────────────────────

resource "azurerm_role_assignment" "contributor" {
  principal_id         = azuread_service_principal.github_actions.object_id
  role_definition_name = "Contributor"
  scope                = "/subscriptions/${var.subscription_id}"
}

# ── RBAC: Storage Blob Data Contributor on tfstate SA (optional) ───────────────

resource "azurerm_role_assignment" "tfstate_blob" {
  count = var.tfstate_storage_account_id != "" ? 1 : 0

  principal_id         = azuread_service_principal.github_actions.object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = var.tfstate_storage_account_id
}
