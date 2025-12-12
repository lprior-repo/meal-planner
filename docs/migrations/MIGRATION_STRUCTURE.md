# Migration Structure and Format

This document describes the technical format, conventions, and structure of database migrations.

## File Organization

### Location

All migrations are stored in:
```
/home/lewis/src/meal-planner/gleam/migrations_pg/
```

### Naming Convention

Migrations follow the naming pattern:

```
NNN_descriptive_name_with_underscores.sql
```

**Format Rules:**
- `NNN` - Zero-padded 3-digit version number (001, 002, ..., 025)
- `_` - Single underscore separator
- `descriptive_name_with_underscores` - Lowercase description using underscores
- `.sql` - SQL file extension

**Valid Examples:**
- `001_schema_migrations.sql` ✓
- `002_usda_tables.sql` ✓
- `025_rename_mealie_recipe_to_tandoor_recipe.sql` ✓
- `026_add_hydration_tracking.sql` ✓

**Invalid Examples:**
- `26_add_hydration.sql` ✗ (not zero-padded)
- `026_Add_Hydration.sql` ✗ (uppercase letters)
- `026-add-hydration.sql` ✗ (hyphens instead of underscores)
- `AddHydration.sql` ✗ (no version prefix)

## File Structure

### Standard Template

Every migration should follow this structure:

```sql
-- ============================================================================
-- Migration: [Brief One-Line Description]
-- ============================================================================
--
-- [Detailed explanation paragraph(s) covering:]
-- - What changes are being made and why
-- - Any data transformations involved
-- - Performance considerations
-- - Rollback implications
--
-- Related Issues/PRs: [if applicable]
--
-- ============================================================================

BEGIN;

-- [Migration SQL statements here]

COMMIT;
```

### Header Documentation

The header comment block includes:

1. **Title Line**: "Migration: [Description]"
2. **Blank Line**: Separator
3. **Details**: Multi-line explanation of:
   - What is changing
   - Why it's changing
   - Any data operations
   - Performance notes
   - Rollback strategy
4. **References**: Related issues, PRs, or decision documents
5. **Footer**: Closing separator

### Example Header

```sql
-- ============================================================================
-- Migration: Add micronutrient tracking to food logs
-- ============================================================================
--
-- Adds support for tracking micronutrients (vitamins, minerals) in food logs.
-- Expands food_logs table with individual nutrient columns for:
-- - Vitamin A (IU)
-- - Vitamin C (mg)
-- - Iron (mg)
-- - Calcium (mg)
-- - Magnesium (mg)
--
-- This migration adds columns only; data population is deferred to application
-- logic. Uses DEFAULT 0.0 for backward compatibility with existing logs.
--
-- Performance: Creating 5 columns is a fast ALTER TABLE operation on any size
-- table. No rewrite necessary since we're only adding columns, not modifying
-- existing ones.
--
-- Rollback: Use migration 999_remove_micronutrient_columns.sql to revert.
-- Any application code using these columns should be rolled back simultaneously.
--
-- ============================================================================
```

## SQL Best Practices

### 1. Use Transactions

Wrap all changes in `BEGIN` / `COMMIT`:

```sql
BEGIN;

-- All migration logic here
-- If any statement fails, entire migration rolls back
-- If all succeed, all changes are committed atomically

COMMIT;
```

**Never use:**
- `ROLLBACK` - PostgreSQL handles this automatically on errors
- Multiple `BEGIN`/`COMMIT` pairs - use one transaction per migration
- `AUTOCOMMIT` - disable it for safety

### 2. Make Migrations Idempotent

Migrations should be safe to run multiple times without errors.

#### Use IF NOT EXISTS / IF EXISTS

```sql
-- GOOD: Safe to run multiple times
CREATE TABLE IF NOT EXISTS recipes (...)
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS source_type TEXT;
DROP TABLE IF EXISTS deprecated_table;
DROP INDEX IF EXISTS old_index;

-- BAD: Fails if already applied
CREATE TABLE recipes (...)  -- Error: table already exists
ALTER TABLE food_logs ADD COLUMN source_type TEXT;  -- Error: column exists
DROP TABLE deprecated_table;  -- Error: table doesn't exist
```

#### Use ON CONFLICT for Inserts

```sql
-- GOOD: Skip if row exists
INSERT INTO nutrients (id, name) VALUES (1, 'Protein')
ON CONFLICT (id) DO NOTHING;

-- BAD: Fails if row exists
INSERT INTO nutrients (id, name) VALUES (1, 'Protein');
```

