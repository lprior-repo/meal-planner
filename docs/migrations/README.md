# Database Migrations Guide

This directory contains comprehensive documentation for managing database migrations in the Meal Planner application.

## Quick Reference

- **Location**: `/gleam/migrations_pg/` - All migration files
- **Tracking**: `schema_migrations` table in PostgreSQL
- **Format**: Sequential SQL files with descriptive names
- **Status Command**: `psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version;"`

## Documentation Files

### [MIGRATION_PROCESS.md](./MIGRATION_PROCESS.md)
Overview of the migration system architecture and how it works:
- How migrations are discovered and applied
- Migration tracking mechanism
- Automation via `init_pg.gleam`
- Key characteristics (idempotent, transactional)

### [RUNNING_MIGRATIONS.md](./RUNNING_MIGRATIONS.md)
Step-by-step instructions for running and managing migrations:
- Manual migration execution
- Verifying migration status
- Creating new migrations
- Testing migrations safely
- Common troubleshooting scenarios

### [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md)
Technical details about migration format and conventions:
- SQL file naming conventions
- Migration file structure
- Writing safe migrations
- Examples of different migration types
- Version numbering scheme

### [MIGRATION_BEST_PRACTICES.md](./MIGRATION_BEST_PRACTICES.md)
Best practices for creating and managing migrations:
- Guidelines for data integrity
- Performance considerations
- Testing strategies
- Coordination with code changes
- Rolling back migrations

## Current Migration Status

The application has 25 migrations applied:

```sql
SELECT * FROM schema_migrations ORDER BY version;
```

### Key Migration Phases

| Phase | Migrations | Purpose |
|-------|-----------|---------|
| Foundation | 001-003 | Schema tracking, USDA tables, application tables |
| Enhancement | 005-010 | Micronutrients, source tracking, meal planning, performance |
| Logging & Recipes | 011-014 | Food logs, recipe management, audit trails |
| Search & Analytics | 015-017 | Recipe search, micronutrient goals, analytics |
| Maintenance | 018-025 | Trigger updates, table cleanup, recipe system migration |

## Quick Start

### Check Migration Status
```bash
psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version;"
```

### Run All Pending Migrations
```bash
cd /home/lewis/src/meal-planner
gleam run -m scripts/init_pg
```

### Create a New Migration
1. Create SQL file: `/gleam/migrations_pg/NNN_description.sql`
2. Follow [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md) guidelines
3. Test with `psql -d meal_planner -f gleam/migrations_pg/NNN_description.sql`
4. Commit with message: `[migration] Add NNN_description`

### Troubleshoot Migration Issues
See [RUNNING_MIGRATIONS.md](./RUNNING_MIGRATIONS.md#troubleshooting) for solutions to common problems.

## Important Concepts

### Idempotent Migrations
All migrations use `IF NOT EXISTS` clauses to make them safe to run multiple times:
```sql
CREATE TABLE IF NOT EXISTS schema_migrations (...)
ALTER TABLE IF EXISTS food_logs ADD COLUMN IF NOT EXISTS ...
```

### Atomic Operations
Migrations wrap changes in transactions:
```sql
BEGIN;
-- Migration changes
COMMIT;  -- or ROLLBACK on error
```

### Version Tracking
Each applied migration is recorded with:
- Version number
- Migration name
- Applied timestamp

This prevents re-application of migrations.

## Related Documentation

- [POSTGRES_SETUP.md](../POSTGRES_SETUP.md) - PostgreSQL installation and configuration
- [ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) - How to rollback migrations
- [DEVELOPMENT.md](../DEVELOPMENT.md) - Development environment setup

## Database Schema Overview

### Core Tables
- **nutrients** - Nutrient definitions
- **foods** - USDA food items
- **food_nutrients** - Nutrient values for foods
- **food_logs** - User food intake logs
- **nutrition_state** - Daily nutrition totals
- **nutrition_goals** - User nutrition targets
- **user_profile** - User profile data
- **auto_meal_plans** - Generated meal plans

### Supporting Tables
- **schema_migrations** - Migration tracking
- **logs** - Application logs
- **search_analytics** - Search performance data
- **todoist_sync** - Todoist integration state

See [POSTGRES_SETUP.md](../POSTGRES_SETUP.md#database-schema) for full schema details.

## Common Tasks

### Add a Column
See example in [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md#adding-a-column)

### Rename a Table
See example in [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md#renaming-a-table)

### Add an Index
See example in [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md#adding-an-index)

### Create a Table
See example in [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md#creating-a-table)

## Support

For migration-related issues:
1. Check [RUNNING_MIGRATIONS.md#troubleshooting](./RUNNING_MIGRATIONS.md#troubleshooting)
2. Review related migration files in `/gleam/migrations_pg/`
3. Consult [ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) if rollback is needed
