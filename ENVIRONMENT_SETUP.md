# Environment Configuration Guide

## Overview

The meal planner application uses environment variables for configuration. This allows for easy deployment across different environments (development, staging, production) and keeps sensitive data out of version control.

## Quick Start

### Development Setup

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Configure PostgreSQL** (optional - defaults work):
   ```bash
   # .env
   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   DATABASE_NAME=meal_planner
   DATABASE_USER=postgres
   DATABASE_PASSWORD=
   ```

3. **Configure Tandoor integration:**
   ```bash
   # Start Tandoor via automated startup
   ./run.sh start

   # OR manually start Tandoor
   docker-compose up -d tandoor

   # Open http://localhost:8000
   # Create account → Settings → API → Create token

   # Add to .env
   TANDOOR_BASE_URL=http://localhost:8000
   TANDOOR_API_TOKEN=your-token-here
   ```

4. **Start the application:**
   ```bash
   cd gleam
   gleam run
   ```

## Environment Variables Reference

### Required Variables

#### Database Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DATABASE_HOST` | PostgreSQL host | `localhost` | `postgres.example.com` |
| `DATABASE_PORT` | PostgreSQL port | `5432` | `5432` |
| `DATABASE_NAME` | Database name | `meal_planner` | `meal_planner_prod` |
| `DATABASE_USER` | Database user | `postgres` | `meal_app` |
| `DATABASE_PASSWORD` | Database password | *(empty)* | `secure-password` |
| `DATABASE_POOL_SIZE` | Connection pool size | `10` | `20` |

#### Server Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `PORT` | HTTP server port | `8080` | `3000` |
| `ENVIRONMENT` | Runtime environment | `development` | `production` |

### Integration Variables

#### Tandoor Integration (Required for Recipe Features)

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TANDOOR_BASE_URL` | Tandoor API base URL | `http://localhost:8000` | Yes |
| `TANDOOR_API_TOKEN` | Tandoor API authentication token | *(empty)* | Yes (production) |

**How to get TANDOOR_API_TOKEN:**

1. Start Tandoor: `docker-compose up -d tandoor` or `./run.sh start`
2. Open http://localhost:8000
3. Create an account (first user becomes admin)
4. Navigate to: Settings → API
5. Click "Create Token"
6. Copy the token and add to `.env`

#### External Services (Optional)

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `TODOIST_API_KEY` | Todoist integration | *(empty)* | No |
| `USDA_API_KEY` | USDA FoodData Central API | *(empty)* | No |
| `OPENAI_API_KEY` | OpenAI API for suggestions | *(empty)* | No |
| `OPENAI_MODEL` | OpenAI model to use | `gpt-4o` | No |

## Environment-Specific Configurations

### Development Environment

**File:** `.env`

```bash
# Development defaults - minimal configuration
DATABASE_HOST=localhost
DATABASE_NAME=meal_planner
PORT=8080
ENVIRONMENT=development

# Tandoor (running locally via Docker)
TANDOOR_BASE_URL=http://localhost:8000
TANDOOR_API_TOKEN=dev-token-from-tandoor-ui
```

### Docker Development

**File:** `.env.docker`

```bash
# Used by docker-compose.yml
POSTGRES_PASSWORD=postgres
TANDOOR_API_TOKEN=
OPENAI_API_KEY=
```

### Production Environment

**File:** `.env` (on production server, not in git)

```bash
# Production configuration - all required fields set
DATABASE_HOST=prod-postgres.example.com
DATABASE_PORT=5432
DATABASE_NAME=meal_planner
DATABASE_USER=meal_app
DATABASE_PASSWORD=<strong-password>
DATABASE_POOL_SIZE=20

PORT=8080
ENVIRONMENT=production

# Tandoor (production instance)
TANDOOR_BASE_URL=https://tandoor.example.com
TANDOOR_API_TOKEN=<production-token>

# External services
OPENAI_API_KEY=<production-key>
OPENAI_MODEL=gpt-4o
```

## Configuration Validation

The Gleam backend validates configuration on startup:

```gleam
import meal_planner/config

pub fn main() {
  let config = config.load()

  // Check production readiness
  case config.is_production_ready(config) {
    True -> io.println("✓ Production configuration validated")
    False -> io.println("⚠ Running with development settings")
  }

  // Check integrations
  case config.has_tandoor_integration(config) {
    True -> io.println("✓ Tandoor integration configured")
    False -> io.println("⚠ Tandoor integration not configured")
  }
}
```

### Production Validation Rules

Production mode (`ENVIRONMENT=production`) requires:
- ✅ `TANDOOR_API_TOKEN` must be set
- ✅ `DATABASE_PASSWORD` must be set
- ✅ All connection strings valid

## Security Best Practices

### ⚠️ Important Security Rules

1. **Never commit `.env` files to git**
   - `.env` is in `.gitignore`
   - Use `.env.example` for documentation

2. **Use strong passwords in production**
   ```bash
   # Generate secure password
   openssl rand -base64 32
   ```

3. **Rotate API tokens regularly**
   - Generate new Tandoor tokens monthly
   - Update OpenAI keys if compromised

4. **Use different credentials per environment**
   - Development: Simple passwords OK
   - Staging: Medium security
   - Production: Strong passwords, token rotation

5. **Store production secrets securely**
   - Use secret management (HashiCorp Vault, AWS Secrets Manager)
   - Or environment variables in deployment platform

## Loading Configuration

### In Gleam Code

```gleam
import meal_planner/config

pub fn main() {
  // Load configuration
  let config = config.load()

  // Use configuration
  let db_url = config.database_url(config)
  io.println("Database: " <> db_url)

  // Check integrations
  case config.has_tandoor_integration(config) {
    True -> setup_tandoor_client(config.tandoor_base_url, config.tandoor_api_token)
    False -> io.println("Tandoor integration disabled")
  }
}
```

### Helper Functions

The `config` module provides:

```gleam
// Load all configuration
config.load() -> Config

// Validate production readiness
config.is_production_ready(config) -> Bool

// Get database URL
config.database_url(config) -> String

// Check integrations
config.has_tandoor_integration(config) -> Bool
config.has_openai_integration(config) -> Bool
config.has_usda_integration(config) -> Bool
```

## Troubleshooting

### Configuration not loading

```bash
# Check if .env file exists
ls -la .env

# Verify file format (no spaces around =)
cat .env

# Check file permissions
chmod 600 .env
```

### Database connection fails

```bash
# Test PostgreSQL connection
psql -h localhost -U postgres -d meal_planner

# Check if database exists
psql -U postgres -c "\l"

# Verify credentials in .env match database
```

### Mealie integration not working

```bash
# Verify Mealie is running
curl http://localhost:9000/api/app/about

# Test API token
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:9000/api/recipes

# Generate new token in Mealie UI if invalid
```

## File Locations

| File | Purpose | Version Control |
|------|---------|-----------------|
| `.env.example` | Template with all variables | ✅ Committed |
| `.env` | Local development config | ❌ Git ignored |
| `.env.docker.example` | Docker template | ✅ Committed |
| `.env.docker` | Docker config | ❌ Git ignored |

## Next Steps

1. ✅ Copy `.env.example` to `.env`
2. ✅ Configure database (or use defaults)
3. ✅ Start Mealie and generate API token
4. ✅ Add token to `.env`
5. ⏭️ Implement HTTP server (meal-planner-wahn)
6. ⏭️ Implement Mealie API client (meal-planner-d9ln)