#### Use Constraints Properly

```sql
-- GOOD: Drop before recreating
ALTER TABLE food_logs DROP CONSTRAINT IF EXISTS food_logs_source_type_check;
ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type IN ('usda_food', 'custom_food', 'tandoor_recipe'));

-- BAD: Fails if constraint already exists
ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check ...;
```

### 3. Handle NULL Values

When adding columns, consider existing data:

```sql
-- GOOD: Explicit DEFAULT for existing rows
ALTER TABLE nutrition_state
ADD COLUMN IF NOT EXISTS water_intake_ml REAL DEFAULT 0.0;

-- GOOD: NULL is acceptable (nullable column)
ALTER TABLE food_logs
ADD COLUMN IF NOT EXISTS recipe_source TEXT;

-- BAD: NOT NULL without DEFAULT breaks inserts of existing rows
ALTER TABLE nutrition_state
ADD COLUMN IF NOT EXISTS water_intake_ml REAL NOT NULL;
```

### 4. Create Indexes After Bulk Data

For operations that add or modify large amounts of data, create indexes after:

```sql
BEGIN;

-- 1. Add columns (fast)
ALTER TABLE food_nutrients ADD COLUMN IF NOT EXISTS source TEXT;

-- 2. Update data (slow for large tables)
UPDATE food_nutrients SET source = 'usda' WHERE source IS NULL;

-- 3. Add constraints (fast)
ALTER TABLE food_nutrients
ADD CONSTRAINT food_nutrients_source_check
CHECK (source IN ('usda', 'custom'));

-- 4. Create indexes (slow but necessary)
CREATE INDEX IF NOT EXISTS idx_food_nutrients_source
ON food_nutrients(source);

COMMIT;
```

### 5. Use Meaningful Comments

```sql
BEGIN;

-- Update all logs without a source to mark them as manually entered
-- This preserves existing data while establishing the source tracking feature
UPDATE food_logs
SET source_type = 'manual'
WHERE source_type IS NULL;

-- Add the new source_type constraint to enforce valid values
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type IN ('usda_food', 'custom_food', 'tandoor_recipe'));

COMMIT;
```

### 6. Quote Identifiers

Always quote SQL identifiers to avoid ambiguity:

```sql
-- GOOD: Quotes protect against reserved words and special characters
ALTER TABLE "food_logs" ADD COLUMN IF NOT EXISTS "source_type" TEXT;

-- Acceptable: Safe identifiers don't strictly need quotes
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS source_type TEXT;

-- BAD: Unquoted reserved words can cause errors
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS order TEXT;  -- 'order' is reserved
```

### 7. Handle Foreign Keys Carefully

```sql
BEGIN;

-- Add foreign key constraint
ALTER TABLE food_logs
ADD CONSTRAINT fk_food_logs_user_id
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

-- Or for existing data that might violate constraints:
ALTER TABLE food_logs
ADD CONSTRAINT fk_food_logs_user_id
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE
DEFERRABLE INITIALLY DEFERRED;

COMMIT;
```

## Common Migration Patterns

### Pattern 1: Adding a Column

```sql
-- ============================================================================
-- Migration: Add hydration tracking to nutrition_state
-- ============================================================================
--
-- Adds water_intake_ml column to track daily water consumption.
-- Existing rows default to 0.0 (no water tracked yet).
--
-- ============================================================================

BEGIN;

ALTER TABLE nutrition_state
ADD COLUMN IF NOT EXISTS water_intake_ml REAL DEFAULT 0.0;

-- Optional: Create index for efficient queries
CREATE INDEX IF NOT EXISTS idx_nutrition_state_water
ON nutrition_state(date) WHERE water_intake_ml > 0;

COMMIT;
```

### Pattern 2: Renaming a Column

```sql
-- ============================================================================
-- Migration: Rename recipe column to recipe_id
-- ============================================================================
--
-- Clarifies that the column contains a recipe ID, not the full recipe.
-- Uses PostgreSQL ALTER TABLE RENAME COLUMN.
--
-- ============================================================================

BEGIN;

-- Rename the column
ALTER TABLE auto_meal_plans
RENAME COLUMN recipe TO recipe_id;

-- Rename related index if it exists
ALTER INDEX IF EXISTS idx_auto_meal_plans_recipe
RENAME TO idx_auto_meal_plans_recipe_id;

COMMIT;
```

### Pattern 3: Renaming a Table

