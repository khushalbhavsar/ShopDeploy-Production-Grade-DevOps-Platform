# 🔄 GitOps Configuration

## Overview

This folder contains environment-specific Helm values for GitOps-based deployments using **ArgoCD** or **Flux**.

---

## Structure

```
gitops/
├── README.md           # This file
├── dev/
│   ├── backend-values.yaml
│   └── frontend-values.yaml
├── staging/
│   ├── backend-values.yaml
│   └── frontend-values.yaml
└── prod/
    ├── backend-values.yaml
    └── frontend-values.yaml
```

---

## GitOps Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GitOps Deployment Flow                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   ┌──────────┐         ┌──────────┐         ┌──────────────────┐           │
│   │   CI     │────────▶│  Update  │────────▶│   Git Repository │           │
│   │ Pipeline │         │  Values  │         │   (gitops/)      │           │
│   └──────────┘         └──────────┘         └────────┬─────────┘           │
│                                                       │                     │
│                                                       ▼                     │
│                                              ┌──────────────────┐           │
│                                              │     ArgoCD /     │           │
│                                              │      Flux        │           │
│                                              └────────┬─────────┘           │
│                                                       │                     │
│                         ┌─────────────────────────────┼──────────────────┐  │
│                         ▼                             ▼                  ▼  │
│                    ┌────────┐                   ┌────────┐         ┌────────┐
│                    │  Dev   │                   │Staging │         │  Prod  │
│                    │Cluster │                   │Cluster │         │Cluster │
│                    └────────┘                   └────────┘         └────────┘
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Usage with ArgoCD

### 1. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Create Application

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: shopdeploy-backend-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/shopdeploy.git
    targetRevision: HEAD
    path: helm/backend
    helm:
      valueFiles:
        - ../../gitops/prod/backend-values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: shopdeploy
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 3. CI Pipeline Updates Values

Instead of deploying directly, CI pipeline updates the values file:

```bash
# In CI pipeline
IMAGE_TAG="42-abc1234"
yq e ".image.tag = \"${IMAGE_TAG}\"" -i gitops/prod/backend-values.yaml
git commit -m "Deploy backend ${IMAGE_TAG} to prod"
git push
```

ArgoCD detects the change and syncs automatically.

---

## Benefits of GitOps

| Feature | Traditional CI/CD | GitOps |
|---------|-------------------|--------|
| Deployment source | CI Pipeline | Git Repository |
| Audit trail | Pipeline logs | Git history |
| Rollback | Re-run pipeline | Git revert |
| Drift detection | Manual | Automatic |
| Disaster recovery | Rebuild | Git clone + sync |

---

## Migration Path

### Current (Jenkins CD)
```
CI → Build → Push → CD → Helm Deploy
```

### Future (GitOps)
```
CI → Build → Push → Update gitops/ → ArgoCD Sync
```

---

## Environment-Specific Values

Each environment folder contains values that override the base Helm chart values:

```yaml
# gitops/prod/backend-values.yaml
image:
  repository: 123456789.dkr.ecr.us-east-1.amazonaws.com/shopdeploy-prod-backend
  tag: "42-abc1234"

replicaCount: 3

service:
  type: LoadBalancer
  port: 5000
  targetPort: 5000

resources:
  limits:
    cpu: 1000m
    memory: 1024Mi
  requests:
    cpu: 500m
    memory: 512Mi
```

### Frontend Configuration Notes

The frontend runs on **nginx-unprivileged** image for enhanced security:
- Container port: **8080** (non-privileged)
- Service external port: **80**
- Service type: **LoadBalancer** (all environments)

```yaml
# gitops/prod/frontend-values.yaml
service:
  type: LoadBalancer
  port: 80
  targetPort: 8080

securityContext:
  runAsUser: 101
  runAsNonRoot: true
```

---

*Last Updated: February 2026*
