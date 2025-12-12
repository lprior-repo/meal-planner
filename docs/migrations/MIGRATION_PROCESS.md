# Migration Process Architecture

## Overview

The Meal Planner application uses a sequential SQL migration system for PostgreSQL database management. Migrations are stored as SQL files in `/gleam/migrations_pg/` and tracked in the `schema_migrations` table.

## How It Works

### 1. Migration Discovery

When the application starts or you run `gleam run -m scripts/init_pg`:

1. The system connects to PostgreSQL
2. Verifies the `schema_migrations` table exists (migration 001 creates it)
3. Queries the table for all applied migrations
4. Compares with files in `/gleam/migrations_pg/`

### 2. Migration Tracking

The `schema_migrations` table records:

```sql
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
```

**Example of applied migrations:**
```
version | name                           | applied_at
--------|--------------------------------|------------------------
    1   | schema_migrations              | 2025-12-01 10:00:00+00
    2   | usda_tables                    | 2025-12-01 10:01:00+00
    3   | app_tables                     | 2025-12-01 10:02:00+00
    5   | add_micronutrients_...         | 2025-12-02 14:30:00+00
   ...
```

### 3. Application Process

The `init_pg.gleam` script implements the initialization flow:

```
START
  |
  ├─ Create database if needed
  |
  ├─ Start PostgreSQL connection pool
  |
  ├─ Check if schema_migrations table exists
  |   └─ If missing: Prompt user to run migrations manually
  |
  ├─ Verify required tables exist (foods, nutrients, food_nutrients)
  |   └─ If missing: Prompt user to run migrations
  |
  ├─ Check if USDA data is imported (26.8M+ food_nutrients)
  |   ├─ If yes: Print statistics and exit
  |   └─ If no: Start parallel import with N workers
  |
  └─ Complete
```

### 4. Key Characteristics

#### Idempotent
All migrations use `IF NOT EXISTS` or `ON CONFLICT` to make them safe to run multiple times:

```sql
-- Safe to run multiple times
CREATE TABLE IF NOT EXISTS schema_migrations (...)
ALTER TABLE IF EXISTS food_logs ADD COLUMN IF NOT EXISTS source_type TEXT;
INSERT INTO nutrients (...) ON CONFLICT (id) DO NOTHING;
```

#### Transactional
Migrations wrap changes in transactions to ensure consistency:

```sql
BEGIN;

-- Migration changes
ALTER TABLE food_logs ADD COLUMN new_column TEXT;
UPDATE food_logs SET new_column = 'default' WHERE new_column IS NULL;

COMMIT;  -- Atomically applies all changes or rolls back entirely
```

#### Ordered
Migrations are applied in version order (1, 2, 3, 5, 6, 8, 9, ...). Version numbers correspond to file prefixes:
- `001_schema_migrations.sql` → version 1
- `002_usda_tables.sql` → version 2
- `025_rename_mealie_recipe_to_tandoor_recipe.sql` → version 25

#### Non-Destructive
Once applied, migrations cannot be "un-applied" by the forward-running system. Rollbacks require manual intervention (see [ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md)).

### 5. Migration Phases

The application's migrations are organized into distinct phases:

#### Phase 1: Foundation (Migrations 1-3)
- **001**: Schema migration tracking table
- **002**: USDA food database tables (nutrients, foods, food_nutrients)
- **003**: Application tables (nutrition goals, food logs, recipes, user profile)

#### Phase 2: Enhancement (Migrations 5-10)
- **005**: Add micronutrient tracking to food logs
- **006**: Add source tracking (manual vs. recipe-based logs)
- **008**: Support for custom user-defined foods
- **009**: Auto meal planning tables and functions
- **010**: Search performance optimization with indexes

#### Phase 3: Logging & Recipes (Migrations 11-14)
- **011** (create_logs): Food logging tables
- **011** (create_recipes): Recipe storage tables
- **012**: Todoist sync integration tables
- **013**: Tim Ferriss recipe templates
- **013**: Vertical diet recipe templates
- **014**: Recipe source audit trail

#### Phase 4: Search & Analytics (Migrations 15-17)
- **015**: GIN indexes for recipe full-text search
- **016**: Micronutrient goal tracking
- **017**: Search analytics and usage tracking

#### Phase 5: Maintenance & System Updates (Migrations 18-25)
- **018**: Update audit triggers with context
- **019-021**: Drop deprecated recipe tables
- **022**: Rename Mealie recipe references
- **023**: Add recipe JSON to auto meal plans
- **024**: Populate recipe JSON for existing plans
- **025**: Rename Mealie to Tandoor throughout system

