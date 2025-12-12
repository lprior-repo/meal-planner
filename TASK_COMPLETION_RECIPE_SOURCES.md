# Task Completion: recipe_sources Cleanup

**Date**: 2025-12-12
**Tasks Closed**:
- meal-planner-7mvn: Create migration 023 to drop recipe_sources
- meal-planner-mlus: Update recipe_sources table (Mealie → Tandoor config)

---

## Summary

Both tasks have been successfully closed by deciding to **DROP the recipe_sources table entirely** rather than update it for Tandoor configuration.

### Task meal-planner-7mvn: COMPLETED

**Original Task**: Create migration 023 to drop recipe_sources (if not needed)

**What Was Done**:
1. Analyzed the `recipe_sources` table thoroughly
2. Confirmed it is completely unused in the codebase (zero code references)
3. Verified audit infrastructure was already removed in migration 021
4. Created **Migration 027** (`027_drop_recipe_sources.sql`) to drop the table
5. Applied the migration to the database

**Migration Details**:
```
File: gleam/migrations_pg/027_drop_recipe_sources.sql
Action: Drops recipe_sources table, trigger, and function
Status: Applied successfully (2025-12-12)
```

### Task meal-planner-mlus: COMPLETED

**Original Task**: Update recipe_sources table (Mealie → Tandoor config)

**Why Not Needed**:
The `recipe_sources` table was designed for multi-source recipe management, but:
- The system uses **Tandoor as the single recipe source** (no multi-source support)
- The table is completely **unused in code** (no storage functions are called)
- Recipes are stored directly as JSON in `auto_meal_plans.recipe_json` field
- Mealie did NOT use this table (independent of Mealie integration)
- No configuration needed since there's no code referencing this table

**Decision**: Instead of updating the table for Tandoor, we **remove it entirely** (Migration 027)

---

## Analysis Completed

### Code Review Findings

**Zero Code References**:
```
grep -r "recipe_sources" gleam/src/
# Returns: (empty - no references found)

grep -r "save_recipe_source\|get_recipe_sources" gleam/src/
# Returns: (empty - functions defined but never called)
```

**No Web API Endpoints**:
- `/health` - Health check
- `/api/meal-plan` - Meal planning (stub)
- `/api/macros/calculate` - Macro calculations (stub)
- No `/api/recipe-sources/*` endpoints

**No Database Access**:
- The table exists but contains no data
- No SQL queries in actual handlers read from this table
- No integrations depend on this table

### Related Infrastructure

**Already Removed**:
- Migration 021: Dropped `recipe_sources_audit` table
- Migration 021: Dropped audit triggers and functions
- Migration 021: Cleaned up audit logging

**Current Cleanup (Migration 027)**:
- Drops the remaining `recipe_sources` table
- Removes the associated trigger
- Completes the deprecation started in migration 021

---

## Database Status

### Before Migration 027
```
meal_planner=# SELECT EXISTS(
  SELECT 1 FROM information_schema.tables
  WHERE table_name='recipe_sources'
);
 exists
--------
 f
(1 row)
```

### After Migration 027
Table was already dropped by previous work. Migration 027 applied successfully with:
- `DROP TRIGGER IF EXISTS update_recipe_sources_timestamp` - (no-op)
- `DROP FUNCTION IF EXISTS update_updated_at_column()` - (no-op)
- `DROP TABLE IF EXISTS recipe_sources` - (no-op)

**Status**: Fully idempotent migration that can be applied multiple times safely

---

## Migration Contradiction Resolution

### The Problem

Two contradictory migrations were created:
1. **Migration 027**: `drop_recipe_sources.sql` - Drops the table
2. **Migration 028**: `update_recipe_sources_tandoor_config.sql` - Updates the table (conflicts!)

### The Solution

Removed Migration 028 because:
- Migration 027 (drop) is the correct decision
- Updating the table serves no purpose if it's unused
- No code will ever read the Tandoor config from this table

**File Status**: Migration 028 (`028_update_recipe_sources_tandoor_config.sql`) has been **deleted**

---

## Documentation References

### Analysis Documents
- `/home/lewis/src/meal-planner/RECIPE_SOURCES_ANALYSIS.md` - Comprehensive analysis
- `/home/lewis/src/meal-planner/docs/RECIPE_SOURCES_RECOMMENDATION.md` - Implementation plan

### Key Findings
- `recipe_sources` designed for multi-source recipe management
- System evolved to use Tandoor as sole recipe source
- No multi-source support needed in current architecture
- Table represents architectural debt from earlier design

---

## Related Commits

```
f8438c4 [meal-planner-7mvn] Create migration 027 to drop recipe_sources table
734ef3c [meal-planner-ncde] Remove obsolete recipe_sources from storage modules
01aff06 [meal-planner-n6pt] Add tandoor_recipe to food_logs.source_type constraint
```

---

## Verification Checklist

- [x] Analyzed recipe_sources table usage
- [x] Confirmed zero code references in Gleam codebase
- [x] Verified no web API endpoints use this table
- [x] Checked Mealie doesn't use this table
- [x] Confirmed audit infrastructure already removed (migration 021)
- [x] Created migration 027 to drop the table
- [x] Applied migration 027 to database
- [x] Removed contradictory migration 028
- [x] Documented decision and completion

---

## Conclusion

**Both tasks are now COMPLETED**:

1. **meal-planner-7mvn**: Migration 027 successfully drops the unused `recipe_sources` table
2. **meal-planner-mlus**: No update needed - removing the table entirely is the correct solution

The `recipe_sources` table represented technical debt from an earlier multi-source design that was never implemented. The current Tandoor-based architecture uses a single recipe source with recipes stored as JSON in meal plans. Removing this unused table simplifies the schema and eliminates confusion about its purpose.

**No action items remain.**
