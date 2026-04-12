###############################################################################
# Dev Environment
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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

provider "azurerm" {
  features {}

  use_oidc        = true
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  client_id       = var.client_id
}

provider "azuread" {
  tenant_id = var.tenant_id
  use_oidc  = true
  client_id = var.client_id
}

resource "azurerm_resource_group" "main" {
  name     = "rg-quadsci-${var.env}"
  location = var.location
  tags     = local.common_tags
}

locals {
  common_tags = {
    environment = var.env
    managed-by  = "terraform"
    project     = "quadsci-challenge"
  }
}

# ── Networking ─────────────────────────────────────────────────────────────────

module "networking" {
  source = "../../modules/networking"

  env                 = var.env
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  vnet_address_space  = var.vnet_address_space
  aci_subnet_cidr     = var.aci_subnet_cidr
  vm_subnet_cidr      = var.vm_subnet_cidr
  tags                = local.common_tags
}

# ── Container Workload ─────────────────────────────────────────────────────────

# Azure requires time for VNet subnet delegation to propagate before ACI can use it.
# Without this delay, ContainerGroupsCreateOrUpdate returns VirtualNetworkNotReady.
resource "time_sleep" "wait_for_vnet_delegation" {
  create_duration = "90s"
  depends_on      = [module.networking]
}

module "container" {
  source = "../../modules/container"

  env                 = var.env
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.aci_subnet_id
  container_image     = var.container_image
  container_port      = var.container_port
  cpu                 = var.container_cpu
  memory_gb           = var.container_memory_gb
  tags                = local.common_tags

  depends_on = [time_sleep.wait_for_vnet_delegation]
}

# ── Azure Virtual Desktop ──────────────────────────────────────────────────────

module "avd" {
  source = "../../modules/avd"

  env                     = var.env
  location                = var.location
  resource_group_name     = azurerm_resource_group.main.name
  workspace_friendly_name = var.avd_workspace_friendly_name
  tags                    = local.common_tags
}

# ── Dev VM (AVD Session Host) ──────────────────────────────────────────────────

# ── AVD Users ─────────────────────────────────────────────────────────────────

module "avd_users" {
  source = "../../modules/avd-users"

  users        = var.avd_users
  app_group_id = module.avd.app_group_id
  vm_id        = module.devbox.vm_id
}

# ── Dev VM (AVD Session Host) ──────────────────────────────────────────────────

module "devbox" {
  source = "../../modules/devbox"

  env                    = var.env
  location               = var.location
  resource_group_name    = azurerm_resource_group.main.name
  subnet_id              = module.networking.vm_subnet_id
  vm_size                = var.vm_size
  admin_username         = var.admin_username
  admin_password         = var.admin_password
  os_disk_size_gb        = var.os_disk_size_gb
  data_disk_size_gb      = var.data_disk_size_gb
  data_disk_storage_type = var.data_disk_storage_type
  host_pool_name         = module.avd.host_pool_name
  registration_token     = module.avd.registration_token
  tags                   = local.common_tags
}