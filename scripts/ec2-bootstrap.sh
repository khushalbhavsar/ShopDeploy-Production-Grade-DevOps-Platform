#!/bin/bash
#==============================================================================
# ShopDeploy - EC2 Bootstrap Script
# Installs ALL required dependencies on a fresh EC2 instance
# Run as: sudo bash ec2-bootstrap.sh
#==============================================================================

set -e

echo "=============================================="
echo "  ShopDeploy EC2 Bootstrap Script"
echo "  Installing all DevOps dependencies..."
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

#------------------------------------------------------------------------------
# System Update
#------------------------------------------------------------------------------
log_info "Updating system packages..."
sudo yum update -y || sudo apt-get update -y

#------------------------------------------------------------------------------
# Install Basic Utilities
#------------------------------------------------------------------------------
log_info "Installing basic utilities..."
sudo yum install -y git curl wget unzip jq tree htop vim \
    || sudo apt-get install -y git curl wget unzip jq tree htop vim

#------------------------------------------------------------------------------
# Install Docker
#------------------------------------------------------------------------------
log_info "Installing Docker..."
./install-docker.sh

#------------------------------------------------------------------------------
# Install Jenkins
#------------------------------------------------------------------------------
log_info "Installing Jenkins..."
./install-jenkins.sh

#------------------------------------------------------------------------------
# Install Terraform
#------------------------------------------------------------------------------
log_info "Installing Terraform..."
./install-terraform.sh

#------------------------------------------------------------------------------
# Install kubectl
#------------------------------------------------------------------------------
log_info "Installing kubectl..."
./install-kubectl.sh

#------------------------------------------------------------------------------
# Install Helm
#------------------------------------------------------------------------------
log_info "Installing Helm..."
./install-helm.sh

#------------------------------------------------------------------------------
# Install AWS CLI
#------------------------------------------------------------------------------
log_info "Installing AWS CLI..."
./install-awscli.sh

#------------------------------------------------------------------------------
# Install Node.js (for build tools)
#------------------------------------------------------------------------------
log_info "Installing Node.js..."
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash - \
    || curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo yum install -y nodejs || sudo apt-get install -y nodejs

#------------------------------------------------------------------------------
# Configure Jenkins User
#------------------------------------------------------------------------------
log_info "Configuring Jenkins user permissions..."
sudo usermod -aG docker jenkins 2>/dev/null || true

#------------------------------------------------------------------------------
# Start Services
#------------------------------------------------------------------------------
log_info "Starting services..."
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl enable jenkins
sudo systemctl start jenkins

#------------------------------------------------------------------------------
# Verify Installations
#------------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Installation Verification"
echo "=============================================="

echo -n "Docker: " && docker --version
echo -n "Docker Compose: " && docker-compose --version 2>/dev/null || echo "Not installed"
echo -n "Jenkins: " && java -version 2>&1 | head -1
echo -n "Terraform: " && terraform --version | head -1
echo -n "kubectl: " && kubectl version --client --short 2>/dev/null || kubectl version --client
echo -n "Helm: " && helm version --short
echo -n "AWS CLI: " && aws --version
echo -n "Node.js: " && node --version
echo -n "npm: " && npm --version

echo ""
echo "=============================================="
echo "  Bootstrap Complete!"
echo "=============================================="

# Get Jenkins initial password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo ""
    log_info "Jenkins Initial Admin Password:"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    echo ""
fi

# Get instance public IP for Jenkins access
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")
log_info "Jenkins URL: http://${INSTANCE_IP}:8080"

echo ""
log_info "Next Steps:"
echo "  1. Access Jenkins at http://<instance-ip>:8080"
echo "  2. Configure AWS credentials in Jenkins"
echo "  3. Set up GitHub webhooks"
echo "  4. Configure pipeline credentials"
