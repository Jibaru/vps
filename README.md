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
├── .env.example         # Environment variables template
└── services/
    └── api-example/     # Example Go API service with PostgreSQL
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

### 4. Configure DNS (Namecheap)

Before configuring Caddy, set up your domain DNS records:

#### Get Your VPS IP

```bash
# From your VPS
curl ifconfig.me
```

Or check your Contabo control panel.

#### Configure DNS Records in Namecheap

1. Go to Namecheap Dashboard: https://ap.www.namecheap.com/
2. Click "Domain List" → "Manage" next to your domain
3. Navigate to "Advanced DNS" tab

**Option A: Main Domain (jibaru.ink)**

| Type | Host | Value          | TTL       |
|------|------|----------------|-----------|
| A    | @    | 164.68.107.2   | Automatic |
| A    | www  | 164.68.107.2   | Automatic |

**Option B: Subdomain (api.jibaru.ink)**

| Type | Host | Value          | TTL       |
|------|------|----------------|-----------|
| A    | api  | 164.68.107.2   | Automatic |

**Option C: Multiple Subdomains (Recommended)**

| Type | Host  | Value          | TTL       |
|------|-------|----------------|-----------|
| A    | @     | 164.68.107.2   | Automatic |
| A    | www   | 164.68.107.2   | Automatic |
| A    | api   | 164.68.107.2   | Automatic |
| A    | admin | 164.68.107.2   | Automatic |

**Wildcard Support (Optional)**

For `*.jibaru.ink`:

| Type | Host | Value          | TTL       |
|------|------|----------------|-----------|
| A    | *    | 164.68.107.2   | Automatic |

#### Verify DNS Propagation

Wait 5-30 minutes, then verify:

```bash
# Check DNS resolution
nslookup jibaru.ink
dig jibaru.ink +short

# Should return: 164.68.107.2

# Test connectivity
ping jibaru.ink
```

### 5. Configure Environment Variables

Create a `.env` file with your database credentials:

```bash
cp .env.example .env
nano .env
```

Update with secure values:
```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=appdb
```

### 6. Configure Caddyfile

Edit the Caddyfile with your domain(s):

```bash
nano Caddyfile
```

**Current Configuration (jibaru.ink):**
```caddy
jibaru.ink, www.jibaru.ink {
    reverse_proxy api-example:8080
}

api.jibaru.ink {
    reverse_proxy api-example:8080
}
```

**Multiple Services Example:**
```caddy
# Main website
jibaru.ink, www.jibaru.ink {
    reverse_proxy frontend:3000
}

# API service
api.jibaru.ink {
    reverse_proxy api-example:8080
}

# Admin panel
admin.jibaru.ink {
    reverse_proxy admin-panel:3000
}
```

### 7. Start Services

```bash
docker compose up -d
```

### 8. Verify Deployment

```bash
# Check running containers
docker compose ps

# View logs
docker compose logs -f

# Test the API
curl https://jibaru.ink/hello

# Test health endpoint (includes database status)
curl https://jibaru.ink/health
```

## PostgreSQL Database

The setup includes a PostgreSQL 16 database service with persistent storage.

### Database Configuration

**Default Credentials** (change in production):
- User: `postgres`
- Password: `postgres`
- Database: `appdb`
- Host: `postgres` (container name)
- Port: `5432` (internal, not exposed externally)

### Connecting to the Database

**From your application:**
```go
DATABASE_URL=postgres://postgres:postgres@postgres:5432/appdb?sslmode=disable
```

**From your VPS (using docker exec):**
```bash
# Access PostgreSQL CLI
docker exec -it postgres psql -U postgres -d appdb

# Run SQL commands
docker exec -it postgres psql -U postgres -d appdb -c "SELECT version();"

# Create a table example
docker exec -it postgres psql -U postgres -d appdb -c "
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);"
```

### Database Backups

**Create a backup:**
```bash
# Backup to file
docker exec postgres pg_dump -U postgres appdb > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup compressed
docker exec postgres pg_dump -U postgres appdb | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

**Restore from backup:**
```bash
# Restore from SQL file
cat backup.sql | docker exec -i postgres psql -U postgres -d appdb

# Restore from compressed backup
gunzip -c backup.sql.gz | docker exec -i postgres psql -U postgres -d appdb
```

### Database Monitoring

```bash
# View PostgreSQL logs
docker compose logs postgres -f

