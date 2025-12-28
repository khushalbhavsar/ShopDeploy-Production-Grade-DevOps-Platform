# 🎯 ShopDeploy DevOps Interview Questions & Answers

<p align="center">
  <img src="https://img.shields.io/badge/Questions-70-blue?style=for-the-badge" alt="Questions"/>
  <img src="https://img.shields.io/badge/Topics-DevOps-orange?style=for-the-badge" alt="DevOps"/>
  <img src="https://img.shields.io/badge/Level-Junior%20to%20Senior-green?style=for-the-badge" alt="Level"/>
</p>

This document contains 70 interview questions and answers based on the ShopDeploy e-commerce project's DevOps implementation. Questions cover Jenkins, Docker, Kubernetes, Terraform, AWS, Helm, and more.

---

## 📋 Table of Contents

- [Jenkins CI/CD (Questions 1-15)](#-jenkins-cicd-questions-1-15)
- [Docker & Containerization (Questions 16-28)](#-docker--containerization-questions-16-28)
- [Kubernetes & EKS (Questions 29-42)](#-kubernetes--eks-questions-29-42)
- [Terraform & IaC (Questions 43-52)](#-terraform--iac-questions-43-52)
- [Helm Charts (Questions 53-58)](#-helm-charts-questions-53-58)
- [AWS Services (Questions 59-65)](#-aws-services-questions-59-65)
- [Monitoring & Security (Questions 66-70)](#-monitoring--security-questions-66-70)

---

## 🔄 Jenkins CI/CD (Questions 1-15)

### Question 1: What is a Jenkins Pipeline and what are the two types?

**Answer:**
A Jenkins Pipeline is a suite of plugins that supports implementing and integrating continuous delivery pipelines into Jenkins. There are two types:

1. **Declarative Pipeline**: Uses a simplified, opinionated syntax with a predefined structure starting with `pipeline {}`. This is what ShopDeploy uses.

2. **Scripted Pipeline**: Uses Groovy-based syntax with more flexibility, starting with `node {}`.

```groovy
// Declarative (ShopDeploy uses this)
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building...'
            }
        }
    }
}
```

---

### Question 2: Explain the 16 stages in the ShopDeploy Jenkins pipeline.

**Answer:**
The ShopDeploy pipeline has 16 stages:

| Stage | Purpose |
|-------|---------|
| 1. Checkout | Clone source code from GitHub |
| 2. Detect Changes | Identify changes in backend/frontend |
| 3. Install Dependencies | npm ci for both services (parallel) |
| 4. Code Linting | ESLint checks (parallel) |
| 5. Unit Tests | Jest tests with coverage (parallel) |
| 6. SonarQube Analysis | Code quality analysis |
| 7. Quality Gate | Verify SonarQube standards |
| 8. Build Docker Images | Multi-stage Docker builds (parallel) |
| 9. Security Scan | Trivy vulnerability scanning |
| 10. Push to ECR | Push images to AWS ECR |
| 11. Deploy Dev/Staging | Helm deployment to non-prod |
| 12. Production Approval | Manual approval gate |
| 13. Deploy Production | Helm deployment to prod |
| 14. Smoke Tests | Verify deployment health |
| 15. Integration Tests | Run integration test suite |
| 16. Cleanup | Remove local Docker images |

---

### Question 3: What is the purpose of the `when` directive in Jenkins?

**Answer:**
The `when` directive defines conditions under which a stage should execute. In ShopDeploy:

```groovy
stage('Deploy to Dev/Staging') {
    when {
        expression { params.ENVIRONMENT != 'prod' }
    }
    // This stage only runs for dev/staging environments
}

stage('Production Approval') {
    when {
        expression { params.ENVIRONMENT == 'prod' }
    }
    // This stage only runs for production
}
```

Common `when` conditions:
- `branch 'main'` - Run only on main branch
- `expression { }` - Custom Groovy expression
- `environment name: 'VAR', value: 'value'`

---

### Question 4: How do you implement parallel execution in Jenkins?

**Answer:**
Use the `parallel` directive to run stages concurrently:

```groovy
stage('Build Docker Images') {
    parallel {
        stage('Build Backend Image') {
            steps {
                sh 'docker build -t backend:latest ./backend'
            }
        }
        stage('Build Frontend Image') {
            steps {
                sh 'docker build -t frontend:latest ./frontend'
            }
        }
    }
}
```

Benefits:
- Reduces total pipeline duration
- Better resource utilization
- Independent operations can fail separately

---

### Question 5: What is the difference between `sh` and `script` blocks in Jenkins?

**Answer:**

**`sh` block**: Executes shell commands directly
```groovy
sh 'npm install'
sh '''
    npm test
    npm run build
'''
```

**`script` block**: Allows Groovy scripting for complex logic
```groovy
script {
    def scannerExists = sh(script: 'command -v sonar-scanner', returnStatus: true) == 0
    if (!scannerExists) {
        echo 'Scanner not found'
    }
}
```

Use `script` when you need:
- Conditional logic (if/else)
- Variable manipulation
- Loops
- Exception handling

---

### Question 6: How do you handle credentials securely in Jenkins?

**Answer:**
Jenkins provides the `credentials()` function and `withCredentials` block:

```groovy
environment {
    AWS_ACCOUNT_ID = credentials('aws-account-id')
}

stage('Push to ECR') {
    steps {
        withCredentials([[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: 'aws-credentials',
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
            sh 'aws ecr get-login-password | docker login ...'
        }
    }
}
```

Best practices:
- Never hardcode credentials
- Use Jenkins Credentials Store
- Limit credential scope
- Rotate credentials regularly

---

### Question 7: What is the `input` step and how is it used for approvals?

**Answer:**
The `input` step pauses pipeline execution and waits for user input:

```groovy
stage('Production Approval') {
    steps {
        timeout(time: 30, unit: 'MINUTES') {
            input(
                message: 'Deploy to PRODUCTION?',
                ok: 'Approve Deployment',
                submitter: 'admin,devops-team',
                submitterParameter: 'APPROVER'
            )
        }
        echo "Approved by ${env.APPROVER}"
    }
}
```

Key parameters:
- `message`: Displayed to approver
- `submitter`: Comma-separated list of allowed users
- `timeout`: Auto-reject after specified time

---

### Question 8: Explain Jenkins pipeline parameters and their types.

**Answer:**
Parameters allow customizing pipeline behavior at runtime:

```groovy
parameters {
    choice(
        name: 'ENVIRONMENT',
        choices: ['dev', 'staging', 'prod'],
        description: 'Target deployment environment'
    )
    booleanParam(
        name: 'SKIP_TESTS',
        defaultValue: false,
        description: 'Skip running unit tests'
    )
    string(
        name: 'IMAGE_TAG',
        defaultValue: 'latest',
        description: 'Docker image tag'
    )
}
```

Access parameters: `params.ENVIRONMENT`, `params.SKIP_TESTS`

Types: `choice`, `booleanParam`, `string`, `password`, `file`

---

### Question 9: What is `cleanWs()` and why is it important?

**Answer:**
`cleanWs()` cleans the Jenkins workspace after build completion:

```groovy
post {
    always {
        cleanWs(
            cleanWhenNotBuilt: false,
            deleteDirs: true,
            disableDeferredWipeout: true,
            notFailBuild: true
        )
    }
}
```

Importance:
- **Disk space**: Prevents workspace accumulation
- **Clean builds**: Avoids stale files affecting builds
- **Security**: Removes sensitive data after builds
- **Consistency**: Each build starts fresh

---

### Question 10: How do you configure Jenkins to trigger on GitHub push?

**Answer:**
Configure webhook-based triggers:

```groovy
triggers {
    githubPush()  // Trigger on GitHub webhook
    // pollSCM('H/5 * * * *')  // Alternative: poll every 5 min
}
```

Setup steps:
1. Install GitHub plugin in Jenkins
2. Configure GitHub webhook: `http://jenkins-url/github-webhook/`
3. Set webhook content type to `application/json`
4. Select "Just the push event"

---

### Question 11: What are Jenkins post-build actions?

**Answer:**
Post-build actions execute after all stages complete:

```groovy
post {
    success {
        echo 'Pipeline succeeded!'
        // slackSend(channel: '#deployments', color: 'good', message: 'Success')
    }
    failure {
        echo 'Pipeline failed!'
        // Trigger rollback for production
    }
    unstable {
        echo 'Pipeline unstable (test failures)'
    }
    always {
        archiveArtifacts artifacts: '**/coverage/**', allowEmptyArchive: true
        cleanWs()
    }
}
```

Conditions: `success`, `failure`, `unstable`, `aborted`, `always`, `changed`

---

### Question 12: How do you archive test results in Jenkins?

**Answer:**
Use `junit` and `archiveArtifacts` steps:

```groovy
post {
    always {
        // Publish JUnit test results
        junit allowEmptyResults: true, testResults: 'coverage/junit.xml'
        
        // Archive coverage reports
        archiveArtifacts artifacts: '**/coverage/**', allowEmptyArchive: true
        
        // Publish HTML reports
        publishHTML(target: [
            reportName: 'Coverage Report',
            reportDir: 'coverage/lcov-report',
            reportFiles: 'index.html'
        ])
    }
}
```

---

### Question 13: What is the purpose of `timeout` in Jenkins pipeline?

**Answer:**
Timeout prevents indefinite pipeline execution:

```groovy
options {
    timeout(time: 60, unit: 'MINUTES')  // Global timeout
}

stage('Deploy') {
    options {
        timeout(time: 10, unit: 'MINUTES')  // Stage-specific timeout
    }
    steps {
        sh 'helm upgrade --install --timeout 5m ...'
    }
}
```

This prevents:
- Hung builds consuming resources
- Blocking concurrent builds
- Wasted compute time

---

### Question 14: How do you install tools dynamically in Jenkins pipeline?

**Answer:**
ShopDeploy installs kubectl and Helm dynamically:

```groovy
sh '''
    mkdir -p ${WORKSPACE}/bin
    export PATH=${WORKSPACE}/bin:$PATH
    
    # Install kubectl if not present
    if [ ! -f ${WORKSPACE}/bin/kubectl ]; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl ${WORKSPACE}/bin/
    fi
    
    # Install Helm
    if ! command -v helm &> /dev/null; then
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | \
            HELM_INSTALL_DIR=${WORKSPACE}/bin USE_SUDO=false bash
    fi
'''
```

---

### Question 15: What is the difference between `agent any` and `agent { label 'node-name' }`?

**Answer:**

```groovy
// Run on any available agent
agent any

// Run on agent with specific label
agent { label 'linux && docker' }

// Run in Docker container
agent {
    docker {
        image 'node:18-alpine'
        args '-v /var/run/docker.sock:/var/run/docker.sock'
    }
}

// No agent (for stages that don't need executor)
agent none
```

Use labels when:
- Specific tools are required
- OS-specific builds
- Hardware requirements (GPU, memory)
- Security isolation

---

## 🐳 Docker & Containerization (Questions 16-28)

### Question 16: What is a multi-stage Docker build and why use it?

**Answer:**
Multi-stage builds create smaller, secure production images:

```dockerfile
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production (only includes built artifacts)
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
CMD ["node", "dist/server.js"]
```

Benefits:
- **Smaller images**: Only production dependencies
- **Security**: No build tools in final image
- **Faster deployments**: Less data to transfer
- **Cache efficiency**: Layers can be cached

---

### Question 17: Explain the ShopDeploy backend Dockerfile.

**Answer:**
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app
RUN apk add --no-cache curl  # For health checks
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
COPY --from=builder /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs . .
USER nodejs
EXPOSE 5000
CMD ["node", "src/server.js"]
```

Key points:
- Alpine base for small image (~200MB)
- Non-root user for security
- Health check support with curl
- Production dependencies only

---

### Question 18: What is the purpose of .dockerignore file?

**Answer:**
`.dockerignore` excludes files from Docker build context:

```
node_modules
npm-debug.log
.git
.env
.env.local
coverage
*.md
Dockerfile
.dockerignore
```

Benefits:
- **Faster builds**: Less data to transfer
- **Smaller context**: Reduced build time
- **Security**: Prevents secrets from being included
- **Consistency**: Avoids local artifacts in images

---

### Question 19: How do you pass build arguments to Docker?

**Answer:**
Use `ARG` and `--build-arg`:

```dockerfile
# Dockerfile
ARG BUILD_DATE
ARG VERSION
ARG VITE_API_URL

ENV VITE_API_URL=$VITE_API_URL

LABEL build-date=$BUILD_DATE
LABEL version=$VERSION
```

```bash
docker build \
    --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg VERSION=1.0.0 \
    --build-arg VITE_API_URL=https://api.example.com \
    -t myapp:1.0.0 .
```

---

### Question 20: What is Docker layer caching and how to optimize it?

**Answer:**
Docker caches each layer; unchanged layers are reused:

```dockerfile
# ❌ Bad: Invalidates cache on any file change
COPY . .
RUN npm install

# ✅ Good: Dependencies cached separately
COPY package*.json ./
RUN npm ci
COPY . .
```

Optimization tips:
1. Order from least to most frequently changed
2. Combine RUN commands to reduce layers
3. Use specific base image tags
4. Separate dependency installation from code copy

---

### Question 21: How do you run containers as non-root user?

**Answer:**
```dockerfile
# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Change ownership of application files
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Container runs as appuser (UID 1001)
CMD ["node", "server.js"]
```

Why non-root?
- Security best practice
- Limits damage from container breakout
- Required in many Kubernetes clusters
- Compliance requirements

---

### Question 22: Explain Docker Compose for local development.

**Answer:**
ShopDeploy's `docker-compose.yml`:

```yaml
version: '3.8'
services:
  backend:
    build: ./shopdeploy-backend
    ports:
      - "5000:5000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/shopdeploy
    depends_on:
      - mongo
    
  frontend:
    build: ./shopdeploy-frontend
    ports:
      - "3000:80"
    depends_on:
      - backend
    
  mongo:
    image: mongo:6
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
```

Commands:
- `docker-compose up -d`: Start all services
- `docker-compose logs -f`: View logs
- `docker-compose down`: Stop and remove

---

### Question 23: How do you tag Docker images for different environments?

**Answer:**
```bash
# Tag with build number and git commit
IMAGE_TAG="${BUILD_NUMBER}-${GIT_COMMIT:0:7}"  # e.g., 42-abc1234

# Tag and push
docker tag myapp:${IMAGE_TAG} registry/myapp:${IMAGE_TAG}
docker tag myapp:${IMAGE_TAG} registry/myapp:latest

# Environment-specific tags
docker tag myapp:${IMAGE_TAG} registry/myapp:dev
docker tag myapp:${IMAGE_TAG} registry/myapp:staging
docker tag myapp:${IMAGE_TAG} registry/myapp:prod
```

Best practices:
- Never use only `latest` in production
- Include git SHA for traceability
- Use semantic versioning for releases

---

### Question 24: What is the difference between CMD and ENTRYPOINT?

**Answer:**
```dockerfile
# ENTRYPOINT: Defines the executable (harder to override)
ENTRYPOINT ["node"]
CMD ["server.js"]
# Runs: node server.js
# Override: docker run myapp test.js → node test.js

# CMD: Default command (easily overridden)
CMD ["node", "server.js"]
# Override: docker run myapp npm test → npm test
```

Use cases:
- `ENTRYPOINT`: When container is a specific executable
- `CMD`: Default behavior with easy override
- Combined: `ENTRYPOINT` + `CMD` for default arguments

---

### Question 25: How do you inspect Docker image layers?

**Answer:**
```bash
# View image history (layers)
docker history myapp:latest

# Inspect image metadata
docker inspect myapp:latest

# View image size
docker images myapp

# Analyze with dive tool
dive myapp:latest

# Export and inspect filesystem
docker save myapp:latest | tar -tvf -
```

Why inspect?
- Optimize image size
- Debug build issues
- Security auditing
- Understand layer composition

---

### Question 26: What are Docker health checks?

**Answer:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
  CMD curl -f http://localhost:5000/api/health/health || exit 1
```

Parameters:
- `interval`: Time between checks (30s)
- `timeout`: Max time for check to complete (10s)
- `retries`: Failures before unhealthy (3)
- `start-period`: Grace period at startup (40s)

Kubernetes ignores Dockerfile HEALTHCHECK; use probe configuration instead.

---

### Question 27: How do you clean up Docker resources?

**Answer:**
ShopDeploy cleanup stage:

```groovy
sh '''
    # Remove specific images
    docker rmi shopdeploy-backend:${IMAGE_TAG} || true
    docker rmi shopdeploy-frontend:${IMAGE_TAG} || true
    
    # Prune dangling images
    docker image prune -f
    
    # Full system cleanup (use cautiously)
    # docker system prune -af --volumes
'''
```

Commands:
- `docker image prune`: Remove dangling images
- `docker container prune`: Remove stopped containers
- `docker volume prune`: Remove unused volumes
- `docker system prune -a`: Remove all unused resources

---

### Question 28: What is the difference between COPY and ADD in Dockerfile?

**Answer:**
```dockerfile
# COPY: Simple file copy (preferred)
COPY package*.json ./
COPY src/ ./src/

# ADD: Additional features
ADD https://example.com/file.tar.gz /tmp/  # URL download
ADD archive.tar.gz /app/                    # Auto-extraction
```

Best practices:
- Use `COPY` for simple file copying
- Use `ADD` only for tar extraction or URL download
- `COPY` is more transparent and predictable

---

## ☸️ Kubernetes & EKS (Questions 29-42)

### Question 29: What is the difference between Deployment and StatefulSet?

**Answer:**
| Feature | Deployment | StatefulSet |
|---------|------------|-------------|
| Pod identity | Random names | Stable, ordered names (app-0, app-1) |
| Storage | Shared/none | Dedicated PVC per pod |
| Scaling | Any order | Ordered (0→1→2) |
| Use case | Stateless apps | Databases, queues |

ShopDeploy examples:
- **Deployment**: Backend API, Frontend
- **StatefulSet**: MongoDB

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
spec:
  serviceName: mongodb
  replicas: 1
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        storageClassName: gp2
        resources:
          requests:
            storage: 10Gi
```

---

### Question 30: Explain Kubernetes liveness and readiness probes.

**Answer:**
```yaml
spec:
  containers:
    - name: backend
      livenessProbe:        # Restart if fails
        httpGet:
          path: /api/health/health
          port: 5000
        initialDelaySeconds: 30
        periodSeconds: 30
        failureThreshold: 5
        
      readinessProbe:       # Remove from LB if fails
        httpGet:
          path: /api/health/ready
          port: 5000
        initialDelaySeconds: 5
        periodSeconds: 10
        failureThreshold: 3
```

| Probe | Purpose | Action on Failure |
|-------|---------|-------------------|
| Liveness | Is container alive? | Restart container |
| Readiness | Is container ready? | Remove from Service |
| Startup | Has container started? | Block other probes |

---

### Question 31: What is a Kubernetes Service and its types?

**Answer:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP  # or NodePort, LoadBalancer, ExternalName
  selector:
    app: backend
  ports:
    - port: 5000
      targetPort: 5000
```

Types:
- **ClusterIP**: Internal only (default)
- **NodePort**: Exposes on node IP:port (30000-32767)
- **LoadBalancer**: Cloud provider LB (AWS ALB/NLB)
- **ExternalName**: DNS CNAME mapping

ShopDeploy uses ClusterIP with Ingress for external access.

---

### Question 32: How does Horizontal Pod Autoscaler (HPA) work?

**Answer:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
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
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

Requirements:
- Metrics Server installed
- Resource requests defined on pods
- Target deployment must exist

---

### Question 33: What is a Kubernetes ConfigMap and Secret?

**Answer:**
```yaml
# ConfigMap: Non-sensitive configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  NODE_ENV: "production"
  LOG_LEVEL: "info"
  
---
# Secret: Sensitive data (base64 encoded)
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
type: Opaque
stringData:  # or data: with base64 values
  MONGODB_URI: "mongodb://..."
  JWT_SECRET: "super-secret-key"
```

Usage in pod:
```yaml
envFrom:
  - configMapRef:
      name: backend-config
  - secretRef:
      name: backend-secrets
```

---

### Question 34: Explain Kubernetes Ingress and its purpose.

**Answer:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shopdeploy-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
spec:
  rules:
    - host: api.shopdeploy.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port:
                  number: 5000
    - host: shopdeploy.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port:
                  number: 80
```

Ingress provides:
- HTTP/HTTPS routing
- SSL termination
- Path-based routing
- Virtual hosting

---

### Question 35: What is a Kubernetes Namespace and why use it?

**Answer:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: shopdeploy
  labels:
    environment: production
```

Benefits:
- **Isolation**: Separate environments (dev, staging, prod)
- **Resource quotas**: Limit resources per namespace
- **RBAC**: Access control per namespace
- **Organization**: Logical grouping of resources

```bash
# Create namespace
kubectl create namespace shopdeploy

# Deploy to specific namespace
kubectl apply -f deployment.yaml -n shopdeploy

# Set default namespace
kubectl config set-context --current --namespace=shopdeploy
```

---

### Question 36: How do you perform a rolling update in Kubernetes?

**Answer:**
```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%  # Max pods that can be unavailable
      maxSurge: 25%        # Max pods over desired count
```

```bash
# Update image
kubectl set image deployment/backend backend=image:v2

# Check rollout status
kubectl rollout status deployment/backend

# View rollout history
kubectl rollout history deployment/backend

# Rollback to previous version
kubectl rollout undo deployment/backend

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2
```

---

### Question 37: What is a Pod Disruption Budget (PDB)?

**Answer:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: backend-pdb
spec:
  minAvailable: 2          # or maxUnavailable: 1
  selector:
    matchLabels:
      app: shopdeploy-backend
```

PDB ensures:
- Minimum pods available during voluntary disruptions
- Safe node drains during upgrades
- Controlled evictions

Use cases:
- Cluster autoscaler node removal
- Node maintenance
- Kubernetes upgrades

---

### Question 38: How do you manage resource limits in Kubernetes?

**Answer:**
```yaml
# Pod-level resources
spec:
  containers:
    - name: backend
      resources:
        requests:          # Guaranteed resources
          cpu: "100m"
          memory: "128Mi"
        limits:            # Maximum allowed
          cpu: "500m"
          memory: "512Mi"

---
# Namespace-level quota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: shopdeploy-quota
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "20"
```

---

### Question 39: What is AWS EKS and its components?

**Answer:**
Amazon EKS (Elastic Kubernetes Service) is a managed Kubernetes service.

Components:
1. **Control Plane**: AWS-managed (API server, etcd, controllers)
2. **Worker Nodes**: EC2 instances or Fargate
3. **Node Groups**: Auto-scaling groups of EC2 instances
4. **Add-ons**: CoreDNS, kube-proxy, VPC CNI

ShopDeploy EKS configuration:
```hcl
resource "aws_eks_cluster" "main" {
  name     = "shopdeploy-prod-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.29"
  
  vpc_config {
    subnet_ids = var.private_subnet_ids
  }
}
```

---

### Question 40: How do you connect kubectl to EKS?

**Answer:**
```bash
# Update kubeconfig
aws eks update-kubeconfig \
    --region us-east-1 \
    --name shopdeploy-prod-eks

# Verify connection
kubectl get nodes
kubectl cluster-info

# Check current context
kubectl config current-context
```

The command modifies `~/.kube/config` with:
- Cluster endpoint
- Certificate authority data
- AWS IAM authenticator config

---

### Question 41: What are Kubernetes Network Policies?

**Answer:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - port: 5000
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: mongodb
      ports:
        - port: 27017
```

This policy:
- Allows frontend → backend on port 5000
- Allows backend → MongoDB on port 27017
- Denies all other traffic

---

### Question 42: How do you debug pods in Kubernetes?

**Answer:**
```bash
# Check pod status
kubectl get pods -n shopdeploy

# View pod details
kubectl describe pod <pod-name> -n shopdeploy

# View logs
kubectl logs <pod-name> -n shopdeploy
kubectl logs <pod-name> -n shopdeploy --previous  # Previous container

# Execute command in pod
kubectl exec -it <pod-name> -n shopdeploy -- /bin/sh

# Port forward for testing
kubectl port-forward pod/<pod-name> 5000:5000 -n shopdeploy

# Check events
kubectl get events -n shopdeploy --sort-by='.lastTimestamp'
```

---

## 🏗️ Terraform & IaC (Questions 43-52)

### Question 43: What is Infrastructure as Code and why use Terraform?

**Answer:**
IaC manages infrastructure through code rather than manual processes.

Terraform benefits:
- **Version Control**: Track infrastructure changes
- **Reproducibility**: Create identical environments
- **Automation**: Eliminate manual configuration
- **Documentation**: Code documents infrastructure
- **Collaboration**: Team review via PRs
- **Multi-cloud**: Works with AWS, Azure, GCP

ShopDeploy uses Terraform for:
- VPC networking
- EKS cluster
- ECR repositories
- IAM roles

---

### Question 44: Explain Terraform state and its importance.

**Answer:**
Terraform state (`terraform.tfstate`) tracks:
- Real-world resource mappings
- Resource metadata
- Dependencies between resources

```hcl
# Remote state backend (recommended)
terraform {
  backend "s3" {
    bucket         = "shopdeploy-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # State locking
  }
}
```

Best practices:
- Use remote backend for team access
- Enable state locking (DynamoDB)
- Encrypt state at rest
- Never commit state to Git

---

### Question 45: What is the difference between `terraform plan` and `terraform apply`?

**Answer:**
```bash
# Plan: Preview changes (no modifications)
terraform plan -out=tfplan
# Shows: + create, ~ modify, - destroy

# Apply: Execute changes
terraform apply tfplan
# or
terraform apply -auto-approve  # Skip confirmation
```

Workflow:
1. `terraform init` - Initialize providers
2. `terraform plan` - Preview changes
3. Review the plan carefully
4. `terraform apply` - Create resources
5. `terraform destroy` - Remove resources

---

### Question 46: How do you organize Terraform code with modules?

**Answer:**
ShopDeploy module structure:
```
terraform/
├── main.tf           # Module calls
├── variables.tf      # Input variables
├── outputs.tf        # Outputs
└── modules/
    ├── vpc/          # VPC module
    ├── iam/          # IAM module
    ├── ecr/          # ECR module
    └── eks/          # EKS module
```

```hcl
# main.tf
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr         = var.vpc_cidr
  environment      = var.environment
  private_subnets  = var.private_subnet_cidrs
  public_subnets   = var.public_subnet_cidrs
}

module "eks" {
  source = "./modules/eks"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
}
```

---

### Question 47: What are Terraform variables and outputs?

**Answer:**
```hcl
# variables.tf - Input variables
variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium", "t3.large"]
}

# outputs.tf - Export values
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}
```

---

### Question 48: How do you manage multiple environments with Terraform?

**Answer:**
**Option 1: Terraform Workspaces**
```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select prod
terraform apply -var-file=prod.tfvars
```

**Option 2: Directory Structure**
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
└── modules/
```

**Option 3: Variable Files**
```bash
terraform apply -var-file=environments/prod.tfvars
```

---

### Question 49: What is Terraform data source?

**Answer:**
Data sources fetch information from existing resources:

```hcl
# Fetch existing VPC
data "aws_vpc" "existing" {
  id = "vpc-123456"
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use data sources
resource "aws_subnet" "private" {
  vpc_id            = data.aws_vpc.existing.id
  availability_zone = data.aws_availability_zones.available.names[0]
}
```

---

### Question 50: How do you handle secrets in Terraform?

**Answer:**
```hcl
# Option 1: Variable marked sensitive
variable "db_password" {
  type      = string
  sensitive = true  # Won't show in logs/output
}

# Option 2: AWS Secrets Manager
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "prod/db-password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db.secret_string
}

# Option 3: Environment variable
# export TF_VAR_db_password="secret"
```

Never commit secrets to Git!

---

### Question 51: What is `terraform import` and when to use it?

**Answer:**
Import brings existing resources under Terraform management:

```bash
# Import existing VPC
terraform import aws_vpc.main vpc-123456789

# Import EKS cluster
terraform import aws_eks_cluster.main shopdeploy-prod-eks

# Import ECR repository
terraform import aws_ecr_repository.backend shopdeploy-backend
```

Then create matching configuration:
```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  # Match existing configuration
}
```

Use cases:
- Migrating manually created resources
- Disaster recovery
- Adopting IaC for existing infrastructure

---

### Question 52: How do you handle Terraform provider versions?

**Answer:**
```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Any 5.x version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "ShopDeploy"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
```

Version constraints:
- `= 5.0.0`: Exact version
- `>= 5.0`: Version 5.0 or higher
- `~> 5.0`: Any 5.x (pessimistic)

---

## ⎈ Helm Charts (Questions 53-58)

### Question 53: What is Helm and why use it?

**Answer:**
Helm is a package manager for Kubernetes.

Benefits:
- **Templating**: Dynamic Kubernetes manifests
- **Packaging**: Bundle related resources
- **Versioning**: Track releases and rollback
- **Reusability**: Share charts across teams
- **Configuration**: Environment-specific values

ShopDeploy Helm structure:
```
helm/
├── backend/
│   ├── Chart.yaml          # Chart metadata
│   ├── values.yaml         # Default values
│   ├── values-dev.yaml     # Dev overrides
│   ├── values-prod.yaml    # Prod overrides
│   └── templates/          # K8s manifests
└── frontend/
```

---

### Question 54: Explain Helm chart values and overrides.

**Answer:**
```yaml
# values.yaml (defaults)
replicaCount: 1
image:
  repository: shopdeploy-backend
  tag: latest
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 100m
    memory: 128Mi

# values-prod.yaml (production overrides)
replicaCount: 3
resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
```

Override priority (highest to lowest):
1. `--set` command line
2. `-f values-prod.yaml`
3. `values.yaml` defaults

```bash
helm upgrade --install backend ./helm/backend \
    -f values-prod.yaml \
    --set image.tag=v1.2.3
```

---

### Question 55: How do Helm templates work?

**Answer:**
```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-{{ .Chart.Name }}
  labels:
    {{- include "backend.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          {{- if .Values.resources }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          {{- end }}
```

Template functions:
- `{{ .Values.x }}`: Access values
- `{{ .Release.Name }}`: Release name
- `{{ include "template" . }}`: Include helper
- `{{- toYaml . | nindent 4 }}`: YAML formatting

---

### Question 56: What is the difference between `helm install` and `helm upgrade --install`?

**Answer:**
```bash
# install: Fails if release exists
helm install backend ./helm/backend

# upgrade: Fails if release doesn't exist
helm upgrade backend ./helm/backend

# upgrade --install: Creates or updates (idempotent)
helm upgrade --install backend ./helm/backend \
    --namespace shopdeploy \
    --values values-dev.yaml \
    --wait \
    --timeout 5m
```

CI/CD best practice: Always use `helm upgrade --install` for idempotency.

---

### Question 57: How do you rollback a Helm release?

**Answer:**
```bash
# View release history
helm history backend -n shopdeploy

# Rollback to previous version
helm rollback backend -n shopdeploy

# Rollback to specific revision
helm rollback backend 3 -n shopdeploy

# Rollback with wait
helm rollback backend 3 -n shopdeploy --wait --timeout 5m
```

Helm stores release history in Kubernetes Secrets (default: 10 revisions).

---

### Question 58: How do you debug Helm chart issues?

**Answer:**
```bash
# Render templates locally (dry-run)
helm template backend ./helm/backend -f values-dev.yaml

# Validate chart
helm lint ./helm/backend

# Debug install (verbose output)
helm install backend ./helm/backend --debug --dry-run

# Get rendered manifests of installed release
helm get manifest backend -n shopdeploy

# Get values used in release
helm get values backend -n shopdeploy

# Check release status
helm status backend -n shopdeploy
```

---

## ☁️ AWS Services (Questions 59-65)

### Question 59: What is AWS ECR and how is it used?

**Answer:**
ECR (Elastic Container Registry) is AWS's Docker registry.

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    123456789.dkr.ecr.us-east-1.amazonaws.com

# Tag and push image
docker tag myapp:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

Terraform configuration:
```hcl
resource "aws_ecr_repository" "backend" {
  name                 = "shopdeploy-prod-backend"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
}
```

---

### Question 60: Explain AWS VPC components for EKS.

**Answer:**
ShopDeploy VPC architecture:

| Component | Purpose |
|-----------|---------|
| VPC | Isolated network (10.0.0.0/16) |
| Public Subnets | NAT Gateway, Load Balancers |
| Private Subnets | EKS worker nodes |
| Internet Gateway | Public internet access |
| NAT Gateway | Private subnet outbound access |
| Route Tables | Traffic routing rules |

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

---

### Question 61: What IAM roles are needed for EKS?

**Answer:**
```hcl
# EKS Cluster Role
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Node Role
resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-role"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}
```

Required policies:
- AmazonEKSClusterPolicy
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly

---

### Question 62: How does AWS Load Balancer Controller work with EKS?

**Answer:**
AWS Load Balancer Controller creates ALB/NLB from Kubernetes Ingress/Service.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
spec:
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

Installation:
```bash
helm install aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=shopdeploy-prod-eks
```

---

### Question 63: What is IRSA (IAM Roles for Service Accounts)?

**Answer:**
IRSA allows Kubernetes pods to assume IAM roles without access keys.

```hcl
# Create OIDC provider
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

# Create role with trust policy
resource "aws_iam_role" "s3_access" {
  name = "eks-s3-access"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:default:my-service-account"
        }
      }
    }]
  })
}
```

---

### Question 64: How do you estimate AWS EKS costs?

**Answer:**
ShopDeploy cost estimation:

| Resource | Dev | Prod | Notes |
|----------|-----|------|-------|
| EKS Control Plane | $73/mo | $73/mo | Fixed price |
| EC2 t3.medium (x3) | $90/mo | $120/mo | Worker nodes |
| NAT Gateway | $32/mo | $96/mo | 1 vs 3 AZs |
| ECR Storage | $1/mo | $5/mo | Image storage |
| ALB | $16/mo | $16/mo | Load balancer |
| Data Transfer | $10/mo | $50/mo | Variable |
| **Total** | **~$222** | **~$360** | |

Cost optimization:
- Use Spot instances for non-prod
- Single NAT Gateway in dev
- Right-size instance types
- Enable Cluster Autoscaler

---

### Question 65: What is EKS cluster autoscaling?

**Answer:**
Two types of autoscaling:

**1. Cluster Autoscaler** (nodes):
```yaml
# Scales nodes based on pending pods
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
spec:
  template:
    spec:
      containers:
        - name: cluster-autoscaler
          image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.26.0
          command:
            - ./cluster-autoscaler
            - --cloud-provider=aws
            - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled
```

**2. HPA** (pods):
```yaml
# Scales pods based on metrics
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
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

---

## 🔒 Monitoring & Security (Questions 66-70)

### Question 66: How do you set up Prometheus monitoring for EKS?

**Answer:**
```bash
# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Install Prometheus stack
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    -f prometheus-values.yaml
```

```yaml
# prometheus-values.yaml
prometheus:
  prometheusSpec:
    retention: 15d
    serviceMonitorSelector: {}
    
grafana:
  adminPassword: "secure-password"
  
alertmanager:
  enabled: true
```

Access Grafana:
```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

---

### Question 67: What is Trivy and how is it used for security scanning?

**Answer:**
Trivy scans container images for vulnerabilities:

```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh

# Scan image
trivy image --severity HIGH,CRITICAL shopdeploy-backend:latest

# Table output
trivy image --format table shopdeploy-backend:latest

# JSON output (for CI/CD)
trivy image --format json --output results.json shopdeploy-backend:latest

# Fail build on vulnerabilities
trivy image --exit-code 1 --severity CRITICAL shopdeploy-backend:latest
```

Jenkins integration:
```groovy
sh 'trivy image --severity HIGH,CRITICAL --exit-code 0 ${IMAGE_TAG}'
```

---

### Question 68: How do you implement SonarQube code analysis?

**Answer:**
```groovy
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh '''
                sonar-scanner \
                    -Dsonar.projectKey=shopdeploy \
                    -Dsonar.projectName=ShopDeploy \
                    -Dsonar.sources=. \
                    -Dsonar.exclusions=node_modules/**,coverage/** \
                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
            '''
        }
    }
}

stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

SonarQube checks:
- Code smells
- Bugs
- Security vulnerabilities
- Code coverage
- Duplications

---

### Question 69: What are Kubernetes security best practices?

**Answer:**
1. **Run as non-root**:
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
```

2. **Read-only filesystem**:
```yaml
securityContext:
  readOnlyRootFilesystem: true
```

3. **Drop capabilities**:
```yaml
securityContext:
  capabilities:
    drop:
      - ALL
```

4. **Network policies**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
spec:
  policyTypes:
    - Ingress
    - Egress
```

5. **Resource limits**: Prevent DoS
6. **Secrets encryption**: Enable etcd encryption
7. **RBAC**: Least privilege access
8. **Pod Security Standards**: Enforce baseline/restricted

---

### Question 70: How do you implement GitOps with this project?

**Answer:**
GitOps principles for ShopDeploy:

**1. Declarative Configuration**:
- All infrastructure in Terraform
- All deployments in Helm/k8s manifests
- All config in Git

**2. Git as Single Source of Truth**:
```
repository/
├── terraform/        # Infrastructure
├── k8s/              # Kubernetes manifests
├── helm/             # Helm charts
└── Jenkinsfile       # CI/CD pipeline
```

**3. Automated Reconciliation** (ArgoCD):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: shopdeploy
spec:
  source:
    repoURL: https://github.com/org/shopdeploy
    path: helm/backend
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: shopdeploy
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**4. Pull-based Deployments**:
- Changes pushed to Git
- ArgoCD/Flux detects changes
- Automatically syncs to cluster

Benefits:
- Audit trail for all changes
- Easy rollback (git revert)
- Consistent environments
- Enhanced security (no direct cluster access)

---

## 📝 Summary

This document covered 70 DevOps interview questions across:

| Category | Questions |
|----------|-----------|
| Jenkins CI/CD | 1-15 |
| Docker | 16-28 |
| Kubernetes/EKS | 29-42 |
| Terraform | 43-52 |
| Helm | 53-58 |
| AWS Services | 59-65 |
| Security/Monitoring | 66-70 |

All questions are based on real ShopDeploy implementation patterns and industry best practices.

---

<p align="center">
  <b>Good luck with your interview! 🚀</b>
</p>
