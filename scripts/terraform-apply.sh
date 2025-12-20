#!/bin/bash
#==============================================================================
# ShopDeploy - Terraform Apply Script
# Plans and applies Terraform infrastructure changes
# Usage: ./terraform-apply.sh [environment] [--auto-approve]
#==============================================================================

set -e

ENVIRONMENT=${1:-prod}
AUTO_APPROVE=${2:-""}
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[TERRAFORM]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "=============================================="
echo "  Terraform Apply"
echo "  Environment: ${ENVIRONMENT}"
echo "=============================================="

cd ${TERRAFORM_DIR}

#------------------------------------------------------------------------------
# Select Workspace
#------------------------------------------------------------------------------
log_info "Selecting workspace: ${ENVIRONMENT}"
terraform workspace select ${ENVIRONMENT} 2>/dev/null || terraform workspace new ${ENVIRONMENT}

#------------------------------------------------------------------------------
# Plan Changes
#------------------------------------------------------------------------------
log_info "Planning infrastructure changes..."

# Use environment-specific tfvars if exists
TFVARS_FILE=""
if [ -f "environments/${ENVIRONMENT}.tfvars" ]; then
    TFVARS_FILE="-var-file=environments/${ENVIRONMENT}.tfvars"
fi

terraform plan \
    ${TFVARS_FILE} \
    -var="environment=${ENVIRONMENT}" \
    -out=tfplan

#------------------------------------------------------------------------------
# Apply Changes
#------------------------------------------------------------------------------
if [ "${AUTO_APPROVE}" == "--auto-approve" ]; then
    log_info "Auto-approving and applying changes..."
    terraform apply tfplan
else
    log_warn "Review the plan above carefully."
    read -p "Do you want to apply these changes? (yes/no): " confirm
    
    if [ "${confirm}" == "yes" ]; then
        log_info "Applying infrastructure changes..."
        terraform apply tfplan
    else
        log_warn "Apply cancelled"
        rm tfplan
        exit 0
    fi
fi

# Cleanup plan file
rm tfplan 2>/dev/null || true

#------------------------------------------------------------------------------
# Output Important Values
#------------------------------------------------------------------------------
echo ""
log_info "Infrastructure created/updated successfully!"
echo ""
log_info "Important outputs:"
terraform output -json | jq '.'

#------------------------------------------------------------------------------
# Configure kubectl
#------------------------------------------------------------------------------
echo ""
log_info "To configure kubectl for the EKS cluster, run:"
terraform output -raw configure_kubectl
echo ""
