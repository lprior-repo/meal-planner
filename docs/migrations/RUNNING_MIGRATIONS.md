# Running Migrations

This guide covers practical steps for running, verifying, and managing database migrations.

## Quick Start

### Check Current Migration Status

```bash
psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version;"
```

Expected output showing all applied migrations with timestamps.

### Run Pending Migrations

```bash
cd /home/lewis/src/meal-planner
gleam run -m scripts/init_pg
```

This:
1. Verifies the database exists
2. Creates the `schema_migrations` table if missing
3. Applies any pending migrations
4. Imports USDA data if not already present
5. Prints final statistics

### Verify Migration Success

```bash
# Check final migration status
psql -U postgres -d meal_planner -c "SELECT COUNT(*) FROM schema_migrations;"

# Expected: should match number of migration files with correct timestamps

# Verify key tables exist
psql -U postgres -d meal_planner -c "SELECT COUNT(*) FROM foods;"
psql -U postgres -d meal_planner -c "SELECT COUNT(*) FROM food_nutrients;"
psql -U postgres -d meal_planner -c "SELECT COUNT(*) FROM food_logs;"
```

## Running Individual Migrations

### Prerequisites

- PostgreSQL must be running
- Database must exist: `meal_planner`
- `schema_migrations` table should exist (from migration 001)

### Manual Migration Execution

Run a single migration SQL file:

```bash
psql -U postgres -d meal_planner -f gleam/migrations_pg/025_rename_mealie_recipe_to_tandoor_recipe.sql
```

### Verify Individual Migration

```bash
# Check if migration was recorded in schema_migrations
psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations WHERE version = 25;"

# Check resulting changes (e.g., verify a column exists)
psql -U postgres -d meal_planner -c "\d food_logs"
```

## Creating New Migrations

### 1. Plan the Migration

Document what changes you're making:
- What tables are affected?
- What columns are being added/modified/removed?
- Are there any data transformations needed?
- What indexes are required?

### 2. Choose Version Number

List existing migrations to find the next number:

```bash
ls -1 gleam/migrations_pg/ | grep -oP '^\d+' | sort -n | tail -5
```

Example output: `20, 21, 22, 23, 24, 25`

Next migration number: **26**

### 3. Create Migration File

Create: `/home/lewis/src/meal-planner/gleam/migrations_pg/026_description_of_change.sql`

Use descriptive names with underscores:
- `026_add_hydration_tracking.sql` ✓ Good
- `026_fix.sql` ✗ Poor
- `026_add_hydration.sql` ✓ Good

### 4. Write Migration Content

Follow the template:

```sql
-- ============================================================================
-- Migration: Brief description of what this migration does
-- ============================================================================
--
-- Detailed explanation of:
-- - What changes are being made
-- - Why they're necessary
-- - Any data transformations involved
-- - Rollback considerations
--
-- ============================================================================

BEGIN;

-- Migration logic here
-- Use IF NOT EXISTS / IF EXISTS to make migration idempotent

COMMIT;
```

### 5. Example Migrations

#### Adding a Column

```sql
-- ============================================================================
-- Migration: Add hydration tracking to nutrition_state
-- ============================================================================
--
-- Adds a water_intake_ml column to track daily water consumption alongside
-- macronutrient tracking. Uses NULL for existing records to allow backfill.
--
-- ============================================================================

BEGIN;

ALTER TABLE nutrition_state
ADD COLUMN IF NOT EXISTS water_intake_ml REAL;

-- Create index for efficient date + water queries
CREATE INDEX IF NOT EXISTS idx_nutrition_state_water
ON nutrition_state(date) WHERE water_intake_ml IS NOT NULL;

COMMIT;
```

#### Renaming a Column

```sql
-- ============================================================================
-- Migration: Rename Mealie recipe references to Tandoor
-- ============================================================================
--
-- The application is migrating from Mealie to Tandoor for recipe management.
-- Updates all references in the database to reflect this change.
--
-- ============================================================================

BEGIN;

-- Rename constraint
ALTER TABLE food_logs
DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

-- Update existing data
UPDATE food_logs
SET source_type = 'tandoor_recipe'
WHERE source_type = 'mealie_recipe';

-- Create new constraint
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type IN ('usda_food', 'custom_food', 'tandoor_recipe'));

COMMIT;
```

