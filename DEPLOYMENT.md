# PlanGoReminisce Deployment Guide

## Prerequisites

### 1. Hetzner Server Setup
- Ubuntu 22.04+ server with root access
- SSH key-based authentication configured
- Docker installed on the server
- Domain name pointing to the server IP

### 2. Docker Hub Account
- Create account at https://hub.docker.com
- Generate access token (Account Settings → Security → Access Tokens)

## Deployment Steps

### 1. Configure Deployment Settings

Update `config/deploy.yml`:
```yaml
# Replace these placeholders with your actual values:
servers:
  web:
    - YOUR_HETZNER_SERVER_IP  # e.g., 95.217.123.456

proxy:
  host: YOUR_DOMAIN_NAME  # e.g., plangoreminisce.yourdomain.com

registry:
  username: YOUR_DOCKER_HUB_USERNAME
```

### 2. Set Environment Variables

```bash
export KAMAL_REGISTRY_PASSWORD="your-docker-hub-access-token"
```

### 3. Initial Server Setup

Run the setup command (only needed once):
```bash
bin/kamal setup
```

This will:
- Install Docker on your server
- Set up the necessary directories
- Configure SSL certificates via Let's Encrypt
- Deploy the application

### 4. Subsequent Deployments

For updates after the initial setup:
```bash
bin/kamal deploy
```

## Staging

This project now includes a separate Kamal staging target:
- Host: `staging.plangoreminisce.duzend.net`
- Config override: [config/deploy.staging.yml](/home/leo/dev/projects/plangoreminisce/config/deploy.staging.yml)
- Separate persistent volume: `plangoreminisce_staging_storage`

Recommended workflow:
```bash
cp .kamal/deploy.env.example .kamal/deploy.env
set -a; source .kamal/deploy.env; set +a
bin/kamal setup -d staging
bin/kamal deploy -d staging
```

Before setup:
1. Create DNS `A` record for `staging.plangoreminisce.duzend.net` to `157.180.19.232`.
2. Ensure ports `80` and `443` are reachable.
3. Export `KAMAL_REGISTRY_PASSWORD` and `RAILS_MASTER_KEY`.

Notes:
1. Staging is isolated from production at the container/service and storage-volume level.
2. Production data is not touched by staging deploys.
3. Mailer host/protocol in production now use `APP_HOST` and `APP_PROTOCOL`, so staging links can point to the staging domain cleanly.
4. After each meaningful staging deploy, run the checklist in [staging_smoke_checklist.md](/home/leo/dev/projects/plangoreminisce/documentation/staging_smoke_checklist.md).
5. If the host logs show a `VIPS` warning about `libopenslide.so.1`, treat it as a host package issue first. It is currently non-blocking for the verified app flows.

## Useful Commands

```bash
# View application logs
bin/kamal logs

# SSH into the server
bin/kamal app exec --interactive --reuse bash

# Rails console on server
bin/kamal console

# Database console
bin/kamal dbc

# Check deployment status
bin/kamal details

# Roll back deployment
bin/kamal rollback
```

## Server Requirements

- **Minimum**: 1 CPU, 2GB RAM, 20GB disk
- **Recommended**: 2 CPU, 4GB RAM, 40GB disk
- **OS**: Ubuntu 22.04 LTS
- **Ports**: 80 (HTTP), 443 (HTTPS), 22 (SSH)

## SSL Configuration

SSL certificates are automatically managed by Let's Encrypt through Kamal. Make sure:
1. Your domain DNS points to the server IP
2. Ports 80 and 443 are open
3. The domain is correctly set in `config/deploy.yml`

## Monitoring

After deployment, monitor:
- Application logs: `bin/kamal logs`
- Server resources: SSH into server and use `htop`, `df -h`
- SSL certificate status: Check https://www.ssllabs.com/ssltest/

## Troubleshooting

### Common Issues

1. **Deploy fails with registry authentication error**
   - Verify KAMAL_REGISTRY_PASSWORD is set correctly
   - Check Docker Hub access token permissions

2. **SSL certificate generation fails**
   - Ensure domain DNS is pointing to server
   - Check that ports 80/443 are open
   - Verify domain in config/deploy.yml matches DNS

3. **Application doesn't start**
   - Check logs with `bin/kamal logs`
   - Verify all environment variables are set
   - Ensure database migrations completed

### Getting Help

- Rails logs: `bin/kamal logs`
- Container status: `bin/kamal details`
- SSH to server: `bin/kamal app exec --interactive --reuse bash`

## Security Notes

- Never commit `config/master.key` to git
- Use environment variables for all secrets
- Regularly update server packages
- Monitor application logs for security events
- Consider setting up automated backups for SQLite database
