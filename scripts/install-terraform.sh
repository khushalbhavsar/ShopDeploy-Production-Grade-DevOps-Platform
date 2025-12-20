#!/bin/bash
#==============================================================================
# ShopDeploy - Terraform Installation Script
# Installs HashiCorp Terraform
#==============================================================================

set -e

TERRAFORM_VERSION="${1:-1.6.6}"

echo "Installing Terraform ${TERRAFORM_VERSION}..."

# Install using HashiCorp official method
if [ -f /etc/amazon-linux-release ] || [ -f /etc/system-release ]; then
    # Amazon Linux 2 / RHEL / CentOS
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum install -y terraform
    
elif [ -f /etc/lsb-release ]; then
    # Ubuntu / Debian
    sudo apt-get update
    sudo apt-get install -y gnupg software-properties-common
    
    # Add HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        gpg --dearmor | \
        sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    
    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
        https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list
    
    sudo apt-get update
    sudo apt-get install -y terraform
else
    # Manual installation fallback
    cd /tmp
    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    sudo mv terraform /usr/local/bin/
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
fi

# Verify installation
terraform --version

echo "Terraform installed successfully!"