#### Creating a Table

```sql
-- ============================================================================
-- Migration: Create hydration_logs table for tracking water intake
-- ============================================================================
--
-- Detailed water intake logging with timestamps to track hydration patterns
-- throughout the day. Links to nutrition_state for daily aggregation.
--
-- ============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS hydration_logs (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    time_of_day TIME NOT NULL,
    amount_ml INTEGER NOT NULL CHECK (amount_ml > 0),
    source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'auto')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (date) REFERENCES nutrition_state(date)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_hydration_logs_date ON hydration_logs(date);
CREATE INDEX IF NOT EXISTS idx_hydration_logs_date_time ON hydration_logs(date, time_of_day);

COMMIT;
```

#### Adding an Index

```sql
-- ============================================================================
-- Migration: Add performance index for recipe searches
-- ============================================================================
--
-- Creates a GIN index on recipe descriptions for full-text search performance.
-- This supports the new recipe search feature that filters by ingredient names.
--
-- ============================================================================

BEGIN;

CREATE INDEX IF NOT EXISTS idx_recipe_description_gin
ON recipes USING gin(to_tsvector('english', name || ' ' || ingredients));

COMMIT;
```

#### Data Migration

```sql
-- ============================================================================
-- Migration: Populate recipe_json for existing auto meal plans
-- ============================================================================
--
-- Backfills the recipe_json column in auto_meal_plans table with JSON
-- representations of recipes for efficiency. Processes in batches to avoid
-- memory issues with large tables.
--
-- ============================================================================

BEGIN;

UPDATE auto_meal_plans
SET recipe_json = jsonb_build_object(
    'id', recipe_id,
    'name', (SELECT name FROM recipes WHERE id = auto_meal_plans.recipe_id),
    'calories', (SELECT calories FROM recipes WHERE id = auto_meal_plans.recipe_id)
)
WHERE recipe_json IS NULL;

COMMIT;
```

### 6. Test the Migration

Test on a local copy of the database:

```bash
# Create test database if needed
psql -U postgres -c "CREATE DATABASE meal_planner_test;"

# Run the migration on test DB
psql -U postgres -d meal_planner_test -f gleam/migrations_pg/026_your_migration.sql

# Verify it worked
psql -U postgres -d meal_planner_test -c "SELECT * FROM schema_migrations WHERE version = 26;"

# Check the schema changes
psql -U postgres -d meal_planner_test -c "\d table_name"

# Clean up test database
psql -U postgres -c "DROP DATABASE meal_planner_test;"
```

### 7. Commit and Deploy

Commit the migration file:

```bash
git add gleam/migrations_pg/026_your_migration.sql
git commit -m "[migration] Add 026_your_migration - Brief description"
git push origin your-branch
```

When deployed:

```bash
cd /home/lewis/src/meal-planner
gleam run -m scripts/init_pg
```

## Monitoring Migration Progress

### During Import (USDA Data)

The `init_pg` script shows progress:

```
Starting parallel USDA import...
Workers: 8 concurrent connections

Importing nutrients...
  -> 355 nutrients
Importing foods with 4 workers...
    Processing 1234567 rows...
    Worker 0 completed with 308642 rows
    Worker 1 completed with 308641 rows
    ...
```

### Tracking Large Operations

For long-running migrations, monitor from another terminal:

```bash
# Watch progress of current queries
psql -U postgres -d meal_planner -c "SELECT pid, query, query_start FROM pg_stat_activity WHERE datname = 'meal_planner' ORDER BY query_start;"

# Check index creation progress
psql -U postgres -d meal_planner -c "SELECT * FROM pg_stat_progress_create_index;"

# Monitor table size as data is imported
psql -U postgres -d meal_planner -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) FROM pg_tables WHERE schemaname = 'public' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
```

### Query Performance

Check if queries are slow:

```bash
# Enable query logging (temporary)
psql -U postgres -d meal_planner -c "ALTER SYSTEM SET log_min_duration_statement = 1000;"
psql -U postgres -d meal_planner -c "SELECT pg_reload_conf();"

# View slow queries
tail -f /var/log/postgresql/postgresql.log | grep duration
```

## Troubleshooting

### Migration Fails with "Table already exists"

**Problem**: Migration 003 fails because `food_logs` table exists

