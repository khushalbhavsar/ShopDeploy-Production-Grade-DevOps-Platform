#!/bin/bash
#==============================================================================
# ShopDeploy - Monitoring Stack Installation Script
# Installs Prometheus, Grafana, and configures CloudWatch integration
# Usage: ./install-monitoring.sh [namespace]
#==============================================================================

set -e

NAMESPACE=${1:-monitoring}
PROJECT_ROOT=$(cd "$(dirname "$0")/.." && pwd)

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[MONITORING]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "=============================================="
echo "  ShopDeploy Monitoring Stack Installation"
echo "  Namespace: ${NAMESPACE}"
echo "=============================================="

#------------------------------------------------------------------------------
# Add Helm Repositories
#------------------------------------------------------------------------------
log_info "Adding Helm repositories..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

#------------------------------------------------------------------------------
# Create Namespace
#------------------------------------------------------------------------------
log_info "Creating monitoring namespace..."

kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

#------------------------------------------------------------------------------
# Install Prometheus
#------------------------------------------------------------------------------
log_info "Installing Prometheus..."

helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace ${NAMESPACE} \
    --values "${PROJECT_ROOT}/monitoring/prometheus-values.yaml" \
    --wait \
    --timeout 10m

#------------------------------------------------------------------------------
# Install Grafana
#------------------------------------------------------------------------------
log_info "Installing Grafana..."

# Generate random admin password if not set
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD:-$(openssl rand -base64 12)}

helm upgrade --install grafana grafana/grafana \
    --namespace ${NAMESPACE} \
    --values "${PROJECT_ROOT}/monitoring/grafana-values.yaml" \
    --set adminPassword="${GRAFANA_ADMIN_PASSWORD}" \
    --wait \
    --timeout 10m

#------------------------------------------------------------------------------
# Install ShopDeploy Dashboard
#------------------------------------------------------------------------------
log_info "Installing ShopDeploy Grafana dashboard..."

kubectl create configmap shopdeploy-dashboard \
    --from-file="${PROJECT_ROOT}/monitoring/dashboards/shopdeploy-dashboard.json" \
    --namespace ${NAMESPACE} \
    --dry-run=client -o yaml | kubectl apply -f -

kubectl label configmap shopdeploy-dashboard grafana_dashboard=1 -n ${NAMESPACE} --overwrite

#------------------------------------------------------------------------------
# Install Metrics Server (if not installed)
#------------------------------------------------------------------------------
log_info "Checking Metrics Server..."

if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
    log_info "Installing Metrics Server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
fi

#------------------------------------------------------------------------------
# Output Access Information
#------------------------------------------------------------------------------
echo ""
echo "=============================================="
echo "  Monitoring Stack Installed!"
echo "=============================================="
echo ""

# Get Grafana URL
GRAFANA_URL=$(kubectl get svc grafana -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [ -z "${GRAFANA_URL}" ]; then
    GRAFANA_URL="Use port-forward: kubectl port-forward svc/grafana 3000:80 -n ${NAMESPACE}"
fi

log_info "Grafana URL: ${GRAFANA_URL}"
log_info "Grafana Admin User: admin"
log_info "Grafana Admin Password: ${GRAFANA_ADMIN_PASSWORD}"
echo ""

# Get Prometheus URL
log_info "Prometheus URL: kubectl port-forward svc/prometheus-server 9090:80 -n ${NAMESPACE}"
echo ""

log_info "Save the Grafana password securely!"
echo ""
log_info "Next steps:"
echo "  1. Access Grafana and verify dashboards"
echo "  2. Configure Slack webhook for alerts"
echo "  3. Set up CloudWatch log groups"
