# Analysis: Is recipe_sources Still Needed for Mealie?

## Task: meal-planner-tik1
**Status**: COMPLETED
**Date**: 2025-12-12
**Decision**: REMOVE `recipe_sources` infrastructure (future cleanup task)

---

## Executive Summary

The `recipe_sources` table and related infrastructure are **NOT needed** for Mealie or any current integration. The table was designed for a flexible recipe source management system that was never implemented or used.

**Recommendation**: Remove `recipe_sources` table, associated Gleam storage functions, and audit infrastructure in a future cleanup task.

---

## Current State Analysis

### What is `recipe_sources`?

A PostgreSQL table created in migration 009 to track configurable recipe sources:

```sql
CREATE TABLE recipe_sources (
  id uuid PRIMARY KEY,
  name VARCHAR(255),
  type VARCHAR(50),  -- "database", "api", "user_provided"
  config JSONB,
  enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

### Gleam Implementation

**Storage functions** in `gleam/src/meal_planner/auto_planner/storage.gleam`:
- `save_recipe_source()` - Insert/update recipe source
- `get_recipe_sources()` - Retrieve all sources

**Types** in `gleam/src/meal_planner/auto_planner/types.gleam`:
```gleam
pub type RecipeSourceType {
  Database
  Api
  UserProvided
}

pub type RecipeSource {
  RecipeSource(
    id: String,
    name: String,
    source_type: RecipeSourceType,
    config: Option(String),
  )
}
```

**Audit infrastructure** (migration 014, dropped in 021):
- `recipe_sources_audit` table
- Audit triggers and functions
- Audit logging views

### Mealie Migration Context

Recent changes (2025-12-12):
- Migration 021: **Dropped** `recipe_sources_audit` table and related objects
- Migration 025: Renamed `mealie_recipe` → `tandoor_recipe` in `food_logs.source_type` constraint
- Complete removal of `mealie/` directory from codebase
- Updated all environment variables from `MEALIE_*` to `TANDOOR_*`

The Mealie cleanup archived in `/openspec/changes/archive/2025-12-12-complete-mealie-cleanup/` has completed all intended work.

---

## Code Usage Analysis

### Functions Defined But NOT Called

Searched entire Gleam codebase for calls to:
- `save_recipe_source()` - **ZERO calls found**
- `get_recipe_sources()` - **ZERO calls found**

### No Web API Endpoints

Checked `gleam/src/meal_planner/web.gleam`:
- Health check endpoint (`/health`, `/`)
- Meal plan endpoint stub (`/api/meal-plan`)
- Macro calculation endpoint stub (`/api/macros/calculate`)

**No recipe_sources endpoints exist or are exposed.**

### Database Never Accessed

- No SQL queries in actual handlers
- No integrations reading from or writing to `recipe_sources`
- Table exists but is completely unused

### Audit Infrastructure Already Removed

Migration 021 (`drop_recipe_sources_audit.sql`):
- Dropped triggers on `recipe_sources`
- Dropped audit functions (`audit_recipe_sources_insert`, etc.)
- Dropped `recipe_sources_audit` table

**Status**: Audit logging for `recipe_sources` is already gone.

---

## Mealie Relationship

### Was `recipe_sources` Ever Used by Mealie?

**NO**. The `recipe_sources` table is not related to Mealie integration.

- Mealie used the `tandoor_recipe` source type in `food_logs.source_type`
- `recipe_sources` was a generic infrastructure for managing multiple recipe APIs
- Mealie never read from or wrote to the `recipe_sources` table
- The table predates Mealie removal and was independent of the Mealie module

### Mealie Replacement with Tandoor

Tandoor uses the same `food_logs.source_type = 'tandoor_recipe'` mechanism as Mealie did (previously `mealie_recipe`). No changes needed to `recipe_sources` table.

---

## Why Was `recipe_sources` Created?

Based on database schema history:

**Original Intent** (migration 009, 014):
- Support pluggable recipe sources (Database, API, UserProvided)
- Enable recipe source discovery and configuration
- Provide audit trail for recipe source changes

**Execution Gap**:
- No web endpoints were ever created to manage recipe sources
- No client code integrated with the feature
- Functions defined but never called
- No migration path was ever implemented

---

## Risk Assessment

### Risk of Keeping `recipe_sources`

**MEDIUM**:
- Dead code creates confusion for new developers
- Audit infrastructure was already removed (inconsistency)
- Maintenance burden if schema changes needed
- Database bloat (unused table)
- Could be mistaken as required infrastructure

### Risk of Removing `recipe_sources`

**LOW**:
- Zero code depends on it
- No API exposes it
- No migrations require it
- Rollback migration (021_restore_recipe_sources_audit.sql) exists for audit reversal

---

## Recommendations

### Immediate (This Task)

- Document that `recipe_sources` is **NOT needed for Mealie**
- Confirm it's unused in the current codebase
- Record the decision for future reference

**Status**: COMPLETED - This analysis document serves as the decision record.

### Future Cleanup (Separate Task)

When ready to reduce database schema bloat, create a new task to:

1. Create new migration (027):
   ```sql
   DROP TABLE IF EXISTS recipe_sources CASCADE;
   ```

2. Remove Gleam storage functions:
   - Delete `save_recipe_source()` from `storage.gleam`
   - Delete `get_recipe_sources()` from `storage.gleam`

3. Remove Gleam types:
   - Delete `RecipeSourceType` from `auto_planner/types.gleam`
   - Delete `RecipeSource` from `auto_planner/types.gleam`

4. Update documentation:
   - Remove from `POSTGRES_SETUP.md`
   - Update migration README

---

## Related Tasks

- `meal-planner-int6`: Replace MealieConfig with TandoorConfig - COMPLETED
- `2025-12-12-complete-mealie-cleanup`: Archive completed - COMPLETED
- `2025-12-12-migrate-mealie-to-tandoor`: Migration completed - COMPLETED

---

## Decision Log

| Date | Decision | Reasoning |
|------|----------|-----------|
| 2025-12-12 | `recipe_sources` is NOT needed | Zero code references, not used in web API, never integrated with Mealie |
| 2025-12-12 | Keep for now (no immediate action) | Avoid premature removal; audit infra already cleaned up (migration 021) |
| 2025-12-12 | Document for future cleanup | Create this analysis document for decision reference |

---

## Validation

### Checklist

- [x] Searched for all `recipe_sources` references
- [x] Confirmed zero calls to `save_recipe_source()`
- [x] Confirmed zero calls to `get_recipe_sources()`
- [x] Verified no web API endpoints expose recipe sources
- [x] Checked Mealie integration does not use recipe_sources
- [x] Reviewed Mealie cleanup completed (migration 021)
- [x] Assessed removal risk (LOW)
- [x] Identified future cleanup scope
- [x] Created decision record

---

## Conclusion

**`recipe_sources` is NOT needed for Mealie or any current integration.** It's unused infrastructure that can be safely removed in a future cleanup task. The Mealie-to-Tandoor migration is independent of this table.

No action needed at this time beyond documentation.