```sql
-- ============================================================================
-- Migration: Rename mealie_recipe to tandoor_recipe
-- ============================================================================
--
-- The application is switching from Mealie to Tandoor for recipe management.
-- Renames the table and all related constraints/indexes.
--
-- ============================================================================

BEGIN;

-- Rename the table
ALTER TABLE mealie_recipe
RENAME TO tandoor_recipe;

-- Update constraint names
ALTER TABLE tandoor_recipe
RENAME CONSTRAINT mealie_recipe_pkey TO tandoor_recipe_pkey;

-- Update index names
ALTER INDEX idx_mealie_recipe_source
RENAME TO idx_tandoor_recipe_source;

COMMIT;
```

### Pattern 4: Renaming Enum/Check Values

```sql
-- ============================================================================
-- Migration: Rename mealie_recipe to tandoor_recipe in source_type
-- ============================================================================
--
-- Updates the check constraint and data to reflect recipe system migration.
--
-- ============================================================================

BEGIN;

-- Update existing data first
UPDATE food_logs
SET source_type = 'tandoor_recipe'
WHERE source_type = 'mealie_recipe';

-- Drop old constraint
ALTER TABLE food_logs
DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

-- Add new constraint with updated values
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type IN ('usda_food', 'custom_food', 'tandoor_recipe'));

COMMIT;
```

### Pattern 5: Creating a Table

```sql
-- ============================================================================
-- Migration: Create hydration_logs table
-- ============================================================================
--
-- Detailed water intake logging with timestamps. Links to nutrition_state
-- table for daily aggregation of water consumption.
--
-- ============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS hydration_logs (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    time_of_day TIME NOT NULL,
    amount_ml INTEGER NOT NULL CHECK (amount_ml > 0),
    source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'auto')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (date) REFERENCES nutrition_state(date) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hydration_logs_date ON hydration_logs(date);
CREATE INDEX IF NOT EXISTS idx_hydration_logs_date_time ON hydration_logs(date, time_of_day);
CREATE INDEX IF NOT EXISTS idx_hydration_logs_source ON hydration_logs(source);

-- Constraints
CREATE UNIQUE INDEX IF NOT EXISTS idx_hydration_logs_unique_entry
ON hydration_logs(date, time_of_day);

COMMIT;
```

### Pattern 6: Data Migration

```sql
-- ============================================================================
-- Migration: Populate recipe_json for existing auto_meal_plans
-- ============================================================================
--
-- Backfills recipe_json column with JSON representations of recipes.
-- Processes efficiently using window functions and UPDATE with subquery.
--
-- ============================================================================

BEGIN;

UPDATE auto_meal_plans
SET recipe_json = (
    SELECT jsonb_build_object(
        'id', r.id,
        'name', r.name,
        'calories', r.calories,
        'protein', r.protein,
        'fat', r.fat,
        'carbs', r.carbs
    )
    FROM recipes r
    WHERE r.id = auto_meal_plans.recipe_id
)
WHERE recipe_json IS NULL
AND recipe_id IS NOT NULL;

-- Verify the update
-- SELECT COUNT(*) FROM auto_meal_plans WHERE recipe_json IS NULL;

COMMIT;
```

### Pattern 7: Adding an Index

```sql
-- ============================================================================
-- Migration: Add GIN index for recipe full-text search
-- ============================================================================
--
-- Creates inverted index for searching recipe names and ingredients.
-- Enables fast full-text search with to_tsvector operations.
--
-- ============================================================================

BEGIN;

CREATE INDEX IF NOT EXISTS idx_recipe_search_gin
ON recipes USING gin(
    to_tsvector('english', name || ' ' || COALESCE(ingredients, ''))
);

-- Optional: Analyze to update query planner statistics
ANALYZE recipes;

COMMIT;
```

### Pattern 8: Adding a Trigger

```sql
-- ============================================================================
-- Migration: Create audit trigger for food_logs
-- ============================================================================
--
-- Automatically records all changes to food_logs in food_logs_audit table.
-- Triggers on INSERT, UPDATE, DELETE operations.
--
-- ============================================================================

BEGIN;

-- Create audit table
CREATE TABLE IF NOT EXISTS food_logs_audit (
    id SERIAL PRIMARY KEY,
    food_log_id INTEGER,
    action TEXT,
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create trigger function
CREATE OR REPLACE FUNCTION food_logs_audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO food_logs_audit (food_log_id, action, old_data, new_data)
    VALUES (COALESCE(NEW.id, OLD.id), TG_OP, row_to_json(OLD), row_to_json(NEW));
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Attach trigger
DROP TRIGGER IF EXISTS food_logs_audit ON food_logs;
CREATE TRIGGER food_logs_audit
AFTER INSERT OR UPDATE OR DELETE ON food_logs
FOR EACH ROW EXECUTE FUNCTION food_logs_audit_trigger();

COMMIT;
```

