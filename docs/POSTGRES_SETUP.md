# PostgreSQL Setup for Meal Planner

## Overview

PostgreSQL is the primary database for the meal planner application. This document describes the current setup, migrations, and configuration.

## Installation

PostgreSQL is pre-installed on the system:

```bash
# Check PostgreSQL status
systemctl status postgresql

# PostgreSQL version
psql --version
```

## Database Configuration

### Main Databases

Two databases are configured:

1. **meal_planner** - Production database
2. **meal_planner_test** - Test database

### Database User

- User: `postgres` (system default)
- No password required (local socket authentication)

## Schema Migrations

All migrations are stored in `/gleam/migrations_pg/` and tracked in the `schema_migrations` table.

### Migration Files

| Version | Migration | Status |
|---------|-----------|--------|
| 1 | schema_migrations | Applied |
| 2 | usda_tables | Applied |
| 3 | app_tables | Applied |
| 5 | add_micronutrients_to_food_logs | Applied |
| 6 | add_source_tracking | Applied |
| 9 | auto_meal_planner | Applied |
| 10 | optimize_search_performance | Applied |
| 11 | create_logs | Applied |
| 11 | create_recipes | Applied |
| 12 | create_todoist_sync | Applied |
| 13 | add_tim_ferriss_recipes | Applied |
| 14 | add_vertical_diet_recipes | Applied |

### Verify Migrations

```bash
psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version;"
```

## Database Schema

### Main Tables

The application uses the following tables:

#### USDA Food Data
- `nutrients` - Nutrient definitions (ID, name, unit)
- `foods` - Food items from USDA FoodData Central (FDC ID, description, category)
- `food_nutrients` - Nutrient values for foods
- `food_nutrients_staging` - Temporary staging table for bulk imports

#### Application Data
- `recipes` - Recipe definitions (name, ingredients, macros, FODMAP level)
- `custom_foods` - User-defined foods
- `food_logs` - Daily food consumption logs
- `nutrition_state` - Daily nutrition totals
- `nutrition_goals` - User's nutrition targets
- `user_profile` - User profile (bodyweight, activity level, goals)
- `weekly_plans` - Weekly meal plans
- `weekly_plan_meals` - Meals in weekly plans
- `recipe_sources` - Recipe source tracking

#### Additional Tables
- `schema_migrations` - Migration tracking
- `logs` - Application logs
- `todoist_sync` - Todoist integration state

### Indexes

Full-text search on foods:
```sql
CREATE INDEX idx_foods_description_gin ON foods USING gin(to_tsvector('english', description));
```

Performance indexes:
- Food lookups by category, data type
- Nutrient lookups by food and nutrient ID
- Date-based food log queries

## Connection

### Direct Connection

```bash
# Connect to production database
psql -U postgres -d meal_planner

# Connect to test database
psql -U postgres -d meal_planner_test
```

### Application Connection

Set the following environment variables:

```bash
DATABASE_URL=postgresql://postgres@localhost/meal_planner
TEST_DATABASE_URL=postgresql://postgres@localhost/meal_planner_test
```

## Running Migrations

Migrations run automatically when the application starts. To manually run migrations:

```bash
# All migrations are idempotent
cd /home/lewis/src/meal-planner
/tmp/run_migrations.sh
```

## Backups

Currently, no automated backups are configured. For production:

```bash
# Manual backup
pg_dump -U postgres meal_planner > meal_planner_backup.sql

# Restore
psql -U postgres -d meal_planner < meal_planner_backup.sql
```

## Connection Pooling

PostgreSQL may reach max connections during heavy concurrent usage. To adjust:

```bash
# View current setting
psql -U postgres -c "SHOW max_connections;"

# Modify postgresql.conf
# max_connections = 200
```

## Common Operations

### Create a new migration

Create a new SQL file in `/gleam/migrations_pg/`:
```sql
-- Migration description
-- Version number should be sequential
```

### Reset the test database

```bash
psql -U postgres -d meal_planner_test -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

### View database size

```bash
psql -U postgres -c "\l+ meal_planner"
```

### Check table sizes

```bash
psql -U postgres -d meal_planner -c "
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

## Troubleshooting

### Too many connections

```bash
# View active connections
psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Terminate idle connections
psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state='idle';"
```

### Missing tables

Run migrations again:
```bash
/tmp/run_migrations.sh
```

## Environment Setup

A template environment file has been created at `.env.example`:

```bash
# PostgreSQL Connection
DATABASE_URL=postgresql://postgres@localhost/meal_planner
TEST_DATABASE_URL=postgresql://postgres@localhost/meal_planner_test

# Application Configuration
PORT=3000
ENVIRONMENT=development
```

Copy to `.env` and adjust as needed for your environment.

