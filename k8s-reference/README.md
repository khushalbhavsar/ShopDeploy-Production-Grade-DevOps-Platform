# ☸️ ShopDeploy Kubernetes Reference Manifests

> ## ⚠️ IMPORTANT: REFERENCE ONLY
> 
> **These manifests are for REFERENCE ONLY. Do NOT use for production deployments.**
> 
> The primary deployment method is **Helm Charts** located in `/helm/`.
> 
> ### Why Keep These?
> | Purpose | Use Case |
> |---------|----------|
> | 📖 Learning | Understand raw Kubernetes concepts |
> | 🔧 Debugging | Quick manual deployments for troubleshooting |
> | 📋 Reference | See what Helm templates generate |
> | 🎓 Training | Onboarding new team members |
> 
> ### ✅ Use Helm Instead
> ```bash
> helm upgrade --install shopdeploy-backend ./helm/backend -n shopdeploy
> helm upgrade --install shopdeploy-frontend ./helm/frontend -n shopdeploy
> ```

---

<p align="center">
  <img src="https://img.shields.io/badge/Kubernetes-1.29-326CE5?style=for-the-badge&logo=kubernetes" alt="Kubernetes"/>
  <img src="https://img.shields.io/badge/AWS_EKS-Managed-FF9900?style=for-the-badge&logo=amazon-aws" alt="EKS"/>
  <img src="https://img.shields.io/badge/Kustomize-Ready-326CE5?style=for-the-badge" alt="Kustomize"/>
</p>

