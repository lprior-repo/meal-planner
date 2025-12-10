# Docker Setup for Meal Planner

## Overview

This Docker Compose setup runs the complete meal planner stack:
- **PostgreSQL 15**: Shared database with two databases (mealie, meal_planner)
- **Mealie v3.6.1**: Recipe manager with Vue.js UI (port 9000)
- **Gleam Backend**: AI meal planning and macro calculations (port 8080)

## Quick Start

### 1. Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

### 2. Configuration

Copy the environment template:

```bash
cp .env.docker.example .env.docker
```

Edit `.env.docker` and set your values (optional - works with defaults):

```bash
# PostgreSQL password (defaults to "postgres")
POSTGRES_PASSWORD=your-secure-password

# OpenAI API key for recipe scraping (optional)
OPENAI_API_KEY=sk-...
```

### 3. Start Services

Start all services:

```bash
docker-compose up -d
```

Watch logs:

```bash
docker-compose logs -f
```

### 4. Access Applications

- **Mealie UI**: http://localhost:9000
  - Create your first user account (admin)
  - Generate API token in Settings > API Tokens
  - Add the token to `.env.docker` as `MEALIE_API_TOKEN`

- **Gleam API** (when implemented): http://localhost:8080
  - Health check: http://localhost:8080/health
  - API docs: http://localhost:8080/docs

- **PostgreSQL**: localhost:5432
  - Database: `mealie` (for Mealie)
  - Database: `meal_planner` (for Gleam)
  - User: `postgres`
  - Password: from `.env.docker`

## Services

### PostgreSQL

- **Image**: postgres:15-alpine
- **Container**: meal-planner-postgres
- **Port**: 5432
- **Databases**:
  - `mealie` - Mealie recipe storage
  - `meal_planner` - Gleam backend storage
- **Health check**: `pg_isready`
- **Persistence**: `postgres_data` volume

### Mealie

- **Image**: ghcr.io/mealie-recipes/mealie:v3.6.1
- **Container**: meal-planner-mealie
- **Port**: 9000
- **Features**:
  - Recipe management with web scraping
  - Meal planning calendar
  - Shopping lists
  - User authentication
  - OpenAI integration (optional)
- **Health check**: `/api/app/about` endpoint
- **Persistence**: `mealie_data` volume

### Gleam Backend

- **Build**: From `./gleam/Dockerfile`
- **Container**: meal-planner-gleam
- **Port**: 8080
- **Features**:
  - AI meal planning algorithms
  - Macro optimization
  - Recipe scoring
  - Vertical diet compliance
- **Status**: Will be enabled when HTTP server is implemented
- **Health check**: `/health` endpoint (commented out until implemented)

## Database Initialization

On first start, PostgreSQL runs `scripts/init-db.sh` which:

1. Creates `mealie` database
2. Creates `meal_planner` database
3. Grants all privileges to postgres user

You can verify with:

```bash
docker-compose exec postgres psql -U postgres -c "\l"
```

## Common Commands

### Start services

```bash
docker-compose up -d
```

### Stop services

```bash
docker-compose down
```

### Stop and remove volumes (⚠️ deletes all data!)

```bash
docker-compose down -v
```

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mealie
docker-compose logs -f gleam-backend
docker-compose logs -f postgres
```

### Rebuild services

```bash
# Rebuild all
docker-compose build

# Rebuild specific service
docker-compose build gleam-backend
```

### Access PostgreSQL

```bash
docker-compose exec postgres psql -U postgres -d mealie
docker-compose exec postgres psql -U postgres -d meal_planner
```

### Restart a service

```bash
docker-compose restart mealie
docker-compose restart gleam-backend
```

## Development Workflow

### Local Development with Docker Database

You can use the Docker PostgreSQL instance for local development:

1. Start only PostgreSQL:
   ```bash
   docker-compose up -d postgres
   ```

2. Run Mealie locally (requires Python 3.12):
   ```bash
   cd mealie-app
   cp ../.env.docker .env
   source venv/bin/activate
   python -m mealie
   ```

3. Run Gleam backend locally:
   ```bash
   cd gleam
   # Set environment variables
   export DATABASE_HOST=localhost
   export DATABASE_NAME=meal_planner
   gleam run
   ```

### Hot Reload (Development Mode)

For Gleam backend development with hot reload:

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

(Note: `docker-compose.dev.yml` to be created for development overrides)

## Troubleshooting

### Mealie won't start

Check logs:
```bash
docker-compose logs mealie
```

Common issues:
- PostgreSQL not ready: Wait for health check to pass
- Database connection: Verify credentials in `.env.docker`

### PostgreSQL connection refused

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check PostgreSQL logs
docker-compose logs postgres

# Verify health check
docker-compose exec postgres pg_isready -U postgres
```

### Gleam backend build fails

```bash
# Check build logs
docker-compose build gleam-backend

# Try rebuilding without cache
docker-compose build --no-cache gleam-backend
```

### Database already exists error

This happens on subsequent starts - it's safe to ignore. The init script runs only once.

### Reset everything

```bash
# Stop and remove all containers, volumes, and networks
docker-compose down -v

# Remove all related Docker images
docker images | grep meal-planner | awk '{print $3}' | xargs docker rmi

# Start fresh
docker-compose up -d
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Docker Network                           │
│                  (meal-planner-network)                      │
│                                                              │
│  ┌────────────────┐        ┌─────────────────┐             │
│  │   Mealie       │        │  Gleam Backend  │             │
│  │   Port 9000    │◄──────►│   Port 8080     │             │
│  └───────┬────────┘        └────────┬────────┘             │
│          │                          │                       │
│          │         ┌────────────────┴───────┐               │
│          │         │                        │               │
│          └────────►│     PostgreSQL         │               │
│                    │      Port 5432         │               │
│                    │                        │               │
│                    │  DB: mealie            │               │
│                    │  DB: meal_planner      │               │
│                    └────────────────────────┘               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Exposed Ports
                           ▼
               Host: localhost:9000 (Mealie UI)
               Host: localhost:8080 (Gleam API)
               Host: localhost:5432 (PostgreSQL)
```

## Data Persistence

Data is persisted in Docker volumes:

- `postgres_data`: PostgreSQL database files
- `mealie_data`: Mealie application data (recipes, images, etc.)

To backup data:

```bash
# Backup PostgreSQL
docker-compose exec postgres pg_dumpall -U postgres > backup.sql

# Backup Mealie data
docker run --rm -v meal-planner_mealie_data:/data -v $(pwd):/backup alpine tar czf /backup/mealie-backup.tar.gz /data
```

To restore:

```bash
# Restore PostgreSQL
cat backup.sql | docker-compose exec -T postgres psql -U postgres

# Restore Mealie data
docker run --rm -v meal-planner_mealie_data:/data -v $(pwd):/backup alpine tar xzf /backup/mealie-backup.tar.gz -C /
```

## Security Notes

- Change `POSTGRES_PASSWORD` in production
- Use environment-specific `.env.docker` files
- Keep `.env.docker` out of version control (it's in `.gitignore`)
- Generate strong API tokens in Mealie
- Consider using Docker secrets for sensitive data in production

## Next Steps

1. ✅ Docker Compose configured
2. ⏭️ Implement Gleam HTTP server (meal-planner-wahn)
3. ⏭️ Implement Mealie API client in Gleam (meal-planner-d9ln)
4. ⏭️ Add AI endpoints to Gleam backend
5. ⏭️ Test end-to-end integration
