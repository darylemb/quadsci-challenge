###############################################################################
# Container Module
#
# Deploys an Azure Container Instance (ACI) with a private IP only.
# The container group is injected into the VNet via subnet delegation — no
# public IP is assigned and no dns_name_label is set (not supported on private).
#
# Access pattern: reached by the dev VM over internal VNet routing.
###############################################################################

resource "azurerm_container_group" "this" {
  name                = "cg-helloworld-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Private IP only — injected into the VNet via subnet delegation
  ip_address_type = "Private"
  subnet_ids      = [var.subnet_id]

  os_type = "Linux"

  # Restart policy: always restart on failure
  restart_policy = "Always"

  container {
    name   = "helloworld"
    image  = var.container_image
    cpu    = var.cpu
    memory = var.memory_gb

    ports {
      port     = var.container_port
      protocol = "TCP"
    }
  }

  tags = var.tags
}
