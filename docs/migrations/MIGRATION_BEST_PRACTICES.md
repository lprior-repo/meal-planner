# Migration Best Practices

This document provides guidelines for creating safe, maintainable database migrations.

## Core Principles

### 1. Make Migrations Forward-Only

Migrations should be designed to move the database forward, never backward.

```sql
-- GOOD: Forward migration
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS water_intake REAL;
UPDATE food_logs SET water_intake = 0.0 WHERE water_intake IS NULL;

-- BAD: Trying to move backward (risks data loss)
DROP TABLE deprecated_foods;  -- How will you undo this?
```

**Why:** Forward-only migrations ensure:
- No accidental data loss
- Clear upgrade path
- Easy to understand what changed
- Reduces cognitive load

### 2. Keep Migrations Focused

Each migration should handle one logical change.

```sql
-- GOOD: One focused change
-- Migration 026: Add hydration tracking
BEGIN;
ALTER TABLE nutrition_state ADD COLUMN water_intake_ml REAL DEFAULT 0.0;
CREATE INDEX idx_nutrition_state_water ON nutrition_state(date);
COMMIT;

-- BAD: Multiple unrelated changes
-- Migration 026: Various improvements
BEGIN;
ALTER TABLE nutrition_state ADD COLUMN water_intake_ml REAL;
ALTER TABLE food_logs ADD COLUMN source_type TEXT;
CREATE TABLE hydration_logs (...);
DROP TABLE old_recipes;
COMMIT;
```

**Why:** Focused migrations:
- Easier to understand and review
- Simpler to rollback (if needed)
- Can be deployed independently
- Make git history more useful

### 3. Document Thoroughly

Include comprehensive comments explaining the migration.

```sql
-- ============================================================================
-- Migration: Add micronutrient tracking to food logs
-- ============================================================================
--
-- This migration adds support for tracking individual micronutrients in the
-- food_logs table. Previously, only macronutrients (protein, fat, carbs) were
-- tracked. This change enables more detailed nutritional analysis.
--
-- Changes:
-- 1. Add 5 new columns to food_logs for micronutrients
-- 2. Create indexes on food_log date for efficient querying
-- 3. Update nutrition_state table to aggregate micronutrients
--
-- Data Considerations:
-- - Existing food_logs have NULL micronutrient values
-- - Application code will populate these values going forward
-- - Old logs can be manually enriched via separate process
--
-- Performance:
-- - ALTER TABLE is fast (schema change only)
-- - Indexes are small and don't impact insert performance
-- - Application should handle NULL values gracefully
--
-- Rollback:
-- If this migration causes issues:
-- 1. Drop the new columns: ALTER TABLE food_logs DROP COLUMN ...;
-- 2. Remove from tracking: DELETE FROM schema_migrations WHERE version = 26;
-- 3. Deploy code that doesn't reference these columns
--
-- Related: Feature PR #456, Design Doc doc/nutrition-tracking.md
--
-- ============================================================================
```

**Documentation should answer:**
- What is changing and why?
- What data operations occur?
- How does this affect performance?
- How would you undo this if needed?
- What related code changes are required?

### 4. Test Before Deployment

Always test migrations locally before production.

```bash
# Create isolated test database
createdb meal_planner_test

# Copy production schema (optional but recommended)
pg_dump -s meal_planner | psql meal_planner_test

# Apply your migration
psql meal_planner_test -f gleam/migrations_pg/026_your_migration.sql

# Verify it worked
psql meal_planner_test -c "SELECT * FROM schema_migrations WHERE version = 26;"
psql meal_planner_test -c "DESC your_modified_table"

# Test application code with new schema
gleam test

# Cleanup
dropdb meal_planner_test
```

**Checklist:**
- [ ] Migration applies without errors
- [ ] Correct data appears in schema_migrations table
- [ ] All indexes were created successfully
- [ ] Application code still works with new schema
- [ ] Performance is acceptable (no table locks, etc.)

### 5. Consider Concurrent Users

