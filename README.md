# 🛒 ShopDeploy - E-Commerce Application

<p align="center">
  <img src="https://img.shields.io/badge/React-18.x-61DAFB?style=for-the-badge&logo=react" alt="React"/>
  <img src="https://img.shields.io/badge/Node.js-18.x-339933?style=for-the-badge&logo=node.js" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Express-4.x-000000?style=for-the-badge&logo=express" alt="Express"/>
  <img src="https://img.shields.io/badge/MongoDB-8.x-47A248?style=for-the-badge&logo=mongodb" alt="MongoDB"/>
  <img src="https://img.shields.io/badge/Docker-Containerized-2496ED?style=for-the-badge&logo=docker" alt="Docker"/>
  <img src="https://img.shields.io/badge/Kubernetes-EKS-326CE5?style=for-the-badge&logo=kubernetes" alt="Kubernetes"/>
  <img src="https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform" alt="Terraform"/>
  <img src="https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins" alt="Jenkins"/>
  <img src="https://img.shields.io/badge/Amazon_Linux-2023-FF9900?style=for-the-badge&logo=amazon-aws" alt="Amazon Linux"/>
</p>

<p align="center">
  <b>A production-ready full-stack e-commerce application with complete DevOps implementation including CI/CD, Kubernetes deployment, Infrastructure as Code, and cloud-native infrastructure on AWS.</b>
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Amazon Linux Setup (Quick Start)](#-amazon-linux-setup-quick-start)
- [Getting Started](#-getting-started)
- [Local Development](#-local-development)
- [Docker Deployment](#-docker-deployment)
- [Kubernetes Deployment](#-kubernetes-deployment)
- [Infrastructure (Terraform)](#-infrastructure-terraform)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Monitoring](#-monitoring)
- [API Documentation](#-api-documentation)
- [Environment Variables](#-environment-variables)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**ShopDeploy** is a modern, production-ready e-commerce platform built with the MERN stack (MongoDB, Express, React, Node.js). This project demonstrates enterprise-level development practices and includes a comprehensive DevOps implementation:

| Component | Technology | Purpose |
|-----------|------------|---------|
| 🏗️ **Infrastructure as Code** | Terraform | Automated AWS infrastructure provisioning |
| 🐳 **Containerization** | Docker | Consistent application packaging |
| ☸️ **Orchestration** | AWS EKS (Kubernetes) | Container orchestration & scaling |
| 🔄 **CI/CD Pipeline** | Jenkins | Automated build, test, and deployment |
| 📊 **Monitoring** | Prometheus & Grafana | Metrics collection and visualization |
| 📦 **Package Management** | Helm Charts | Kubernetes application packaging |
| 🔐 **Security** | JWT, HTTPS, IAM Roles | Authentication and authorization |

---

## ✨ Features

### Customer Features
- 🛍️ Browse products by categories
- 🔍 Search and filter products
- 🛒 Shopping cart management
- 💳 Secure checkout with Stripe
- 📦 Order tracking and history
- 👤 User authentication (JWT)
- 📱 Responsive design

### Admin Features
- 📊 Admin dashboard
- 📦 Product management (CRUD)
- 📋 Order management
- 👥 User management
- 📈 Sales analytics

### Technical Features
- 🔐 JWT-based authentication with refresh tokens
- 🖼️ Image upload with Cloudinary
- 💳 Payment processing with Stripe
- 📧 Email notifications
- 🔄 Real-time updates
- 📱 Mobile-responsive UI

---

## 🛠 Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| React 18 | UI Library |
| Vite | Build Tool |
| Redux Toolkit | State Management |
| React Router | Navigation |
| Tailwind CSS | Styling |
| Axios | HTTP Client |

### Backend
| Technology | Purpose |
|------------|---------|
| Node.js 18 | Runtime |
| Express.js | Web Framework |
| MongoDB | Database |
| Mongoose | ODM |
| JWT | Authentication |
| Stripe | Payments |
| Cloudinary | Image Storage |

### DevOps
| Technology | Purpose |
|------------|---------|
| Docker | Containerization |
| Kubernetes (EKS) | Orchestration |
| Terraform | Infrastructure as Code |
| Jenkins | CI/CD Pipeline |
| Helm | Package Management |
| Prometheus | Monitoring |
| Grafana | Visualization |
| AWS | Cloud Provider |

---

## 📁 Project Structure

```
ShopDeploy/
├── 📂 shopdeploy-backend/          # Backend API (Node.js/Express)
│   ├── src/
│   │   ├── app.js                  # Express app configuration
│   │   ├── server.js               # Server entry point
│   │   ├── config/                 # Database & environment config
│   │   ├── controllers/            # Route controllers
│   │   ├── middleware/             # Auth, error handling, validation
│   │   ├── models/                 # Mongoose schemas
│   │   ├── routes/                 # API routes (including health)
│   │   ├── services/               # Business logic layer
│   │   ├── scripts/                # Database scripts
│   │   └── utils/                  # Helper functions
│   ├── scripts/
│   │   ├── build-and-push.sh       # Docker build (Linux)
│   │   └── build-and-push.ps1      # Docker build (Windows)
│   ├── Dockerfile                  # Multi-stage Docker image
│   ├── .env.example                # Environment template
│   ├── README.md                   # Backend documentation
│   └── package.json
│
├── 📂 shopdeploy-frontend/         # Frontend (React/Vite)
│   ├── src/
│   │   ├── App.jsx                 # Main React component
│   │   ├── main.jsx                # App entry point
│   │   ├── index.css               # Global styles
│   │   ├── api/                    # Axios API clients
│   │   ├── app/                    # Redux store configuration
│   │   ├── components/             # Reusable UI components
│   │   ├── features/               # Redux slices (auth, cart, product)
│   │   ├── layouts/                # Page layouts
│   │   ├── pages/                  # Page components
│   │   ├── routes/                 # Route definitions
│   │   └── utils/                  # Helper functions
│   ├── scripts/
│   │   ├── deploy-frontend.sh      # Deploy script (Linux)
│   │   └── deploy-frontend.ps1     # Deploy script (Windows)
│   ├── Dockerfile                  # Multi-stage Docker image (Nginx)
│   ├── nginx.conf                  # Nginx configuration
│   ├── vite.config.js              # Vite build configuration
│   ├── tailwind.config.js          # Tailwind CSS configuration
│   ├── .eslintrc.cjs               # ESLint configuration
│   ├── README.md                   # Frontend documentation
│   └── package.json
│
├── 📂 terraform/                   # Infrastructure as Code (AWS)
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variable definitions
│   ├── outputs.tf                  # Output values
│   ├── data.tf                     # Data sources
│   ├── terraform.tfvars.example    # Example variables
│   ├── Makefile                    # Terraform shortcuts
│   ├── README.md                   # Terraform documentation
│   ├── backend-setup/              # S3 backend configuration
│   ├── environments/               # Environment-specific configs
│   └── modules/
│       ├── vpc/                    # VPC, subnets, NAT gateway
│       ├── iam/                    # IAM roles & policies
│       ├── ecr/                    # Container registry
│       └── eks/                    # EKS cluster & node groups
│
├── 📂 helm/                        # Helm Charts for Kubernetes
│   ├── backend/
│   │   ├── Chart.yaml              # Chart metadata
│   │   ├── values.yaml             # Default values
│   │   ├── values-dev.yaml         # Development overrides
│   │   ├── values-staging.yaml     # Staging overrides
│   │   ├── values-prod.yaml        # Production overrides
│   │   └── templates/              # Kubernetes templates
│   └── frontend/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-staging.yaml
│       ├── values-prod.yaml
│       └── templates/
│
├── 📂 k8s/                         # Raw Kubernetes manifests
│   ├── namespace.yaml              # shopdeploy namespace
│   ├── backend-deployment.yaml     # Backend deployment
│   ├── backend-service.yaml        # Backend ClusterIP service
│   ├── backend-configmap.yaml      # Backend configuration
│   ├── backend-secret.yaml         # Backend secrets (template)
│   ├── frontend-deployment.yaml    # Frontend deployment
│   ├── frontend-service.yaml       # Frontend service
│   ├── frontend-configmap.yaml     # Frontend configuration
│   ├── mongodb-statefulset.yaml    # MongoDB for development
│   ├── mongodb-statefulset-prod.yaml # MongoDB for production
│   ├── ingress.yaml                # Ingress configuration
│   ├── hpa.yaml                    # Horizontal Pod Autoscaler
│   ├── pdb.yaml                    # Pod Disruption Budget
│   ├── network-policy.yaml         # Network policies
│   ├── resource-quota.yaml         # Resource quotas
│   ├── kustomization.yaml          # Kustomize configuration
│   └── README.md                   # K8s documentation
│
├── 📂 docs/                        # Documentation
│   ├── AMAZON-LINUX-COMPLETE-SETUP-GUIDE.md  # Complete EC2 setup guide
│   ├── HELM-SETUP-GUIDE.md         # Helm installation & usage
│   ├── JENKINS-SETUP-GUIDE.md      # Jenkins CI/CD setup
│   └── MONITORING-SETUP-GUIDE.md   # Prometheus/Grafana setup
│
├── 📂 monitoring/                  # Observability stack
│   ├── prometheus-values.yaml      # Prometheus Helm values
│   ├── grafana-values.yaml         # Grafana Helm values
│   ├── install-monitoring.sh       # Installation script
│   └── dashboards/
│       └── shopdeploy-dashboard.json # Custom Grafana dashboard
│
├── 📂 scripts/                     # Automation scripts
│   ├── ec2-bootstrap.sh            # 🚀 Complete EC2 setup (Amazon Linux 2/2023)
│   ├── install-docker.sh           # Docker + Docker Compose (AL2/AL2023)
│   ├── install-jenkins.sh          # Jenkins LTS + Java 21 (AL2/AL2023)
│   ├── install-sonarqube.sh        # SonarQube + PostgreSQL 15 (AL2)
│   ├── install-grafana-prometheus.sh # Grafana 12.2 + Prometheus 3.5 + Node Exporter (AL2/AL2023)
│   ├── install-terraform.sh        # Terraform via HashiCorp repo (AL2/AL2023)
│   ├── install-kubectl.sh          # kubectl + autocompletion (AL2/AL2023)
│   ├── install-helm.sh             # Helm 3 + common repos (AL2/AL2023)
│   ├── install-awscli.sh           # AWS CLI v2 + eksctl (AL2/AL2023)
│   ├── build.sh                    # Docker build script
│   ├── push.sh                     # Docker push script
│   ├── deploy.sh                   # Kubernetes deployment
│   ├── rollback.sh                 # Rollback deployment
│   ├── cleanup.sh                  # Cleanup resources
│   ├── test.sh                     # Run tests
│   ├── smoke-test.sh               # Smoke tests
│   ├── helm-deploy.sh              # Helm deployment (Linux)
│   ├── helm-deploy.ps1             # Helm deployment (Windows)
│   ├── install-jenkins.ps1         # Install Jenkins (Windows)
│   ├── install-monitoring.ps1      # Install monitoring (Windows)
│   ├── terraform-init.sh           # Terraform init
│   ├── terraform-apply.sh          # Terraform apply
│   └── terraform-destroy.sh        # Terraform destroy
│
├── 📄 Jenkinsfile                  # CI/CD Pipeline (16 stages)
├── 📄 docker-compose.yml           # Local development setup
├── 📄 .env.example                 # Environment template
├── 📄 .gitignore                   # Git ignore rules
└── 📄 README.md                    # This file
```

---

## 🏛️ Architecture

### Project Flow Diagram

<p align="center">
  <img src="docs/Project_Flow_Diagram.png" alt="Project Flow Diagram" width="100%"/>
</p>

### System Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           ShopDeploy Architecture                            │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│    ┌─────────────┐         ┌─────────────┐         ┌─────────────┐          │
│    │   GitHub    │────────▶│   Jenkins   │────────▶│     ECR     │          │
│    │ Repository  │         │   CI/CD     │         │  Registry   │          │
│    └─────────────┘         └─────────────┘         └──────┬──────┘          │
│                                                           │                  │
│    ┌──────────────────────────────────────────────────────┼─────────────┐   │
│    │                        AWS Cloud                     │             │   │
│    │                                                      ▼             │   │
│    │   ┌────────────────────────────────────────────────────────────┐  │   │
│    │   │                    EKS Cluster                             │  │   │
│    │   │  ┌─────────────────────────────────────────────────────┐   │  │   │
│    │   │  │                  Kubernetes                         │   │  │   │
│    │   │  │                                                     │   │  │   │
│    │   │  │   ┌─────────┐    ┌─────────┐    ┌─────────┐        │   │  │   │
│    │   │  │   │Frontend │    │ Backend │    │ MongoDB │        │   │  │   │
│    │   │  │   │  Pods   │───▶│  Pods   │───▶│   Pod   │        │   │  │   │
│    │   │  │   └─────────┘    └─────────┘    └─────────┘        │   │  │   │
│    │   │  │        │                                            │   │  │   │
│    │   │  │   ┌────┴────┐                                       │   │  │   │
│    │   │  │   │ Ingress │◀──────────────(Users)                 │   │  │   │
│    │   │  │   │   ALB   │                                       │   │  │   │
│    │   │  │   └─────────┘                                       │   │  │   │
│    │   │  └─────────────────────────────────────────────────────┘   │  │   │
│    │   └────────────────────────────────────────────────────────────┘  │   │
│    │                                                                    │   │
│    │   ┌───────────────┐    ┌───────────────┐                          │   │
│    │   │  Prometheus   │───▶│    Grafana    │  (Monitoring)            │   │
│    │   └───────────────┘    └───────────────┘                          │   │
│    └────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## �️ Amazon Linux Setup (Quick Start)

> 📖 For complete step-by-step guide, see [docs/AMAZON-LINUX-COMPLETE-SETUP-GUIDE.md](docs/AMAZON-LINUX-COMPLETE-SETUP-GUIDE.md)

### Supported Operating Systems

| OS | Version | Status |
|----|---------|--------|
| **Amazon Linux** | 2023 | ✅ Fully Supported |
| **Amazon Linux** | 2 | ✅ Fully Supported |
| **Ubuntu** | 20.04/22.04 | ✅ Supported |
| **Debian** | 11/12 | ✅ Supported |

### One-Command Bootstrap (Amazon Linux)

```bash
# 1. SSH into your EC2 instance
ssh -i "your-key.pem" ec2-user@<EC2-PUBLIC-IP>

# 2. Clone the repository
git clone https://github.com/yourusername/ShopDeploy.git
cd ShopDeploy/scripts

# 3. Run the complete bootstrap script
chmod +x *.sh
sudo ./ec2-bootstrap.sh
```

### What Gets Installed

| Tool | Version | Purpose |
|------|---------|--------|
| **Docker** | Latest | Container runtime |
| **Docker Compose** | v2 | Multi-container orchestration |
| **Jenkins** | LTS | CI/CD automation |
| **Java** | 21 (Corretto) | Jenkins runtime |
| **Maven** | Latest | Build automation |
| **Terraform** | Latest | Infrastructure as Code |
| **kubectl** | Latest stable | Kubernetes CLI |
| **Helm** | v3 | Kubernetes package manager |
| **AWS CLI** | v2 | AWS management |
| **eksctl** | Latest | EKS cluster management |
| **Node.js** | 18.x | Build tools |
| **SonarQube** | 10.6.0 | Code quality analysis |
| **Grafana** | 12.2.1 | Metrics visualization |
| **Prometheus** | 3.5.0 | Metrics collection |
| **Node Exporter** | 1.10.2 | System metrics |

### Individual Tool Installation

```bash
# Install tools individually if needed
cd scripts

./install-docker.sh              # Docker + Docker Compose
./install-jenkins.sh             # Jenkins + Java 21 + Maven
./install-sonarqube.sh           # SonarQube + PostgreSQL 15
./install-grafana-prometheus.sh  # Grafana + Prometheus + Node Exporter
./install-terraform.sh           # Terraform
./install-kubectl.sh             # kubectl + autocompletion
./install-helm.sh                # Helm + common repositories
./install-awscli.sh              # AWS CLI v2 + eksctl
```

### Post-Installation

```bash
# 1. Get Jenkins initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# 2. Access Jenkins
http://<EC2-IP>:8080

# 3. Configure AWS credentials
aws configure

# 4. Log out and back in (for Docker group)
exit
ssh -i "your-key.pem" ec2-user@<EC2-IP>

# 5. Verify installations
docker --version
terraform --version
kubectl version --client
helm version
aws --version
```

---

## �🚀 Getting Started

### Prerequisites

- **Node.js** 18.x or higher
- **npm** 9.x or higher
- **MongoDB** (local or Atlas)
- **Docker** (for containerized deployment)
- **kubectl** (for Kubernetes deployment)

### Clone Repository

```bash
git clone https://github.com/yourusername/shopdeploy.git
cd shopdeploy
```

---

## 💻 Local Development

### Backend Setup

```bash
# Navigate to backend
cd shopdeploy-backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev
```

### Frontend Setup

```bash
# Navigate to frontend
cd shopdeploy-frontend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev
```

### Access the Application

| Service | URL | Description |
|---------|-----|-------------|
| **Frontend** | http://localhost:5173 | React application (Vite dev server) |
| **Backend API** | http://localhost:5000 | Express REST API |
| **Health Check** | http://localhost:5000/api/health/health | Liveness probe |
| **Readiness Check** | http://localhost:5000/api/health/ready | Readiness probe |

---

## 🐳 Docker Deployment

### Using Docker Compose (Recommended for Development)

```bash
# Build and start all services
docker-compose up --build

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Manual Docker Build

```bash
# Build Backend
cd shopdeploy-backend
docker build -t shopdeploy-backend:latest .

# Build Frontend
cd shopdeploy-frontend
docker build -t shopdeploy-frontend:latest .

# Run Backend
docker run -d -p 5000:5000 --env-file .env shopdeploy-backend:latest

# Run Frontend
docker run -d -p 3000:80 shopdeploy-frontend:latest
```

---

## ☸️ Kubernetes Deployment

### Prerequisites

- AWS CLI configured
- kubectl installed
- Helm v3 installed
- EKS cluster running (see Terraform section)

### Deploy with Helm

```bash
# Add namespace
kubectl create namespace shopdeploy

# Deploy Backend
helm upgrade --install shopdeploy-backend ./helm/backend \
  --namespace shopdeploy \
  --set image.repository=<ECR_URL>/shopdeploy-backend \
  --set image.tag=latest

# Deploy Frontend
helm upgrade --install shopdeploy-frontend ./helm/frontend \
  --namespace shopdeploy \
  --set image.repository=<ECR_URL>/shopdeploy-frontend \
  --set image.tag=latest

# Verify deployment
kubectl get pods -n shopdeploy
kubectl get svc -n shopdeploy
```

### Deploy with kubectl

```bash
# Apply all manifests
kubectl apply -f k8s/

# Check status
kubectl get all -n shopdeploy
```

---

## 🏗️ Infrastructure (Terraform)

> 📖 For detailed Terraform documentation, see [terraform/README.md](terraform/README.md)

### Why Terraform?

- **Infrastructure as Code**: Version control your cloud infrastructure
- **Reproducibility**: Create identical environments consistently
- **Automation**: Eliminate manual AWS console configuration
- **Cost Management**: Easily destroy non-production environments

### What Gets Created

| Module | Resources |
|--------|-----------|
| **VPC** | VPC, Subnets (public/private), NAT Gateway, Internet Gateway, Route Tables |
| **IAM** | EKS Cluster Role, Node Role, Service Account Roles |
| **ECR** | Container repositories for backend and frontend images |
| **EKS** | Kubernetes cluster, Node Groups, Add-ons (CoreDNS, VPC-CNI) |

### Quick Start

```bash
cd terraform

# 1. Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Initialize Terraform
terraform init

# 3. Preview changes
terraform plan

# 4. Apply infrastructure (takes ~15-20 minutes)
terraform apply

# 5. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name shopdeploy-prod-eks

# Verify connection
kubectl get nodes
```

### Destroy Infrastructure

```bash
# CAUTION: This will delete all resources
terraform destroy
```

---

## 🔄 CI/CD Pipeline

> 📖 For Jenkins setup guide, see [docs/JENKINS-SETUP-GUIDE.md](docs/JENKINS-SETUP-GUIDE.md)

### Pipeline Overview

The Jenkins pipeline automates the complete CI/CD workflow with 16 stages:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        ShopDeploy CI/CD Pipeline                             │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   │
│  │1.Checkout│──▶│2.Detect  │──▶│3.Install │──▶│ 4.Lint   │──▶│ 5.Tests  │   │
│  │          │   │ Changes  │   │   Deps   │   │          │   │          │   │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘   │
│                                                                     │        │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐         │        │
│  │10.Push   │◀──│9.Security│◀──│ 8.Build  │◀──│7.Quality │◀──┬─────┘        │
│  │  ECR     │   │   Scan   │   │  Docker  │   │   Gate   │   │              │
│  └────┬─────┘   └──────────┘   └──────────┘   └──────────┘   │              │
│       │                                                       │              │
│       │    ┌──────────────────────────────────────────────────┘              │
│       │    │  6. SonarQube Analysis                                          │
│       │    └──────────────────────────────────────────────────               │
│       ▼                                                                      │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   │
│  │11.Deploy │──▶│12.Prod   │──▶│13.Deploy │──▶│14.Smoke  │──▶│15.Integ. │   │
│  │Dev/Stage │   │ Approval │   │   Prod   │   │  Tests   │   │  Tests   │   │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘   └────┬─────┘   │
│                                                                    │         │
│                                               ┌──────────┐         │         │
│                                               │16.Cleanup│◀────────┘         │
│                                               └──────────┘                   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### All 16 Pipeline Stages

| Stage | Name | Description |
|-------|------|-------------|
| 1 | **Checkout** | Clone repository from GitHub with commit info |
| 2 | **Detect Changes** | Identify changes in backend/frontend directories |
| 3 | **Install Dependencies** | Parallel `npm ci` for backend & frontend |
| 4 | **Code Linting** | Parallel ESLint checks for both services |
| 5 | **Unit Tests** | Parallel Jest tests with coverage reports |
| 6 | **SonarQube Analysis** | Code quality analysis (optional) |
| 7 | **Quality Gate** | Verify SonarQube quality standards |
| 8 | **Build Docker Images** | Parallel multi-stage Docker builds |
| 9 | **Security Scan** | Trivy vulnerability scanning (HIGH/CRITICAL) |
| 10 | **Push to ECR** | Tag and push images to AWS ECR |
| 11 | **Deploy Dev/Staging** | Helm deployment to non-prod EKS |
| 12 | **Production Approval** | Manual approval gate for prod deploys |
| 13 | **Deploy Production** | Helm deployment to production EKS |
| 14 | **Smoke Tests** | Verify pod rollout and health checks |
| 15 | **Integration Tests** | Run integration test suite |
| 16 | **Cleanup** | Remove local Docker images to save space |

### Pipeline Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ENVIRONMENT` | Choice | `dev` | Target environment: `dev`, `staging`, `prod` |
| `SKIP_TESTS` | Boolean | `false` | Skip unit test execution |
| `SKIP_SONAR` | Boolean | `false` | Skip SonarQube analysis |
| `FORCE_DEPLOY` | Boolean | `true` | Deploy even without code changes |
| `RUN_SECURITY_SCAN` | Boolean | `true` | Run Trivy security scanning |

### Running the Pipeline

```bash
# Option 1: Trigger via GitHub webhook (automatic on push)
# Option 2: Manual trigger in Jenkins UI with parameters

# Example: Deploy to production
# 1. Go to Jenkins > ShopDeploy > Build with Parameters
# 2. Select ENVIRONMENT: prod
# 3. Click Build
# 4. Approve deployment at Stage 12 (Production Approval)
```

### Pipeline Features

- ✅ **Parallel Execution**: Dependencies, linting, tests, and builds run in parallel
- ✅ **Environment-Specific Configs**: Separate Helm values for dev/staging/prod
- ✅ **Automatic Tool Installation**: kubectl, Helm, Trivy installed automatically
- ✅ **Security Scanning**: Trivy scans for HIGH/CRITICAL vulnerabilities
- ✅ **Health Verification**: Smoke tests verify pod rollout status
- ✅ **Cleanup**: Automatic Docker image cleanup to save disk space

---

## 📊 Monitoring

> 📖 For monitoring setup, see [docs/MONITORING-SETUP-GUIDE.md](docs/MONITORING-SETUP-GUIDE.md)

### Stack

- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards
- **Custom Dashboards**: ShopDeploy-specific metrics

### Installation

```bash
# Install monitoring stack
./monitoring/install-monitoring.sh

# Access Grafana (default: admin/admin)
kubectl port-forward svc/grafana 3000:80 -n monitoring

# Access Prometheus
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

### Available Dashboards

- Kubernetes Cluster Overview
- Node Metrics
- Pod Metrics
- ShopDeploy Application Dashboard

### Monitoring Setup

```bash
# Install monitoring stack
./monitoring/install-monitoring.sh

# Access Grafana
kubectl port-forward svc/grafana 3000:80 -n monitoring

# Access Prometheus
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

---

## 📖 API Documentation

### Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | User login |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | User logout |

### Product Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products` | Get all products |
| GET | `/api/products/:id` | Get product by ID |
| POST | `/api/products` | Create product (Admin) |
| PUT | `/api/products/:id` | Update product (Admin) |
| DELETE | `/api/products/:id` | Delete product (Admin) |

### Cart Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/cart` | Get user cart |
| POST | `/api/cart` | Add item to cart |
| PUT | `/api/cart/:itemId` | Update cart item |
| DELETE | `/api/cart/:itemId` | Remove cart item |

### Order Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders` | Get user orders |
| GET | `/api/orders/:id` | Get order by ID |
| POST | `/api/orders` | Create new order |
| PUT | `/api/orders/:id/status` | Update order status (Admin) |

### Health Endpoints

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| GET | `/api/health/health` | Liveness check | `{ status: "OK", timestamp, uptime, environment }` |
| GET | `/api/health/ready` | Readiness check | `{ status: "ready", timestamp }` |

---

## ⚙️ Environment Variables

### Backend (.env)

```env
# Server
NODE_ENV=production
PORT=5000

# Database
MONGODB_URI=mongodb://localhost:27017/shopdeploy

# JWT
JWT_ACCESS_SECRET=your-access-secret
JWT_REFRESH_SECRET=your-refresh-secret
JWT_ACCESS_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d

# Stripe
STRIPE_SECRET_KEY=sk_test_xxx

# Cloudinary
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:3000
```

### Frontend (.env)

```env
VITE_API_URL=http://localhost:5000/api
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow ESLint configuration
- Write meaningful commit messages
- Add tests for new features
- Update documentation as needed

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Contact

**Project Repository**: [GitHub](https://github.com/yourusername/shopdeploy)

---

## 🙏 Acknowledgments

- [React Documentation](https://react.dev/)
- [Express.js](https://expressjs.com/)
- [Kubernetes](https://kubernetes.io/)
- [Terraform](https://www.terraform.io/)
- [AWS Documentation](https://docs.aws.amazon.com/)

---

<p align="center">
  <b>⭐ Star this repository if you found it helpful!</b>
</p>

<p align="center">
  Made with ❤️ by the ShopDeploy Team
</p>