# Check database size
docker exec postgres psql -U postgres -d appdb -c "
SELECT pg_size_pretty(pg_database_size('appdb'));"

# List all databases
docker exec postgres psql -U postgres -c "\l"

# List all tables
docker exec postgres psql -U postgres -d appdb -c "\dt"
```

### Changing Database Credentials

1. Update your `.env` file:
```bash
nano .env
```

2. Restart services:
```bash
docker compose down
docker compose up -d
```

**Warning:** Changing credentials after initial setup may require rebuilding the database volume.

### Accessing from External Tools

For security, PostgreSQL is **not exposed externally** by default. To connect from tools like pgAdmin or DBeaver:

**Option 1: SSH Tunnel (Recommended)**
```bash
# On your local machine
ssh -L 5432:localhost:5432 root@164.68.107.2

# Then connect to localhost:5432
```

**Option 2: Expose Port (Not Recommended for Production)**

Edit `docker-compose.yml` to add ports:
```yaml
postgres:
  ports:
    - "5432:5432"  # Only do this for development
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
myservice.jibaru.ink {
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

# View logs for specific service
docker compose logs caddy -f

# Restart services
docker compose restart

# Restart only Caddy
docker compose restart caddy

# Stop all services
docker compose down

# Rebuild and restart
docker compose up -d --build

# Update and redeploy
git pull
docker compose up -d --build
```

## Updating Caddy Configuration

After modifying the Caddyfile, you need to apply the changes:

### Option 1: Reload Without Downtime (Recommended)

```bash
# Validate configuration first (optional)
docker exec reverse-proxy caddy validate --config /etc/caddy/Caddyfile

# Reload configuration (no downtime)
docker exec reverse-proxy caddy reload --config /etc/caddy/Caddyfile

# Check logs to verify
docker compose logs caddy -f
```

### Option 2: Restart Caddy Container

```bash
# Restart only Caddy (brief downtime)
docker compose restart caddy
```

### Option 3: Full Restart

```bash
# Stop and start all services
docker compose down
docker compose up -d
```

### Recommended Workflow

```bash
# 1. Edit Caddyfile
nano Caddyfile

# 2. Validate syntax
docker exec reverse-proxy caddy validate --config /etc/caddy/Caddyfile

# 3. Apply changes without downtime
docker exec reverse-proxy caddy reload --config /etc/caddy/Caddyfile

# 4. Verify changes
curl -I https://jibaru.ink
docker compose logs caddy --tail 50
```

## Firewall Configuration

The setup script configures UFW with these rules:

- Port 22 (SSH) - Remote access
- Port 80 (HTTP) - Caddy will auto-redirect to HTTPS
- Port 443 (HTTPS) - Secure traffic

## Automatic HTTPS

Caddy automatically provisions and renews SSL certificates from Let's Encrypt. Just make sure:

1. Your domain DNS points to your VPS IP (164.68.107.2)
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
nslookup jibaru.ink
dig jibaru.ink +short
# Should return: 164.68.107.2

# Verify nameservers
dig jibaru.ink NS

# Check if port is accessible
curl -I http://164.68.107.2
```

### Caddy SSL Certificate Issues

If Caddy can't obtain SSL certificates:

```bash
# Check Caddy logs for certificate errors
docker compose logs caddy | grep -i "certificate\|acme\|tls"

# Verify DNS points to correct IP
dig jibaru.ink +short
# Should return: 164.68.107.2

# Verify ports 80 and 443 are open
sudo ufw status | grep -E "80|443"

# Test ACME challenge accessibility
curl http://jibaru.ink/.well-known/acme-challenge/test

# Force certificate renewal (if needed)
docker exec reverse-proxy caddy reload --config /etc/caddy/Caddyfile --force
```

**Common causes:**
- DNS not pointing to VPS IP
- Ports 80 or 443 blocked by firewall
- Domain DNS not fully propagated (wait 5-30 minutes)
- Rate limiting from Let's Encrypt (wait 1 hour and retry)

### Caddy Configuration Validation Failed

```bash
# Check syntax errors in Caddyfile
docker exec reverse-proxy caddy validate --config /etc/caddy/Caddyfile

# Common issues:
# - Missing closing braces
# - Invalid reverse_proxy syntax
# - Duplicate domain definitions
```

## License

MIT
