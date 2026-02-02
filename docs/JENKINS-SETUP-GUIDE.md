# Jenkins Pipeline Setup Guide for ShopDeploy

## Table of Contents
1. [Why Multi-Environment Setup?](#why-multi-environment-setup)
2. [Prerequisites](#prerequisites)
3. [Connect to EC2 Instance](#connect-to-ec2-instance)
4. [Install Required Packages](#install-required-packages)
5. [Start Jenkins](#start-jenkins)
6. [Access Jenkins Web UI](#access-jenkins-web-ui)
7. [Required Jenkins Plugins](#required-jenkins-plugins)
8. [Credentials Configuration](#credentials-configuration)
9. [Pipeline Configuration](#pipeline-configuration)
10. [Webhook Setup](#webhook-setup)
11. [Troubleshooting](#troubleshooting)

---

## Why Multi-Environment Setup?

Multi-environment setup (Dev → Staging → Prod) is an **industry standard** used by all professional engineering teams. Here's why:

### 🎯 The Deployment Flow

```
Developer Code → Dev → Staging → Production
                  ↓       ↓          ↓
               "Works"  "Tested"  "Users See It"
```

---

### 🟢 DEV Environment

| Purpose | Details |
|---------|---------|
| **Who uses it** | Developers |
| **Stability** | Can break anytime |
| **Data** | Fake/test data |
| **Deployments** | Every commit, multiple times/day |

**Example:** Developer pushes code → immediately deploys to dev → tests feature

---

### 🟡 STAGING Environment

| Purpose | Details |
|---------|---------|
| **Who uses it** | QA Team, Product Managers |
| **Stability** | Should be stable |
| **Data** | Copy of production (sanitized) |
| **Deployments** | Before every release |

**Example:** QA tests the complete feature, runs integration tests, simulates real user behavior

---

### 🔴 PROD Environment

| Purpose | Details |
|---------|---------|
| **Who uses it** | Real customers |
| **Stability** | Must NEVER break |
| **Data** | Real customer data |
| **Deployments** | After approval, carefully |

**Example:** Only deploys after staging passes all tests + manager approval

---

### 🔥 Real-World Deployment Scenario

```
Monday 10:00am   Developer writes "Add to Cart" feature
Monday 10:05am   Auto-deploys to DEV ← dev breaks, that's OK
Monday 11:00am   Dev fixed, works in DEV
Monday 2:00pm    Deploys to STAGING ← QA tests it
Monday 5:00pm    QA finds bug, rejected
Tuesday 10:00am  Bug fixed, re-deployed to STAGING
Tuesday 3:00pm   QA approves ✅
Tuesday 4:00pm   Deploys to PROD ← real users see it
```

---

### 💡 Why This Matters for Business

| Without Environments | With Environments |
|---------------------|-------------------|
| Bug goes directly to customers | Bug caught in dev/staging |
| Downtime for real users | Only test environments affected |
| Customer complaints | Customers never see broken code |
| Lost revenue | Revenue protected |
| Reputation damage | Professional deployment process |

---

### 🏢 How Companies Use This

| Company Size | Environments |
|-------------|-------------|
| **Small startup** | dev, prod |
| **Medium company** | dev, staging, prod |
| **Large enterprise** | dev, qa, staging, pre-prod, prod |
| **Netflix/Google** | Multiple staging + canary + prod regions |

---

### 🚀 ShopDeploy Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    CI Pipeline (Build Once)                  │
├─────────────────────────────────────────────────────────────┤
│  Checkout → Test → Lint → SonarQube → Build Docker → Push  │
│                           ↓                                  │
│              Docker Image: 42-a1b2c3d (ECR)                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   CD Pipeline (Deploy Many)                  │
├─────────────────────────────────────────────────────────────┤
│  Same image deployed to different environments:             │
│                                                              │
│  ├── 🟢 DEV      (auto-deploy, no approval needed)         │
│  ├── 🟡 STAGING  (auto-deploy, QA testing)                  │
│  └── 🔴 PROD     (manual approval required)                 │
└─────────────────────────────────────────────────────────────┘
```

### 💎 Key Insight: Build Once, Deploy Many

> **The image `42-a1b2c3d` that passes staging tests is the EXACT same image deployed to production.**

- ✅ No rebuilding for different environments
- ✅ No "it works on my machine" problems
- ✅ What you test is what you deploy
- ✅ Configuration differs, code stays the same

---

## Prerequisites

Before setting up Jenkins, ensure you have:

### AWS EC2 Instance Requirements
- **Instance Type**: Amazon Linux 2023 (t3.large recommended)
- **Storage**: 30 GB SSD

### Security Group Ports Open
| Port | Service | Description |
|------|---------|-------------|
| 22 | SSH | Secure Shell access |
| 80 | HTTP | Web traffic |
| 443 | HTTPS | Secure web traffic |
| 8080 | Jenkins | Jenkins Web UI |

### Key Pair
- **Key Pair**: `jenkins.pem` (ensure secure permissions with `chmod 400`)

---

## Connect to EC2 Instance

### ⚙️ Step 1: Connect to EC2 Instance

```bash
# Navigate to your downloads folder (where jenkins.pem is located)
cd Downloads

# Set secure permissions on the key file
chmod 400 jenkins.pem

# Connect to your EC2 instance
ssh -i "jenkins.pem" ec2-user@<YOUR_EC2_PUBLIC_IP>
```

---

## Install Required Packages

### 📦 Step 2: Install Required Packages

#### 1. Update and Install Git

```bash
sudo yum update -y
sudo yum install git -y
git --version
```

#### 2. Configure Git (Optional)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
git config --list
```

#### 3. Install Docker

```bash
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
```

#### 4. Install Java (Amazon Corretto 21)

```bash
# Option 1: Amazon Corretto 21 (Recommended)
sudo dnf install java-21-amazon-corretto -y

# Option 2: OpenJDK 21 (Alternative)
sudo yum install fontconfig java-21-openjdk -y

# Verify installation
java --version
```

#### 5. Install Maven

```bash
sudo yum install maven -y
mvn -v
```

#### 6. Install Jenkins

```bash
# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Upgrade packages
sudo yum upgrade -y

# Install Jenkins
sudo yum install jenkins -y

# Verify installation
jenkins --version
```

#### 7. Add Jenkins User to Docker Group

```bash
sudo usermod -aG docker jenkins
```

---

## Start Jenkins

### ▶️ Step 3: Start Jenkins

```bash
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

---

## Access Jenkins Web UI

### 🌐 Step 4: Access Jenkins Web UI

1. Open your browser and go to:
   ```
   http://<YOUR_EC2_PUBLIC_IP>:8080
   ```

2. Unlock Jenkins using the initial admin password:
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

3. Paste the password into the Jenkins setup screen and proceed.

---

### Quick Installation Script

Alternatively, run the installation script:

```bash
# Run the installation script
chmod +x scripts/install-jenkins.sh
./scripts/install-jenkins.sh
```

### Run Jenkins in Docker (Alternative)

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

### Deploy on Kubernetes using Helm (Alternative)

```bash
# Add Jenkins Helm repository
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Install Jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  --set controller.serviceType=LoadBalancer \
  --set controller.adminPassword=admin123 \
  --wait
```

---

## Required Jenkins Plugins

Install these plugins from **Manage Jenkins → Plugins → Available plugins**:

### Essential Plugins
| Plugin Name | Purpose |
|------------|---------|
| **Pipeline** | Enables Jenkinsfile pipelines |
| **Git** | Git integration |
| **GitHub** | GitHub webhook integration |
| **Docker Pipeline** | Docker build support |
| **Amazon ECR** | AWS ECR authentication |
| **AWS Credentials** | AWS credentials management |
| **Kubernetes** | Kubernetes deployment |
| **Kubernetes CLI** | kubectl integration |

### Recommended Plugins
| Plugin Name | Purpose |
|------------|---------|
| **Blue Ocean** | Modern UI for pipelines |
| **Slack Notification** | Slack integration |
| **HTML Publisher** | Test report publishing |
| **NodeJS** | Node.js build support |
| **AnsiColor** | Colorized console output |
| **Timestamper** | Build timestamps |
| **Build Timeout** | Build timeout control |
| **Workspace Cleanup** | Workspace management |

### Install via CLI
```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Install plugins via Jenkins CLI
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin \
  workflow-aggregator git github docker-workflow \
  amazon-ecr aws-credentials kubernetes kubernetes-cli \
  blueocean slack htmlpublisher nodejs ansicolor \
  timestamper build-timeout ws-cleanup
```

---

## Credentials Configuration

### 1. AWS Credentials

Navigate to: **Manage Jenkins → Credentials → System → Global credentials**

#### AWS Credentials Binding
- **Kind**: AWS Credentials
- **ID**: `aws-credentials`
- **Access Key ID**: Your AWS Access Key
- **Secret Access Key**: Your AWS Secret Key

#### AWS Account ID (Secret Text)
- **Kind**: Secret text
- **ID**: `aws-account-id`
- **Secret**: Your 12-digit AWS Account ID

### 2. GitHub Credentials

For private repositories:
- **Kind**: Username with password
- **ID**: `github-credentials`
- **Username**: Your GitHub username
- **Password**: GitHub Personal Access Token (PAT)

### 3. SonarQube Credentials

#### Install SonarQube on Amazon Linux 2 (Native Installation)

**Environment Requirements:**
- Instance Type: t2.medium / t3.medium or higher
- RAM: Minimum 4GB
- Key Pair: `sonar.pem`
- Security Group: Port 9000 open
- Storage: 20GB SSD

##### Step 1: Update System Packages

```bash
sudo yum update -y
sudo dnf update -y
sudo yum install unzip -y
```

##### Step 2: Install Java 17 (Amazon Corretto)

```bash
sudo yum search java-17
sudo yum install java-17-amazon-corretto.x86_64 -y
java --version
```

##### Step 3: Install PostgreSQL 15

```bash
sudo dnf install postgresql15.x86_64 postgresql15-server -y
sudo postgresql-setup --initdb

sudo systemctl start postgresql
sudo systemctl enable postgresql
```

##### Step 4: Configure PostgreSQL User & Database

```bash
# Set postgres user password
sudo passwd postgres
# Enter password: Khushal@41 (retype)

# Login as postgres
sudo -i -u postgres psql
```

Run SQL commands:

```sql
ALTER USER postgres WITH PASSWORD 'Khushal@41';
CREATE DATABASE sonarqube;
CREATE USER sonar WITH ENCRYPTED PASSWORD 'Khushal@41';
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;
\q
```

##### Step 5: Download & Setup SonarQube

```bash
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.6.0.92116.zip
sudo unzip sonarqube-10.6.0.92116.zip
sudo mv sonarqube-10.6.0.92116 sonarqube
```

##### Step 6: Set Kernel & OS Limits

```bash
# Set vm.max_map_count
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Add limits for sonar user
sudo tee -a /etc/security/limits.conf <<EOF
sonar   -   nofile   65536
sonar   -   nproc    4096
EOF
```

##### Step 7: Configure SonarQube Database Settings

```bash
sudo nano /opt/sonarqube/conf/sonar.properties
```

Add the following lines:

```properties
sonar.jdbc.username=sonar
sonar.jdbc.password=Khushal@41
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
```

##### Step 8: Create SonarQube User

```bash
sudo useradd sonar
sudo chown -R sonar:sonar /opt/sonarqube
```

##### Step 9: Create Systemd Service File

```bash
sudo nano /etc/systemd/system/sonarqube.service
```

Paste the following:

```ini
[Unit]
Description=SonarQube LTS Service
After=network.target

[Service]
Type=forking
User=sonar
Group=sonar
LimitNOFILE=65536
LimitNPROC=4096

Environment="JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto.x86_64"
Environment="PATH=/usr/lib/jvm/java-17-amazon-corretto.x86_64/bin:/usr/local/bin:/usr/bin:/bin"

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

Restart=always

[Install]
WantedBy=multi-user.target
```

##### Step 10: Set Permissions

```bash
sudo chmod +x /opt/sonarqube/bin/linux-x86-64/sonar.sh
sudo chmod -R 755 /opt/sonarqube/bin/
sudo chown -R sonar:sonar /opt/sonarqube
```

##### Step 11: Start SonarQube Service

```bash
sudo systemctl reset-failed sonarqube
sudo systemctl daemon-reload
sudo systemctl start sonarqube
sudo systemctl enable sonarqube
sudo systemctl status sonarqube -l
```

##### Access SonarQube

Open in browser: `http://<EC2-PUBLIC-IP>:9000`

Default credentials: `admin` / `admin`

#### Generate SonarQube Token

1. Login to SonarQube → **My Account** → **Security**
2. Generate Token: Name it `jenkins-token`
3. Copy the token

#### Add SonarQube Credential in Jenkins

Navigate to: **Manage Jenkins → Credentials → System → Global credentials**

- **Kind**: Secret text
- **ID**: `sonarqube-token`
- **Secret**: `<paste-your-sonarqube-token>`
- **Description**: SonarQube Authentication Token

#### Configure SonarQube Server

Navigate to: **Manage Jenkins → System → SonarQube servers**

Click **Add SonarQube**:
- **Name**: `SonarQube` *(must match exactly - this name is used in Jenkinsfile)*
- **Server URL**: `http://<SONARQUBE-IP>:9000`
- **Server authentication token**: Select `sonarqube-token`

#### Install SonarQube Scanner Tool

Navigate to: **Manage Jenkins → Tools → SonarQube Scanner installations**

Click **Add SonarQube Scanner**:
- **Name**: `SonarScanner`
- ✅ Install automatically
- **Version**: Latest

### 4. Docker Hub Credentials (Optional)

If pushing images to Docker Hub instead of AWS ECR:

Navigate to: **Manage Jenkins → Credentials → System → Global credentials**

- **Kind**: Username with password
- **ID**: `docker-hub-credentials`
- **Username**: Your Docker Hub username
- **Password**: Docker Hub password or Access Token
- **Description**: Docker Hub Credentials

### 5. Slack Webhook (Optional)

- **Kind**: Secret text
- **ID**: `slack-webhook`
- **Secret**: Slack Incoming Webhook URL

### Credentials Summary

| Credential ID | Kind | Purpose |
|---------------|------|---------|
| `aws-credentials` | AWS Credentials | ECR login, EKS access, AWS CLI |
| `aws-account-id` | Secret text | AWS Account ID for ECR URL |
| `github-credentials` | Username/Password | Git repository access |
| `sonarqube-token` | Secret text | SonarQube authentication |
| `docker-hub-credentials` | Username/Password | Docker Hub (optional) |
| `slack-webhook` | Secret text | Slack notifications (optional) |

### Verify Credentials

```bash
# Test Docker access on Jenkins server
sudo -u jenkins docker ps

# Test AWS ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Test SonarQube connectivity
curl -u admin:admin http://<SONARQUBE-IP>:9000/api/system/status

# Test GitHub access
git ls-remote https://github.com/your-org/shopdeploy.git
```

---

## Pipeline Configuration

### Create New Pipeline Job

1. Click **New Item**
2. Enter name: `shopdeploy-pipeline`
3. Select **Pipeline**
4. Click **OK**

### Configure Pipeline

#### General Settings
- ✅ GitHub project: `https://github.com/your-org/shopdeploy`
- ✅ Discard old builds: Keep last 20

#### Build Triggers
- ✅ GitHub hook trigger for GITScm polling
- ✅ Poll SCM (as backup): `H/5 * * * *`

#### Pipeline Definition
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: `https://github.com/your-org/shopdeploy.git`
- **Credentials**: `github-credentials`
- **Branch**: `*/main`
- **Script Path**: `Jenkinsfile`

---

## Webhook Setup

### GitHub Webhook Configuration

1. Go to your GitHub repository
2. Navigate to **Settings → Webhooks → Add webhook**
3. Configure:
   - **Payload URL**: `http://<jenkins-url>:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (optional, add for security)
   - **Events**: Select **Just the push event** or **Let me select individual events**

### Verify Webhook
- Send a test commit
- Check **Recent Deliveries** in GitHub webhook settings
- Verify Jenkins triggers the build

---

## Pipeline Parameters

The Jenkinsfile supports these parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ENVIRONMENT` | Choice | dev | Target environment (dev/staging/prod) |
| `SKIP_TESTS` | Boolean | false | Skip test stage |
| `FORCE_DEPLOY` | Boolean | false | Force deployment |
| `BACKEND_VERSION` | String | "" | Specific backend version |
| `FRONTEND_VERSION` | String | "" | Specific frontend version |

---

## Environment Variables

Set these in Jenkins (Manage Jenkins → System → Global properties):

```properties
AWS_REGION=us-east-1
EKS_CLUSTER_NAME=shopdeploy-prod-eks
K8S_NAMESPACE=shopdeploy
SLACK_CHANNEL=#devops-alerts
```

---

## Pipeline Stages Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ShopDeploy CI/CD Pipeline                        │
├─────────────────────────────────────────────────────────────────────┤
│  1. Checkout          → Clone source code from Git                  │
│  2. Detect Changes    → Identify modified components                │
│  3. Install Deps      → npm ci for backend/frontend (parallel)      │
│  4. Code Quality      → Lint + Security scan (parallel)             │
│  5. Tests             → Unit tests + coverage (parallel)            │
│  6. Build Images      → Docker build for changed components         │
│  7. Push to ECR       → Push images to AWS ECR                      │
│  8. Deploy to EKS     → Helm deploy to Kubernetes                   │
│  9. Approval Gate     → Manual approval for production              │
│ 10. Production Deploy → Canary deployment to prod                   │
│ 11. Smoke Tests       → Post-deployment validation                  │
│ 12. Cleanup           → Docker image pruning                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Security Best Practices

### 1. Secure Jenkins Instance
```bash
# Configure Jenkins behind a reverse proxy (nginx)
sudo apt install nginx -y

# /etc/nginx/sites-available/jenkins
server {
    listen 80;
    server_name jenkins.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 2. Enable HTTPS with SSL
```bash
sudo certbot --nginx -d jenkins.yourdomain.com
```

### 3. Configure Security Realm
- Use **LDAP** or **Active Directory** for authentication
- Enable **Matrix-based security** for fine-grained access control

---

## Troubleshooting

### Common Issues

#### 1. Docker Permission Denied
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

#### 2. AWS Credentials Not Working
```bash
# Test AWS CLI in Jenkins shell
aws sts get-caller-identity
aws ecr get-login-password --region us-east-1
```

#### 3. kubectl Context Issues
```bash
# Update kubeconfig in Jenkins
aws eks update-kubeconfig --region us-east-1 --name shopdeploy-prod-eks
```

#### 4. Build Failing on npm ci
```bash
# Clear npm cache
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

---

## Backup Jenkins Configuration

```bash
# Backup Jenkins home
tar -czvf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins

# Backup specific configurations
tar -czvf jenkins-config-backup.tar.gz \
  /var/lib/jenkins/config.xml \
  /var/lib/jenkins/credentials.xml \
  /var/lib/jenkins/jobs/*/config.xml
```

---

## Next Steps

1. [Set up Prometheus & Grafana Monitoring](./MONITORING-SETUP-GUIDE.md)
2. [Configure Helm Charts](./HELM-SETUP-GUIDE.md)
3. [Review EC2 Deployment Guide](../EC2-DEPLOYMENT-GUIDE.md)
