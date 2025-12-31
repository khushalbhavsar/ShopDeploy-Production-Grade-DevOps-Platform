# 🚀 ShopDeploy - Complete Amazon Linux Setup Guide

<p align="center">
  <img src="https://img.shields.io/badge/Amazon_Linux-2023-FF9900?style=for-the-badge&logo=amazon-aws" alt="Amazon Linux"/>
  <img src="https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=for-the-badge&logo=terraform" alt="Terraform"/>
  <img src="https://img.shields.io/badge/Jenkins-LTS-D24939?style=for-the-badge&logo=jenkins" alt="Jenkins"/>
  <img src="https://img.shields.io/badge/SonarQube-4E9BCD?style=for-the-badge&logo=sonarqube" alt="SonarQube"/>
  <img src="https://img.shields.io/badge/Kubernetes-EKS-326CE5?style=for-the-badge&logo=kubernetes" alt="EKS"/>
</p>

This guide provides **step-by-step instructions** to set up the complete ShopDeploy infrastructure on Amazon Linux from scratch.

---

## 📋 Table of Contents

1. [Prerequisites & EC2 Launch](#-step-1-prerequisites--ec2-launch)
2. [Clone Git Repository](#-step-2-clone-git-repository)
3. [Install All Dependencies](#-step-3-install-all-dependencies)
4. [AWS CLI Configuration](#-step-4-aws-cli-configuration)
5. [Terraform Setup & Infrastructure](#-step-5-terraform-setup--infrastructure)
6. [Jenkins Setup & Configuration](#-step-6-jenkins-setup--configuration)
7. [SonarQube Setup & Configuration](#-step-7-sonarqube-setup--configuration)
8. [Deploy Application to EKS](#-step-8-deploy-application-to-eks)
9. [Monitoring Setup (Prometheus & Grafana)](#-step-9-monitoring-setup-prometheus--grafana)
10. [Dashboard Creation](#-step-10-dashboard-creation)
11. [Verification & Testing](#-step-11-verification--testing)
12. [Troubleshooting](#-troubleshooting)

---

## 🖥️ Step 1: Prerequisites & EC2 Launch

### Launch EC2 Instance

1. **Go to AWS Console** → EC2 → Launch Instance

2. **Configure Instance:**

| Setting | Recommended Value |
|---------|------------------|
| **Name** | `shopdeploy-devops-server` |
| **AMI** | Amazon Linux 2023 / Amazon Linux 2 |
| **Instance Type** | `t3.large` (2 vCPU, 8GB RAM) minimum |
| **Storage** | 50 GB gp3 |
| **Key Pair** | Create or select existing |
| **Security Group** | See below |

3. **Security Group Rules:**

| Type | Port | Source | Purpose |
|------|------|--------|---------|
| SSH | 22 | Your IP | SSH access |
| HTTP | 80 | 0.0.0.0/0 | Web access |
| HTTPS | 443 | 0.0.0.0/0 | Secure web |
| Custom TCP | 8080 | 0.0.0.0/0 | Jenkins |
| Custom TCP | 9090 | Your IP | Prometheus |
| Custom TCP | 3000 | 0.0.0.0/0 | Grafana |
| Custom TCP | 9000 | Your IP | SonarQube |

4. **Launch and Connect:**

```bash
# Connect via SSH
ssh -i "your-key.pem" ec2-user@<EC2-PUBLIC-IP>

# Or for Amazon Linux 2023
ssh -i "your-key.pem" ec2-user@<EC2-PUBLIC-IP>
```

---

## 📥 Step 2: Clone Git Repository

### Clone the ShopDeploy Repository

```bash
# Update system packages
sudo yum update -y

# Install Git
sudo yum install -y git

# Clone the repository
cd ~
git clone https://github.com/YOUR-USERNAME/ShopDeploy.git

# Navigate to project directory
cd ShopDeploy

# Verify project structure
ls -la
```

### Expected Structure:
```
ShopDeploy/
├── docker-compose.yml
├── Jenkinsfile
├── docs/
├── helm/
├── k8s/
├── monitoring/
├── scripts/
├── shopdeploy-backend/
├── shopdeploy-frontend/
└── terraform/
```

---

## 🛠️ Step 3: Install All Dependencies

### Option A: Automated Installation (Recommended)

```bash
# Navigate to scripts directory
cd ~/ShopDeploy/scripts

# Make all scripts executable
chmod +x *.sh

# Run the complete bootstrap script
sudo ./ec2-bootstrap.sh
```

### Option B: Manual Installation (Step by Step)

#### 3.1 Install Basic Utilities

```bash
sudo yum update -y
sudo yum install -y git curl wget unzip jq tree htop vim
```

#### 3.2 Install Docker

```bash
# Install Docker
sudo yum install -y docker

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add ec2-user to docker group
sudo usermod -aG docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# IMPORTANT: Log out and log back in for group changes
exit
# Then reconnect via SSH
```

#### 3.3 Install Jenkins

```bash
# Install Java 17 (required for Jenkins)
sudo yum install -y java-17-amazon-corretto java-17-amazon-corretto-devel

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo yum install -y jenkins

# Start and enable Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Add Jenkins to docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

#### 3.4 Install Terraform

```bash
# Add HashiCorp repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install Terraform
sudo yum install -y terraform

# Verify installation
terraform --version
```

#### 3.5 Install kubectl

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

#### 3.6 Install Helm

```bash
# Download and install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Verify installation
helm version
```

#### 3.7 Install AWS CLI v2

```bash
# Download AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip and install
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version

# Clean up
rm -rf aws awscliv2.zip
```

#### 3.8 Install Node.js

```bash
# Install Node.js 18.x
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Verify installation
node --version
npm --version
```

### Verify All Installations

```bash
echo "=== Verification ==="
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker-compose --version)"
echo "Java: $(java -version 2>&1 | head -1)"
echo "Jenkins: $(systemctl status jenkins | grep Active)"
echo "Terraform: $(terraform --version | head -1)"
echo "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "Helm: $(helm version --short)"
echo "AWS CLI: $(aws --version)"
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
```

---

## 🔐 Step 4: AWS CLI Configuration

### Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure
```

Enter your credentials:
```
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: us-east-1
Default output format [None]: json
```

### Verify AWS Configuration

```bash
# Verify credentials
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAXXXXXXXXXX",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/your-user"
# }
```

### Required IAM Permissions

Ensure your IAM user/role has these policies:
- `AmazonVPCFullAccess`
- `AmazonEKSClusterPolicy`
- `AmazonEC2ContainerRegistryFullAccess`
- `IAMFullAccess`
- `AmazonEC2FullAccess`

---

## 🏗️ Step 5: Terraform Setup & Infrastructure

### 5.1 Navigate to Terraform Directory

```bash
cd ~/ShopDeploy/terraform
```

### 5.2 Configure Terraform Variables

```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit variables (use vim, nano, or any editor)
vim terraform.tfvars
```

**terraform.tfvars Configuration:**

```hcl
# Project Configuration
project_name = "shopdeploy"
environment  = "prod"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
enable_nat_gateway   = true
single_nat_gateway   = true  # Set to true for cost savings

# EKS Configuration
eks_cluster_version     = "1.29"
eks_node_instance_types = ["t3.medium"]
eks_node_desired_size   = 2
eks_node_min_size       = 2
eks_node_max_size       = 5
eks_node_disk_size      = 50

# ECR Configuration
ecr_image_retention_count = 30
```

### 5.3 Initialize Terraform

```bash
# Initialize Terraform (downloads providers)
terraform init

# Expected output: "Terraform has been successfully initialized!"
```

### 5.4 Plan Infrastructure

```bash
# Preview what will be created
terraform plan -out=tfplan

# Review the plan carefully - it shows:
# - Resources to be created
# - Estimated costs
# - Any potential issues
```

### 5.5 Apply Infrastructure

```bash
# Create all AWS resources
terraform apply tfplan

# Or with auto-approve (use with caution)
# terraform apply -auto-approve
```

**⏱️ This takes 15-25 minutes** to create:
- VPC with public/private subnets
- EKS cluster
- ECR repositories
- IAM roles and policies
- NAT Gateway

### 5.6 Configure kubectl for EKS

```bash
# Get the kubectl configuration command from Terraform output
terraform output configure_kubectl

# Run the command (example):
aws eks update-kubeconfig --region us-east-1 --name shopdeploy-prod-eks

# Verify connection
kubectl get nodes
kubectl cluster-info
```

### 5.7 Save Important Outputs

```bash
# Save all outputs for later use
terraform output > ~/terraform-outputs.txt

# View ECR URLs
terraform output ecr_backend_url
terraform output ecr_frontend_url

# View EKS cluster name
terraform output eks_cluster_name
```

---

## 🔧 Step 6: Jenkins Setup & Configuration

### 6.1 Access Jenkins

```bash
# Get Jenkins initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

1. Open browser: `http://<EC2-PUBLIC-IP>:8080`
2. Paste the initial admin password
3. Click "Install suggested plugins"
4. Create admin user

### 6.2 Install Required Plugins

Go to **Manage Jenkins → Plugins → Available plugins**

Install these plugins:

| Plugin | Purpose |
|--------|---------|
| **Pipeline** | Jenkinsfile pipelines |
| **Git** | Git integration |
| **GitHub** | GitHub webhooks |
| **Docker Pipeline** | Docker builds |
| **Amazon ECR** | AWS ECR auth |
| **AWS Credentials** | AWS credentials |
| **Kubernetes** | K8s deployments |
| **Kubernetes CLI** | kubectl integration |
| **NodeJS** | Node.js builds |
| **Blue Ocean** | Modern UI |

### 6.3 Configure Credentials

Go to **Manage Jenkins → Credentials → System → Global credentials**

#### Add AWS Credentials:

1. Click "Add Credentials"
2. **Kind:** AWS Credentials
3. **ID:** `aws-credentials`
4. **Access Key ID:** Your AWS access key
5. **Secret Access Key:** Your AWS secret key
6. Click "Create"

#### Add AWS Account ID:

1. Click "Add Credentials"
2. **Kind:** Secret text
3. **ID:** `aws-account-id`
4. **Secret:** Your 12-digit AWS account ID
5. Click "Create"

#### Add GitHub Credentials (for private repos):

1. Click "Add Credentials"
2. **Kind:** Username with password
3. **ID:** `github-credentials`
4. **Username:** Your GitHub username
5. **Password:** Your GitHub Personal Access Token
6. Click "Create"

### 6.4 Configure Node.js in Jenkins

Go to **Manage Jenkins → Tools**

1. Scroll to "NodeJS installations"
2. Click "Add NodeJS"
3. **Name:** `NodeJS-18`
4. **Version:** Select 18.x
5. Click "Save"

### 6.5 Create Pipeline Job

1. Click "New Item"
2. Enter name: `shopdeploy-pipeline`
3. Select "Pipeline"
4. Click "OK"

**Pipeline Configuration:**

- **Definition:** Pipeline script from SCM
- **SCM:** Git
- **Repository URL:** `https://github.com/YOUR-USERNAME/ShopDeploy.git`
- **Credentials:** Select your GitHub credentials
- **Branch:** `*/main`
- **Script Path:** `Jenkinsfile`

Click "Save"

### 6.6 Run Your First Build

1. Click "Build Now"
2. Click on the build number to see logs
3. Monitor the pipeline stages

---
## 🔍 Step 7: SonarQube Setup & Configuration

SonarQube is used for continuous code quality inspection and security vulnerability detection.

### 7.1 Install SonarQube Using Docker

```bash
# Create a directory for SonarQube data
sudo mkdir -p /opt/sonarqube/data
sudo mkdir -p /opt/sonarqube/logs
sudo mkdir -p /opt/sonarqube/extensions
sudo chown -R 1000:1000 /opt/sonarqube

# Set required system limits for Elasticsearch
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072

# Make it persistent
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf

# Pull the latest SonarQube LTS image (10.7+)
docker pull sonarqube:10.7-community

# Run SonarQube container
docker run -d --name sonarqube \
    --restart unless-stopped \
    -p 9000:9000 \
    -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
    -v /opt/sonarqube/data:/opt/sonarqube/data \
    -v /opt/sonarqube/logs:/opt/sonarqube/logs \
    -v /opt/sonarqube/extensions:/opt/sonarqube/extensions \
    sonarqube:10.7-community

# Verify container is running
docker ps | grep sonarqube

# Wait for SonarQube to start (takes 1-2 minutes)
echo "Waiting for SonarQube to start..."
until curl -s http://localhost:9000/api/system/status | grep -q '"status":"UP"'; do
    sleep 10
    echo "Still waiting..."
done
echo "SonarQube is ready!"

# Check logs
docker logs -f sonarqube
```

### 7.2 Access SonarQube Web UI

1. Open browser: `http://<EC2-PUBLIC-IP>:9000`
2. Default credentials:
   - **Username:** `admin`
   - **Password:** `admin`
3. You will be prompted to change the password on first login

### 7.3 Create SonarQube Project

1. **Login to SonarQube**
2. Click **"Create Project"** → **"Manually"**
3. Configure project:
   - **Project display name:** `ShopDeploy`
   - **Project key:** `shopdeploy`
   - Click **"Set Up"**

4. **Generate Token:**
   - Select **"Generate a token"**
   - Token name: `jenkins-token`
   - Click **"Generate"**
   - **⚠️ Copy and save the token** (you won't see it again)

5. **Select Analysis Method:**
   - Choose **"Other CI"** for Jenkins integration
   - Select **"JavaScript"** for frontend or appropriate language

### 7.4 Install SonarQube Scanner

```bash
# Download SonarQube Scanner (latest version 6.2)
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.2.1.4610-linux-x64.zip

# Unzip
sudo unzip sonar-scanner-cli-6.2.1.4610-linux-x64.zip
sudo mv sonar-scanner-6.2.1.4610-linux-x64 sonar-scanner

# Add to PATH
echo 'export PATH=$PATH:/opt/sonar-scanner/bin' | sudo tee -a /etc/profile.d/sonar-scanner.sh
source /etc/profile.d/sonar-scanner.sh

# Verify installation
sonar-scanner --version

# Expected output: SonarScanner 6.2.1.4610
```

### 7.5 Configure SonarQube Quality Gates

1. Go to **Quality Gates** in SonarQube
2. Click **"Create"** or use default **"Sonar way"**
3. Recommended conditions:

| Metric | Operator | Value |
|--------|----------|-------|
| Coverage | is less than | 80% |
| Duplicated Lines (%) | is greater than | 3% |
| Maintainability Rating | is worse than | A |
| Reliability Rating | is worse than | A |
| Security Hotspots Reviewed | is less than | 100% |
| Security Rating | is worse than | A |

### 7.6 Integrate SonarQube with Jenkins

#### Install SonarQube Plugin in Jenkins:

1. Go to **Manage Jenkins → Plugins → Available plugins**
2. Search and install:
   - **SonarQube Scanner**
   - **Sonar Quality Gates Plugin**
3. Restart Jenkins

#### Configure SonarQube Server in Jenkins:

1. Go to **Manage Jenkins → System**
2. Scroll to **SonarQube servers**
3. Click **"Add SonarQube"**
4. Configure:
   - **Name:** `SonarQube`
   - **Server URL:** `http://<EC2-PUBLIC-IP>:9000`
   - **Server authentication token:** Add credentials
     - Kind: **Secret text**
     - Secret: Your SonarQube token
     - ID: `sonarqube-token`
5. Click **Save**

#### Configure SonarQube Scanner in Jenkins:

1. Go to **Manage Jenkins → Tools**
2. Scroll to **SonarQube Scanner installations**
3. Click **"Add SonarQube Scanner"**
4. Configure:
   - **Name:** `SonarScanner`
   - **Install automatically:** ✓ Check this
   - **Version:** Select latest version
5. Click **Save**

### 7.7 Add SonarQube Stage to Jenkinsfile

Add the following stage to your `Jenkinsfile`:

```groovy
// Add environment variable
environment {
    SONAR_SCANNER_HOME = tool 'SonarScanner'
}

// Add SonarQube analysis stage
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh '''
                ${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectKey=shopdeploy \
                    -Dsonar.projectName=ShopDeploy \
                    -Dsonar.sources=. \
                    -Dsonar.sourceEncoding=UTF-8 \
                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                    -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js
            '''
        }
    }
}

// Add Quality Gate stage
stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

### 7.8 Create sonar-project.properties File

Create this file in your project root:

```properties
# Project identification
sonar.projectKey=shopdeploy
sonar.projectName=ShopDeploy
sonar.projectVersion=1.0

# Source directories
sonar.sources=shopdeploy-backend/src,shopdeploy-frontend/src

# Exclusions
sonar.exclusions=**/node_modules/**,**/coverage/**,**/dist/**,**/*.test.js,**/*.spec.js

# Test directories
sonar.tests=shopdeploy-backend/src,shopdeploy-frontend/src
sonar.test.inclusions=**/*.test.js,**/*.spec.js

# Coverage reports
sonar.javascript.lcov.reportPaths=shopdeploy-backend/coverage/lcov.info,shopdeploy-frontend/coverage/lcov.info

# Encoding
sonar.sourceEncoding=UTF-8
```

### 7.9 Run SonarQube Analysis Manually

```bash
# Navigate to project directory
cd ~/ShopDeploy

# Set your SonarQube token (recommended: use environment variable)
export SONAR_TOKEN="YOUR_SONARQUBE_TOKEN"

# Run SonarQube analysis
sonar-scanner \
    -Dsonar.host.url=http://localhost:9000 \
    -Dsonar.token=$SONAR_TOKEN

# Alternative: Run with inline token (not recommended for scripts)
# sonar-scanner \
#     -Dsonar.host.url=http://localhost:9000 \
#     -Dsonar.token=YOUR_SONARQUBE_TOKEN

# Check analysis results
echo "Analysis complete! View results at http://<EC2-PUBLIC-IP>:9000/dashboard?id=shopdeploy"
```

### 7.10 SonarQube with Docker Compose (Alternative)

For production setup with PostgreSQL database:

```yaml
# docker-compose-sonarqube.yml
version: "3.8"

services:
  sonarqube:
    image: sonarqube:10.7-community
    container_name: sonarqube
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: "true"
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ports:
      - "9000:9000"
    networks:
      - sonarnet
    ulimits:
      nofile:
        soft: 65536
        hard: 65536

  db:
    image: postgres:16-alpine
    container_name: sonarqube-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    networks:
      - sonarnet
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sonar -d sonar"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  sonarnet:
    driver: bridge

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql_data:
```

```bash
# Deploy SonarQube with PostgreSQL
docker-compose -f docker-compose-sonarqube.yml up -d
```

### 7.11 Verify SonarQube Installation

```bash
# Check SonarQube container status
docker ps | grep sonarqube

# Check SonarQube logs
docker logs sonarqube

# Test SonarQube API
curl -s http://localhost:9000/api/system/status | jq .

# Expected output:
# {
#   "id": "...",
#   "version": "...",
#   "status": "UP"
# }
```

---
## 🚀 Step 8: Deploy Application to EKS

### 8.1 Login to ECR

```bash
# Get ECR login command from Terraform output
eval $(terraform output -raw ecr_login_command)

# Or manually:
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com
```

### 8.2 Build and Push Docker Images

```bash
# Navigate to backend
cd ~/ShopDeploy/shopdeploy-backend

# Build backend image
docker build -t shopdeploy-backend:latest .

# Tag for ECR
docker tag shopdeploy-backend:latest <ECR-BACKEND-URL>:latest

# Push to ECR
docker push <ECR-BACKEND-URL>:latest

# Navigate to frontend
cd ~/ShopDeploy/shopdeploy-frontend

# Build frontend image
docker build -t shopdeploy-frontend:latest .

# Tag for ECR
docker tag shopdeploy-frontend:latest <ECR-FRONTEND-URL>:latest

# Push to ECR
docker push <ECR-FRONTEND-URL>:latest
```

### 8.3 Deploy Using Helm

```bash
# Create namespace
kubectl create namespace shopdeploy

# Deploy backend
cd ~/ShopDeploy
helm upgrade --install shopdeploy-backend ./helm/backend \
    --namespace shopdeploy \
    --set image.repository=<ECR-BACKEND-URL> \
    --set image.tag=latest \
    --values ./helm/backend/values-prod.yaml

# Deploy frontend
helm upgrade --install shopdeploy-frontend ./helm/frontend \
    --namespace shopdeploy \
    --set image.repository=<ECR-FRONTEND-URL> \
    --set image.tag=latest \
    --values ./helm/frontend/values-prod.yaml
```

### 8.4 Verify Deployment

```bash
# Check pods
kubectl get pods -n shopdeploy

# Check services
kubectl get svc -n shopdeploy

# Get application URL
kubectl get ingress -n shopdeploy
```

---

## 📊 Step 9: Monitoring Setup (Prometheus & Grafana)

### 9.1 Automated Installation

```bash
# Set Grafana admin password
export GRAFANA_ADMIN_PASSWORD="YourSecurePassword123!"

# Navigate to monitoring directory
cd ~/ShopDeploy/monitoring

# Make script executable
chmod +x install-monitoring.sh

# Run installation
./install-monitoring.sh monitoring
```

### 9.2 Manual Installation

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace monitoring

# Install Prometheus
helm upgrade --install prometheus prometheus-community/prometheus \
    --namespace monitoring \
    --values ~/ShopDeploy/monitoring/prometheus-values.yaml \
    --wait --timeout 10m

# Install Grafana
helm upgrade --install grafana grafana/grafana \
    --namespace monitoring \
    --values ~/ShopDeploy/monitoring/grafana-values.yaml \
    --set adminPassword="YourSecurePassword123!" \
    --wait --timeout 10m
```

### 9.3 Access Monitoring Tools

```bash
# Get Grafana LoadBalancer URL
kubectl get svc grafana -n monitoring

# Or port-forward for local access
kubectl port-forward svc/grafana 3000:80 -n monitoring &

# Access Prometheus
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring &
```

**Access URLs:**
- **Grafana:** `http://<LOADBALANCER-URL>:3000` or `http://localhost:3000`
  - Username: `admin`
  - Password: The password you set
- **Prometheus:** `http://localhost:9090`

### 9.4 Verify Monitoring Installation

```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Expected output:
# NAME                                             READY   STATUS    RESTARTS   AGE
# grafana-xxxxxxxxx-xxxxx                          1/1     Running   0          5m
# prometheus-alertmanager-xxxxxxxxx-xxxxx          1/1     Running   0          5m
# prometheus-kube-state-metrics-xxxxxxxxx-xxxxx    1/1     Running   0          5m
# prometheus-node-exporter-xxxxx                   1/1     Running   0          5m
# prometheus-server-xxxxxxxxx-xxxxx                2/2     Running   0          5m
```

---

## 📈 Step 10: Dashboard Creation

### 10.1 Import ShopDeploy Dashboard

1. **Login to Grafana** (`http://<GRAFANA-URL>:3000`)

2. **Add Prometheus Data Source:**
   - Go to: Configuration → Data Sources → Add data source
   - Select: Prometheus
   - URL: `http://prometheus-server.monitoring.svc.cluster.local`
   - Click: "Save & Test"

3. **Import ShopDeploy Dashboard:**
   - Go to: Dashboards → Import
   - Upload: `~/ShopDeploy/monitoring/dashboards/shopdeploy-dashboard.json`
   - Select Prometheus data source
   - Click: "Import"

### 10.2 Create Custom Dashboards

#### Create Kubernetes Overview Dashboard:

1. Dashboards → New Dashboard → Add new panel
2. Add these panels:

**Panel 1: Pod Count**
```promql
count(kube_pod_info{namespace="shopdeploy"})
```

**Panel 2: CPU Usage**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="shopdeploy"}[5m])) by (pod)
```

**Panel 3: Memory Usage**
```promql
sum(container_memory_usage_bytes{namespace="shopdeploy"}) by (pod) / 1024 / 1024
```

**Panel 4: HTTP Request Rate**
```promql
sum(rate(http_requests_total{namespace="shopdeploy"}[5m])) by (service)
```

### 10.3 Import Community Dashboards

Import these popular dashboards from Grafana.com:

| Dashboard ID | Name | Purpose |
|--------------|------|---------|
| **315** | Kubernetes Cluster Monitoring | Overall cluster health |
| **6417** | Kubernetes Pods | Pod-level metrics |
| **7249** | Kubernetes Cluster | Namespace overview |
| **11074** | Node Exporter | Host metrics |

**To Import:**
1. Dashboards → Import
2. Enter Dashboard ID
3. Click "Load"
4. Select Prometheus data source
5. Click "Import"

### 10.4 Configure Alerting

1. **Go to:** Alerting → Alert rules → New alert rule

2. **Create CPU Alert:**
   - Name: `High CPU Usage`
   - Query: `avg(rate(container_cpu_usage_seconds_total{namespace="shopdeploy"}[5m])) > 0.8`
   - Condition: When query is above 0.8
   - Notification: Select your notification channel

3. **Create Memory Alert:**
   - Name: `High Memory Usage`
   - Query: `sum(container_memory_usage_bytes{namespace="shopdeploy"}) / sum(machine_memory_bytes) > 0.85`

---

## ✅ Step 11: Verification & Testing

### 11.1 Infrastructure Verification

```bash
# Check all AWS resources
aws eks describe-cluster --name shopdeploy-prod-eks --query 'cluster.status'
aws ecr describe-repositories --query 'repositories[*].repositoryName'

# Check EKS nodes
kubectl get nodes -o wide

# Check all namespaces
kubectl get ns
```

### 11.2 Application Verification

```bash
# Check shopdeploy pods
kubectl get pods -n shopdeploy -o wide

# Check services
kubectl get svc -n shopdeploy

# Check ingress
kubectl get ingress -n shopdeploy

# Check pod logs
kubectl logs -n shopdeploy -l app=shopdeploy-backend --tail=50
kubectl logs -n shopdeploy -l app=shopdeploy-frontend --tail=50
```

### 11.3 Monitoring Verification

```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Check Prometheus targets
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring &
# Open http://localhost:9090/targets

# Check Grafana dashboards
kubectl port-forward svc/grafana 3000:80 -n monitoring &
# Open http://localhost:3000
```

### 11.4 End-to-End Test

```bash
# Get application URL
APP_URL=$(kubectl get ingress -n shopdeploy -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')

# Test frontend
curl -I http://$APP_URL

# Test backend health
curl http://$APP_URL/api/health

# Run smoke tests
cd ~/ShopDeploy/scripts
chmod +x smoke-test.sh
./smoke-test.sh $APP_URL
```

---

## 🔧 Troubleshooting

### Common Issues & Solutions

#### 1. Terraform Init Fails

```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Reinitialize
terraform init -upgrade
```

#### 2. EKS Connection Issues

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name shopdeploy-prod-eks

# Verify context
kubectl config current-context

# Test connection
kubectl get nodes
```

#### 3. Jenkins Cannot Access Docker

```bash
# Add Jenkins to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

#### 4. Pods Not Starting

```bash
# Check pod status
kubectl describe pod <POD-NAME> -n shopdeploy

# Check events
kubectl get events -n shopdeploy --sort-by='.lastTimestamp'

# Check resource limits
kubectl top pods -n shopdeploy
```

#### 5. Grafana Cannot Connect to Prometheus

```bash
# Verify Prometheus service
kubectl get svc -n monitoring

# Use correct internal URL in Grafana:
# http://prometheus-server.monitoring.svc.cluster.local
```

#### 6. ECR Push Failed

```bash
# Re-authenticate to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT-ID>.dkr.ecr.us-east-1.amazonaws.com
```

#### 7. SonarQube Not Starting

```bash
# Check if vm.max_map_count is set
sysctl vm.max_map_count

# If not set or too low
sudo sysctl -w vm.max_map_count=524288

# Check SonarQube logs for errors
docker logs sonarqube

# Restart SonarQube container
docker restart sonarqube

# If permission issues
sudo chown -R 1000:1000 /opt/sonarqube
```

#### 8. SonarQube Quality Gate Fails

```bash
# Check SonarQube project status
curl -u admin:YOUR_PASSWORD "http://localhost:9000/api/qualitygates/project_status?projectKey=shopdeploy"

# View analysis logs
cat .scannerwork/report-task.txt

# Re-run analysis with debug
sonar-scanner -X -Dsonar.host.url=http://localhost:9000 -Dsonar.login=YOUR_TOKEN
```

---

## 📝 Quick Reference Commands

```bash
# === TERRAFORM ===
terraform init              # Initialize
terraform plan              # Preview changes
terraform apply             # Apply changes
terraform destroy           # Destroy infrastructure
terraform output            # View outputs

# === KUBECTL ===
kubectl get all -n shopdeploy       # Get all resources
kubectl logs <pod> -n shopdeploy    # View pod logs
kubectl exec -it <pod> -- /bin/sh   # Shell into pod
kubectl rollout restart deployment/<name> -n shopdeploy  # Restart deployment

# === HELM ===
helm list -n shopdeploy             # List releases
helm upgrade --install <name> <chart> -n shopdeploy  # Deploy
helm rollback <name> <revision> -n shopdeploy        # Rollback
helm uninstall <name> -n shopdeploy # Uninstall

# === DOCKER ===
docker build -t <name> .            # Build image
docker push <ecr-url>:<tag>         # Push to ECR
docker logs <container>             # View logs

# === MONITORING ===
kubectl port-forward svc/grafana 3000:80 -n monitoring &
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring &

# === SONARQUBE ===
docker start sonarqube             # Start SonarQube
docker stop sonarqube              # Stop SonarQube
docker logs -f sonarqube           # View logs
sonar-scanner                      # Run code analysis
curl http://localhost:9000/api/system/status  # Check status
```

---

## 🎉 Setup Complete!

You now have a fully configured ShopDeploy environment with:

| Component | Status | Access |
|-----------|--------|--------|
| ✅ AWS Infrastructure | Provisioned | AWS Console |
| ✅ EKS Cluster | Running | kubectl |
| ✅ ECR Repositories | Created | Docker push |
| ✅ Jenkins | Configured | `http://<EC2-IP>:8080` |
| ✅ SonarQube | Code Quality | `http://<EC2-IP>:9000` |
| ✅ Prometheus | Monitoring | `http://localhost:9090` |
| ✅ Grafana | Dashboards | `http://localhost:3000` |
| ✅ Application | Deployed | `http://<LB-URL>` |

---

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [Helm Documentation](https://helm.sh/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

---

<p align="center">
  <b>Happy Deploying! 🚀</b><br>
  ShopDeploy DevOps Team
</p>
