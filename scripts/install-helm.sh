#!/bin/bash
#==============================================================================
# ShopDeploy - Helm Installation Script
# Installs Helm (Kubernetes Package Manager)
#==============================================================================

set -e

HELM_VERSION="${1:-3.13.3}"

echo "Installing Helm..."

# Install using official script
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Or manual installation
# cd /tmp
# wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz"
# tar -zxvf "helm-v${HELM_VERSION}-linux-amd64.tar.gz"
# sudo mv linux-amd64/helm /usr/local/bin/helm
# rm -rf linux-amd64 "helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Enable Helm autocompletion
echo 'source <(helm completion bash)' >> ~/.bashrc

# Add common Helm repositories
helm repo add stable https://charts.helm.sh/stable 2>/dev/null || true
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

# Verify installation
helm version

echo "Helm installed successfully!"