Migrations should not disrupt active users.

```sql
-- GOOD: Non-blocking changes
-- Adding a column with a default is fast and doesn't lock
ALTER TABLE nutrition_state ADD COLUMN water_intake REAL DEFAULT 0.0;

-- RISKY: Blocking changes
-- Renaming a column can cause brief locks
ALTER TABLE nutrition_state RENAME COLUMN water TO water_intake;

-- RISKY: Time-consuming changes on large tables
-- Rebuilding a table holds exclusive locks
ALTER TABLE food_nutrients ALTER COLUMN amount TYPE NUMERIC;
```

**Considerations:**
- **Table locks**: Brief locks are OK if quick (< 1 second)
- **Column renames**: Generally safe but cause brief lock
- **Type changes**: May require table rewrite, avoid during peak hours
- **Index creation**: Use `CREATE INDEX CONCURRENTLY` when possible
- **Foreign keys**: Adding constraints needs validation, causes locks

### 6. Handle NULL Values Carefully

Plan for NULL values in existing data.

```sql
-- GOOD: Explicit DEFAULT or allow NULL
ALTER TABLE nutrition_state
ADD COLUMN water_intake REAL DEFAULT 0.0;  -- Old rows get 0.0

ALTER TABLE food_logs
ADD COLUMN recipe_source TEXT;  -- Old rows get NULL, which is fine

-- RISKY: NOT NULL without DEFAULT
ALTER TABLE nutrition_state
ADD COLUMN water_intake REAL NOT NULL;  -- Error! Where do old rows get value?

-- GOOD: Add nullable, update selectively, then add constraint
ALTER TABLE nutrition_state ADD COLUMN water_intake REAL;
UPDATE nutrition_state SET water_intake = 0.0 WHERE user_id IN (SELECT id FROM active_users);
ALTER TABLE nutrition_state ALTER COLUMN water_intake SET NOT NULL;
```

**Pattern:**
1. Add column as nullable
2. Populate with appropriate values
3. Add NOT NULL constraint if needed
4. Create indexes if querying by this column

### 7. Coordinate with Code Changes

Migrations and code changes must be synchronized.

```
Timeline:

1. Create migration file
   - Migration 026: Add water_intake column
   - File: gleam/migrations_pg/026_add_water_intake.sql

2. Update Gleam code
   - Update types to include water_intake field
   - Update queries to use the new column
   - File: gleam/src/meal_planner/models.gleam

3. Test together
   - Run migration on test database
   - Run tests with new schema
   - Verify application works end-to-end

4. Deploy as unit
   - Commit both migration and code changes
   - Deploy code and run migrations in same release
   - Never deploy migration without code expecting it
```

**Timing Issues:**

```
WRONG: Deploy code first, then migration later
- Code tries to use column that doesn't exist
- Application crashes

WRONG: Deploy migration first, then code later
- Database has unused columns
- Application hasn't been updated to use them

RIGHT: Deploy both together
- Code update and schema match
- Application starts correctly
```

### 8. Plan for Rollback

Every migration should be reversible (at least theoretically).

```sql
-- GOOD: Migration with rollback plan documented

-- Migration 026: Add water_intake tracking
-- ============================================================================
--
-- Forward:
--   ALTER TABLE nutrition_state ADD COLUMN water_intake REAL DEFAULT 0.0;
--
-- Rollback (if needed):
--   ALTER TABLE nutrition_state DROP COLUMN water_intake;
--   DELETE FROM schema_migrations WHERE version = 26;
--
-- Note: Rollback destroys water_intake data. Only do if absolutely necessary.
-- ============================================================================

BEGIN;
ALTER TABLE nutrition_state ADD COLUMN IF NOT EXISTS water_intake REAL DEFAULT 0.0;
COMMIT;
```

**Rollback Documentation Should Include:**
- Exact SQL to revert the change
- Data that will be lost (if any)
- Manual steps needed
- Testing steps to verify rollback worked