**Solution**:
```bash
# Check schema_migrations table
psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations;"

# If migration 003 is recorded, it already ran - continue to next step
# If migration 003 is NOT recorded, but table exists:
psql -U postgres -d meal_planner -c "INSERT INTO schema_migrations (version, name) VALUES (3, 'app_tables');"
```

### "Column already exists" Error

**Problem**: Adding a column fails because it already exists

**Solution**: This is harmless - the migration is idempotent:
```bash
# Just re-run the migration
psql -U postgres -d meal_planner -f gleam/migrations_pg/NNN_your_migration.sql

# The "IF NOT EXISTS" clause prevents the error
```

### Connection Timeout

**Problem**: Migration hangs on large table operations

**Solution**:
```bash
# Increase timeout
psql -U postgres -d meal_planner -c "SET statement_timeout TO '30 min';"

# Run migration again
psql -U postgres -d meal_planner -f gleam/migrations_pg/NNN_your_migration.sql
```

### Missing USDA Data

**Problem**: After migrations, `foods` table is empty

**Solution**:
```bash
# Check if USDA CSV files exist
ls -lh ~/.local/share/meal-planner/usda-cache/FoodData_Central_csv_*/

# If missing, download from USDA
# Then re-run:
cd /home/lewis/src/meal-planner
gleam run -m scripts/init_pg
```

### Too Many Connections

**Problem**: "FATAL: too many connections for database"

**Solution**:
```bash
# Check active connections
psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Terminate idle connections
psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle';"

# Or increase max_connections in postgresql.conf
# max_connections = 200
```

### Permission Denied

**Problem**: "Permission denied" when creating objects

**Solution**:
```bash
# Ensure you're connecting as postgres user
psql -U postgres -d meal_planner

# Check current user
SELECT current_user;

# Grant permissions if needed
GRANT ALL ON DATABASE meal_planner TO postgres;
```

### Transaction Aborted

**Problem**: "current transaction is aborted" error

**Solution**:
```bash
# Abort the current transaction
ROLLBACK;

# Start fresh
BEGIN;
-- Re-run your migration logic
COMMIT;
```

## Batch Operations

For migrations that process millions of rows, use batch processing:

```sql
BEGIN;

-- Update in batches to avoid locking the table
WITH batch AS (
    SELECT id FROM food_nutrients WHERE ingredient IS NULL LIMIT 10000
)
UPDATE food_nutrients
SET ingredient = 'value'
WHERE id IN (SELECT id FROM batch);

-- Repeat in application until complete
COMMIT;
```

Or use the Gleam script with parallel workers as `init_pg.gleam` does.

## Environment-Specific Migrations

### Test Database

```bash
# Run migration on test DB only
psql -U postgres -d meal_planner_test -f gleam/migrations_pg/026_new_migration.sql
```

### Production Database

```bash
# Deploy to production
./run.sh restart

# Verify migrations applied
psql -U postgres -d meal_planner -c "SELECT COUNT(*) FROM schema_migrations;"
```

## Rollback Scenarios

If a migration goes wrong, see [ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) for detailed recovery steps.

Quick reference:
1. Stop the application
2. Create backup: `pg_dump -U postgres meal_planner > backup.sql`
3. Drop the problematic migration from `schema_migrations`
4. Fix the SQL and retry
5. Restore from backup if needed

## Performance Tips

1. **Add indexes after bulk data loads** - faster than building while inserting
2. **Use CONCURRENTLY for index creation** - allows queries during creation
   ```sql
   CREATE INDEX CONCURRENTLY idx_name ON table (column);
   ```
3. **Disable triggers temporarily** - for large batch inserts
   ```sql
   ALTER TABLE table_name DISABLE TRIGGER ALL;
   -- Insert data
   ALTER TABLE table_name ENABLE TRIGGER ALL;
   ```
4. **Use ANALYZE after bulk operations** - updates query optimizer statistics
   ```sql
   ANALYZE food_nutrients;
   ```

## See Also

- [MIGRATION_PROCESS.md](./MIGRATION_PROCESS.md) - How migrations work internally
- [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md) - Technical format details
- [MIGRATION_BEST_PRACTICES.md](./MIGRATION_BEST_PRACTICES.md) - Best practices
- [ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) - Recovery procedures
