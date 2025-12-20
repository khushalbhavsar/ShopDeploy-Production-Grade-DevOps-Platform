#!/bin/bash
#==============================================================================
# ShopDeploy - kubectl Installation Script
# Installs Kubernetes CLI
#==============================================================================

set -e

KUBECTL_VERSION="${1:-1.28.0}"

echo "Installing kubectl..."

# Download kubectl
curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

# Verify checksum (optional but recommended)
curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check || true

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Cleanup
rm kubectl kubectl.sha256 2>/dev/null || true

# Enable kubectl autocompletion
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc

# Verify installation
kubectl version --client

echo "kubectl installed successfully!"
