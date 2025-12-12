# Rollback Migrations (Migrations 019-023)

This directory contains SQL scripts to reverse the changes made by forward migrations 019-023. These rollback scripts are designed for emergency scenarios and should only be used when:

1. **Critical issues** are discovered in production
2. **Data corruption** occurs due to migration problems
3. **Performance degradation** is caused by new schema changes
4. **Mealie integration issues** require reverting to a previous state

## Rollback Migration Details

### 019: Restore recipes table
**Forward Migration:** `019_drop_recipes_table.sql`
**Rollback Script:** `019_restore_recipes_table.sql`

**What it does:**
- Recreates the `recipes` table with its original schema
- Restores all indexes on the table (name, cuisine, difficulty, calories, dietary_tags, verified)
- Does NOT restore historical data (must recover from backup if needed)

**When to use:**
- If local recipe management needs to be re-enabled
- When Mealie integration is temporarily unavailable

**Cautions:**
- Data loss: Historical records are not automatically restored
- Foreign keys: Any references to this table in other tables need careful verification

---

### 020: Restore recipes_simplified table
**Forward Migration:** `020_drop_recipes_simplified_table.sql`
**Rollback Script:** `020_restore_recipes_simplified_table.sql`

**What it does:**
- Recreates the simplified recipes schema
- Restores all indexes (protein, fat, category, verified, branded, tags)
- Does NOT restore historical data

**When to use:**
- If simplified recipe cache needs to be restored

---

### 021: Restore recipe_sources_audit infrastructure
**Forward Migration:** `021_drop_recipe_sources_audit.sql`
**Rollback Script:** `021_restore_recipe_sources_audit.sql`

**What it does:**
- Recreates the `recipe_sources_audit` table
- Restores all audit trigger functions:
  - `audit_recipe_sources_insert()`
  - `audit_recipe_sources_update()`
  - `audit_recipe_sources_delete()`
- Recreates all audit triggers
- Recreates the `recipe_sources_audit_changes` view

**When to use:**
- If audit logging for recipe sources needs to be re-enabled
- To restore audit trail functionality

---

### 022: Revert source_type constraint change
**Forward Migration:** `022_rename_recipe_to_mealie_recipe.sql`
**Rollback Script:** `022_rename_recipe_to_mealie_recipe.sql`

**What it does:**
- Changes `source_type` values from `'mealie_recipe'` back to `'recipe'`
- Drops the new constraint allowing only `'mealie_recipe'`
- Recreates the original constraint allowing `'recipe'`

**When to use:**
- If reverting to pre-Mealie integration state
- Before rolling back migrations 019-020

**Order Dependency:**
- Must be run BEFORE rolling back migrations 019-020
- The data type change must be reverted first

---

### 023: Remove recipe_json column
**Forward Migration:** `023_add_recipe_json_to_auto_meal_plans.sql`
**Rollback Script:** `023_add_recipe_json_to_auto_meal_plans.sql`

**What it does:**
- Drops the GIN index on `recipe_json`
- Removes the `recipe_json` JSONB column from `auto_meal_plans`

**When to use:**
- If denormalized recipe data is causing issues
- To free up storage space
- To revert to join-based recipe access

---

## Complete Rollback Sequence

To rollback ALL migrations 019-023, execute in this order:

```sql
-- Step 1: Revert source_type constraint first (data change)
BEGIN;
  -- Run: 022_rename_recipe_to_mealie_recipe.sql
COMMIT;

-- Step 2: Remove recipe_json column
BEGIN;
  -- Run: 023_add_recipe_json_to_auto_meal_plans.sql
COMMIT;

-- Step 3: Restore audit infrastructure
BEGIN;
  -- Run: 021_restore_recipe_sources_audit.sql
COMMIT;

-- Step 4: Restore simplified recipes
BEGIN;
  -- Run: 020_restore_recipes_simplified_table.sql
COMMIT;

-- Step 5: Restore original recipes table
BEGIN;
  -- Run: 019_restore_recipes_table.sql
COMMIT;
```

**Important:** Execute in this exact sequence to avoid foreign key violations and constraint errors.

---

## Partial Rollbacks

You can rollback individual migrations without reverting all of them:

### Just rollback 023 (keep 022, 021, 020, 019)
```bash
psql -d meal_planner_db < rollback/023_add_recipe_json_to_auto_meal_plans.sql
```

### Rollback 023 and 022 (keep 021, 020, 019)
```bash
psql -d meal_planner_db < rollback/023_add_recipe_json_to_auto_meal_plans.sql
psql -d meal_planner_db < rollback/022_rename_recipe_to_mealie_recipe.sql
```

---

## Data Recovery Considerations

All rollback scripts recreate schemas but NOT historical data. To recover data:

1. **Backup-based recovery (recommended):**
   - Restore from a backup taken before the migrations
   - Run the forward migrations on the restored data

2. **Partial recovery:**
   - Extract data from Mealie API before rollback
   - Re-import critical records after schema restoration

3. **Query logs:**
   - Check PostgreSQL query logs for INSERT/UPDATE statements
   - Manually reconstruct critical changes

---

## Safety Practices

1. **Always test on staging first** - Never rollback directly on production
2. **Notify team members** - Coordinate rollback with the team
3. **Document the reason** - Record why the rollback was necessary
4. **Backup before rollback** - Take a backup before executing rollbacks
5. **Monitor post-rollback** - Watch application logs for errors after rollback
6. **Verify data integrity** - Run consistency checks after rollback

---

## Troubleshooting

### Foreign Key Violations
**Problem:** "ERROR: update or delete on table "X" violates foreign key constraint"

**Solution:**
- Identify which tables reference the dropped table
- Manually clean up orphaned records before rolling back
- Or use `CASCADE` option in DROP statements (use with caution)

### Constraint Violations
**Problem:** "ERROR: duplicate key value violates unique constraint"

**Solution:**
- Check for duplicate values in unique columns
- The `IF NOT EXISTS` clauses should prevent most issues
- Verify data consistency before rollback

### Missing Indexes
**Problem:** "ERROR: relation 'idx_X_Y' already exists"

**Solution:**
- The `IF NOT EXISTS` clauses should prevent this
- Manually drop conflicting indexes if needed
- Check for partial index definitions

---

## Related Files

- `/gleam/migrations_pg/` - Forward migrations
- `/gleam/migrations_pg/rollback/` - All rollback scripts
- `/gleam/test/rollback_test.gleam` - Rollback test suite

---

## Contact & Support

For questions about rollback procedures or data recovery:
- Review the forward migration comments
- Check the application logs for migration status
- Consult with the database team