See [../ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) for detailed rollback procedures.

### 9. Monitor Performance Impact

Understand how migrations affect database performance.

```bash
# Before running large migration, disable auto-analyze
psql -U postgres -d meal_planner -c "ALTER SYSTEM SET autovacuum = false;"
psql -U postgres -d meal_planner -c "SELECT pg_reload_conf();"

# Run the migration
psql -U postgres -d meal_planner -f gleam/migrations_pg/026_large_migration.sql

# Manually analyze tables to update statistics
psql -U postgres -d meal_planner -c "ANALYZE food_nutrients; ANALYZE food_logs;"

# Re-enable auto-analyze
psql -U postgres -d meal_planner -c "ALTER SYSTEM SET autovacuum = true;"
psql -U postgres -d meal_planner -c "SELECT pg_reload_conf();"
```

**Considerations:**
- **Index creation**: Can be slow on millions of rows (monitor with `pg_stat_progress_create_index`)
- **Bulk updates**: Can cause locking and memory pressure
- **Table rewrites**: Very slow, avoid if possible
- **Statistics**: Update after bulk operations with `ANALYZE`

### 10. Use Transactions Properly

All migrations must be transactional.

```sql
-- GOOD: Atomic transaction
BEGIN;

-- Multiple related changes
ALTER TABLE food_logs ADD COLUMN source_type TEXT;
ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check
CHECK (source_type IN ('usda', 'custom', 'recipe'));
CREATE INDEX idx_food_logs_source ON food_logs(source_type);

-- All succeed or all fail as a unit
COMMIT;

-- BAD: Multiple transactions
psql -U postgres -d meal_planner -f migration1.sql;  -- Separate transaction
psql -U postgres -d meal_planner -f migration2.sql;  -- Separate transaction
-- If migration2 fails, migration1 was already applied!

-- BAD: No transaction
ALTER TABLE food_logs ADD COLUMN source_type TEXT;
UPDATE food_logs SET source_type = 'manual';
ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check ...;
-- If the constraint fails, column exists but updates might be incomplete
```

## Migration Patterns

### Pattern: Renaming a Column

```sql
-- ============================================================================
-- Migration: Rename recipe column to recipe_id
-- ============================================================================
--
-- Clarifies that column contains recipe ID, not full recipe object.
-- Safe operation - only changes metadata, not data.
--
-- ============================================================================

BEGIN;

-- Rename column
ALTER TABLE auto_meal_plans
RENAME COLUMN recipe TO recipe_id;

-- Rename index if it exists
ALTER INDEX IF EXISTS idx_auto_meal_plans_recipe
RENAME TO idx_auto_meal_plans_recipe_id;

-- Rename constraint if it exists
ALTER TABLE auto_meal_plans
RENAME CONSTRAINT fk_auto_meal_plans_recipe
TO fk_auto_meal_plans_recipe_id;

COMMIT;
```

### Pattern: Converting Data Type

```sql
-- ============================================================================
-- Migration: Convert food_log calories from INT to FLOAT
-- ============================================================================
--
-- Allows tracking fractional calories (e.g., 1234.5). Old integer values
-- are preserved exactly (100 becomes 100.0).
--
-- ============================================================================

BEGIN;

-- PostgreSQL can convert INT to FLOAT directly with USING
ALTER TABLE food_logs
ALTER COLUMN calories TYPE FLOAT USING calories::FLOAT;

-- Verify some data
-- SELECT id, calories FROM food_logs LIMIT 10;

COMMIT;
```

### Pattern: Adding a Check Constraint

```sql
-- ============================================================================
-- Migration: Add constraint that calories must be positive
-- ============================================================================
--
-- Ensures no negative or zero calorie values are entered.
-- Applied to future inserts/updates. Existing invalid data (if any) is not
-- automatically fixed - must be cleaned separately if needed.
--
-- ============================================================================

BEGIN;

-- Only add constraint if all existing data satisfies it
-- Check first:
-- SELECT COUNT(*) FROM food_logs WHERE calories <= 0;

ALTER TABLE food_logs
ADD CONSTRAINT food_logs_calories_positive
CHECK (calories > 0);

COMMIT;
```