## Data Flow

### Initial Setup
```
1. Create database (PostgreSQL)
2. Run migration 001 → schema_migrations table created
3. Run migration 002 → USDA tables created
4. Import USDA CSV data → 26.8M food nutrients
5. Run migration 003 → application tables created
```

### Adding New Feature
```
1. Write Gleam code with new feature requirements
2. Create new migration SQL file (e.g., 026_add_feature.sql)
3. Apply migration to database
4. Update Gleam code to use new columns/tables
5. Test thoroughly
6. Commit both Gleam code and migration
```

### Post-Deployment
```
1. Deploy new Gleam code
2. Run init_pg script → applies pending migrations
3. System is ready with schema and data intact
```

## Migration Coupling

Migrations are tightly coupled with the Gleam application code:

- **Migrations define the schema** that Gleam code expects
- **Gleam code uses columns/tables** created by migrations
- **Both must be deployed together** to avoid errors

Example: Migration 025 renames `mealie_recipe` to `tandoor_recipe` in the `food_logs.source_type` column. The Gleam code must be updated to use the new name, and both changes deployed as a unit.

## Error Handling

### Migration Failures

If a migration fails during execution:

1. **PostgreSQL rolls back** the transaction automatically
2. **schema_migrations table** is not updated
3. **Next run will retry** the failed migration
4. **Error message** is displayed with diagnostics

### Partial Failures

If a migration partially completes (rare):

```bash
# Check migration status
psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version;"

# Verify schema state
psql -U postgres -d meal_planner -c "\dt"  # List tables
psql -U postgres -d meal_planner -c "\di"  # List indexes

# Consult ROLLBACK_PROCEDURE.md for recovery options
```

## Performance Considerations

### Large Migrations

For large data operations (e.g., migration 024 populating 1M+ rows):

1. Use **batch processing** to avoid memory issues
2. Disable triggers temporarily if needed
3. Add indexes **after** bulk loading
4. Monitor with: `SELECT * FROM pg_stat_activity;`

### Index Creation

Creating indexes on large tables (millions of rows) takes time:

- Monitor progress: `SELECT * FROM pg_stat_progress_create_index;`
- Large indexes may cause temporary performance impact
- Plan creation during low-traffic periods

### Parallel Workers

The `init_pg.gleam` script uses parallel workers for USDA data import:

```gleam
nutrition_constants.food_nutrient_import_workers  // Default: 8 workers
nutrition_constants.food_import_workers           // Default: 4 workers
nutrition_constants.nutrient_import_workers       // Default: 2 workers
```

## Version Numbering

The application uses **sequential integer versioning**:

- Versions: 1, 2, 3, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
- Note: Versions 4 and 7 are missing (possibly skipped or consolidated)
- New migrations should use the next available integer

## Related Concepts

### Schema vs. Data

- **Schema migrations** change structure (CREATE TABLE, ALTER COLUMN)
- **Data migrations** change content (UPDATE, DELETE)
- Most migrations are **both** - creating structure and populating data

### Database Versioning

The `schema_migrations` table acts as the **single source of truth**:
- It determines which version the database is at
- All deployments check this before running
- Prevents migrations from being applied twice

### Rollback Capability

While forward migrations are automatic, **rollbacks require manual SQL** because:
- Different situations need different approaches
- Rollbacks are rare and high-risk
- Automation could cause data loss

See [ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) for detailed rollback instructions.

## Testing Migrations

Before applying to production:

```bash
# Test on local copy
psql -U postgres -d meal_planner_test -f gleam/migrations_pg/026_new_migration.sql

# Verify schema
psql -U postgres -d meal_planner_test -c "SELECT * FROM schema_migrations ORDER BY version;"

# Verify data integrity
psql -U postgres -d meal_planner_test -c "SELECT COUNT(*) FROM food_logs;"
```

## Environment Variables

Migrations use these environment variables:

- `DATABASE_URL` - Primary database (default: postgresql://postgres@localhost/meal_planner)
- `TEST_DATABASE_URL` - Test database (default: postgresql://postgres@localhost/meal_planner_test)
- `PG_POOL_SIZE` - Connection pool size (affects import workers)

## See Also

- [RUNNING_MIGRATIONS.md](./RUNNING_MIGRATIONS.md) - Practical execution guide
- [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md) - Technical format and conventions
- [MIGRATION_BEST_PRACTICES.md](./MIGRATION_BEST_PRACTICES.md) - Creating safe migrations
- [POSTGRES_SETUP.md](../POSTGRES_SETUP.md) - PostgreSQL configuration
- [ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) - Recovering from migration issues
