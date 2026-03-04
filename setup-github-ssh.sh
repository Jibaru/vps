#!/bin/bash

set -e

echo "🔑 Setting up GitHub SSH Authentication"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install it first:"
    echo "   curl -fsSL https://raw.githubusercontent.com/Jibaru/vps/main/install-git.sh | sudo bash"
    exit 1
fi

# Get user email
read -p "Enter your GitHub email: " EMAIL

# Generate SSH key
echo ""
echo "📝 Generating SSH key..."
ssh-keygen -t ed25519 -C "$EMAIL" -f ~/.ssh/github_vps -N ""

# Create SSH config
echo ""
echo "⚙️  Configuring SSH..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat >> ~/.ssh/config << EOF

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github_vps
EOF

chmod 600 ~/.ssh/config

# Start ssh-agent and add key
echo ""
echo "🔐 Adding key to SSH agent..."
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_vps

# Display public key
echo ""
echo "✅ SSH key generated successfully!"
echo ""
echo "📋 Copy this public key and add it to GitHub:"
echo "   https://github.com/settings/keys"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat ~/.ssh/github_vps.pub
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "After adding the key to GitHub, test the connection:"
echo "   ssh -T git@github.com"
echo ""
echo "Then clone your repository:"
echo "   git clone git@github.com:Jibaru/vps.git"
