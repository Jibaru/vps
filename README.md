# VPS Setup - Docker + Caddy

Automated VPS configuration for Contabo (or any Ubuntu-based VPS) with Docker, Docker Compose, and Caddy reverse proxy.

## Quick Setup

### Option 1: Public Repository (Easiest)

If your repository is public, run this on your VPS:

```bash
git clone https://github.com/Jibaru/vps.git && cd vps && chmod +x setup.sh && sudo ./setup.sh
```

Or download and execute directly:

```bash
curl -fsSL https://raw.githubusercontent.com/Jibaru/vps/main/setup.sh | sudo bash
```

### Option 2: Private Repository with SSH (Recommended)

For private repositories, use SSH authentication.

**Quick setup with helper script:**
```bash
curl -fsSL https://raw.githubusercontent.com/Jibaru/vps/main/setup-github-ssh.sh | bash
```

**Manual setup:**
```bash
# 1. Generate SSH key on your VPS
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/github_vps

# 2. Display your public key
cat ~/.ssh/github_vps.pub

# 3. Add the key to GitHub: Settings → SSH and GPG keys → New SSH key

# 4. Configure SSH
cat >> ~/.ssh/config << EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/github_vps
EOF

# 5. Clone with SSH
git clone git@github.com:Jibaru/vps.git && cd vps && chmod +x setup.sh && sudo ./setup.sh
```

### Option 3: Private Repository with Personal Access Token

```bash
# Clone with token (replace YOUR_TOKEN)
git clone https://YOUR_TOKEN@github.com/Jibaru/vps.git && cd vps && chmod +x setup.sh && sudo ./setup.sh
```

> **Note:** Get your token at: GitHub Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token (select `repo` scope)

## What Gets Installed

- **Docker CE** - Container runtime
- **Docker Compose** - Multi-container orchestration
- **UFW Firewall** - Configured for SSH (22), HTTP (80), and HTTPS (443)

## Project Structure

```
vps/
├── README.md
├── setup.sh              # Main VPS setup script
├── install-git.sh        # Git installation (if needed)
├── setup-github-ssh.sh   # GitHub SSH authentication helper
├── docker-compose.yml    # Service orchestration
├── Caddyfile            # Reverse proxy configuration
└── services/
    └── api-example/     # Example Go API service
        ├── main.go
        ├── Dockerfile
        └── go.mod
```

## Manual Setup Steps

### 1. Install Git (if not already installed)

```bash
curl -fsSL https://raw.githubusercontent.com/Jibaru/vps/main/install-git.sh | sudo bash
```

### 2. Clone Repository

Choose based on repository visibility:

**Public repository:**
```bash
git clone https://github.com/Jibaru/vps.git
cd vps
```

**Private repository (SSH - recommended):**
```bash
# Set up SSH key first (see Quick Setup section)
git clone git@github.com:Jibaru/vps.git
cd vps
```

**Private repository (Personal Access Token):**
```bash
git clone https://YOUR_TOKEN@github.com/Jibaru/vps.git
cd vps
```

### 3. Run Setup Script

```bash
chmod +x setup.sh
sudo ./setup.sh
```

### 4. Configure Your Domain

Edit the Caddyfile and replace `api.midominio.com` with your actual domain:

```bash
nano Caddyfile
```

```caddy
your-domain.com {
    reverse_proxy api-example:8080
}
```

### 5. Start Services

```bash
docker compose up -d
```

### 6. Verify Deployment

```bash
# Check running containers
docker compose ps

# View logs
docker compose logs -f

# Test the API
curl https://your-domain.com/hello
```

## Adding New Services

1. Create a new service directory:

```bash
mkdir -p services/my-new-service
```

2. Add your application code and Dockerfile

3. Update `docker-compose.yml`:

```yaml
services:
  my-new-service:
    build: ./services/my-new-service
    container_name: my-new-service
    restart: unless-stopped
    networks:
      - web
```

4. Update `Caddyfile` for routing:

```caddy
myservice.example.com {
    reverse_proxy my-new-service:8080
}
```

5. Rebuild and restart:

```bash
docker compose up -d --build
```

## Common Commands

```bash
# View all containers
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop all services
docker compose down

# Rebuild and restart
docker compose up -d --build

# Update and redeploy
git pull
docker compose up -d --build
```

## Firewall Configuration

The setup script configures UFW with these rules:

- Port 22 (SSH) - Remote access
- Port 80 (HTTP) - Caddy will auto-redirect to HTTPS
- Port 443 (HTTPS) - Secure traffic

## Automatic HTTPS

Caddy automatically provisions and renews SSL certificates from Let's Encrypt. Just make sure:

1. Your domain DNS points to your VPS IP
2. Ports 80 and 443 are open (handled by setup script)
3. Your domain is correctly configured in Caddyfile

## Troubleshooting

### GitHub Authentication Failed

If you see `Password authentication is not supported`:

**Solution 1: Use SSH (Recommended)**
```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/github_vps

# Copy public key to GitHub
cat ~/.ssh/github_vps.pub
# Paste at: https://github.com/settings/keys

# Test connection
ssh -T git@github.com
```

**Solution 2: Use Personal Access Token**
```bash
# Get token: https://github.com/settings/tokens
# Clone with: git clone https://YOUR_TOKEN@github.com/Jibaru/vps.git
```

**Solution 3: Make Repository Public**
```bash
# Go to: Repository Settings → Danger Zone → Change visibility
```

### Check Docker Status
```bash
systemctl status docker
```

### Check Firewall Rules
```bash
sudo ufw status
```

### View Caddy Logs
```bash
docker compose logs caddy
```

### Test Internal Service
```bash
docker exec -it reverse-proxy wget -O- http://api-example:8080/hello
```

### DNS Issues
```bash
# Verify DNS propagation
nslookup your-domain.com

# Check if port is accessible
curl -I http://YOUR_VPS_IP
```

## License

MIT
