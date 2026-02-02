# 🔧 ShopDeploy Jenkins Pipeline Setup Guide

<p align="center">
  <img src="https://img.shields.io/badge/Jenkins-LTS-D24939?style=for-the-badge&logo=jenkins" alt="Jenkins"/>
  <img src="https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker" alt="Docker"/>
  <img src="https://img.shields.io/badge/AWS-EKS-FF9900?style=for-the-badge&logo=amazon-aws" alt="AWS"/>
  <img src="https://img.shields.io/badge/Helm-v3-0F1689?style=for-the-badge&logo=helm" alt="Helm"/>
</p>

> Complete guide for setting up Jenkins CI/CD pipelines for ShopDeploy e-commerce application.

---

## 📋 Table of Contents

- [Prerequisites](#-prerequisites)
- [Jenkins Installation](#-jenkins-installation)
- [Required Plugins](#-required-plugins)
- [Credentials Setup](#-credentials-setup)
- [Tool Configuration](#-tool-configuration)
- [Pipeline Jobs Creation](#-pipeline-jobs-creation)
- [CI Pipeline Overview](#-ci-pipeline-overview)
- [CD Pipeline Overview](#-cd-pipeline-overview)
- [Pipeline Parameters](#-pipeline-parameters)
- [Environment Configuration](#-environment-configuration)
- [SonarQube Integration](#-sonarqube-integration)
- [Slack Integration](#-slack-integration)
- [Troubleshooting](#-troubleshooting)
- [Best Practices](#-best-practices)

---

## 📋 Prerequisites

### Server Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 2 cores | 4 cores |
| **RAM** | 4 GB | 8 GB |
| **Disk** | 50 GB | 100 GB |
| **OS** | Amazon Linux 2023 / Ubuntu 22.04 | Amazon Linux 2023 |

### Required Tools on Jenkins Server

| Tool | Version | Purpose |
|------|---------|---------|
| Java | 21 (Corretto) | Jenkins runtime |
| Docker | Latest | Container builds |
| AWS CLI | v2 | AWS operations |
| kubectl | Latest | Kubernetes management |
| Helm | v3 | Kubernetes deployments |
| Node.js | 18.x | Build dependencies |
| Trivy | Latest | Security scanning |

---

## 🚀 Jenkins Installation

### Option 1: Using Install Script (Recommended)

```bash
# Navigate to scripts directory
cd scripts/monitoring

# Make script executable
chmod +x install-jenkins.sh

# Run installation
sudo ./install-jenkins.sh
```

### Option 2: Manual Installation (Amazon Linux 2023)

```bash
# Install Java 21 (Amazon Corretto)
sudo dnf install -y java-21-amazon-corretto-headless

# Verify Java
java -version

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo dnf install -y jenkins

# Start and enable Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Check status
sudo systemctl status jenkins
```

### Get Initial Admin Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Access Jenkins

```
http://<SERVER-IP>:8080
```

---

## 🔌 Required Plugins

### Install via Jenkins UI

Navigate to: `Manage Jenkins → Plugins → Available plugins`

### Essential Plugins

| Plugin | Purpose |
|--------|---------|
| **Pipeline** | Pipeline as code support |
| **Git** | Git SCM integration |
| **GitHub** | GitHub webhooks & integration |
| **Docker Pipeline** | Docker build support |
| **Amazon ECR** | ECR authentication |
| **AWS Credentials** | AWS credential binding |
| **Credentials Binding** | Secure credential access |
| **Pipeline: AWS Steps** | AWS SDK integration |
| **NodeJS** | Node.js build support |
| **Slack Notification** | Slack integration (optional) |

### Optional Plugins

| Plugin | Purpose |
|--------|---------|
| **SonarQube Scanner** | Code quality analysis |
| **JUnit** | Test result publishing |
| **Workspace Cleanup** | Build cleanup |
| **Build Timeout** | Build timeout control |
| **Timestamper** | Console output timestamps |
| **Blue Ocean** | Modern UI (optional) |

### Install via CLI

```bash
# Install plugins using Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080 install-plugin \
  workflow-aggregator \
  git \
  github \
  docker-workflow \
  amazon-ecr \
  aws-credentials \
  credentials-binding \
  pipeline-aws \
  nodejs \
  slack \
  sonar \
  junit \
  ws-cleanup \
  build-timeout \
  timestamper
```

---

## 🔐 Credentials Setup

Navigate to: `Manage Jenkins → Credentials → System → Global credentials`

### 1. AWS Account ID

| Field | Value |
|-------|-------|
| **Kind** | Secret text |
| **Secret** | Your 12-digit AWS Account ID |
| **ID** | `aws-account-id` |
| **Description** | AWS Account ID for ECR |

### 2. AWS Credentials

| Field | Value |
|-------|-------|
| **Kind** | AWS Credentials |
| **Access Key ID** | Your AWS Access Key |
| **Secret Access Key** | Your AWS Secret Key |
| **ID** | `aws-credentials` |
| **Description** | AWS Credentials for ECR/EKS |

### 3. GitHub Credentials (for private repos)

| Field | Value |
|-------|-------|
| **Kind** | Username with password |
| **Username** | Your GitHub username |
| **Password** | GitHub Personal Access Token |
| **ID** | `github-credentials` |
| **Description** | GitHub access |

### 4. SonarQube Token (if using SonarQube)

| Field | Value |
|-------|-------|
| **Kind** | Secret text |
| **Secret** | SonarQube authentication token |
| **ID** | `sonarqube-token` |
| **Description** | SonarQube authentication |

### Verify Credentials

```bash
# Test AWS credentials from Jenkins server
aws sts get-caller-identity

# Should return your account info
```

---

## 🛠️ Tool Configuration

Navigate to: `Manage Jenkins → Tools`

### NodeJS Installation

| Field | Value |
|-------|-------|
| **Name** | `nodejs-18` |
| **Install automatically** | ✅ Yes |
| **Version** | NodeJS 18.x |

### Docker Installation

Docker should be available on the Jenkins server:

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
```

### SonarQube Scanner (Optional)

| Field | Value |
|-------|-------|
| **Name** | `sonar-scanner` |
| **Install automatically** | ✅ Yes |
| **Version** | SonarQube Scanner 5.x |

---

## 📦 Pipeline Jobs Creation

### Create CI Pipeline Job

1. **New Item** → Enter name: `shopdeploy-ci`
2. Select: **Pipeline**
3. Click: **OK**

#### Configure CI Pipeline

**General:**
- ✅ GitHub project: `https://github.com/your-org/shopdeploy`
- ✅ Discard old builds: Keep 20 builds

**Build Triggers:**
- ✅ GitHub hook trigger for GITScm polling

**Pipeline:**
| Field | Value |
|-------|-------|
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | `https://github.com/your-org/shopdeploy.git` |
| Credentials | github-credentials |
| Branch | `*/main` |
| Script Path | `ci-cd/Jenkinsfile-ci` |

### Create CD Pipeline Job

1. **New Item** → Enter name: `shopdeploy-cd`
2. Select: **Pipeline**
3. Click: **OK**

#### Configure CD Pipeline

**General:**
- ✅ This project is parameterized (parameters defined in Jenkinsfile)
- ✅ Discard old builds: Keep 50 builds

**Pipeline:**
| Field | Value |
|-------|-------|
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | `https://github.com/your-org/shopdeploy.git` |
| Credentials | github-credentials |
| Branch | `*/main` |
| Script Path | `ci-cd/Jenkinsfile-cd` |

---

## 🔄 CI Pipeline Overview

### Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           CI PIPELINE FLOW                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                 │
│  │ Checkout │──▶│ Detect   │──▶│ Install  │──▶│  Lint    │                 │
│  │          │   │ Changes  │   │   Deps   │   │          │                 │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘                 │
│                                                     │                       │
│                                                     ▼                       │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                 │
│  │  Tests   │──▶│ SonarQube│──▶│ Quality  │──▶│  Build   │                 │
│  │          │   │ Analysis │   │   Gate   │   │  Docker  │                 │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘                 │
│                                                     │                       │
│                                                     ▼                       │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                 │
│  │ Security │──▶│ Push to  │──▶│  Save    │──▶│ Cleanup  │                 │
│  │   Scan   │   │   ECR    │   │   Tag    │   │          │                 │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘                 │
│                                                     │                       │
│                                                     ▼                       │
│                                              ┌──────────┐                   │
│                                              │ Trigger  │                   │
│                                              │   CD     │                   │
│                                              └──────────┘                   │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### CI Pipeline Stages

| # | Stage | Description | Duration |
|---|-------|-------------|----------|
| 1 | **Environment Setup** | Set environment-specific variables | ~5s |
| 2 | **Checkout** | Clone source code from Git | ~10s |
| 3 | **Detect Changes** | Identify which components changed | ~5s |
| 4 | **Install Dependencies** | `npm ci` for backend & frontend (parallel) | ~60s |
| 5 | **Code Linting** | ESLint checks (parallel) | ~30s |
| 6 | **Unit Tests** | Jest tests with coverage (parallel) | ~60s |
| 7 | **Verify Coverage** | Check coverage reports exist | ~5s |
| 8 | **SonarQube Analysis** | Code quality scan (skips if not configured) | ~120s |
| 9 | **Quality Gate** | Wait for SonarQube quality gate | ~60s |
| 10 | **Build Docker Images** | Multi-stage Docker builds (parallel) | ~120s |
| 11 | **Security Scan** | Trivy vulnerability scan (parallel) | ~60s |
| 12 | **Push to ECR** | Push images to AWS ECR (with retry) | ~60s |
| 13 | **Save Image Tag** | Archive tag & update Parameter Store | ~10s |
| 14 | **Cleanup** | Remove local Docker images | ~10s |

**Total Duration:** ~10-15 minutes

### Environment Variables

```groovy
environment {
    // AWS Configuration
    AWS_REGION = 'us-east-1'
    AWS_ACCOUNT_ID = credentials('aws-account-id')

    // ECR Configuration
    ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    ECR_BACKEND_REPO = "shopdeploy-prod-backend"
    ECR_FRONTEND_REPO = "shopdeploy-prod-frontend"

    // Image Tag (immutable - BUILD_NUMBER + commit hash)
    IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"

    // SonarQube Configuration
    SONAR_PROJECT_KEY = 'shopdeploy'

    // Directory Paths
    BACKEND_DIR = 'shopdeploy-backend'
    FRONTEND_DIR = 'shopdeploy-frontend'
}
```

---

## 🚀 CD Pipeline Overview

### Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                           CD PIPELINE FLOW                                   │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                 │
│  │Initialize│──▶│ Verify   │──▶│ Verify   │──▶│Production│                 │
│  │ Get Tag  │   │  Tools   │   │  Images  │   │ Approval │                 │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘                 │
│                                                     │                       │
│                                                     ▼                       │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐                 │
│  │ Capture  │──▶│ Deploy   │──▶│ Deploy   │──▶│  Smoke   │                 │
│  │ Rollback │   │ MongoDB  │   │  (Helm)  │   │  Tests   │                 │
│  └──────────┘   └──────────┘   └──────────┘   └──────────┘                 │
│                                                     │                       │
│                                                     ▼                       │
│                                              ┌──────────┐                   │
│                                              │Integrat. │                   │
│                                              │  Tests   │                   │
│                                              └──────────┘                   │
│                                                                              │
│                    ┌─────────────────────────────────────┐                  │
│                    │  ❌ FAILURE → AUTO ROLLBACK (Helm)  │                  │
│                    └─────────────────────────────────────┘                  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### CD Pipeline Stages

| # | Stage | Description | Duration |
|---|-------|-------------|----------|
| 1 | **Initialize** | Get IMAGE_TAG from parameter or Parameter Store | ~10s |
| 2 | **Verify Tools** | Check Docker, AWS CLI, kubectl, Helm | ~5s |
| 3 | **Verify Images** | Confirm images exist in ECR | ~10s |
| 4 | **Production Approval** | Manual approval gate (prod only) | Manual |
| 5 | **Capture Rollback Info** | Save current Helm revisions | ~10s |
| 6 | **Deploy MongoDB** | Deploy database if not exists | ~60s |
| 7 | **Deploy** | Helm upgrade for backend & frontend | ~300s |
| 8 | **Smoke Tests** | Verify pod health and rollout | ~60s |
| 9 | **Integration Tests** | Run integration tests (non-prod) | ~60s |

**Total Duration:** ~8-10 minutes (excluding approval)

### Environment Variables

```groovy
environment {
    // AWS Configuration
    AWS_REGION = 'us-east-1'
    
    // ECR Configuration
    ECR_BACKEND_REPO = "shopdeploy-prod-backend"
    ECR_FRONTEND_REPO = "shopdeploy-prod-frontend"

    // EKS Configuration
    EKS_CLUSTER_NAME = 'shopdeploy-prod-eks'
    
    // Slack integration (set to 'true' when configured)
    SLACK_ENABLED = 'false'
}
```

---

## ⚙️ Pipeline Parameters

### CI Pipeline Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `TARGET_ENVIRONMENT` | Choice | `dev` | Target environment (dev/staging/prod) |
| `TRIGGER_CD` | Boolean | `true` | Auto-trigger CD pipeline on success |

> **Note:** All stages are mandatory - linting, tests, and security scans run on every build.

### CD Pipeline Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ENVIRONMENT` | Choice | `dev` | Target: dev, staging, prod |
| `IMAGE_TAG` | String | *(empty)* | Tag to deploy (fetches from Parameter Store if empty) |
| `SKIP_SMOKE_TESTS` | Boolean | `false` | Skip smoke tests (NOT allowed for prod) |
| `DRY_RUN` | Boolean | `false` | Perform dry-run without actual deployment |

---

## 🌍 Environment Configuration

### Why Dev, Staging, and Production Environments?

Using multiple environments is a **DevOps best practice** that provides:

#### 🎯 Purpose of Each Environment

| Environment | Purpose | Who Uses It | Risk Level |
|-------------|---------|-------------|------------|
| **🟢 Development (dev)** | Active development & testing | Developers | Low |
| **🟡 Staging** | Pre-production validation | QA Team, Stakeholders | Medium |
| **🔴 Production (prod)** | Live users, real business | End Users | High |

---

#### 🟢 Development Environment (dev)

**Purpose:** Daily development and feature testing

| Aspect | Details |
|--------|---------|
| **Updates** | Multiple times per day |
| **Data** | Test/mock data only |
| **Stability** | Can break frequently |
| **Access** | Developers only |
| **Approval** | No approval needed |

**Use Cases:**
- Developers test new features immediately
- Integration testing with other services
- Debug and fix issues safely
- Experiment without fear of breaking production

---

#### 🟡 Staging Environment

**Purpose:** Final validation before production (mirrors production)

| Aspect | Details |
|--------|---------|
| **Updates** | After dev testing passes |
| **Data** | Production-like (anonymized) |
| **Stability** | Should be stable |
| **Access** | QA, Product, Stakeholders |
| **Approval** | Optional (team policy) |

**Use Cases:**
- QA team performs full regression testing
- Stakeholders preview new features
- Performance testing with realistic data
- Security testing before production
- UAT (User Acceptance Testing)

**Why "Staging"?**
- Acts as **dress rehearsal** before going live
- Catches issues that dev environment missed
- Same infrastructure as production (same configs, resources)

---

#### 🔴 Production Environment (prod)

**Purpose:** Real users, real business, real money

| Aspect | Details |
|--------|---------|
| **Updates** | Carefully scheduled releases |
| **Data** | Real customer data |
| **Stability** | MUST be stable (99.9% uptime) |
| **Access** | End users worldwide |
| **Approval** | **Mandatory approval required** |

**Use Cases:**
- Serving actual customers
- Processing real transactions
- Business-critical operations

**Why Strict Controls?**
- Downtime = Lost revenue + damaged reputation
- Bugs affect real users
- Security breaches expose customer data
- Compliance requirements (GDPR, PCI-DSS)

---

### 🔄 Environment Flow (Promotion Pipeline)

```
┌─────────────────────────────────────────────────────────────────┐
│                    CODE PROMOTION FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Developer                                                      │
│      │                                                          │
│      ▼                                                          │
│   ┌─────────┐    Tests    ┌───────────┐   Approval  ┌────────┐ │
│   │   DEV   │ ──────────► │  STAGING  │ ──────────► │  PROD  │ │
│   └─────────┘   Pass?     └───────────┘   Required  └────────┘ │
│                                                                  │
│   🟢 Fast        🟡 Stable          🔴 Protected                │
│   iterations     validation         live traffic                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Flow:**
1. **Code → Dev**: Deploy immediately after CI passes
2. **Dev → Staging**: After dev testing, promote to staging
3. **Staging → Prod**: After QA approval, deploy to production

---

### 🛡️ Why This Matters in Real Companies

| Without Multiple Environments | With Dev/Staging/Prod |
|-------------------------------|----------------------|
| ❌ Bugs reach customers directly | ✅ Bugs caught before production |
| ❌ No safe place to test | ✅ Safe testing in dev/staging |
| ❌ Rollback is chaotic | ✅ Tested rollback procedures |
| ❌ No stakeholder preview | ✅ Stakeholders approve in staging |
| ❌ Compliance violations | ✅ Audit trail with approvals |
| ❌ High-stress deployments | ✅ Confident, tested deployments |

---

### 📊 Environment Comparison Table

| Feature | Dev | Staging | Prod |
|---------|-----|---------|------|
| **Replicas** | 1 | 2 | 3+ |
| **CPU Request** | 100m | 200m | 500m |
| **Memory Request** | 128Mi | 256Mi | 512Mi |
| **HPA Enabled** | No | Yes | Yes |
| **Auto-scaling** | 1-2 | 2-4 | 3-10 |
| **Database** | Shared | Dedicated | HA Cluster |
| **Monitoring** | Basic | Full | Full + Alerts |
| **Logging** | Debug | Info | Info + Audit |
| **SSL/TLS** | Optional | Required | Required |
| **Backup** | None | Daily | Hourly |

---

### 🎯 Interview Question: "Why not deploy directly to production?"

**Answer:**
> "Direct production deployment is risky because:
> 1. **No safety net** - bugs affect real users immediately
> 2. **No testing environment** - can't catch issues before they go live
> 3. **No rollback confidence** - rollback procedures untested
> 4. **Compliance issues** - no audit trail or approval process
> 5. **Business risk** - downtime affects revenue and reputation
>
> Using dev → staging → prod allows us to:
> - Test thoroughly at each stage
> - Get stakeholder approval
> - Have confidence in deployments
> - Maintain compliance requirements"

---

### Environment-Specific Settings

| Environment | Emoji | Approval | Namespace | API URL |
|-------------|-------|----------|-----------|---------|
| **dev** | 🟢 | No | `shopdeploy-dev` | `https://api-dev.shopdeploy.com/api` |
| **staging** | 🟡 | No | `shopdeploy-staging` | `https://api-staging.shopdeploy.com/api` |
| **prod** | 🔴 | Yes | `shopdeploy-prod` | `https://api.shopdeploy.com/api` |

### Production Safeguards

- ❌ Cannot skip tests for production
- ❌ Cannot skip smoke tests for production
- ✅ Requires manual approval from `admin` or `devops-team`
- ✅ Automatic rollback on deployment failure

### Helm Values Files

```
helm/
├── backend/
│   ├── values.yaml           # Default values
│   ├── values-dev.yaml       # Development overrides
│   ├── values-staging.yaml   # Staging overrides
│   └── values-prod.yaml      # Production overrides
└── frontend/
    ├── values.yaml
    ├── values-dev.yaml
    ├── values-staging.yaml
    └── values-prod.yaml
```

---

## 🔍 SonarQube Integration

### What is SonarQube?

SonarQube is an open-source platform for continuous inspection of code quality. It performs:

| Feature | Description |
|---------|-------------|
| **Code Smells** | Maintainability issues |
| **Bugs** | Reliability problems |
| **Vulnerabilities** | Security weaknesses |
| **Coverage** | Test coverage analysis |
| **Duplications** | Duplicate code detection |
| **Complexity** | Cyclomatic complexity metrics |

---

### 🖥️ SonarQube Server Installation

#### Prerequisites

```bash
# System requirements
# CPU: 2 cores minimum
# RAM: 4 GB minimum (8 GB recommended)
# Disk: 30 GB minimum

# Increase virtual memory (required)
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072

# Make permanent
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf
```

#### Option 1: Docker Installation (Recommended)

```bash
# Create Docker network
docker network create sonarqube-net

# Start PostgreSQL database
docker run -d --name sonarqube-db \
  --network sonarqube-net \
  -e POSTGRES_USER=sonar \
  -e POSTGRES_PASSWORD=sonar123 \
  -e POSTGRES_DB=sonarqube \
  -v sonarqube_db:/var/lib/postgresql/data \
  postgres:15

# Start SonarQube
docker run -d --name sonarqube \
  --network sonarqube-net \
  -p 9000:9000 \
  -e SONAR_JDBC_URL=jdbc:postgresql://sonarqube-db:5432/sonarqube \
  -e SONAR_JDBC_USERNAME=sonar \
  -e SONAR_JDBC_PASSWORD=sonar123 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:10.6-community

# Check status
docker ps | grep sonarqube
docker logs -f sonarqube
```

#### Option 2: Docker Compose

Create `docker-compose-sonarqube.yml`:

```yaml
version: '3.8'

services:
  sonarqube-db:
    image: postgres:15
    container_name: sonarqube-db
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar123
      POSTGRES_DB: sonarqube
    volumes:
      - sonarqube_db:/var/lib/postgresql/data
    networks:
      - sonarqube-net

  sonarqube:
    image: sonarqube:10.6-community
    container_name: sonarqube
    depends_on:
      - sonarqube-db
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://sonarqube-db:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar123
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_logs:/opt/sonarqube/logs
      - sonarqube_extensions:/opt/sonarqube/extensions
    networks:
      - sonarqube-net

volumes:
  sonarqube_db:
  sonarqube_data:
  sonarqube_logs:
  sonarqube_extensions:

networks:
  sonarqube-net:
```

Run:

```bash
docker-compose -f docker-compose-sonarqube.yml up -d
```

#### Option 3: Native Installation (Amazon Linux 2023)

```bash
# Install Java 17
sudo dnf install -y java-17-amazon-corretto

# Create SonarQube user
sudo useradd -r -s /bin/false sonarqube

# Download SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.6.0.92116.zip
sudo unzip sonarqube-10.6.0.92116.zip
sudo mv sonarqube-10.6.0.92116 sonarqube
sudo chown -R sonarqube:sonarqube /opt/sonarqube

# Configure database (in sonar.properties)
sudo vi /opt/sonarqube/conf/sonar.properties
# Add:
# sonar.jdbc.username=sonar
# sonar.jdbc.password=sonar123
# sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube

# Create systemd service
sudo tee /etc/systemd/system/sonarqube.service << 'EOF'
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=131072
LimitNPROC=8192

[Install]
WantedBy=multi-user.target
EOF

# Start SonarQube
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube
sudo systemctl status sonarqube
```

---

### 🔐 Initial SonarQube Setup

#### Step 1: Access SonarQube

```
URL: http://<server-ip>:9000
Default Login: admin / admin
```

#### Step 2: Change Admin Password

1. Login with `admin` / `admin`
2. You'll be prompted to change password
3. Set strong password: `SonarAdmin@2024`

#### Step 3: Generate Authentication Token

```
My Account → Security → Generate Tokens

Token Name: jenkins-token
Type: Global Analysis Token
Expires: No expiration (or 365 days)

⚠️ COPY TOKEN NOW - It won't be shown again!
Example: squ_abc123def456...
```

#### Step 4: Create Project

```
Projects → Create Project → Manually

Project Key: shopdeploy
Display Name: ShopDeploy E-Commerce
Main Branch: main
```

---

### 📝 SonarQube Project Configuration

Your project already has `sonar-project.properties`:

```properties
# Project identification
sonar.projectKey=shopdeploy
sonar.projectName=ShopDeploy E-Commerce Application
sonar.projectVersion=1.0.0

# Source directories
sonar.sources=shopdeploy-frontend/src,shopdeploy-backend/src
sonar.tests=shopdeploy-frontend/src,shopdeploy-backend/src

# Test patterns
sonar.test.inclusions=**/*.test.js,**/*.test.jsx,**/*.spec.js,**/*.spec.jsx

# Exclusions
sonar.exclusions=**/node_modules/**,**/dist/**,**/build/**,**/coverage/**

# Coverage report paths
sonar.javascript.lcov.reportPaths=shopdeploy-frontend/coverage/lcov.info,shopdeploy-backend/coverage/lcov.info

# Encoding
sonar.sourceEncoding=UTF-8

# Language specific
sonar.language=js
```

---

### 🔧 Jenkins Integration

#### Step 1: Install SonarQube Plugin

```
Manage Jenkins → Plugins → Available plugins
Search: "SonarQube Scanner"
Install without restart
```

#### Step 2: Add SonarQube Credentials

```
Manage Jenkins → Credentials → System → Global credentials

Kind: Secret text
Secret: squ_abc123def456... (your token)
ID: sonarqube-token
Description: SonarQube Authentication Token
```

#### Step 3: Configure SonarQube Server

```
Manage Jenkins → System → SonarQube servers

☑️ Environment variables: Enable
Name: SonarQube
Server URL: http://localhost:9000 (or http://<sonar-ip>:9000)
Server authentication token: sonarqube-token
```

#### Step 4: Add SonarQube Scanner Tool

```
Manage Jenkins → Tools → SonarQube Scanner installations

Name: sonar-scanner
☑️ Install automatically
Version: SonarQube Scanner 5.0.1
```

---

### 🔄 Pipeline Integration

#### How CI Pipeline Uses SonarQube

```groovy
stage('SonarQube Analysis') {
    steps {
        script {
            def scannerHome = tool name: 'sonar-scanner', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
            
            if (scannerHome) {
                withSonarQubeEnv('SonarQube') {
                    sh """
                        ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=shopdeploy \
                            -Dsonar.projectName='ShopDeploy' \
                            -Dsonar.sources=. \
                            -Dsonar.exclusions='**/node_modules/**,**/dist/**' \
                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                    """
                }
            }
        }
    }
}
```

#### Quality Gate Check

```groovy
stage('Quality Gate') {
    steps {
        timeout(time: 10, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

---

### 📊 Quality Gates

#### Default Quality Gate

| Metric | Condition | Value |
|--------|-----------|-------|
| Coverage | is less than | 80% |
| Duplicated Lines | is greater than | 3% |
| Maintainability Rating | is worse than | A |
| Reliability Rating | is worse than | A |
| Security Rating | is worse than | A |

#### Create Custom Quality Gate

```
Quality Gates → Create

Name: ShopDeploy Gate
Add Conditions:
  - Coverage on New Code < 70% → Fail
  - New Bugs > 0 → Fail
  - New Vulnerabilities > 0 → Fail
  - New Code Smells > 10 → Fail
  - Duplicated Lines on New Code > 5% → Fail

Set as Default: ✅
```

---

### 🛡️ Quality Profiles

#### For JavaScript/TypeScript

```
Quality Profiles → JavaScript → Create

Name: ShopDeploy JavaScript Rules
Parent: Sonar way
Activate Additional Rules:
  - security/detect-child-process
  - security/detect-non-literal-fs-filename
  - security/detect-eval-with-expression

Set as Default: ✅
```

---

### 🔍 Viewing Analysis Results

#### Dashboard Metrics

| Panel | Shows |
|-------|-------|
| **Reliability** | Bugs count (A-E rating) |
| **Security** | Vulnerabilities count |
| **Security Review** | Security hotspots |
| **Maintainability** | Code smells, tech debt |
| **Coverage** | Line & branch coverage |
| **Duplications** | Duplicate code % |

#### Drill Down

```
Project → Issues tab
Filter by:
  - Type: Bug, Vulnerability, Code Smell
  - Severity: Blocker, Critical, Major, Minor, Info
  - Status: Open, Confirmed, Resolved
  - Assignee: Team member
```

---

### 🚨 Webhooks for Jenkins

#### Configure Webhook

```
SonarQube → Administration → Configuration → Webhooks

Name: Jenkins
URL: http://<jenkins-ip>:8080/sonarqube-webhook/
Secret: (optional, but recommended)
```

This enables `waitForQualityGate` in Jenkins pipeline.

---

### 📈 Branch Analysis

#### Enable Branch Analysis

```groovy
// In Jenkinsfile
withSonarQubeEnv('SonarQube') {
    sh """
        sonar-scanner \
            -Dsonar.projectKey=shopdeploy \
            -Dsonar.branch.name=${env.BRANCH_NAME}
    """
}
```

#### PR Analysis (Decoration)

```groovy
// For Pull Requests
withSonarQubeEnv('SonarQube') {
    sh """
        sonar-scanner \
            -Dsonar.projectKey=shopdeploy \
            -Dsonar.pullrequest.key=${env.CHANGE_ID} \
            -Dsonar.pullrequest.branch=${env.CHANGE_BRANCH} \
            -Dsonar.pullrequest.base=${env.CHANGE_TARGET}
    """
}
```

---

### ⚠️ Graceful Skip (When SonarQube Not Configured)

The pipeline handles missing SonarQube gracefully:

```
⚠️ SonarQube Scanner tool not configured in Jenkins
To enable SonarQube analysis:
  1. Install SonarQube Scanner plugin
  2. Go to: Manage Jenkins → Global Tool Configuration
  3. Add SonarQube Scanner with name 'sonar-scanner'
Skipping SonarQube analysis...
```

This allows builds to proceed without failing when SonarQube is unavailable.

---

### 🔧 Troubleshooting SonarQube

| Issue | Solution |
|-------|----------|
| **Container won't start** | Check `vm.max_map_count`: `sysctl vm.max_map_count` |
| **Database connection failed** | Verify PostgreSQL is running: `docker ps` |
| **Scanner not found** | Add tool in Jenkins: `Manage Jenkins → Tools` |
| **Quality Gate timeout** | Configure webhook in SonarQube |
| **Token invalid** | Regenerate token in SonarQube |
| **No coverage data** | Ensure `lcov.info` exists after tests |
| **Out of memory** | Increase heap: `-Xmx4g` in scanner |

#### Check SonarQube Logs

```bash
# Docker
docker logs sonarqube

# Native
tail -f /opt/sonarqube/logs/sonar.log
tail -f /opt/sonarqube/logs/web.log
tail -f /opt/sonarqube/logs/ce.log
```

---

### 🎯 SonarQube Commands Quick Reference

```bash
# Start/Stop Docker SonarQube
docker start sonarqube
docker stop sonarqube
docker restart sonarqube

# View logs
docker logs -f sonarqube

# Run scanner manually
sonar-scanner \
  -Dsonar.projectKey=shopdeploy \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=squ_xxx

# Check scanner version
sonar-scanner --version

# Clean cache
rm -rf ~/.sonar/cache
```

---

## 💬 Slack Integration

### Enable Slack Notifications

1. **Create Slack App**
   - Go to: https://api.slack.com/apps
   - Create new app → From scratch
   - Add `Incoming Webhooks` feature
   - Create webhook for `#deployments` channel

2. **Configure in Jenkins**
   
   Navigate to: `Manage Jenkins → Configure System → Slack`
   
   | Field | Value |
   |-------|-------|
   | Workspace | Your Slack workspace |
   | Credential | Slack token credential |
   | Default channel | `#deployments` |

3. **Enable in Pipeline**
   
   Update `Jenkinsfile-cd`:
   ```groovy
   environment {
       SLACK_ENABLED = 'true'  // Change from 'false' to 'true'
   }
   ```

### Notification Types

| Event | Channel | Color | Example |
|-------|---------|-------|---------|
| CI Success | #deployments | 🟢 Green | `🟢 CI Build Success | DEV | Build #42 | Tag: 42-abc1234` |
| CI Failure | #deployments | 🔴 Red | `❌ CI Build FAILED | DEV | Build #42 | Stage: Tests` |
| Prod Approval | #deployments | 🟡 Yellow | `🔴 Production deployment approval needed | Tag: 42-abc1234` |
| Deploy Success | #deployments | 🟢 Green | `🔴 Deployed to PROD | Namespace: shopdeploy-prod | Tag: 42-abc1234` |
| Deploy Failure | #deployments | 🔴 Red | `❌ Deploy FAILED: PROD | Tag: 42-abc1234 | Stage: Deploy` |

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Docker Permission Denied

**Error:**
```
Got permission denied while trying to connect to the Docker daemon socket
```

**Solution:**
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

#### 2. ECR Login Failed

**Error:**
```
Error: Cannot perform an interactive login from a non TTY device
```

**Solution:**
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Manual ECR login test
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_URL>
```

#### 3. kubectl Not Configured

**Error:**
```
error: You must be logged in to the server (Unauthorized)
```

**Solution:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name shopdeploy-prod-eks

# Verify
kubectl get nodes
```

#### 4. Helm Release Stuck

**Error:**
```
Error: UPGRADE FAILED: another operation (install/upgrade/rollback) is in progress
```

**Solution:**
```bash
# Check Helm history
helm history <release-name> -n <namespace>

# If stuck, use rollback
helm rollback <release-name> <revision> -n <namespace>

# Nuclear option (use carefully)
kubectl delete secret -l owner=helm,name=<release-name> -n <namespace>
```

#### 5. SonarQube Scanner Not Found

**Error:**
```
No tool named sonar-scanner found
```

**Solution:**
1. Go to: `Manage Jenkins → Tools`
2. Add SonarQube Scanner installation
3. Name it exactly: `sonar-scanner`

#### 6. Pod CrashLoopBackOff

**Debug:**
```bash
# Check pod status
kubectl get pods -n shopdeploy-<env>

# Check pod events
kubectl describe pod <pod-name> -n shopdeploy-<env>

# Check pod logs
kubectl logs <pod-name> -n shopdeploy-<env> --previous
```

#### 7. Image Not Found in ECR

**Error:**
```
Backend image not found: 42-abc1234
```

**Solution:**
```bash
# List available images
aws ecr describe-images --repository-name shopdeploy-prod-backend --region us-east-1

# Verify correct tag format
# Tags should be: BUILD_NUMBER-COMMIT_HASH (e.g., 42-abc1234)
```

### Debug Commands

```bash
# Check Jenkins logs
sudo journalctl -u jenkins -f

# Check Docker daemon
sudo systemctl status docker

# Test AWS connectivity
aws sts get-caller-identity

# Test kubectl
kubectl cluster-info

# Test Helm
helm list -A

# Check ECR images
aws ecr describe-images --repository-name shopdeploy-prod-backend
```

---

## ✅ Best Practices

### Pipeline Best Practices

| Practice | Implementation |
|----------|----------------|
| **Pipeline as Code** | Jenkinsfile stored in Git repository |
| **Immutable Tags** | Format: `BUILD_NUMBER-COMMIT_HASH` (never `latest`) |
| **Parallel Stages** | Backend/Frontend built simultaneously |
| **Retry Logic** | ECR push with 3 retries |
| **Timeout** | 45 min CI, 30 min CD |
| **Cleanup** | Workspace and Docker image cleanup |
| **Artifacts** | Archive `image-tag.txt` and coverage reports |

### Security Best Practices

| Practice | Implementation |
|----------|----------------|
| **Credentials** | Jenkins Credentials Plugin (never hardcode) |
| **Secrets** | AWS Secrets Manager / Parameter Store |
| **Image Scanning** | Trivy scans for HIGH/CRITICAL CVEs |
| **Code Analysis** | SonarQube security rules |
| **RBAC** | Role-based Jenkins access |
| **Approval Gates** | Manual approval for production |

### Operational Best Practices

| Practice | Implementation |
|----------|----------------|
| **Build Once, Deploy Many** | Same image: dev → staging → prod |
| **Automatic Rollback** | Helm rollback on failure |
| **Health Checks** | Smoke tests after deployment |
| **Notifications** | Slack alerts for all deployments |
| **Audit Trail** | Git history + Jenkins build logs |
| **Backup** | Jenkins home directory backup |

---

## 📊 Pipeline Metrics

### Key Metrics to Track

| Metric | Target | Current |
|--------|--------|---------|
| **CI Build Time** | < 15 min | ~12 min |
| **CD Deploy Time** | < 10 min | ~8 min |
| **Build Success Rate** | > 95% | - |
| **Deployment Frequency** | Daily | - |
| **MTTR (Mean Time to Recovery)** | < 30 min | - |
| **Change Failure Rate** | < 5% | - |

### Dashboard Setup

Consider setting up a Jenkins Dashboard with:
- Build history trends
- Test coverage trends
- Deployment frequency
- Success/failure rates

---

## 🔗 Quick Reference

### Pipeline Trigger Flow

```
Git Push → GitHub Webhook → Jenkins CI → ECR Push → Trigger CD → Helm Deploy → EKS
```

### Manual Deployment

```bash
# Deploy specific image tag
# 1. Go to Jenkins → shopdeploy-cd → Build with Parameters
# 2. Set IMAGE_TAG: 42-abc1234
# 3. Set ENVIRONMENT: prod
# 4. Click Build
# 5. Approve at Production Approval stage
```

### Useful Jenkins URLs

| URL | Purpose |
|-----|---------|
| `/job/shopdeploy-ci/` | CI Pipeline |
| `/job/shopdeploy-cd/` | CD Pipeline |
| `/credentials/` | Manage Credentials |
| `/configureTools/` | Tool Configuration |
| `/configure/` | System Configuration |
| `/safeRestart` | Safe Restart |

---

## 🎯 Production Kubernetes Commands Cheat Sheet

> **After pipeline deployment, use these commands daily for operations and debugging.**

### 🔧 Quick Setup: Stop Typing `kubectl`

```bash
# Add to ~/.bashrc or ~/.zshrc
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
```

---

### 🚀 1. Cluster Commands (First Thing to Check)

```bash
# Verify cluster connection
kubectl cluster-info

# Check worker nodes (IP, instance type, zone)
kubectl get nodes -o wide

# Check node health (memory/disk pressure, kubelet errors)
kubectl describe node <node-name>
```

**Use when:** Pods not scheduling, node crash, capacity issues

---

### 🚀 2. Namespace Commands

```bash
# List all namespaces
kubectl get ns

# Set default namespace (avoid typing -n every time)
kubectl config set-context --current --namespace=shopdeploy-dev

# Your namespaces:
# shopdeploy-dev | shopdeploy-staging | shopdeploy-prod
```

---

### 🚀 3. Deployment Commands (Most Important)

```bash
# List deployments
kubectl get deploy -n shopdeploy-dev

# Check rollout status (used in CI/CD)
kubectl rollout status deployment/shopdeploy-backend -n shopdeploy-dev

# Restart deployment (after ConfigMap/Secret change)
kubectl rollout restart deployment shopdeploy-backend -n shopdeploy-dev

# 🔥 ROLLBACK (Production Lifesaver)
kubectl rollout undo deployment shopdeploy-backend -n shopdeploy-dev

# Rollback to specific revision
kubectl rollout undo deployment shopdeploy-backend --to-revision=2 -n shopdeploy-dev
```

---

### 🚀 4. Pod Commands (Debugging Hero)

```bash
# List pods with details
kubectl get pods -o wide -n shopdeploy-dev

# 🔥 Describe pod (MOST used debug command)
kubectl describe pod <pod-name> -n shopdeploy-dev

# View logs
kubectl logs <pod-name> -n shopdeploy-dev

# Real-time logs
kubectl logs -f <pod-name> -n shopdeploy-dev

# Logs from crashed container
kubectl logs <pod-name> --previous -n shopdeploy-dev

# 🔥 Execute inside pod (DB test, curl, env vars)
kubectl exec -it <pod-name> -n shopdeploy-dev -- sh
```

---

### 🚀 5. Service Commands

```bash
# List all services
kubectl get svc -n shopdeploy-dev

# Describe service (targetPort, endpoints, ELB events)
kubectl describe svc shopdeploy-backend -n shopdeploy-dev

# Watch LoadBalancer creation
kubectl get svc -w -n shopdeploy-dev

# Get LoadBalancer URL
kubectl get svc shopdeploy-frontend -n shopdeploy-dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

### 🚀 6. Access Application

```bash
# Port forward (temporary local access)
kubectl port-forward svc/shopdeploy-backend 5000:5000 -n shopdeploy-dev
# Open: http://localhost:5000

kubectl port-forward svc/shopdeploy-frontend 8080:80 -n shopdeploy-dev
# Open: http://localhost:8080

# Test health endpoint
curl http://localhost:5000/api/health/health
```

---

### 🚀 7. Helm Commands

```bash
# List releases
helm list -n shopdeploy-dev

# View release history
helm history shopdeploy-backend -n shopdeploy-dev

# Upgrade app
helm upgrade shopdeploy-backend ./helm/backend \
  -n shopdeploy-dev -f helm/backend/values-dev.yaml

# 🔥 Rollback Helm release (safer than kubectl)
helm rollback shopdeploy-backend 1 -n shopdeploy-dev

# View current values
helm get values shopdeploy-backend -n shopdeploy-dev

# Dry-run upgrade
helm upgrade shopdeploy-backend ./helm/backend --dry-run -n shopdeploy-dev
```

---

### 🚀 8. Scaling

```bash
# Manual scaling (Black Friday, traffic spike)
kubectl scale deployment shopdeploy-backend --replicas=5 -n shopdeploy-dev

# Check HPA status
kubectl get hpa -n shopdeploy-dev

# Describe HPA
kubectl describe hpa shopdeploy-backend -n shopdeploy-dev
```

---

### 🚀 9. Resource Monitoring

```bash
# Pod CPU/Memory usage
kubectl top pods -n shopdeploy-dev

# Node usage
kubectl top nodes

# Events (sorted by time)
kubectl get events --sort-by='.lastTimestamp' -n shopdeploy-dev
```

---

### 🚀 10. Delete Commands (⚠️ Careful)

```bash
# Delete pod (new one auto-created)
kubectl delete pod <pod-name> -n shopdeploy-dev

# Delete deployment
kubectl delete deployment shopdeploy-backend -n shopdeploy-dev

# Uninstall Helm release
helm uninstall shopdeploy-backend -n shopdeploy-dev
```

---

### ⭐ Top 10 Commands (Memorize These)

```bash
kubectl get pods -o wide              # See all pods
kubectl get svc                       # See services/LoadBalancers
kubectl get deploy                    # See deployments
kubectl logs <pod>                    # View logs
kubectl describe pod <pod>            # Debug pod issues
kubectl exec -it <pod> -- sh          # Shell into pod
kubectl rollout status deploy <name>  # Watch deployment
kubectl rollout undo deploy <name>    # Rollback deployment
helm list                             # See Helm releases
helm rollback <release> <revision>    # Rollback Helm
```

> 💡 These 10 commands solve **80% of production issues**.

---

### 🔥 Quick Debugging Workflow

```bash
# 1. Check pod status
kubectl get pods -n shopdeploy-prod

# 2. If not Running, describe it
kubectl describe pod <pod-name> -n shopdeploy-prod

# 3. Check logs
kubectl logs <pod-name> -n shopdeploy-prod

# 4. If CrashLoopBackOff, check previous logs
kubectl logs <pod-name> --previous -n shopdeploy-prod

# 5. If needed, rollback
kubectl rollout undo deployment shopdeploy-backend -n shopdeploy-prod
# OR
helm rollback shopdeploy-backend 1 -n shopdeploy-prod
```

---

## 📁 Related Files

| File | Location | Purpose |
|------|----------|---------|
| CI Pipeline | `ci-cd/Jenkinsfile-ci` | CI pipeline definition |
| CD Pipeline | `ci-cd/Jenkinsfile-cd` | CD pipeline definition |
| Backend Helm | `helm/backend/` | Backend deployment chart |
| Frontend Helm | `helm/frontend/` | Frontend deployment chart |
| Install Script | `scripts/monitoring/install-jenkins.sh` | Jenkins installation |

---

*Last Updated: February 2026*