### Pattern: Splitting Data into Separate Table

```sql
-- ============================================================================
-- Migration: Extract micronutrient data into separate table
-- ============================================================================
--
-- Normalizes schema by moving micronutrient data (vitamin A, C, etc.) from
-- food_logs into a new micronutrient_logs table with one row per nutrient.
-- This is more efficient for queries and supports arbitrary micronutrients.
--
-- ============================================================================

BEGIN;

-- Create new normalized table
CREATE TABLE IF NOT EXISTS micronutrient_logs (
    id SERIAL PRIMARY KEY,
    food_log_id INTEGER NOT NULL,
    nutrient_name TEXT NOT NULL,
    amount REAL NOT NULL,
    unit TEXT NOT NULL,
    FOREIGN KEY (food_log_id) REFERENCES food_logs(id) ON DELETE CASCADE,
    UNIQUE(food_log_id, nutrient_name)
);

-- Create index
CREATE INDEX idx_micronutrient_logs_food_log
ON micronutrient_logs(food_log_id);

-- Migration note: Data migration should happen in application code
-- to handle any NULL values or type conversions

COMMIT;
```

## Code Coordination

### Migration + Code Example

**Migration File: `026_add_water_intake.sql`**
```sql
-- ============================================================================
-- Migration: Add water intake tracking to nutrition_state
-- ============================================================================

BEGIN;
ALTER TABLE nutrition_state
ADD COLUMN IF NOT EXISTS water_intake_ml REAL DEFAULT 0.0;
COMMIT;
```

**Gleam Code: `storage.gleam`**
```gleam
pub type NutritionState {
  NutritionState(
    date: Date,
    protein: Float,
    fat: Float,
    carbs: Float,
    calories: Float,
    water_intake_ml: Float,  // NEW FIELD
    synced_at: DateTime,
  )
}

pub fn get_nutrition_state(db: Connection, date: Date) -> Result(NutritionState, Error) {
  let query = pog.query(
    "SELECT date, protein, fat, carbs, calories, water_intake_ml, synced_at
     FROM nutrition_state WHERE date = $1"
  )
  |> pog.parameter(pog.date(date))
  |> pog.returning(decode_nutrition_state)

  pog.execute(query, db)
  |> result.try(fn(pog.Returned(_, rows)) {
    case rows {
      [row] -> Ok(row)
      _ -> Error(NotFound)
    }
  })
}
```

**Git Commit:**
```bash
git add gleam/migrations_pg/026_add_water_intake.sql
git add gleam/src/meal_planner/storage.gleam
git commit -m "[meal-planner-XXX] Add water intake tracking

- Add water_intake_ml column to nutrition_state table
- Update NutritionState type to include water_intake_ml field
- Create index for efficient water queries
"
git push origin your-branch
```

## Testing Migrations

### Unit Test Example

```gleam
// In gleam/test/storage_test.gleam

import gleam/result
import meal_planner/storage

pub fn test_water_intake_column() {
  let db = setup_test_database()

  // Verify column exists and can be written
  case storage.update_nutrition_state(
    db,
    Date(2025, 12, 12),
    water_intake_ml: 2500.0,
  ) {
    Ok(_) -> Nil
    Error(e) -> {
      io.println("FAIL: Could not write water_intake_ml")
      io.println(string.inspect(e))
      panic
    }
  }

  // Verify we can read it back
  case storage.get_nutrition_state(db, Date(2025, 12, 12)) {
    Ok(state) -> {
      assert state.water_intake_ml == 2500.0
    }
    Error(e) -> {
      io.println("FAIL: Could not read water_intake_ml")
      panic
    }
  }
}
```

### Integration Test Example

