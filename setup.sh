#!/usr/bin/env bash
# =============================================================================
# setup.sh
# Run this script to set up your local environment for development and testing.

./scripts/local-plan.sh
terraform -chdir=terraform/environments/dev apply -var-file=local.tfvars -auto-approve