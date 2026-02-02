# 🚀 ShopDeploy DevOps Project - Interview & Viva Questions

<p align="center">
  <b>Comprehensive DevOps Questions & Answers for Interviews, Viva, and Production Discussions</b>
</p>

> **Project:** ShopDeploy - Cloud-Native E-Commerce Application  
> **Stack:** MERN + Docker + Kubernetes (EKS) + Terraform + Jenkins CI/CD  
> **Last Updated:** February 2026

---

## 📋 Table of Contents

- [Source Control](#-source-control)
- [CI/CD](#-cicd)
- [Containerization](#-containerization)
- [Container Orchestration](#-container-orchestration)
- [Infrastructure as Code](#-infrastructure-as-code)
- [Cloud Platform (AWS)](#-cloud-platform-aws)
- [Monitoring & Observability](#-monitoring--observability)
- [Security](#-security)
- [Testing & Quality](#-testing--quality)
- [Architecture & Design](#-architecture--design)

---

# 📂 Source Control

## Git

### 1️⃣ Basics

**Q: What is Git?**  
A: Distributed version control system that tracks changes in source code during development.

**Q: Why use Git?**  
A: Enables collaboration, maintains history, supports branching, and allows rollback to any previous state.

**Q: What problem does Git solve?**  
A: Prevents "works on my machine" issues, tracks who changed what, and enables parallel development.

### 2️⃣ Project Usage

**Q: How is Git used in ShopDeploy?**  
A: Every code change is committed to Git. Jenkins CI is triggered by Git push events via webhooks.

**Q: What would break without Git?**  
A: No version history, no CI/CD triggers, no collaboration, no rollback capability.

**Q: What are alternatives to Git?**  
A: SVN, Mercurial, Perforce — but Git is the industry standard.

### 3️⃣ Commands / Practical

```bash
# Clone repository
git clone https://github.com/org/shopdeploy.git

# Create feature branch
git checkout -b feature/add-payment

# Stage and commit
git add .
git commit -m "feat: add Stripe payment integration"

# Push to remote
git push origin feature/add-payment

# Merge with main
git checkout main && git merge feature/add-payment

# View commit history
git log --oneline --graph

# Revert a commit
git revert <commit-hash>

# Stash changes temporarily
git stash && git stash pop
```

### 4️⃣ Scenario-Based Questions

**Q: A developer accidentally pushed secrets to Git. What do you do?**  
A: 
1. Immediately rotate the exposed credentials
2. Use `git filter-branch` or BFG Repo Cleaner to remove from history
3. Force push the cleaned history
4. Add secrets to `.gitignore`
5. Use git-secrets or pre-commit hooks to prevent future leaks

**Q: Two developers modified the same file. How do you resolve conflicts?**  
A: 
1. Pull latest changes: `git pull origin main`
2. Git marks conflicts in the file
3. Manually edit to keep correct changes
4. Stage and commit the resolution

**Q: How do you undo the last commit without losing changes?**  
A: `git reset --soft HEAD~1` — keeps changes staged for recommit.

### 5️⃣ Advanced / Interview Level

**Q: Difference between `git merge` and `git rebase`?**  
A: 
- **Merge**: Creates a merge commit, preserves complete history
- **Rebase**: Rewrites history, creates linear commit history
- Use merge for shared branches, rebase for local cleanup

**Q: What is Git cherry-pick?**  
A: Apply a specific commit from one branch to another without merging entire branch.

**Q: Explain Git hooks.**  
A: Scripts that run automatically on Git events (pre-commit, post-push). Used for linting, testing, preventing bad commits.

---

## GitHub

### 1️⃣ Basics

**Q: What is GitHub?**  
A: Cloud-based Git repository hosting with collaboration features like PRs, Issues, Actions, and code review.

**Q: Why GitHub over self-hosted Git?**  
A: Managed service, built-in CI/CD (Actions), security scanning, integrations, zero maintenance.

### 2️⃣ Project Usage

**Q: How is GitHub used in ShopDeploy?**  
A: 
- Hosts source code repository
- Webhooks trigger Jenkins on push
- Pull Requests enforce code review
- Branch protection prevents direct pushes to main

**Q: What GitHub features are used?**  
A: Webhooks, Branch Protection, Pull Requests, Issues, Secrets (for Actions if used).

### 3️⃣ Scenario-Based Questions

**Q: How do you enforce code review before merge?**  
A: Enable Branch Protection Rules:
- Require pull request before merging
- Require 1+ approving reviews
- Require status checks to pass (CI)
- Dismiss stale reviews on new commits

**Q: How do you prevent force pushes to main?**  
A: Branch Protection → Enable "Do not allow force pushes"

### 4️⃣ Production Best Practices

**Q: GitHub security best practices?**  
A: 
- Enable 2FA for all users
- Use SSH keys or personal access tokens (not passwords)
- Enable Dependabot for vulnerability alerts
- Use branch protection on main/production
- Never commit secrets — use GitHub Secrets

---

# 🔄 CI/CD

## Jenkins

### 1️⃣ Basics

**Q: What is Jenkins?**  
A: Open-source automation server for building, testing, and deploying software.

**Q: Why Jenkins?**  
A: Highly customizable, 1800+ plugins, self-hosted (data control), mature ecosystem.

**Q: What problem does Jenkins solve?**  
A: Automates repetitive tasks: build, test, security scan, deploy — reducing human error and speeding delivery.

### 2️⃣ Project Usage

**Q: How is Jenkins used in ShopDeploy?**  
A: 
- **Jenkinsfile-ci**: Build → Test → SonarQube → Docker Build → Push ECR
- **Jenkinsfile-cd**: Deploy to EKS via Helm → Smoke Tests → Rollback on failure

**Q: What triggers Jenkins builds?**  
A: GitHub webhook on push event + manual triggers for production deployments.

**Q: What would break without Jenkins?**  
A: No automated builds, manual Docker builds, no automated testing, no deployment automation.

**Q: Jenkins alternatives?**  
A: GitHub Actions, GitLab CI, CircleCI, Azure DevOps, Tekton.

### 3️⃣ Commands / Practical

```bash
# Start Jenkins (Docker)
docker run -d -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts

# Get initial admin password
cat /var/lib/jenkins/secrets/initialAdminPassword

# Restart Jenkins
sudo systemctl restart jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f

# Trigger build via CLI
java -jar jenkins-cli.jar -s http://localhost:8080 build shopdeploy-ci

# Safe restart (waits for builds)
http://localhost:8080/safeRestart
```

### 4️⃣ Scenario-Based Questions

**Q: Jenkins build is stuck. How do you debug?**  
A: 
1. Check console output for the stuck stage
2. Check agent availability (`Manage Jenkins → Nodes`)
3. Check disk space on Jenkins server
4. Look for deadlocks in parallel stages
5. Kill stuck build and check logs

**Q: How do you handle secrets in Jenkins?**  
A: 
- Use Jenkins Credentials plugin
- Store as `Secret text` or `Username/Password`
- Access via `credentials('credential-id')` in Jenkinsfile
- Never echo secrets in logs

**Q: Jenkins master crashed. How do you recover?**  
A: 
- Jenkins stores config in `$JENKINS_HOME`
- Restore from backup or recreate from Jenkinsfile (Pipeline as Code)
- Critical: Backup `$JENKINS_HOME/jobs/` and `credentials.xml`

**Q: How do you run Jenkins agents on Kubernetes?**  
A: Use Kubernetes plugin — dynamically provisions pods as build agents, scales with demand.

### 5️⃣ Advanced / Interview Level

**Q: Difference between Declarative and Scripted Pipeline?**  
A: 
- **Declarative**: Structured, easier syntax, `pipeline { }` block
- **Scripted**: Groovy-based, more flexible, `node { }` block
- ShopDeploy uses Declarative for readability

**Q: How does Jenkins integrate with SonarQube?**  
A: 
1. Install SonarQube Scanner plugin
2. Configure SonarQube server in `Manage Jenkins → Configure System`
3. Add `sonar-scanner` tool
4. Use `withSonarQubeEnv('SonarQube')` wrapper in pipeline
5. `waitForQualityGate()` fails build if quality gate fails

**Q: How do you implement Blue-Green deployment in Jenkins?**  
A: 
1. Deploy new version to "green" environment
2. Run smoke tests
3. Switch load balancer to green
4. Keep blue as rollback target

### 6️⃣ Production Best Practices

**Q: Jenkins best practices?**  
A: 
- Use Pipeline as Code (Jenkinsfile in repo)
- Use shared libraries for reusable code
- Run agents on Kubernetes (ephemeral)
- Backup `$JENKINS_HOME` regularly
- Use credentials plugin for secrets
- Enable role-based access control (RBAC)
- Archive artifacts and test results
- Use `timeout` and `retry` for resilience

---

## Helm

### 1️⃣ Basics

**Q: What is Helm?**  
A: Package manager for Kubernetes — bundles K8s manifests into reusable, versioned charts.

**Q: Why Helm?**  
A: Templating, versioning, easy rollbacks, environment-specific values, dependency management.

**Q: What problem does Helm solve?**  
A: Managing dozens of YAML files manually is error-prone. Helm packages them into one deployable unit.

### 2️⃣ Project Usage

**Q: How is Helm used in ShopDeploy?**  
A: 
- `helm/backend/` — Backend deployment chart
- `helm/frontend/` — Frontend deployment chart
- `values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml` — Environment configs
- Jenkins CD uses `helm upgrade --install` for deployments

**Q: What would break without Helm?**  
A: Manual kubectl applies, no rollback versioning, copy-paste errors across environments.

### 3️⃣ Commands / Practical

```bash
# Install/upgrade a release
helm upgrade --install shopdeploy-backend ./helm/backend \
  -n shopdeploy -f helm/backend/values-prod.yaml

# List releases
helm list -n shopdeploy

# Check release history
helm history shopdeploy-backend -n shopdeploy

# Rollback to previous version
helm rollback shopdeploy-backend 1 -n shopdeploy

# Dry-run (preview changes)
helm upgrade --install shopdeploy-backend ./helm/backend --dry-run

# Uninstall release
helm uninstall shopdeploy-backend -n shopdeploy

# Template locally (debug)
helm template shopdeploy-backend ./helm/backend -f values-prod.yaml

# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 4️⃣ Scenario-Based Questions

**Q: Deployment failed. How do you rollback?**  
A: 
```bash
helm history shopdeploy-backend -n shopdeploy  # Find last good revision
helm rollback shopdeploy-backend 3 -n shopdeploy  # Rollback to revision 3
```

**Q: How do you deploy same chart to dev/staging/prod?**  
A: Use separate values files:
```bash
helm upgrade --install app ./chart -f values-dev.yaml      # Dev
helm upgrade --install app ./chart -f values-staging.yaml  # Staging
helm upgrade --install app ./chart -f values-prod.yaml     # Prod
```

**Q: Helm release stuck in "pending-upgrade". How to fix?**  
A: 
```bash
helm history <release>  # Check status
kubectl delete secret -l owner=helm,name=<release> -n <namespace>  # Nuclear option
helm upgrade --install <release> <chart> --force  # Force upgrade
```

### 5️⃣ Advanced / Interview Level

**Q: Difference between `helm install` and `helm upgrade --install`?**  
A: 
- `install`: Fails if release exists
- `upgrade --install`: Creates if not exists, upgrades if exists (idempotent)

**Q: How do Helm hooks work?**  
A: Annotations that run at lifecycle points:
- `pre-install`, `post-install`
- `pre-upgrade`, `post-upgrade`
- `pre-delete`, `post-delete`
- Used for DB migrations, backups, notifications

**Q: How to manage secrets in Helm?**  
A: 
- Helm Secrets plugin (SOPS encryption)
- External Secrets Operator
- Sealed Secrets
- Never commit plain secrets in values.yaml

---

## Amazon ECR

### 1️⃣ Basics

**Q: What is Amazon ECR?**  
A: Fully managed Docker container registry by AWS.

**Q: Why ECR over Docker Hub?**  
A: 
- Private by default
- Integrated with EKS/ECS
- IAM-based authentication
- Vulnerability scanning
- No rate limits (paid)

### 2️⃣ Project Usage

**Q: How is ECR used in ShopDeploy?**  
A: 
- Stores backend and frontend Docker images
- Jenkins pushes images after build
- EKS pulls images during deployment
- Immutable tags: `BUILD_NUMBER-commit-hash`

### 3️⃣ Commands / Practical

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com

# Create repository
aws ecr create-repository --repository-name shopdeploy-backend

# Push image
docker tag shopdeploy-backend:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/shopdeploy-backend:v1
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/shopdeploy-backend:v1

# List images
aws ecr describe-images --repository-name shopdeploy-backend

# Delete old images (lifecycle policy)
aws ecr put-lifecycle-policy --repository-name shopdeploy-backend --lifecycle-policy-text file://policy.json

# Scan image for vulnerabilities
aws ecr start-image-scan --repository-name shopdeploy-backend --image-id imageTag=v1
```

### 4️⃣ Scenario-Based Questions

**Q: ECR pull is failing in EKS. How to debug?**  
A: 
1. Check node IAM role has `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`
2. Check image exists: `aws ecr describe-images`
3. Check imagePullSecrets if using cross-account
4. Check VPC endpoints if in private subnet

**Q: How to reduce ECR storage costs?**  
A: Create lifecycle policy to delete untagged images after 7 days and keep only last 10 tagged images.

---

## ArgoCD

### 1️⃣ Basics

**Q: What is ArgoCD?**  
A: GitOps continuous delivery tool for Kubernetes — syncs cluster state with Git repository.

**Q: What is GitOps?**  
A: Git as single source of truth. All changes go through Git, ArgoCD applies them to cluster.

### 2️⃣ Project Usage

**Q: How would ArgoCD be used in ShopDeploy?**  
A: 
- `gitops/` folder contains environment values
- ArgoCD watches Git for changes
- Auto-syncs Helm releases when values change
- Replaces Jenkins CD for deployments

**Q: GitOps vs Traditional CI/CD?**  
A: 
| Aspect | Traditional | GitOps |
|--------|-------------|--------|
| Deployment trigger | CI pipeline | Git commit |
| Audit trail | Pipeline logs | Git history |
| Rollback | Re-run pipeline | `git revert` |
| Drift detection | Manual | Automatic |

### 3️⃣ Commands / Practical

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login via CLI
argocd login localhost:8080 --username admin --password <password>

# Create application
argocd app create shopdeploy-backend \
  --repo https://github.com/org/shopdeploy.git \
  --path helm/backend \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace shopdeploy

# Sync application
argocd app sync shopdeploy-backend

# Check app status
argocd app get shopdeploy-backend
```

### 4️⃣ Scenario-Based Questions

**Q: Application is OutOfSync. What does it mean?**  
A: Cluster state differs from Git. Either:
- Someone made manual `kubectl` changes (drift)
- Git was updated but not synced
- Fix: `argocd app sync <app>` or enable auto-sync

**Q: How to implement progressive rollouts with ArgoCD?**  
A: Use Argo Rollouts with:
- Canary: Route 10% traffic to new version
- Blue-Green: Switch all traffic after validation
- Analysis: Auto-rollback on metric failures

---

# 🐳 Containerization

## Docker

### 1️⃣ Basics

**Q: What is Docker?**  
A: Platform for developing, shipping, and running applications in containers.

**Q: Why Docker?**  
A: Consistent environments, isolation, fast startup, efficient resource usage, portable.

**Q: What problem does Docker solve?**  
A: "Works on my machine" — packages app + dependencies into a single unit.

### 2️⃣ Project Usage

**Q: How is Docker used in ShopDeploy?**  
A: 
- Backend: `node:18-alpine` base image
- Frontend: `nginxinc/nginx-unprivileged:alpine` (port 8080)
- Multi-stage builds for smaller images
- Built by Jenkins, pushed to ECR, deployed to EKS

**Q: Why nginx-unprivileged for frontend?**  
A: Runs as non-root user (UID 101), enhanced security, required for restricted Pod Security Policies.

### 3️⃣ Commands / Practical

```bash
# Build image
docker build -t shopdeploy-backend:v1 .

# Build with build args
docker build --build-arg VITE_API_URL=https://api.example.com -t frontend:v1 .

# Run container
docker run -d -p 5000:5000 --name backend shopdeploy-backend:v1

# View logs
docker logs -f backend

# Execute command in container
docker exec -it backend sh

# List running containers
docker ps

# Stop and remove
docker stop backend && docker rm backend

# Remove unused images
docker system prune -a

# Inspect image layers
docker history shopdeploy-backend:v1

# Copy file from container
docker cp backend:/app/logs ./logs
```

### 4️⃣ Scenario-Based Questions

**Q: Docker build is slow. How to optimize?**  
A: 
1. Order Dockerfile commands by change frequency (COPY package.json first)
2. Use `.dockerignore` to exclude node_modules, .git
3. Use multi-stage builds
4. Use `--cache-from` for CI builds
5. Use smaller base images (alpine)

**Q: Container keeps restarting. How to debug?**  
A: 
```bash
docker logs <container>           # Check error logs
docker inspect <container>        # Check exit code
docker exec -it <container> sh    # If running, inspect inside
```

**Q: How to reduce Docker image size?**  
A: 
- Multi-stage builds (build stage → runtime stage)
- Alpine base images
- Remove dev dependencies
- Combine RUN commands
- Clean up in same layer (apt-get clean)

### 5️⃣ Advanced / Interview Level

**Q: Difference between CMD and ENTRYPOINT?**  
A: 
- **ENTRYPOINT**: Defines the executable (not easily overridden)
- **CMD**: Default arguments (easily overridden)
- Together: `ENTRYPOINT ["node"]` + `CMD ["server.js"]`

**Q: Difference between COPY and ADD?**  
A: 
- **COPY**: Simple file copy
- **ADD**: Can extract tar files, fetch URLs
- Best practice: Use COPY unless you need ADD features

**Q: How does Docker networking work?**  
A: 
- **bridge**: Default, containers on same host communicate
- **host**: Container uses host network directly
- **none**: No networking
- **overlay**: Multi-host networking (Swarm/K8s)

**Q: What is Docker layer caching?**  
A: Each Dockerfile instruction creates a layer. Unchanged layers are cached, speeding up builds.

### 6️⃣ Production Best Practices

**Q: Docker security best practices?**  
A: 
- Run as non-root user (`USER node`)
- Use official/verified base images
- Scan images with Trivy
- Don't store secrets in images
- Use read-only filesystem where possible
- Keep images minimal (alpine)
- Pin base image versions (not `latest`)

---

## Docker Compose

### 1️⃣ Basics

**Q: What is Docker Compose?**  
A: Tool for defining and running multi-container Docker applications using YAML.

**Q: When to use Docker Compose?**  
A: Local development, testing multi-service apps, quick prototyping.

### 2️⃣ Project Usage

**Q: How is Docker Compose used in ShopDeploy?**  
A: 
```yaml
# docker-compose.yml
services:
  backend:
    build: ./shopdeploy-backend
    ports:
      - "5000:5000"
  frontend:
    build: ./shopdeploy-frontend
    ports:
      - "8080:8080"
  mongodb:
    image: mongo:8
    volumes:
      - mongo-data:/data/db
```

### 3️⃣ Commands / Practical

```bash
# Start all services
docker-compose up -d

# Build and start
docker-compose up --build

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Scale service
docker-compose up -d --scale backend=3

# Execute command
docker-compose exec backend npm test
```

---

## Nginx

### 1️⃣ Basics

**Q: What is Nginx?**  
A: High-performance web server, reverse proxy, and load balancer.

**Q: Why Nginx for frontend?**  
A: Efficiently serves static files, handles compression, provides caching, production-grade.

### 2️⃣ Project Usage

**Q: How is Nginx configured in ShopDeploy?**  
A: 
- Serves React build from `/usr/share/nginx/html`
- Port 8080 (nginx-unprivileged)
- SPA routing: Falls back to `index.html`
- Gzip compression enabled
- Security headers configured

**Q: Why port 8080 instead of 80?**  
A: Ports below 1024 require root. Using nginx-unprivileged on 8080 allows non-root execution.

### 3️⃣ Scenario-Based Questions

**Q: Frontend shows 404 on page refresh. How to fix?**  
A: SPA routing issue. Add to nginx.conf:
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

---

# ☸️ Container Orchestration

## Amazon EKS

### 1️⃣ Basics

**Q: What is Amazon EKS?**  
A: Managed Kubernetes service by AWS — AWS handles control plane, you manage worker nodes.

**Q: Why EKS over self-managed Kubernetes?**  
A: 
- AWS manages control plane (HA, upgrades, patches)
- Integrated with AWS services (IAM, ALB, ECR)
- Reduced operational burden
- Enterprise support available

### 2️⃣ Project Usage

**Q: How is EKS used in ShopDeploy?**  
A: 
- Created via Terraform
- Runs backend and frontend pods
- Managed node groups (auto-scaling)
- Uses AWS Load Balancer Controller for ALB

**Q: What's in the EKS cluster?**  
A: 
- shopdeploy namespace
- Backend Deployment (3 replicas)
- Frontend Deployment (3 replicas)
- LoadBalancer Services
- HPA for auto-scaling

### 3️⃣ Commands / Practical

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name shopdeploy-prod-eks

# Get cluster info
kubectl cluster-info
kubectl get nodes

# View all resources
kubectl get all -n shopdeploy

# Describe node (troubleshooting)
kubectl describe node <node-name>

# Get EKS cluster details
aws eks describe-cluster --name shopdeploy-prod-eks

# Scale node group
aws eks update-nodegroup-config --cluster-name shopdeploy-prod-eks \
  --nodegroup-name workers --scaling-config minSize=2,maxSize=10,desiredSize=3
```

### 4️⃣ Scenario-Based Questions

**Q: Pods are pending. How to debug?**  
A: 
```bash
kubectl describe pod <pod-name> -n shopdeploy  # Check events
kubectl get nodes  # Check if nodes are Ready
kubectl describe node <node>  # Check allocatable resources
```
Common causes:
- Insufficient CPU/memory on nodes
- Node not ready
- Pod affinity/anti-affinity rules
- PVC not bound

**Q: Nodes are NotReady. What to check?**  
A: 
1. Check node status: `kubectl describe node`
2. Check kubelet logs on node
3. Check AWS Console for instance issues
4. Check security groups allow control plane communication

**Q: How do you upgrade EKS cluster?**  
A: 
1. Upgrade control plane first (AWS Console or `eksctl upgrade cluster`)
2. Update node groups (rolling update)
3. Update add-ons (CoreDNS, kube-proxy, VPC-CNI)
4. Test application functionality

### 5️⃣ Advanced / Interview Level

**Q: EKS vs ECS vs Fargate?**  
A: 
| Feature | EKS | ECS | Fargate |
|---------|-----|-----|---------|
| Orchestrator | Kubernetes | AWS proprietary | Serverless compute |
| Portability | High (K8s standard) | AWS locked | AWS locked |
| Complexity | Higher | Medium | Low |
| Use case | Multi-cloud, complex | AWS native | Simple, no node mgmt |

**Q: How does EKS integrate with IAM?**  
A: 
- IRSA (IAM Roles for Service Accounts)
- Pods assume IAM roles via service account annotations
- No credentials in pods — uses OIDC federation

**Q: What is the EKS VPC CNI plugin?**  
A: Assigns real VPC IPs to pods, enabling direct VPC communication without NAT.

---

## kubectl

### 1️⃣ Basics

**Q: What is kubectl?**  
A: Command-line tool for communicating with Kubernetes clusters.

### 2️⃣ Commands / Practical

```bash
# VIEWING RESOURCES
kubectl get pods -n shopdeploy
kubectl get pods -o wide  # More details
kubectl get svc -n shopdeploy
kubectl get deploy -n shopdeploy
kubectl get all -n shopdeploy

# DEBUGGING
kubectl describe pod <pod-name> -n shopdeploy
kubectl logs <pod-name> -n shopdeploy
kubectl logs <pod-name> -c <container> -n shopdeploy  # Specific container
kubectl logs -f <pod-name>  # Follow logs
kubectl logs --previous <pod-name>  # Previous container logs

# EXEC INTO POD
kubectl exec -it <pod-name> -n shopdeploy -- sh

# PORT FORWARD
kubectl port-forward svc/shopdeploy-backend 5000:5000 -n shopdeploy

# SCALING
kubectl scale deployment backend --replicas=5 -n shopdeploy

# ROLLOUT
kubectl rollout status deployment/backend -n shopdeploy
kubectl rollout history deployment/backend -n shopdeploy
kubectl rollout undo deployment/backend -n shopdeploy

# APPLY/DELETE
kubectl apply -f manifest.yaml
kubectl delete -f manifest.yaml

# CONTEXT
kubectl config get-contexts
kubectl config use-context prod-cluster

# RESOURCE USAGE
kubectl top pods -n shopdeploy
kubectl top nodes
```

### 3️⃣ Scenario-Based Questions

**Q: Pod is CrashLoopBackOff. How to debug?**  
A: 
```bash
kubectl describe pod <pod>  # Check events
kubectl logs <pod> --previous  # Check crash logs
```
Common causes:
- Application error on startup
- Missing environment variables
- Liveness probe failing
- OOMKilled (memory limit too low)

**Q: How to check why pod was OOMKilled?**  
A: 
```bash
kubectl describe pod <pod>  # Look for "OOMKilled" in state
kubectl top pods  # Check current memory usage
# Solution: Increase memory limits or fix memory leak
```

---

## HPA (Horizontal Pod Autoscaler)

### 1️⃣ Basics

**Q: What is HPA?**  
A: Automatically scales pod replicas based on CPU/memory utilization or custom metrics.

**Q: How does HPA work?**  
A: 
1. Metrics Server collects pod metrics
2. HPA controller checks metrics every 15 seconds
3. Calculates desired replicas based on target utilization
4. Scales deployment up or down

### 2️⃣ Project Usage

**Q: How is HPA configured in ShopDeploy?**  
A: 
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: shopdeploy-backend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 3️⃣ Commands / Practical

```bash
# View HPA status
kubectl get hpa -n shopdeploy

# Describe HPA (see scaling decisions)
kubectl describe hpa shopdeploy-backend -n shopdeploy

# Create HPA imperatively
kubectl autoscale deployment backend --cpu-percent=70 --min=2 --max=10 -n shopdeploy

# Check metrics server
kubectl top pods -n shopdeploy
```

### 4️⃣ Scenario-Based Questions

**Q: HPA is not scaling. What to check?**  
A: 
1. Metrics Server installed? `kubectl get deployment metrics-server -n kube-system`
2. Resource requests defined? HPA needs `resources.requests`
3. Check HPA events: `kubectl describe hpa`
4. Metrics available? `kubectl top pods`

**Q: How to prevent scale-down during deployment?**  
A: Use PodDisruptionBudget or set `stabilizationWindowSeconds` in HPA behavior.

---

## Pod Disruption Budget (PDB)

### 1️⃣ Basics

**Q: What is PDB?**  
A: Limits the number of pods that can be simultaneously unavailable during voluntary disruptions.

**Q: Why is PDB important?**  
A: Ensures high availability during:
- Node drains
- Cluster upgrades
- Voluntary evictions

### 2️⃣ Project Usage

**Q: How is PDB configured in ShopDeploy?**  
A: 
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: backend-pdb
spec:
  minAvailable: 2  # At least 2 pods must always be running
  selector:
    matchLabels:
      app: shopdeploy-backend
```

### 3️⃣ Scenario-Based Questions

**Q: Node drain is stuck. Could PDB be the cause?**  
A: Yes! If PDB requires more pods available than exist, drain blocks. Check:
```bash
kubectl get pdb -n shopdeploy
kubectl describe pdb backend-pdb
```

---

# 🏗️ Infrastructure as Code

## Terraform

### 1️⃣ Basics

**Q: What is Terraform?**  
A: Infrastructure as Code tool for provisioning cloud resources declaratively.

**Q: Why Terraform?**  
A: 
- Multi-cloud support
- Declarative syntax (define desired state)
- State management (tracks what exists)
- Plan before apply (preview changes)
- Modular and reusable

**Q: What problem does Terraform solve?**  
A: Manual AWS console clicks are slow, error-prone, and not reproducible. Terraform automates infrastructure creation.

### 2️⃣ Project Usage

**Q: What does Terraform create for ShopDeploy?**  
A: 
- VPC (public/private subnets, NAT Gateway)
- EKS Cluster + Node Groups
- ECR Repositories
- IAM Roles and Policies
- Security Groups

**Q: How is Terraform structured in this project?**  
A: 
```
terraform/
├── main.tf           # Main configuration
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── data.tf           # Data sources
├── terraform.tfvars  # Variable values
└── modules/
    ├── vpc/
    ├── eks/
    ├── ecr/
    └── iam/
```

### 3️⃣ Commands / Practical

```bash
# Initialize (download providers)
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt

# Preview changes
terraform plan

# Preview and save plan
terraform plan -out=tfplan

# Apply changes
terraform apply

# Apply saved plan
terraform apply tfplan

# Apply with auto-approve (CI/CD)
terraform apply -auto-approve

# Destroy all resources
terraform destroy

# Show current state
terraform show

# List resources in state
terraform state list

# Remove resource from state (dangerous)
terraform state rm aws_instance.example

# Import existing resource
terraform import aws_instance.example i-1234567890abcdef0

# Refresh state (sync with actual)
terraform refresh

# Output values
terraform output
```

### 4️⃣ Scenario-Based Questions

**Q: `terraform apply` failed midway. What happens?**  
A: 
- State contains resources created before failure
- Run `terraform apply` again — Terraform is idempotent
- Only remaining resources will be created

**Q: Someone manually changed a resource. How to detect?**  
A: 
```bash
terraform plan  # Shows drift from desired state
terraform apply  # Corrects drift
```

**Q: State file is corrupted/lost. What to do?**  
A: 
1. If using S3 backend: Check versioning, restore previous version
2. If local: Recreate state by importing resources
3. Prevention: Always use remote state with versioning

**Q: How to move resource to a module without recreating?**  
A: 
```bash
terraform state mv aws_instance.example module.compute.aws_instance.example
```

**Q: Two people running Terraform simultaneously. What happens?**  
A: State corruption risk! Use:
- S3 backend with DynamoDB locking
- Terraform Cloud/Enterprise
- CI/CD pipeline (serialized runs)

### 5️⃣ Advanced / Interview Level

**Q: Difference between `count` and `for_each`?**  
A: 
- **count**: Integer-based, indexes resources (count.index)
- **for_each**: Map/set-based, keyed resources
- `for_each` preferred — removing middle item doesn't affect others

**Q: What are Terraform workspaces?**  
A: Isolated state files for same configuration. Use for dev/staging/prod:
```bash
terraform workspace new staging
terraform workspace select staging
```

**Q: Explain Terraform lifecycle rules.**  
A: 
```hcl
lifecycle {
  create_before_destroy = true  # Create new before destroying old
  prevent_destroy = true        # Prevent accidental deletion
  ignore_changes = [tags]       # Ignore external changes to tags
}
```

**Q: How does Terraform handle dependencies?**  
A: 
- Implicit: Resource references (`aws_instance.web.id`)
- Explicit: `depends_on = [aws_vpc.main]`
- Terraform builds a dependency graph and creates in order

### 6️⃣ Production Best Practices

**Q: Terraform state best practices?**  
A: 
- Use remote backend (S3 + DynamoDB)
- Enable versioning on S3 bucket
- Enable encryption
- Lock state during operations
- Never commit state files to Git
- Use separate states per environment

**Q: Terraform security best practices?**  
A: 
- Never hardcode secrets in `.tf` files
- Use AWS Secrets Manager or Parameter Store
- Mark sensitive outputs: `sensitive = true`
- Use least privilege IAM for Terraform
- Review plans carefully before apply
- Use `terraform validate` in CI

---

## Terraform Modules

### 1️⃣ Basics

**Q: What are Terraform Modules?**  
A: Reusable, self-contained packages of Terraform configurations.

**Q: Why use modules?**  
A: DRY principle — write once, use multiple times with different inputs.

### 2️⃣ Project Usage

**Q: What modules exist in ShopDeploy?**  
A: 
```
modules/
├── vpc/    # VPC, subnets, NAT
├── eks/    # EKS cluster, node groups
├── ecr/    # Container registries
└── iam/    # Roles and policies
```

### 3️⃣ Scenario-Based Questions

**Q: How to use the same VPC module for dev and prod?**  
A: Call module twice with different variables:
```hcl
module "vpc_dev" {
  source = "./modules/vpc"
  environment = "dev"
  vpc_cidr = "10.0.0.0/16"
}

module "vpc_prod" {
  source = "./modules/vpc"
  environment = "prod"
  vpc_cidr = "10.1.0.0/16"
}
```

---

## S3 Backend

### 1️⃣ Basics

**Q: What is S3 Backend?**  
A: Remote storage for Terraform state files in AWS S3.

**Q: Why use S3 backend?**  
A: 
- Team collaboration (shared state)
- State locking (DynamoDB)
- Versioning (rollback)
- Encryption (security)

### 2️⃣ Project Usage

**Q: How is S3 backend configured?**  
A: 
```hcl
terraform {
  backend "s3" {
    bucket         = "shopdeploy-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### 3️⃣ Scenario-Based Questions

**Q: State is locked and previous run crashed. How to unlock?**  
A: 
```bash
terraform force-unlock <LOCK_ID>
```
Get LOCK_ID from error message. Use carefully!

---

# ☁️ Cloud Platform (AWS)

## VPC

### 1️⃣ Basics

**Q: What is VPC?**  
A: Virtual Private Cloud — isolated virtual network in AWS.

**Q: Why do we need VPC?**  
A: Network isolation, security, control over IP ranges, subnets, routing.

### 2️⃣ Project Usage

**Q: How is VPC structured for ShopDeploy?**  
A: 
```
VPC (10.0.0.0/16)
├── Public Subnets (2 AZs)
│   └── NAT Gateway, Load Balancer
├── Private Subnets (2 AZs)
│   └── EKS Worker Nodes
└── Internet Gateway
```

### 3️⃣ Scenario-Based Questions

**Q: Private subnet pods can't access internet. What's wrong?**  
A: Check:
1. NAT Gateway exists in public subnet
2. Private route table has route: `0.0.0.0/0 → NAT Gateway`
3. NAT Gateway has Elastic IP

**Q: How to allow EKS nodes to pull from ECR in private subnet?**  
A: 
- Option 1: NAT Gateway (costs money for data transfer)
- Option 2: VPC Endpoints for ECR (dkr and api endpoints)

---

## ALB (Application Load Balancer)

### 1️⃣ Basics

**Q: What is ALB?**  
A: Layer 7 load balancer for HTTP/HTTPS traffic.

**Q: ALB vs NLB vs CLB?**  
A: 
| Type | Layer | Use Case |
|------|-------|----------|
| ALB | 7 (HTTP) | Web apps, path-based routing |
| NLB | 4 (TCP) | Ultra-low latency, static IPs |
| CLB | 4/7 | Legacy, avoid for new projects |

### 2️⃣ Project Usage

**Q: How is ALB used in ShopDeploy?**  
A: 
- AWS Load Balancer Controller creates ALB from Ingress
- Routes `/api/*` to backend service
- Routes `/` to frontend service
- Terminates HTTPS

### 3️⃣ Scenario-Based Questions

**Q: 502 Bad Gateway from ALB. How to debug?**  
A: 
1. Target group health checks failing
2. Security group blocks ALB → pod traffic
3. Pod not listening on expected port
4. Check ALB access logs in S3

**Q: How to implement Blue-Green with ALB?**  
A: 
- Two target groups (blue and green)
- Switch listener rules to point to new target group
- Rollback by switching back

---

## IAM

### 1️⃣ Basics

**Q: What is IAM?**  
A: Identity and Access Management — controls who can access what in AWS.

**Q: IAM Users vs Roles?**  
A: 
- **Users**: Long-term credentials for humans
- **Roles**: Temporary credentials for services/applications
- Best practice: Use roles for applications (EKS pods, EC2)

### 2️⃣ Project Usage

**Q: What IAM roles exist for ShopDeploy?**  
A: 
- EKS Cluster Role (control plane permissions)
- EKS Node Role (EC2, ECR, CloudWatch permissions)
- Pod Service Account Role (IRSA for app-specific access)

### 3️⃣ Scenario-Based Questions

**Q: Pod can't access S3. How to fix?**  
A: 
1. Create IAM policy for S3 access
2. Create IAM role with OIDC trust policy
3. Annotate ServiceAccount with role ARN
4. Use ServiceAccount in pod spec

### 4️⃣ Production Best Practices

**Q: IAM security best practices?**  
A: 
- Least privilege principle
- Use roles, not access keys
- Enable MFA for users
- Rotate credentials regularly
- Use IAM Access Analyzer
- Never use root account

---

## Parameter Store

### 1️⃣ Basics

**Q: What is AWS Parameter Store?**  
A: Secure, hierarchical storage for configuration data and secrets.

**Q: Parameter Store vs Secrets Manager?**  
A: 
| Feature | Parameter Store | Secrets Manager |
|---------|-----------------|-----------------|
| Cost | Free (standard) | $0.40/secret/month |
| Rotation | Manual | Automatic |
| Size limit | 8KB | 64KB |
| Use case | Config, simple secrets | Sensitive secrets, rotation |

### 2️⃣ Project Usage

**Q: How is Parameter Store used in ShopDeploy?**  
A: 
- Stores IMAGE_TAG after CI build
- CD pipeline reads IMAGE_TAG for deployment
- Cross-pipeline parameter sharing

### 3️⃣ Commands / Practical

```bash
# Put parameter
aws ssm put-parameter --name "/shopdeploy/prod/IMAGE_TAG" --value "42-abc1234" --type String --overwrite

# Get parameter
aws ssm get-parameter --name "/shopdeploy/prod/IMAGE_TAG" --query Parameter.Value --output text

# Get secure parameter (decrypted)
aws ssm get-parameter --name "/shopdeploy/prod/DB_PASSWORD" --with-decryption
```

---

# 📊 Monitoring & Observability

## Prometheus

### 1️⃣ Basics

**Q: What is Prometheus?**  
A: Open-source monitoring system for collecting and querying time-series metrics.

**Q: How does Prometheus work?**  
A: 
- **Pull model**: Prometheus scrapes metrics from targets
- Stores in time-series database
- PromQL for querying
- Alertmanager for notifications

### 2️⃣ Project Usage

**Q: What does Prometheus monitor in ShopDeploy?**  
A: 
- Pod CPU/memory usage
- Request latency and throughput
- Error rates
- Node metrics (via Node Exporter)
- Kubernetes metrics (via kube-state-metrics)

### 3️⃣ Commands / Practical

```bash
# Port-forward to Prometheus UI
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring

# Common PromQL queries
# Container CPU usage
sum(rate(container_cpu_usage_seconds_total{namespace="shopdeploy"}[5m])) by (pod)

# Memory usage
sum(container_memory_usage_bytes{namespace="shopdeploy"}) by (pod)

# HTTP request rate
sum(rate(http_requests_total{namespace="shopdeploy"}[5m])) by (service)
```

### 4️⃣ Scenario-Based Questions

**Q: Prometheus is running out of disk. What to do?**  
A: 
1. Reduce retention: `--storage.tsdb.retention.time=15d`
2. Reduce scrape interval
3. Drop unnecessary metrics
4. Increase disk size

**Q: How to alert on high error rate?**  
A: Create Prometheus alert rule:
```yaml
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
  for: 5m
  labels:
    severity: critical
```

---

## Grafana

### 1️⃣ Basics

**Q: What is Grafana?**  
A: Visualization platform for metrics, logs, and traces.

**Q: Why Grafana with Prometheus?**  
A: Prometheus stores data, Grafana visualizes it with rich dashboards.

### 2️⃣ Project Usage

**Q: What dashboards exist for ShopDeploy?**  
A: 
- Kubernetes Cluster Overview
- Node Metrics
- Pod Metrics
- ShopDeploy Application Dashboard (custom)

### 3️⃣ Scenario-Based Questions

**Q: How to create a dashboard for API latency?**  
A: 
1. Add Prometheus data source
2. Create panel with PromQL:
   ```
   histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
   ```
3. Set visualization to Graph
4. Set thresholds for alerting

---

## Node Exporter

### 1️⃣ Basics

**Q: What is Node Exporter?**  
A: Prometheus exporter for OS-level metrics (CPU, memory, disk, network).

**Q: Why Node Exporter?**  
A: Provides visibility into underlying node health, not just containers.

### 2️⃣ Key Metrics

| Metric | Purpose |
|--------|---------|
| `node_cpu_seconds_total` | CPU usage |
| `node_memory_MemAvailable_bytes` | Available memory |
| `node_disk_io_time_seconds_total` | Disk I/O |
| `node_network_receive_bytes_total` | Network traffic |

---

## Kubernetes Probes

### 1️⃣ Basics

**Q: What are Kubernetes probes?**  
A: Health checks for containers to determine readiness and liveness.

**Q: Types of probes?**  
A: 
| Probe | Purpose |
|-------|---------|
| **Liveness** | Restart container if unhealthy |
| **Readiness** | Remove from load balancer if not ready |
| **Startup** | Wait for slow-starting apps |

### 2️⃣ Project Usage

**Q: What probes are configured for ShopDeploy?**  
A: 
```yaml
# Backend
livenessProbe:
  httpGet:
    path: /api/health/health
    port: 5000
readinessProbe:
  httpGet:
    path: /api/health/ready
    port: 5000

# Frontend
livenessProbe:
  httpGet:
    path: /
    port: 8080
readinessProbe:
  httpGet:
    path: /
    port: 8080
```

### 3️⃣ Scenario-Based Questions

**Q: Pods keep restarting. Could probes be the cause?**  
A: Yes! If liveness probe fails, container restarts. Check:
```bash
kubectl describe pod <pod>  # Look at events
kubectl logs <pod>          # Check if app is slow to start
```
Fix: Increase `initialDelaySeconds` or fix application startup.

**Q: New pods receive traffic before ready. Why?**  
A: Readiness probe not configured or too lenient. Traffic only routes to pods passing readiness check.

---

# 🔐 Security

## Trivy

### 1️⃣ Basics

**Q: What is Trivy?**  
A: Open-source vulnerability scanner for containers, filesystems, and IaC.

**Q: Why use Trivy?**  
A: Finds CVEs in container images before production deployment.

### 2️⃣ Project Usage

**Q: How is Trivy used in ShopDeploy?**  
A: 
- Jenkins CI scans images after Docker build
- Fails build on HIGH/CRITICAL vulnerabilities
- Scans both backend and frontend images

### 3️⃣ Commands / Practical

```bash
# Scan image
trivy image shopdeploy-backend:latest

# Scan and fail on HIGH/CRITICAL
trivy image --severity HIGH,CRITICAL --exit-code 1 shopdeploy-backend:latest

# Scan with JSON output
trivy image -f json -o results.json shopdeploy-backend:latest

# Scan filesystem
trivy fs --security-checks vuln,config .

# Scan Kubernetes manifests
trivy k8s --report summary cluster
```

### 4️⃣ Scenario-Based Questions

**Q: Trivy found a CRITICAL CVE. What do you do?**  
A: 
1. Check if CVE is exploitable in your context
2. Update base image if patch available
3. Update vulnerable dependency
4. If no fix available, document risk acceptance
5. Never ignore silently

**Q: How to integrate Trivy with CI/CD?**  
A: 
```groovy
stage('Security Scan') {
    steps {
        sh 'trivy image --severity HIGH,CRITICAL --exit-code 1 ${IMAGE}'
    }
}
```

---

## SonarQube

### 1️⃣ Basics

**Q: What is SonarQube?**  
A: Static code analysis platform for detecting bugs, vulnerabilities, and code smells.

**Q: Why SonarQube?**  
A: Catches issues before production — security vulnerabilities, bugs, code duplication.

### 2️⃣ Project Usage

**Q: How is SonarQube used in ShopDeploy?**  
A: 
- Jenkins runs SonarQube Scanner on every build
- Analyzes JavaScript/TypeScript code
- Quality Gate blocks merge if standards not met
- Gracefully skips if not configured

**Q: What does SonarQube check?**  
A: 
- Bugs (code that will break)
- Vulnerabilities (security issues)
- Code Smells (maintainability issues)
- Coverage (test coverage %)
- Duplications (copy-paste code)

### 3️⃣ Scenario-Based Questions

**Q: Quality Gate failed. What to do?**  
A: 
1. Check SonarQube dashboard for failed conditions
2. Fix critical/blocker issues
3. Run analysis again
4. If false positive, mark as "Won't Fix" with justification

**Q: SonarQube shows 0% coverage. Why?**  
A: 
- Test reports not generated
- Report path not configured in `sonar-project.properties`
- Tests not running before analysis

---

## JWT (JSON Web Tokens)

### 1️⃣ Basics

**Q: What is JWT?**  
A: Compact, URL-safe token format for securely transmitting information.

**Q: How does JWT work?**  
A: 
1. User logs in with credentials
2. Server creates JWT signed with secret
3. Client stores JWT and sends with requests
4. Server validates signature and claims

### 2️⃣ Project Usage

**Q: How is JWT used in ShopDeploy?**  
A: 
- Access Token: 15 min expiry, used for API requests
- Refresh Token: 7 day expiry, used to get new access tokens
- Stored in HTTP-only cookies (XSS protection)

### 3️⃣ Scenario-Based Questions

**Q: JWT secret was compromised. What to do?**  
A: 
1. Immediately rotate the secret
2. All existing tokens become invalid
3. Users must re-authenticate
4. Investigate how compromise occurred

**Q: Why use two tokens (access + refresh)?**  
A: 
- Short access token: Limits damage if stolen
- Long refresh token: Better UX (no frequent re-login)
- Refresh token can be revoked server-side

---

## Network Policies

### 1️⃣ Basics

**Q: What are Kubernetes Network Policies?**  
A: Firewall rules for pod-to-pod communication.

**Q: Why use Network Policies?**  
A: Default: All pods can talk to all pods. Network Policies enforce least privilege.

### 2️⃣ Project Usage

**Q: What Network Policies exist for ShopDeploy?**  
A: 
```yaml
# Allow frontend → backend only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: shopdeploy-backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: shopdeploy-frontend
    ports:
    - port: 5000
```

### 3️⃣ Scenario-Based Questions

**Q: After enabling Network Policies, pod communication broke. How to debug?**  
A: 
```bash
kubectl describe networkpolicy -n shopdeploy  # Check rules
kubectl get pods --show-labels  # Verify label selectors
# Test connectivity from one pod to another
kubectl exec -it frontend-pod -- curl backend:5000/api/health/health
```

---

# 🧪 Testing & Quality

## Jest

### 1️⃣ Basics

**Q: What is Jest?**  
A: JavaScript testing framework by Facebook for unit and integration tests.

**Q: Why Jest?**  
A: Zero config, fast, built-in coverage, snapshot testing, great developer experience.

### 2️⃣ Project Usage

**Q: How is Jest used in ShopDeploy?**  
A: 
- Unit tests for backend controllers/services
- Unit tests for frontend components
- Coverage reports in CI pipeline
- Runs on every PR

### 3️⃣ Commands / Practical

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test file
npm test -- auth.test.js

# Run in watch mode
npm test -- --watch

# Update snapshots
npm test -- -u
```

---

## ESLint

### 1️⃣ Basics

**Q: What is ESLint?**  
A: Static analysis tool for identifying problematic JavaScript/TypeScript patterns.

**Q: Why ESLint?**  
A: Catches errors before runtime, enforces code style, prevents common mistakes.

### 2️⃣ Project Usage

**Q: How is ESLint used in ShopDeploy?**  
A: 
- Configured in `.eslintrc.cjs`
- Runs in CI pipeline before tests
- Fails build on linting errors
- VS Code integration for real-time feedback

### 3️⃣ Commands / Practical

```bash
# Lint all files
npm run lint

# Lint with auto-fix
npm run lint -- --fix

# Lint specific directory
npx eslint src/
```

---

# 🏛️ Architecture & Design

## Scalability Questions

**Q: How would you design ShopDeploy for 1 million users?**  
A: 
1. **Horizontal scaling**: HPA for pods, ASG for nodes
2. **Database**: MongoDB Atlas with sharding, read replicas
3. **Caching**: Redis for sessions, product catalog
4. **CDN**: CloudFront for static assets
5. **Queue**: SQS for order processing (decouple)
6. **Multi-region**: EKS in multiple regions with Route 53

**Q: How to reduce cloud costs?**  
A: 
1. Right-size instances (analyze actual usage)
2. Use Spot Instances for non-critical workloads
3. Reserved Instances/Savings Plans for baseline
4. Shut down dev/staging at night
5. Implement pod resource limits
6. Use Graviton (ARM) instances (20% cheaper)
7. S3 lifecycle policies for old data

## High Availability Questions

**Q: How to make this architecture highly available?**  
A: 
1. Multi-AZ deployment (already in place)
2. Multiple pod replicas with anti-affinity
3. PodDisruptionBudget for maintenance
4. Database replication
5. Health checks and auto-healing
6. Load balancer health checks
7. Multi-region for disaster recovery

**Q: What's the recovery process if us-east-1 goes down?**  
A: 
1. Route 53 health check detects failure
2. Traffic fails over to us-west-2
3. Cross-region database replication ensures data
4. Recovery Time Objective (RTO): < 5 minutes
5. Recovery Point Objective (RPO): < 1 minute (async replication)

## Security Architecture Questions

**Q: How to secure the CI/CD pipeline?**  
A: 
1. Jenkins credentials plugin for secrets
2. RBAC for Jenkins access
3. Signed commits requirement
4. Branch protection rules
5. Container image scanning (Trivy)
6. SonarQube security analysis
7. Least privilege IAM roles
8. Audit logging enabled

**Q: How would you implement zero-trust in this architecture?**  
A: 
1. mTLS between services (service mesh)
2. Network policies (deny by default)
3. IRSA for pod permissions (no static credentials)
4. Short-lived tokens
5. Continuous verification (not just perimeter)

---

## 📚 Quick Reference Card

### Emergency Commands

```bash
# Rollback Helm deployment
helm rollback <release> <revision> -n shopdeploy

# Rollback Kubernetes deployment
kubectl rollout undo deployment/<name> -n shopdeploy

# Scale to zero (emergency)
kubectl scale deployment --all --replicas=0 -n shopdeploy

# Delete pod (force recreate)
kubectl delete pod <pod-name> -n shopdeploy

# Get crash logs
kubectl logs <pod-name> --previous -n shopdeploy

# Force unlock Terraform
terraform force-unlock <LOCK_ID>

# Destroy specific resource
terraform destroy -target=aws_instance.example
```

### Debugging Checklist

1. **Pod not starting?**
   - `kubectl describe pod` → Check events
   - `kubectl logs` → Check application logs
   - `kubectl get events --sort-by=.lastTimestamp`

2. **Service not reachable?**
   - Check pod is Running: `kubectl get pods`
   - Check endpoints: `kubectl get endpoints`
   - Check service selector matches pod labels

3. **Image pull error?**
   - Check image exists in ECR
   - Check node IAM role permissions
   - Check imagePullSecrets

4. **High latency?**
   - Check HPA status (scaling?)
   - Check resource limits (throttling?)
   - Check database connection pool

---

*Created for ShopDeploy Project — DevOps Interview Preparation*  
*Last Updated: February 2026*
