# Development Guide

## Prerequisites

- Erlang/OTP 26+
- Gleam 1.5.1+
- PostgreSQL 14+
- Task (taskfile.dev)

## Setup

```bash
# Install dependencies
cd gleam
gleam deps download

# Initialize database
./scripts/init-database.sh

# Run migrations
gleam run -m scripts/migrate

# Build
gleam build

# Run tests
gleam test

# Start server
gleam run
```

## Project Commands (Task)

```bash
# Build all
task build

# Run tests
task test

# Format code
task format

# Start server
task server

# Clean build artifacts
task clean
```

## Development Workflow

1. **Create Bead** for feature/bug
2. **Write tests** (TDD approach)
3. **Implement** feature
4. **Run tests**: `gleam test`
5. **Format**: `gleam format`
6. **Commit** with bead ID in message

## Testing

- Framework: gleeunit
- Run: `gleam test`
- Location: `gleam/test/`
- Coverage: Aim for >80%

## Code Style

- Follow Gleam conventions
- Use pattern matching
- Prefer pure functions
- Handle errors with Result types
- Document public functions

## Database Migrations

```bash
# Create migration
touch gleam/migrations_pg/008_migration_name.sql

# Apply migration
gleam run -m scripts/migrate

# Check schema
psql meal_planner -c "\d table_name"
```

## Debugging

```bash
# Enable debug logging
export LOG_LEVEL=debug
gleam run

# Database queries
export DB_DEBUG=true
gleam run
```

## Common Issues

**Build fails:**
- Check Gleam version: `gleam --version`
- Clean and rebuild: `gleam clean && gleam build`

**Tests fail:**
- Check database is running
- Run migrations
- Check test database exists

**Server won't start:**
- Check port 8080 is free
- Verify database connection
- Check environment variables
