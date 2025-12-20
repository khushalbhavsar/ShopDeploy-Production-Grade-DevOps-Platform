#!/bin/bash
#==============================================================================
# ShopDeploy - Terraform Init Script
# Initializes Terraform with S3 backend
# Usage: ./terraform-init.sh [environment]
#==============================================================================

set -e

ENVIRONMENT=${1:-prod}
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[TERRAFORM]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "=============================================="
echo "  Terraform Initialization"
echo "  Environment: ${ENVIRONMENT}"
echo "=============================================="

cd ${TERRAFORM_DIR}

#------------------------------------------------------------------------------
# Create S3 Backend Bucket (if not exists)
#------------------------------------------------------------------------------
log_info "Checking S3 backend bucket..."

BUCKET_NAME="shopdeploy-terraform-state"
REGION="us-east-1"

# Check if bucket exists
if ! aws s3api head-bucket --bucket ${BUCKET_NAME} 2>/dev/null; then
    log_info "Creating S3 bucket for Terraform state..."
    aws s3api create-bucket \
        --bucket ${BUCKET_NAME} \
        --region ${REGION}
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket ${BUCKET_NAME} \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket ${BUCKET_NAME} \
        --server-side-encryption-configuration \
        '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'
    
    log_info "S3 bucket created: ${BUCKET_NAME}"
fi

#------------------------------------------------------------------------------
# Create DynamoDB Table for State Locking
#------------------------------------------------------------------------------
log_info "Checking DynamoDB lock table..."

TABLE_NAME="shopdeploy-terraform-locks"

if ! aws dynamodb describe-table --table-name ${TABLE_NAME} 2>/dev/null; then
    log_info "Creating DynamoDB table for state locking..."
    aws dynamodb create-table \
        --table-name ${TABLE_NAME} \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region ${REGION}
    
    log_info "DynamoDB table created: ${TABLE_NAME}"
    
    # Wait for table to be active
    aws dynamodb wait table-exists --table-name ${TABLE_NAME}
fi

#------------------------------------------------------------------------------
# Initialize Terraform
#------------------------------------------------------------------------------
log_info "Initializing Terraform..."

terraform init \
    -backend-config="bucket=${BUCKET_NAME}" \
    -backend-config="key=infrastructure/${ENVIRONMENT}/terraform.tfstate" \
    -backend-config="region=${REGION}" \
    -backend-config="dynamodb_table=${TABLE_NAME}" \
    -backend-config="encrypt=true" \
    -reconfigure

#------------------------------------------------------------------------------
# Validate Configuration
#------------------------------------------------------------------------------
log_info "Validating Terraform configuration..."
terraform validate

#------------------------------------------------------------------------------
# Select Workspace
#------------------------------------------------------------------------------
log_info "Selecting workspace: ${ENVIRONMENT}"
terraform workspace select ${ENVIRONMENT} 2>/dev/null || terraform workspace new ${ENVIRONMENT}

echo ""
log_info "Terraform initialized successfully!"
echo ""
echo "Next steps:"
echo "  1. Review terraform.tfvars.example"
echo "  2. Create terraform.tfvars with your values"
echo "  3. Run: terraform plan"
echo "  4. Run: terraform apply"