```bash
#!/bin/bash
# test_migration_026.sh

set -e

# Create test database
createdb meal_planner_test

# Apply migrations up to 025
for i in {001..025}; do
  psql meal_planner_test -f gleam/migrations_pg/${i}*.sql 2>/dev/null || true
done

# Apply the new migration
psql meal_planner_test -f gleam/migrations_pg/026_add_water_intake.sql

# Verify it worked
RESULT=$(psql meal_planner_test -t -c "SELECT column_name FROM information_schema.columns WHERE table_name='nutrition_state' AND column_name='water_intake_ml';")

if [ -z "$RESULT" ]; then
  echo "FAIL: water_intake_ml column not found"
  dropdb meal_planner_test
  exit 1
fi

echo "PASS: Migration 026 applied successfully"

# Cleanup
dropdb meal_planner_test
```

## Security Considerations

### 1. Avoid SQL Injection

Always use parameterized queries, never string concatenation.

```sql
-- GOOD: Values are clearly separated from SQL
INSERT INTO nutrients (name, value) VALUES ('Protein', 100)
ON CONFLICT (name) DO NOTHING;

-- BAD: String interpolation (even for migrations, avoid it)
-- INSERT INTO nutrients (name, value) VALUES ('Protein', ' || value || ');
```

### 2. Validate Data During Migration

```sql
BEGIN;

-- Add constraint to validate existing data
ALTER TABLE food_logs
ADD CONSTRAINT food_logs_calories_valid
CHECK (calories > 0 AND calories < 10000);  -- Reasonable bounds

-- Remove invalid data before constraint
DELETE FROM food_logs
WHERE calories <= 0 OR calories >= 10000;

COMMIT;
```

### 3. Secure Password/Credential Fields

If migrations involve sensitive data:

```sql
-- GOOD: Never log sensitive data
INSERT INTO users (email, password_hash) VALUES ('user@example.com', crypt('password', gen_salt('bf')));

-- BAD: Exposing passwords in migration
INSERT INTO users (email, password) VALUES ('user@example.com', 'plaintext_password');
```

## Deployment Checklist

Before marking migration as complete:

- [ ] **Format**: Correct naming (NNN_description.sql)
- [ ] **Documentation**: Header explains purpose and implications
- [ ] **Idempotency**: Uses IF NOT EXISTS / ON CONFLICT
- [ ] **Transactions**: Wrapped in BEGIN/COMMIT
- [ ] **Testing**: Tested on local test database
- [ ] **Performance**: Understands impact on large tables
- [ ] **Code Coordination**: Gleam code updated to match
- [ ] **Rollback**: Documented how to reverse if needed
- [ ] **Data Integrity**: NULL handling, constraints checked
- [ ] **Index Creation**: After bulk data loads, not before
- [ ] **Git**: Committed with clear message mentioning issue ID

## Common Mistakes to Avoid

| Mistake | Problem | Solution |
|---------|---------|----------|
| No `IF NOT EXISTS` | Fails if migration already ran | Add `IF NOT EXISTS` to all DDL |
| Multiple transactions | Can't rollback atomically | Use single `BEGIN`/`COMMIT` |
| No NULL handling | Breaks with existing data | Set DEFAULT or UPDATE first |
| Index before insert | Slow import | Create indexes after bulk data |
| No documentation | Future confusion | Add detailed header comments |
| Separate code deploy | Code/schema mismatch | Deploy both together |
| Never test | Production surprises | Test on isolated database |
| Risky operations | Data loss | Always backup before risky ops |

## See Also

- [MIGRATION_PROCESS.md](./MIGRATION_PROCESS.md) - System architecture
- [RUNNING_MIGRATIONS.md](./RUNNING_MIGRATIONS.md) - Execution guide
- [MIGRATION_STRUCTURE.md](./MIGRATION_STRUCTURE.md) - Technical format
- [../ROLLBACK_PROCEDURE.md](../ROLLBACK_PROCEDURE.md) - Recovery procedures
- [../POSTGRES_SETUP.md](../POSTGRES_SETUP.md) - PostgreSQL configuration
