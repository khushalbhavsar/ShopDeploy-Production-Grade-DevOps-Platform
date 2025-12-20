#!/bin/bash
#==============================================================================
# ShopDeploy - Docker Installation Script
# Installs Docker and Docker Compose on Amazon Linux 2 / Ubuntu
#==============================================================================

set -e

echo "Installing Docker..."

# Detect OS
if [ -f /etc/amazon-linux-release ] || [ -f /etc/system-release ]; then
    # Amazon Linux 2 / RHEL / CentOS
    sudo yum install -y docker
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
elif [ -f /etc/lsb-release ]; then
    # Ubuntu / Debian
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

# Add current user to docker group
sudo usermod -aG docker $USER 2>/dev/null || true
sudo usermod -aG docker jenkins 2>/dev/null || true

echo "Docker installed successfully!"
docker --version
