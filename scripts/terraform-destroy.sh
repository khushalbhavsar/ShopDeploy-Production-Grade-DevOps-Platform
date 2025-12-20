#!/bin/bash
#==============================================================================
# ShopDeploy - Terraform Destroy Script
# Destroys all Terraform-managed infrastructure
# Usage: ./terraform-destroy.sh [environment]
#==============================================================================

set -e

ENVIRONMENT=${1:-prod}
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[TERRAFORM]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=============================================="
echo "  Terraform Destroy"
echo "  Environment: ${ENVIRONMENT}"
echo "=============================================="

log_warn "⚠️  WARNING: This will DESTROY all infrastructure!"
log_warn "⚠️  This action cannot be undone!"
echo ""

cd ${TERRAFORM_DIR}

#------------------------------------------------------------------------------
# Select Workspace
#------------------------------------------------------------------------------
log_info "Selecting workspace: ${ENVIRONMENT}"
terraform workspace select ${ENVIRONMENT}

#------------------------------------------------------------------------------
# Confirmation
#------------------------------------------------------------------------------
read -p "Type '${ENVIRONMENT}' to confirm destruction: " confirm

if [ "${confirm}" != "${ENVIRONMENT}" ]; then
    log_warn "Destruction cancelled"
    exit 0
fi

#------------------------------------------------------------------------------
# Plan Destruction
#------------------------------------------------------------------------------
log_info "Planning destruction..."

TFVARS_FILE=""
if [ -f "environments/${ENVIRONMENT}.tfvars" ]; then
    TFVARS_FILE="-var-file=environments/${ENVIRONMENT}.tfvars"
fi

terraform plan -destroy \
    ${TFVARS_FILE} \
    -var="environment=${ENVIRONMENT}" \
    -out=tfplan-destroy

#------------------------------------------------------------------------------
# Final Confirmation
#------------------------------------------------------------------------------
log_warn "Review the destruction plan above."
read -p "Are you ABSOLUTELY sure? Type 'DESTROY' to confirm: " final_confirm

if [ "${final_confirm}" != "DESTROY" ]; then
    log_warn "Destruction cancelled"
    rm tfplan-destroy 2>/dev/null || true
    exit 0
fi

#------------------------------------------------------------------------------
# Execute Destruction
#------------------------------------------------------------------------------
log_error "Destroying infrastructure..."
terraform apply tfplan-destroy

# Cleanup
rm tfplan-destroy 2>/dev/null || true

echo ""
log_info "Infrastructure destroyed successfully"