## Version Numbering

### Schema

Versions are **sequential integers** starting from 1:
- `001` → version 1
- `002` → version 2
- `025` → version 25
- `026` → version 26 (next)

### Gaps

Version 4 and 7 are missing (possibly skipped during development). Gaps are acceptable.

### Choosing Next Version

List existing migrations:
```bash
ls -1 gleam/migrations_pg/ | grep -oP '^\d+' | sort -n | tail -3
# Output: 23, 24, 25
# Next: 026
```

Or query the database:
```sql
SELECT MAX(version) FROM schema_migrations;
-- Output: 25
-- Next: 26
```

## Performance Considerations

### Large Table Operations

When working with millions of rows:

```sql
BEGIN;

-- Add column (fast - schema change only)
ALTER TABLE food_nutrients ADD COLUMN source TEXT;

-- Update in batches instead of all at once
-- (Prevents lock contention and memory pressure)

-- For very large tables, application code should do batched updates:
-- LOOP:
--   UPDATE food_nutrients SET source = 'usda'
--   WHERE source IS NULL
--   LIMIT 10000;
--   -- Sleep and repeat until done

-- Create index AFTER data migration (index building is expensive)
CREATE INDEX idx_food_nutrients_source ON food_nutrients(source);

COMMIT;
```

### Index Creation

Creating indexes on large tables takes time:

```sql
BEGIN;

-- Standard index creation
-- Locks table briefly during creation
CREATE INDEX idx_foods_category ON foods(food_category);

-- Concurrent index creation (PostgreSQL 11+)
-- Allows queries while index is being built
CREATE INDEX CONCURRENTLY idx_foods_category_gin
ON foods USING gin(to_tsvector('english', description));

COMMIT;
```

### Analyzing Statistics

After bulk operations, update statistics:

```sql
BEGIN;

UPDATE food_nutrients SET source = 'usda' WHERE source IS NULL;

-- Update optimizer statistics so queries plan efficiently
ANALYZE food_nutrients;

COMMIT;
```

## Safety Practices

### Always Test First

```bash
# Create test database
createdb meal_planner_test

# Apply migration
psql -d meal_planner_test -f gleam/migrations_pg/026_new_migration.sql

# Verify
psql -d meal_planner_test -c "SELECT * FROM schema_migrations WHERE version = 26;"

# Cleanup
dropdb meal_planner_test
```

### Use Transactions

All migrations should be wrapped in `BEGIN`/`COMMIT` to ensure atomicity.

### Include Rollback Information

Every migration should document how to reverse it:

```sql
-- Rollback: To undo this migration:
-- ALTER TABLE nutrition_state DROP COLUMN IF EXISTS water_intake_ml;
-- DELETE FROM schema_migrations WHERE version = 026;
```

### Avoid Risky Operations

```sql
-- RISKY: Data loss without recovery
DROP TABLE foods;  -- No warning, data is gone

-- SAFER: Explicit checks and backups
-- 1. Backup first: pg_dump
-- 2. Use IF EXISTS to show intent:
DROP TABLE IF EXISTS deprecated_foods;
-- 3. Document rollback procedure
```

## Deployment Checklist

Before committing a new migration:

- [ ] File named correctly: `NNN_description.sql`
- [ ] Header documented with purpose and details
- [ ] All SQL wrapped in `BEGIN`/`COMMIT`
- [ ] Uses `IF NOT EXISTS` / `ON CONFLICT` for idempotency
- [ ] Tested on local test database
- [ ] Indexes created after bulk data operations
- [ ] Foreign keys specify `ON DELETE` behavior
- [ ] Performance considered (no table rewrites unless necessary)
- [ ] Rollback procedure documented in comments
- [ ] No JavaScript files included (Gleam code updates separate)

## Related Files

- `/gleam/migrations_pg/` - All migration files
- `gleam/src/scripts/init_pg.gleam` - Migration execution logic
- `gleam/migrations_pg/001_schema_migrations.sql` - Tracking table definition

## See Also

- [RUNNING_MIGRATIONS.md](./RUNNING_MIGRATIONS.md) - How to execute migrations
- [MIGRATION_PROCESS.md](./MIGRATION_PROCESS.md) - How the system works
- [MIGRATION_BEST_PRACTICES.md](./MIGRATION_BEST_PRACTICES.md) - Creating safe migrations
