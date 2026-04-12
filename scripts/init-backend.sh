#!/usr/bin/env bash
# =============================================================================
# init-backend.sh
# Bootstrap the Terraform remote state backend for a given environment.
#
# Usage:
#   ./scripts/init-backend.sh <env> <location>
#
# Example:
#   ./scripts/init-backend.sh dev eastus
#   ./scripts/init-backend.sh prod westeurope
#
# What this script does:
#   1. Creates a dedicated resource group for Terraform state (not the app RG)
#   2. Creates an Azure Storage Account with secure defaults:
#        - HTTPS-only traffic
#        - Minimum TLS 1.2
#        - Public blob access disabled
#        - Soft-delete for blobs (7-day retention)
#   3. Creates a blob container named "tfstate"
#   4. Grants the current caller Storage Blob Data Contributor on the container
#   5. Prints the backend configuration values to use in backend.tf
#
# Requirements:
#   - Azure CLI (az) ≥ 2.55 installed and in PATH
#   - Logged in via: az login  (or az login --use-device-code)
#   - Target subscription set: az account set --subscription "<id>"
# =============================================================================
set -euo pipefail

# ── Arguments ────────────────────────────────────────────────────────────────
ENV="${1:-}"
LOCATION="${2:-eastus}"

if [[ -z "${ENV}" ]]; then
  echo "ERROR: environment name is required." >&2
  echo "Usage: $0 <env> [location]" >&2
  exit 1
fi

# ── Derived names ─────────────────────────────────────────────────────────────
# Storage account names must be 3-24 lowercase alphanumeric characters.
# We use a short hash of the subscription+env to stay unique while deterministic.
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Cross-platform SHA256: prefer openssl (available on macOS and most Linux CI),
# fall back to sha256sum (Linux), then shasum -a 256 (macOS fallback).
if command -v openssl &>/dev/null; then
  HASH=$(echo -n "${SUBSCRIPTION_ID}${ENV}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-8)
elif command -v sha256sum &>/dev/null; then
  HASH=$(echo -n "${SUBSCRIPTION_ID}${ENV}" | sha256sum | cut -c1-8)
else
  HASH=$(echo -n "${SUBSCRIPTION_ID}${ENV}" | shasum -a 256 | cut -c1-8)
fi

RG_NAME="rg-tfstate-${ENV}"
SA_NAME="tfstate${HASH}${ENV}"
# Trim to 24 chars maximum to satisfy Storage Account naming limits
SA_NAME="${SA_NAME:0:24}"
CONTAINER_NAME="tfstate"

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Terraform Backend Bootstrap"
echo "  Environment : ${ENV}"
echo "  Location    : ${LOCATION}"
echo "  Subscription: ${SUBSCRIPTION_ID}"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Resource Group ────────────────────────────────────────────────────────────
echo "Creating resource group: ${RG_NAME} ..."
az group create \
  --name "${RG_NAME}" \
  --location "${LOCATION}" \
  --tags "managed-by=terraform-bootstrap" "environment=${ENV}" \
  --output none

echo "Resource group ready."

# ── Storage Account ───────────────────────────────────────────────────────────
echo "Creating storage account: ${SA_NAME} ..."
az storage account create \
  --name "${SA_NAME}" \
  --resource-group "${RG_NAME}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags "managed-by=terraform-bootstrap" "environment=${ENV}" \
  --output none

echo "Storage account ready."

# ── Blob Container ────────────────────────────────────────────────────────────
echo "Creating blob container: ${CONTAINER_NAME} ..."
az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${SA_NAME}" \
  --auth-mode login \
  --output none

echo "Blob container ready."

# ── Soft Delete ───────────────────────────────────────────────────────────────
echo "Enabling blob soft-delete (7-day retention) ..."
az storage account blob-service-properties update \
  --account-name "${SA_NAME}" \
  --resource-group "${RG_NAME}" \
  --enable-delete-retention true \
  --delete-retention-days 7 \
  --output none

echo "Soft-delete enabled."

# ── RBAC: grant current caller Storage Blob Data Contributor ─────────────────
CALLER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || \
            az account show --query user.name -o tsv)

if [[ -n "${CALLER_ID}" ]]; then
  SA_SCOPE=$(az storage account show \
    --name "${SA_NAME}" \
    --resource-group "${RG_NAME}" \
    --query id -o tsv)

  echo "Granting Storage Blob Data Contributor to caller ..."
  # Use --assignee-object-id when available (avoids AAD graph lookup ambiguity).
  # Fall back to --assignee for interactive logins where object ID is unavailable.
  CALLER_OID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)
  if [[ -n "${CALLER_OID}" ]]; then
    az role assignment create \
      --assignee-object-id "${CALLER_OID}" \
      --assignee-principal-type User \
      --role "Storage Blob Data Contributor" \
      --scope "${SA_SCOPE}" \
      --output none 2>/dev/null || echo "Role assignment already exists or caller lacks permission — skipping."
  else
    az role assignment create \
      --assignee "${CALLER_ID}" \
      --role "Storage Blob Data Contributor" \
      --scope "${SA_SCOPE}" \
      --output none 2>/dev/null || echo "Role assignment already exists or caller lacks permission — skipping."
  fi

  echo "RBAC assignment done."
fi

# ── Output ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Backend bootstrap complete!"
echo "══════════════════════════════════════════════════════"
echo ""
echo "Add the following to terraform/environments/${ENV}/backend.tf:"
echo ""
echo '  terraform {'
echo '    backend "azurerm" {'
echo "      resource_group_name  = \"${RG_NAME}\""
echo "      storage_account_name = \"${SA_NAME}\""
echo "      container_name       = \"${CONTAINER_NAME}\""
echo "      key                  = \"${ENV}.tfstate\""
echo "      use_oidc             = true"
echo '    }'
echo '  }'
echo ""
