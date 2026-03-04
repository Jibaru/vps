#!/bin/bash

set -e

echo "🚀 Updating system..."
apt update && apt upgrade -y

echo "🐳 Installing Docker..."
apt install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "🔥 Configuring firewall..."
apt install -y ufw
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw --force enable

echo "✅ Docker installed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Clone your repository: git clone <your-repo>"
echo "2. Configure Caddyfile with your domain"
echo "3. Run: docker compose up -d"
echo ""
echo "Server IP: $(curl -s ifconfig.me)"
