#!/bin/bash
#==============================================================================
# ShopDeploy - Jenkins Installation Script
# Installs Jenkins LTS on Amazon Linux 2 / Ubuntu
#==============================================================================

set -e

echo "Installing Jenkins..."

# Detect OS
if [ -f /etc/amazon-linux-release ] || [ -f /etc/system-release ]; then
    # Amazon Linux 2 / RHEL / CentOS
    
    # Install Java 17 (required for Jenkins)
    sudo amazon-linux-extras install java-openjdk17 -y 2>/dev/null || \
        sudo yum install -y java-17-amazon-corretto java-17-amazon-corretto-devel
    
    # Add Jenkins repository
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    
    # Install Jenkins
    sudo yum install -y jenkins
    
elif [ -f /etc/lsb-release ]; then
    # Ubuntu / Debian
    
    # Install Java 17
    sudo apt-get update
    sudo apt-get install -y fontconfig openjdk-17-jre
    
    # Add Jenkins repository
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
        https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y jenkins
fi

# Configure Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
sleep 30

# Display initial admin password
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo ""
    echo "============================================"
    echo "Jenkins Initial Admin Password:"
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    echo ""
    echo "============================================"
fi

echo "Jenkins installed successfully!"
echo "Access Jenkins at http://<server-ip>:8080"
