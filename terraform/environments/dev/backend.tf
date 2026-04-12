###############################################################################
# Dev Environment — Backend Configuration
#
# Using local backend for local development/testing.
# To switch to Azure remote state, run:
#   ./scripts/init-backend.sh dev eastus
# and replace the block below with:
#
#   backend "azurerm" {
#     resource_group_name  = "rg-tfstate-dev"
#     storage_account_name = "tfstate95746ea7dev"
#     container_name       = "tfstate"
#     key                  = "dev.tfstate"
#     use_oidc             = true
#   }
###############################################################################

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
