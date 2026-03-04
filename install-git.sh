#!/bin/bash

set -e

echo "📦 Installing Git..."
apt update
apt install -y git

echo "✅ Git installed successfully!"
git --version

echo ""
echo "📋 Recommended configuration:"
echo "git config --global user.name \"Your Name\""
echo "git config --global user.email \"your@email.com\""
