# Meal Planner Deployment Guide

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Environment Setup](#environment-setup)
4. [Deployment Strategies](#deployment-strategies)
5. [CI/CD Pipeline](#cicd-pipeline)
6. [Monitoring & Observability](#monitoring--observability)
7. [Rollback Procedures](#rollback-procedures)
8. [Troubleshooting](#troubleshooting)

## Overview

The Meal Planner application uses a blue/green deployment strategy for zero-downtime releases. The infrastructure is containerized using Docker and orchestrated with Docker Compose for production deployments.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Nginx (Port 80)                     │
│                    Load Balancer/Proxy                      │
└────────────────┬────────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
   ┌─────────┐      ┌─────────┐
   │  Blue   │      │  Green  │
   │  :8080  │      │  :8081  │
   └────┬────┘      └────┬────┘
        │                │
        └────────┬────────┘
                 │
                 ▼
         ┌──────────────┐
         │  PostgreSQL  │
         │    :5432     │
         └──────────────┘
```

## Prerequisites

### Required Software

- Docker Engine 20.10+
- Docker Compose 2.0+
- curl (for health checks)
- jq (for JSON parsing, optional)

### Required Credentials

1. **Database**:
   - PostgreSQL user and password
   - Database name

2. **External APIs**:
   - Tandoor API token
   - FatSecret OAuth credentials
   - OAuth encryption key

3. **Optional Services**:
   - Todoist API key
   - USDA API key
   - OpenAI API key

## Environment Setup

### 1. Clone Configuration

```bash
cp .env.example .env.production
```

### 2. Configure Environment Variables

Edit `.env.production` and set all required values:

```bash
# Core settings
ENVIRONMENT=production
PORT=8080
LOG_LEVEL=info

# Database
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=meal_planner
DATABASE_USER=postgres
DATABASE_PASSWORD=<secure-password>
DATABASE_POOL_SIZE=20

# Tandoor
TANDOOR_BASE_URL=https://your-tandoor-instance.com
TANDOOR_API_TOKEN=<your-token>

# FatSecret
FATSECRET_CONSUMER_KEY=<your-key>
FATSECRET_CONSUMER_SECRET=<your-secret>
OAUTH_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Security
JWT_SECRET=$(openssl rand -base64 32)
RATE_LIMIT_REQUESTS=100
CORS_ALLOWED_ORIGINS=https://your-frontend.com
```

### 3. SSL Certificates (Production)

For HTTPS, place SSL certificates in `nginx/ssl/`:

```bash
nginx/ssl/
├── cert.pem
└── key.pem
```

Then uncomment the HTTPS server block in `nginx/nginx.conf`.

## Deployment Strategies

### Blue/Green Deployment

The blue/green strategy allows zero-downtime deployments by running two identical production environments.

#### Initial Deployment

```bash
# Set environment variables
export VERSION=v1.0.0

# Deploy to blue (default)
docker-compose -f docker-compose.prod.yml up -d
```

#### Rolling Update

```bash
# Deploy new version using automated script
./scripts/deployment/deploy-blue-green.sh production v1.1.0
```

The script performs:

1. Pull new Docker image
2. Deploy to inactive slot (green)
3. Run health checks
4. Switch nginx traffic
5. Stop old deployment (blue)

#### Manual Deployment Steps

If you prefer manual control:

```bash
# 1. Pull new image
docker pull ghcr.io/lprior-repo/meal-planner:v1.1.0

# 2. Start green deployment
export VERSION=v1.1.0
docker-compose -f docker-compose.prod.yml --profile green-deployment up -d api-green

# 3. Health check green
./scripts/deployment/health-check.sh http://localhost:8081 60

# 4. Update nginx upstream in nginx.conf
# Change: upstream api_active { server api-blue:8080; }
# To:     upstream api_active { server api-green:8080; }

# 5. Reload nginx
docker exec meal_planner_nginx nginx -s reload

# 6. Stop blue
docker-compose -f docker-compose.prod.yml stop api-blue
```

## CI/CD Pipeline

### GitHub Actions Workflow

The CI/CD pipeline (`.github/workflows/ci.yml`) automates:

1. **Quality Gates**:
   - Code formatting check
   - Type checking
   - Dependency security audit

2. **Testing**:
   - Fast unit tests
   - Integration tests with PostgreSQL
   - CLI smoke tests
   - Coverage reporting

3. **Build**:
   - Multi-architecture Docker images (amd64, arm64)
   - Semantic versioning
   - Image signing

4. **Deployment**:
   - Staging (on `develop` branch)
   - Production (on `main` branch)

### Triggering Deployments

#### Staging Deployment

```bash
git checkout develop
git merge feature-branch
git push origin develop
```

Triggers automatic deployment to staging environment.

#### Production Deployment

```bash
git checkout main
git merge develop
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin main --tags
```

Triggers automatic deployment to production.

#### Manual Deployment

Use GitHub Actions workflow dispatch:

```bash
gh workflow run ci.yml -f environment=production -f version=v1.1.0
```

## Monitoring & Observability

### Health Endpoints

The application exposes three health check endpoints:

1. **`/health`** - Basic health check
   ```json
   {
     "status": "healthy",
     "service": "meal-planner",
     "version": "1.0.0"
   }
   ```

2. **`/ready`** - Readiness check (database + dependencies)
   - Returns 200 when ready to serve traffic
   - Returns 503 when dependencies unavailable

3. **`/live`** - Liveness check
   - Returns 200 when application is running
   - Used by orchestrators to detect deadlocks

### Metrics (Prometheus)

Start monitoring stack:

```bash
docker-compose -f docker-compose.prod.yml --profile monitoring up -d
```

Access dashboards:

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/password from env)

### Log Aggregation

Application logs are available:

```bash
# View API logs
docker logs -f meal_planner_api_blue

# View nginx logs
docker logs -f meal_planner_nginx

# View all logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Rollback Procedures

### Automated Rollback

```bash
./scripts/deployment/rollback.sh
```

The script will:

1. Identify current deployment
2. Restart previous deployment
3. Run health checks
4. Switch nginx traffic back
5. Stop failed deployment

### Manual Rollback

```bash
# 1. Start previous deployment (blue)
docker-compose -f docker-compose.prod.yml up -d api-blue

# 2. Verify health
curl -f http://localhost:8080/health

# 3. Update nginx to route to blue
# Edit nginx.conf: upstream api_active { server api-blue:8080; }
docker exec meal_planner_nginx nginx -s reload

# 4. Stop failed deployment (green)
docker-compose -f docker-compose.prod.yml --profile green-deployment stop api-green
```

### Database Rollback

If schema changes were deployed:

```bash
# 1. Connect to database
docker exec -it meal_planner_db psql -U postgres -d meal_planner

# 2. Check migrations
SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;

# 3. Run rollback migration
\i db/migrations/rollback/XXX_rollback_migration.sql
```

## Troubleshooting

### Deployment Failures

#### Health Checks Failing

```bash
# Check application logs
docker logs meal_planner_api_blue

# Check database connectivity
docker exec meal_planner_api_blue ping -c 3 postgres

# Manual health check
curl -v http://localhost:8080/health
```

#### Container Won't Start

```bash
# Check container status
docker ps -a | grep meal_planner

# Check container logs
docker logs meal_planner_api_blue

# Inspect container
docker inspect meal_planner_api_blue

# Check resource usage
docker stats
```

#### Database Connection Issues

```bash
# Verify database is running
docker exec meal_planner_db pg_isready

# Check database logs
docker logs meal_planner_db

# Test connection from API container
docker exec meal_planner_api_blue env | grep DATABASE
```

### Performance Issues

#### High CPU Usage

```bash
# Check container resources
docker stats

# Increase resource limits in docker-compose.prod.yml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 2G
```

#### High Memory Usage

```bash
# Check memory usage
docker stats --no-stream

# Analyze memory leaks
docker exec meal_planner_api_blue top -b -n 1
```

#### Slow Response Times

```bash
# Check nginx access logs
docker exec meal_planner_nginx tail -f /var/log/nginx/access.log

# Check database query performance
docker exec meal_planner_db psql -U postgres -d meal_planner \
  -c "SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;"
```

### Network Issues

#### Container Can't Reach External APIs

```bash
# Test external connectivity
docker exec meal_planner_api_blue curl -v https://api.fatsecret.com

# Check DNS resolution
docker exec meal_planner_api_blue nslookup api.fatsecret.com

# Verify network configuration
docker network inspect meal_planner_network
```

## Maintenance

### Backup Procedures

```bash
# Database backup
docker exec meal_planner_db pg_dump -U postgres meal_planner > backup-$(date +%Y%m%d).sql

# Upload to S3 (optional)
aws s3 cp backup-$(date +%Y%m%d).sql s3://your-backup-bucket/
```

### Database Migrations

```bash
# Run migrations
docker exec meal_planner_db psql -U postgres -d meal_planner -f /schema/XXX_migration.sql

# Verify migration
docker exec meal_planner_db psql -U postgres -d meal_planner \
  -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 1;"
```

### Security Updates

```bash
# Update base images
docker-compose -f docker-compose.prod.yml pull

# Rebuild with latest security patches
docker-compose -f docker-compose.prod.yml build --no-cache

# Deploy updated images
./scripts/deployment/deploy-blue-green.sh production latest
```

## Support

For additional help:

- Check application logs: `docker-compose -f docker-compose.prod.yml logs`
- Review health endpoints: `curl http://localhost:8080/health`
- Contact DevOps team: devops@example.com
