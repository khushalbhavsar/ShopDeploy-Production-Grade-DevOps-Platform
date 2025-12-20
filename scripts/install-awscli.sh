#!/bin/bash
#==============================================================================
# ShopDeploy - AWS CLI Installation Script
# Installs AWS CLI v2
#==============================================================================

set -e

echo "Installing AWS CLI v2..."

# Remove old version if exists
sudo rm -rf /usr/local/aws-cli 2>/dev/null || true
sudo rm /usr/local/bin/aws 2>/dev/null || true

# Download and install AWS CLI v2
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
sudo ./aws/install --update

# Cleanup
rm -rf aws awscliv2.zip

# Enable CLI autocompletion
echo 'complete -C "/usr/local/bin/aws_completer" aws' >> ~/.bashrc

# Install eksctl (optional but recommended for EKS)
echo "Installing eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
aws --version
eksctl version 2>/dev/null || true

echo "AWS CLI installed successfully!"
echo ""
echo "Configure AWS credentials using: aws configure"
echo "Or set environment variables:"
echo "  export AWS_ACCESS_KEY_ID=<your-key>"
echo "  export AWS_SECRET_ACCESS_KEY=<your-secret>"
echo "  export AWS_DEFAULT_REGION=us-east-1"