This directory contains Kubernetes manifests for deploying the ShopDeploy application to any Kubernetes cluster (EKS, GKE, AKS, minikube, etc.).

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Directory Structure](#-directory-structure)
- [Configuration](#-configuration)
- [Deployment Methods](#-deployment-methods)
- [Useful Commands](#-useful-commands)
- [Scaling](#-scaling)
- [Local Development](#-local-development)
- [Production Considerations](#-production-considerations)
- [Troubleshooting](#-troubleshooting)

---

## 📋 Prerequisites

- **Kubernetes cluster** (minikube, Docker Desktop, EKS, GKE, AKS)
- **kubectl** configured to connect to your cluster
- **Docker images** built and pushed to a registry

```bash
# Verify kubectl connection
kubectl cluster-info
kubectl get nodes
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    shopdeploy namespace                         │   │
│   │                                                                 │   │
│   │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │   │
│   │   │   Ingress   │───▶│  Frontend   │    │   Backend   │        │   │
│   │   │  (ALB/Nginx)│    │   Service   │    │   Service   │        │   │
│   │   └─────────────┘    └──────┬──────┘    └──────┬──────┘        │   │
│   │                             │                  │               │   │
│   │                      ┌──────┴──────┐    ┌──────┴──────┐        │   │
│   │                      │  Frontend   │    │   Backend   │        │   │
│   │                      │ Deployment  │    │ Deployment  │        │   │
│   │                      │ (3 replicas)│    │ (3 replicas)│        │   │
│   │                      └─────────────┘    └──────┬──────┘        │   │
│   │                                                │               │   │
│   │                                         ┌──────┴──────┐        │   │
│   │                                         │   MongoDB   │        │   │
│   │                                         │ StatefulSet │        │   │
│   │                                         └─────────────┘        │   │
│   │                                                                 │   │
│   │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐        │   │
│   │   │  ConfigMap  │    │   Secrets   │    │     HPA     │        │   │
│   │   │  (Backend)  │    │ (Credentials)│   │ (Auto-scale)│        │   │
│   │   └─────────────┘    └─────────────┘    └─────────────┘        │   │
│   │                                                                 │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Step 1: Build and Push Docker Images

```bash
# Build images
docker build -t shopdeploy-backend:latest ./shopdeploy-backend
docker build -t shopdeploy-frontend:latest ./shopdeploy-frontend

# Tag for ECR (or your registry)
docker tag shopdeploy-backend:latest <ECR_URL>/shopdeploy-backend:latest
docker tag shopdeploy-frontend:latest <ECR_URL>/shopdeploy-frontend:latest

# Push to registry
docker push <ECR_URL>/shopdeploy-backend:latest
docker push <ECR_URL>/shopdeploy-frontend:latest
```

### Step 2: Update Image References

Update the image names in deployment files:
- [backend-deployment.yaml](backend-deployment.yaml)
- [frontend-deployment.yaml](frontend-deployment.yaml)

### Step 3: Configure Secrets

Edit `backend-secret.yaml` with your actual values:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: shopdeploy
type: Opaque
stringData:
  MONGODB_URI: "mongodb://mongo-service:27017/shopdeploy"
  JWT_ACCESS_SECRET: "your-super-secure-access-secret-min-32-chars"
  JWT_REFRESH_SECRET: "your-super-secure-refresh-secret-min-32-chars"
```

**⚠️ For production**, create secrets using kubectl (don't commit to Git):

```bash
kubectl create secret generic backend-secrets \
  --namespace=shopdeploy \
  --from-literal=MONGODB_URI='mongodb://...' \
  --from-literal=JWT_ACCESS_SECRET='your-secret' \
  --from-literal=JWT_REFRESH_SECRET='your-secret'
```

### Step 4: Deploy to Kubernetes

**Using Kustomize (Recommended):**

```bash
# Preview what will be deployed
kubectl kustomize k8s/

# Apply all resources
kubectl apply -k k8s/
```

**Or apply individually:**

```bash
# Create namespace first
kubectl apply -f k8s/namespace.yaml

# Apply all resources
kubectl apply -f k8s/
```

### Step 5: Verify Deployment

```bash
# Check all resources
kubectl get all -n shopdeploy

# Check pods are running
kubectl get pods -n shopdeploy

# Check services
kubectl get svc -n shopdeploy

# Verify health endpoints (port-forward to test)
kubectl port-forward svc/shopdeploy-backend 5000:5000 -n shopdeploy
# Then in another terminal:
curl http://localhost:5000/api/health/health
# Expected: { "status": "OK", "timestamp": "...", "uptime": ..., "environment": "..." }

curl http://localhost:5000/api/health/ready
# Expected: { "status": "ready", "timestamp": "..." }
```

### Health Probes Configuration

The backend deployment uses the following Kubernetes probes:

| Probe Type | Endpoint | Purpose |
|------------|----------|----------|
| **Liveness** | `/api/health/health` | Restarts pod if unhealthy |
| **Readiness** | `/api/health/ready` | Removes from service if not ready |

---

## 📁 Directory Structure

```
k8s/
├── namespace.yaml              # Kubernetes namespace (shopdeploy)
├── backend-configmap.yaml      # Backend environment configuration
├── backend-secret.yaml         # Backend sensitive data (⚠️ edit before use!)
├── backend-deployment.yaml     # Backend deployment (3 replicas)
├── backend-service.yaml        # Backend LoadBalancer service (port 5000)
├── frontend-configmap.yaml     # Frontend configuration
├── frontend-deployment.yaml    # Frontend deployment (3 replicas, nginx-unprivileged)
├── frontend-service.yaml       # Frontend LoadBalancer service (port 80 → 8080)
├── mongodb-statefulset.yaml    # MongoDB StatefulSet (development)
├── mongodb-statefulset-prod.yaml # MongoDB StatefulSet (production)
├── ingress.yaml                # Ingress configuration (ALB/Nginx)
├── hpa.yaml                    # Horizontal Pod Autoscaler
├── pdb.yaml                    # Pod Disruption Budget
├── network-policy.yaml         # Network security policies
├── resource-quota.yaml         # Namespace resource quotas
├── kustomization.yaml          # Kustomize configuration
└── README.md                   # This file
```

### Service Configuration

| Component | Service Type | External Port | Container Port | Notes |
|-----------|--------------|---------------|----------------|-------|
| **Backend** | LoadBalancer | 5000 | 5000 | REST API |
| **Frontend** | LoadBalancer | 80 | 8080 | nginx-unprivileged |
| **MongoDB** | ClusterIP | 27017 | 27017 | Internal only |

---

## ⚙️ Configuration

### ConfigMaps

| ConfigMap | Purpose |
|-----------|---------|
| `backend-config` | Backend environment variables (non-sensitive) |
| `frontend-config` | Frontend Nginx configuration |

### Secrets

| Secret | Contains |
|--------|----------|
| `backend-secrets` | MongoDB URI, JWT secrets, Stripe keys |

### Resource Limits

Default resource configuration:

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Backend | 100m | 500m | 128Mi | 512Mi |
| Frontend | 50m | 200m | 64Mi | 256Mi |
| MongoDB | 200m | 1000m | 256Mi | 1Gi |

---

## 🔄 Deployment Methods

### Method 1: Kustomize (Recommended)

```bash
# Development
kubectl apply -k k8s/overlays/dev

# Staging
kubectl apply -k k8s/overlays/staging

# Production
kubectl apply -k k8s/overlays/prod
```

### Method 2: Plain kubectl

```bash
kubectl apply -f k8s/
```

### Method 3: Helm Charts

See [helm/](../helm/) directory for Helm-based deployments.

---

## 🛠️ Useful Commands

### View Resources

```bash
# Check deployment status
kubectl get all -n shopdeploy

# View pods (watch mode)
kubectl get pods -n shopdeploy -w

# View logs
kubectl logs -f deployment/backend -n shopdeploy
kubectl logs -f deployment/frontend -n shopdeploy
```

### Debugging

```bash
# Describe resources (shows events, errors)
kubectl describe deployment backend -n shopdeploy
kubectl describe pod <pod-name> -n shopdeploy

# Port forward for local testing
kubectl port-forward svc/backend-service 5000:5000 -n shopdeploy
kubectl port-forward svc/frontend-service 3000:80 -n shopdeploy

# Execute commands in pod
kubectl exec -it deployment/backend -n shopdeploy -- /bin/sh
```

### Scaling & Updates

```bash
# Manual scaling
kubectl scale deployment backend --replicas=5 -n shopdeploy

# Check HPA status
kubectl get hpa -n shopdeploy

# Update image
kubectl set image deployment/backend backend=<ECR_URL>/shopdeploy-backend:v2 -n shopdeploy

# Check rollout status
kubectl rollout status deployment/backend -n shopdeploy

# Rollback
kubectl rollout undo deployment/backend -n shopdeploy
```

### Cleanup

```bash
# Delete all resources
kubectl delete -k k8s/

# Or delete namespace
kubectl delete namespace shopdeploy
```

---

## 💻 Local Development with Minikube

```bash
# Start minikube
minikube start

# Enable ingress addon
minikube addons enable ingress

# Use minikube's Docker daemon (to use local images)
eval $(minikube docker-env)

# Build images in minikube's Docker
docker build -t shopdeploy-backend:latest ./shopdeploy-backend
docker build -t shopdeploy-frontend:latest ./shopdeploy-frontend

# Deploy
kubectl apply -k k8s/

# Get minikube IP
minikube ip

# Add to /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
# <minikube-ip> shopdeploy.local

# Access the application
# http://shopdeploy.local
```

---

## 🏭 Production Considerations

| Consideration | Recommendation |
|---------------|----------------|
| **Secrets Management** | Use AWS Secrets Manager or HashiCorp Vault |
| **TLS/SSL** | Enable TLS in ingress with cert-manager |
| **Resource Limits** | Adjust CPU/memory based on actual usage |
| **MongoDB** | Use managed MongoDB (Atlas) instead of in-cluster |
| **Monitoring** | Add Prometheus/Grafana for monitoring |
| **Logging** | Configure centralized logging (ELK, Loki) |
| **Backup** | Set up regular MongoDB backups |
| **Network Policies** | Implement network policies for pod isolation |

---

## 🔧 Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n shopdeploy

# Check logs
kubectl logs <pod-name> -n shopdeploy

# Check previous container logs (if restarting)
kubectl logs <pod-name> -n shopdeploy --previous
```

### MongoDB Connection Issues

```bash
# Check MongoDB pod
kubectl logs statefulset/mongodb -n shopdeploy

# Test connection from backend pod
kubectl exec -it deployment/backend -n shopdeploy -- sh
# Inside pod: nc -zv mongo-service 27017
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress status
kubectl describe ingress shopdeploy-ingress -n shopdeploy

# Check ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Image Pull Errors

```bash
# Check if secret exists for private registry
kubectl get secrets -n shopdeploy

# Create ECR pull secret (if using ECR)
kubectl create secret docker-registry ecr-secret \
  --docker-server=<ECR_URL> \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password) \
  -n shopdeploy
```

---

<p align="center">
  <b>Part of the ShopDeploy E-Commerce Platform</b><br>
  See <a href="../terraform/README.md">Terraform README</a> for infrastructure setup
</p>
