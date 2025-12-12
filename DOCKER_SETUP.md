# Docker Setup for Meal Planner

## Overview

This Docker Compose setup runs the complete meal planner stack:
- **PostgreSQL 15**: Database for Gleam backend (meal_planner database)
- **Tandoor**: Recipe manager with modern web UI (port 8000, separate tandoor database)
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

- **Tandoor UI**: http://localhost:8000
  - Create your first user account (admin)
  - Generate API token in Settings > API Tokens
  - Add the token to environment variables as `TANDOOR_API_TOKEN`

- **Gleam API**: http://localhost:8080
  - Health check: http://localhost:8080/health
  - API documentation available in source

- **PostgreSQL**: localhost:5432
  - Database: `meal_planner` (for Gleam backend)
  - Database: `tandoor` (for Tandoor, separate database)
  - User: `postgres`
  - Password: from `.env.docker`

## Services

### PostgreSQL

- **Image**: postgres:15-alpine
- **Container**: meal-planner-postgres
- **Port**: 5432
- **Databases**:
  - `meal_planner` - Gleam backend storage
  - `tandoor` - Tandoor recipe management
- **Health check**: `pg_isready`
- **Persistence**: `postgres_data` volume

### Tandoor

- **Image**: vabene1111/recipes:latest
- **Container**: meal-planner-tandoor
- **Port**: 8000
- **Features**:
  - Recipe management with web scraping
  - Meal planning calendar
  - Shopping lists
  - User authentication
  - API for recipe synchronization
- **Database**: Uses `tandoor` database (separate from meal_planner)
- **Health check**: `/health` endpoint
- **Persistence**: `tandoor_data` volume

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

1. Creates `meal_planner` database for Gleam backend
2. Creates `tandoor` database for Tandoor
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
docker-compose logs -f tandoor
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
docker-compose exec postgres psql -U postgres -d tandoor
docker-compose exec postgres psql -U postgres -d meal_planner
```

### Restart a service

```bash
docker-compose restart tandoor
docker-compose restart gleam-backend
```

## Development Workflow

### Local Development with Docker Database

You can use the Docker PostgreSQL and Tandoor instances for local development:

1. Start PostgreSQL and Tandoor:
   ```bash
   docker-compose up -d postgres tandoor
   ```

2. Run Gleam backend locally:
   ```bash
   cd gleam
   # Set environment variables
   export DATABASE_HOST=localhost
   export DATABASE_NAME=meal_planner
   export TANDOOR_BASE_URL=http://localhost:8000
   gleam run
   ```

### Hot Reload (Development Mode)

For Gleam backend development with hot reload:

```bash
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

(Note: `docker-compose.dev.yml` to be created for development overrides)

## Troubleshooting

### Tandoor won't start

Check logs:
```bash
docker-compose logs tandoor
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
│  │   Tandoor      │        │  Gleam Backend  │             │
│  │   Port 8000    │◄──────►│   Port 8080     │             │
│  └───────┬────────┘        └────────┬────────┘             │
│          │                          │                       │
│          │         ┌────────────────┴───────┐               │
│          │         │                        │               │
│          └────────►│     PostgreSQL         │               │
│                    │      Port 5432         │               │
│                    │                        │               │
│                    │  DB: tandoor           │               │
│                    │  DB: meal_planner      │               │
│                    └────────────────────────┘               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ Exposed Ports
                           ▼
               Host: localhost:8000 (Tandoor UI)
               Host: localhost:8080 (Gleam API)
               Host: localhost:5432 (PostgreSQL)
```

## Data Persistence

Data is persisted in Docker volumes:

- `postgres_data`: PostgreSQL database files
- `tandoor_data`: Tandoor application data (recipes, images, etc.)

To backup data:

```bash
# Backup PostgreSQL
docker-compose exec postgres pg_dumpall -U postgres > backup.sql

# Backup Tandoor data
docker run --rm -v meal-planner_tandoor_data:/data -v $(pwd):/backup alpine tar czf /backup/tandoor-backup.tar.gz /data
```

To restore:

```bash
# Restore PostgreSQL
cat backup.sql | docker-compose exec -T postgres psql -U postgres

# Restore Tandoor data
docker run --rm -v meal-planner_tandoor_data:/data -v $(pwd):/backup alpine tar xzf /backup/tandoor-backup.tar.gz -C /
```

## Security Notes

- Change `POSTGRES_PASSWORD` in production
- Use environment-specific `.env.docker` files
- Keep `.env.docker` out of version control (it's in `.gitignore`)
- Generate strong API tokens in Tandoor
- Consider using Docker secrets for sensitive data in production

## Next Steps

1. ✅ Docker Compose configured with Tandoor
2. ✅ Gleam HTTP server implemented
3. ✅ Tandoor integration in progress
4. ⏭️ Complete Tandoor API client in Gleam
5. ⏭️ Test end-to-end integration with Tandoor recipes
