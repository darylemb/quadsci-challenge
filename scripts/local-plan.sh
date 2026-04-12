#!/usr/bin/env bash
# =============================================================================
# local-plan.sh
# Run terraform plan locally using your personal az login credentials.
# No client secrets or OIDC needed — authenticates as the logged-in az user.
#
# Usage:
#   ./scripts/local-plan.sh [env] [extra terraform flags]
#
# Examples:
#   ./scripts/local-plan.sh
#   ./scripts/local-plan.sh dev
#   ./scripts/local-plan.sh dev -target=module.networking
#   ./scripts/local-plan.sh dev -out=tfplan
# =============================================================================
set -euo pipefail

ENV="${1:-dev}"
shift || true  # remaining args are forwarded to terraform plan

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TF_DIR="${REPO_ROOT}/terraform/environments/${ENV}"

# ── Preflight checks ──────────────────────────────────────────────────────────
if ! command -v az &>/dev/null; then
  echo "ERROR: Azure CLI not found. Install it from https://aka.ms/installazurecli" >&2
  exit 1
fi

if ! command -v terraform &>/dev/null; then
  echo "ERROR: terraform not found. Install it from https://developer.hashicorp.com/terraform/downloads" >&2
  exit 1
fi

if [[ ! -d "${TF_DIR}" ]]; then
  echo "ERROR: Environment directory not found: ${TF_DIR}" >&2
  exit 1
fi

# ── Verify az login ───────────────────────────────────────────────────────────
echo "Checking Azure login ..."
az account show &>/dev/null || {
  echo "Not logged in. Running az login ..."
  az login
}

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
ACCOUNT_NAME=$(az account show --query "user.name" -o tsv)

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Local Terraform Plan"
echo "  Environment  : ${ENV}"
echo "  Account      : ${ACCOUNT_NAME}"
echo "  Subscription : ${SUBSCRIPTION_ID}"
echo "  Tenant       : ${TENANT_ID}"
echo "══════════════════════════════════════════════════════"
echo ""

# ── Derive state storage account name (same logic as init-backend.sh) ─────────
if command -v openssl &>/dev/null; then
  HASH=$(echo -n "${SUBSCRIPTION_ID}${ENV}" | openssl dgst -sha256 | awk '{print $2}' | cut -c1-8)
elif command -v sha256sum &>/dev/null; then
  HASH=$(echo -n "${SUBSCRIPTION_ID}${ENV}" | sha256sum | cut -c1-8)
else
  HASH=$(echo -n "${SUBSCRIPTION_ID}${ENV}" | shasum -a 256 | cut -c1-8)
fi
SA_NAME="tfstate${HASH}${ENV}"
SA_NAME="${SA_NAME:0:24}"

# ── Create local.tfvars if it doesn't exist ───────────────────────────────────
LOCAL_TFVARS="${TF_DIR}/local.tfvars"

if [[ ! -f "${LOCAL_TFVARS}" ]]; then
  echo "Creating ${LOCAL_TFVARS} ..."

  # Prompt until the password satisfies all validation rules
  while true; do
    echo ""
    echo "Enter the Windows VM admin_password (12+ chars, upper, lower, digit, symbol):"
    read -r -s ADMIN_PASSWORD
    echo ""

    ERRORS=""
    [[ ${#ADMIN_PASSWORD} -lt 12 ]]            && ERRORS+="  • Must be at least 12 characters\n"
    [[ ! "${ADMIN_PASSWORD}" =~ [A-Z] ]]       && ERRORS+="  • Must contain at least one uppercase letter\n"
    [[ ! "${ADMIN_PASSWORD}" =~ [a-z] ]]       && ERRORS+="  • Must contain at least one lowercase letter\n"
    [[ ! "${ADMIN_PASSWORD}" =~ [0-9] ]]       && ERRORS+="  • Must contain at least one digit\n"
    [[ ! "${ADMIN_PASSWORD}" =~ [^a-zA-Z0-9] ]] && ERRORS+="  • Must contain at least one special character\n"

    if [[ -z "${ERRORS}" ]]; then
      break
    fi
    printf "Password does not meet requirements:\n${ERRORS}" >&2
  done

  cat > "${LOCAL_TFVARS}" <<EOF
# Local development overrides — never commit this file (.gitignore: *.tfvars)
tenant_id       = "${TENANT_ID}"
subscription_id = "${SUBSCRIPTION_ID}"
client_id       = "local-az-login"
admin_password  = "${ADMIN_PASSWORD}"
EOF
  echo "Created ${LOCAL_TFVARS}"
else
  echo "Using existing ${LOCAL_TFVARS}"
fi

# ── Unset OIDC/SP env vars that would conflict with az login auth ─────────────
unset ARM_USE_OIDC ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_CLIENT_CERTIFICATE_PATH 2>/dev/null || true
export ARM_SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"
export ARM_TENANT_ID="${TENANT_ID}"

# ── Terraform init ────────────────────────────────────────────────────────────
echo ""
echo "Running terraform init ..."
cd "${TF_DIR}"

# Only pass azurerm backend-config args when the backend is actually azurerm.
# Use grep -v to exclude comment lines before checking.
if grep -v '^\s*#' "${TF_DIR}/backend.tf" 2>/dev/null | grep -q 'backend "azurerm"'; then
  terraform init -input=false \
    -backend-config="storage_account_name=${SA_NAME}" \
    -reconfigure
else
  terraform init -input=false -reconfigure
fi

# ── Terraform plan ────────────────────────────────────────────────────────────
echo ""
echo "Running terraform plan ..."
terraform plan \
  -input=false \
  -var-file="local.tfvars" \
  "$@"
