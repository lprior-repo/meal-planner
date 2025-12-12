# Recipe Sources Table: Keep or Remove?

## Executive Summary

**RECOMMENDATION: REMOVE** the `recipe_sources` table from the meal planner codebase.

The table was designed to track multiple recipe sources (API integrations, scrapers, manual entries) but is **completely unused** in the current architecture. Removing it will:
1. Reduce database complexity (eliminate 1 table, 2 indexes, 1 view, 3 trigger functions)
2. Simplify the schema and migrations
3. Eliminate technical debt from an unused data structure
4. Allow cleaner Tandoor recipe integration

**Timeline**: Remove in next database migration (after Tandoor migration completes)

---

## Detailed Analysis

### What Is recipe_sources?

The `recipe_sources` table was created in migration 009 to track recipe data sources:

```sql
CREATE TABLE IF NOT EXISTS recipe_sources (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('api', 'scraper', 'manual')),
    config JSONB,
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Original Purpose**:
- Store configurations for multiple recipe sources (APIs, web scrapers, user-provided recipes)
- Allow enabling/disabling recipe sources
- Manage source-specific configuration (API keys, endpoints, etc.)

### Current Usage Analysis

#### 1. Database Components

| Component | File | Status |
|-----------|------|--------|
| Table | `gleam/migrations_pg/009_auto_meal_planner.sql` | EXISTS |
| Audit Trigger Functions | `gleam/migrations_pg/014_add_recipe_sources_audit.sql` | EXISTS |
| Audit Logging | `gleam/migrations_pg/021_drop_recipe_sources_audit.sql` | **DROPPED in 021** |
| Related Type | `gleam/src/meal_planner/auto_planner/types.gleam` | EXISTS |
| Storage Functions | `gleam/src/meal_planner/auto_planner/storage.gleam` | EXISTS |
| NCP Storage Functions | `gleam/src/meal_planner/auto_planner/ncp_auto_planner/storage.gleam` | EXISTS |

#### 2. Gleam Code References

The table has two storage functions defined:
- `save_recipe_source/2` - Insert or update a recipe source
- `get_recipe_sources/1` - Retrieve all recipe sources

However, **neither function is called anywhere in the codebase**:
```bash
grep -r "storage\.save_recipe_source\|storage\.get_recipe_sources" *.gleam
# Returns: (no results - functions are never invoked)
```

The `RecipeSource` type exists in `auto_planner/types.gleam` but has no callers.

#### 3. Recent Migration History

- **Migration 009**: Created `recipe_sources` table with all components
- **Migration 014**: Added audit logging for `recipe_sources_audit` table
- **Migration 021**: **Dropped** the audit logging infrastructure (triggers, functions, views)

**Key Observation**: Migration 021 already dropped most of the `recipe_sources` audit infrastructure, suggesting a move toward **removal**.

#### 4. Current Architecture

The actual recipe data storage now uses:
- **Tandoor Integration** (replacing Mealie): Recipes stored directly in Tandoor database
- **Auto Meal Plans**: Stores recipes as JSON in `auto_meal_plans.recipe_json` field
- **Food Logs**: References recipes by ID with source type (`tandoor_recipe`)

Recipe sources are **not consulted** when:
- Generating auto meal plans
- Logging food entries
- Filtering recipes by macros
- Creating meal plans

### Why Was recipe_sources Abandoned?

1. **Architectural Shift**: Initial design assumed multiple recipe sources, but system evolved to single-source (Tandoor)
2. **JSON Storage**: Recipes now stored directly as JSON in `auto_meal_plans.recipe_json`, eliminating need for source configuration
3. **Single Integration**: Tandoor serves as the exclusive recipe source; no multi-source support needed
4. **Audit Removal**: Migration 021 already removed audit infrastructure, indicating the team recognized unused complexity

---

## Decision Framework

### Keep If:
- Multi-source recipe integration were planned in future
- Different food sources required different configuration management
- Cross-source recipe deduplication was needed
- Source-level access control was required

**None of these apply to current or planned architecture.**

### Remove If:
- Table is completely unused ✓ **YES**
- No current code references it ✓ **YES**
- Database audit/tracking infrastructure is already gone ✓ **YES**
- Removing simplifies schema ✓ **YES**
- No planned features depend on it ✓ **YES**

---

## Impact Assessment

### What Gets Removed

1. **Database Table**
   - `recipe_sources` table itself
   - 2 indexes: `idx_recipe_sources_type`, `idx_recipe_sources_enabled`
   - 1 GIN index: `idx_recipe_sources_config`
   - 1 trigger: `update_recipe_sources_timestamp`
   - 1 trigger function: `update_updated_at_column()` (shared with other tables, keep this)

2. **Gleam Code**
   - `RecipeSource` type in `auto_planner/types.gleam`
   - `RecipeSourceType` enum (`Database`, `Api`, `UserProvided`)
   - `recipe_source_type_to_string/1` function
   - `recipe_source_to_json/1` function
   - `save_recipe_source/2` in storage modules
   - `get_recipe_sources/1` in storage modules
   - Storage helper: `format_pog_error/1` (keep, shared with other functions)

3. **Documentation**
   - Remove from `docs/POSTGRES_SETUP.md`
   - Remove from migration guides
   - Remove from schema diagrams

### What Stays

- `auto_meal_plans` table (unchanged - recipes stored as JSON)
- `food_logs.source_type` field (used for Tandoor recipe references)
- All Tandoor integration code

### Affected Files

| File | Type | Action |
|------|------|--------|
| `gleam/migrations_pg/009_auto_meal_planner.sql` | Migration | Remove recipe_sources creation |
| `gleam/migrations_pg/026_remove_recipe_sources.sql` | Migration | **CREATE NEW** - drop table |
| `gleam/src/meal_planner/auto_planner/types.gleam` | Code | Remove RecipeSource, RecipeSourceType |
| `gleam/src/meal_planner/auto_planner/storage.gleam` | Code | Remove storage functions |
| `gleam/src/meal_planner/auto_planner/ncp_auto_planner/storage.gleam` | Code | Remove storage functions |
| `docs/POSTGRES_SETUP.md` | Docs | Remove from table list |
| `MIGRATION_STATUS.md` | Docs | Update status |

**Total Risk**: Low - removing dead code with zero impact on running system

---

## Implementation Plan

### Phase 1: Create Removal Migration (1 task)
- **Task**: Create `gleam/migrations_pg/026_remove_recipe_sources.sql`
- **SQL**:
  ```sql
  -- Migration 026: Remove recipe_sources table
  -- This table was designed for multi-source recipe tracking but
  -- was never used. Current architecture uses Tandoor as single source.

  -- Drop trigger first (depends on table)
  DROP TRIGGER IF EXISTS update_recipe_sources_timestamp ON recipe_sources;

  -- Drop function (shared utility, keep with other uses)
  -- Note: update_updated_at_column() stays - used by other tables

  -- Drop indexes
  DROP INDEX IF EXISTS idx_recipe_sources_config;
  DROP INDEX IF EXISTS idx_recipe_sources_enabled;
  DROP INDEX IF EXISTS idx_recipe_sources_type;

  -- Drop table
  DROP TABLE IF EXISTS recipe_sources CASCADE;
  ```

### Phase 2: Remove Code (3 tasks)
1. **Remove from `auto_planner/types.gleam`**
   - Remove `RecipeSourceType` enum
   - Remove `RecipeSource` type
   - Remove `recipe_source_type_to_string/1`
   - Remove `recipe_source_to_json/1`

2. **Remove from `auto_planner/storage.gleam`**
   - Remove `save_recipe_source/2`
   - Remove `get_recipe_sources/1`

3. **Remove from `ncp_auto_planner/storage.gleam`**
   - Remove `save_recipe_source/2`
   - Remove `get_recipe_sources/1`

### Phase 3: Update Documentation (1 task)
- Update `docs/POSTGRES_SETUP.md` - remove recipe_sources table reference
- Update `MIGRATION_STATUS.md` - note removal completion

### Phase 4: Testing (1 task)
- Run migration on test database
- Verify table is gone
- Verify no compilation errors in Gleam code
- Run test suite: `gleam test`

**Total Effort**: 6 tasks, minimal risk, immediate technical debt reduction

---

## Benefits of Removal

### Code Quality
- **Removes dead code**: 30+ lines of unused storage functions
- **Simplifies types**: Eliminates 1 enum + 1 struct from auto_planner module
- **Reduces complexity**: One fewer table to maintain

### Database
- **Simpler schema**: Fewer tables = easier to understand
- **Faster migrations**: Fewer objects to manage in migration files
- **Cleaner audit trail**: No confusion about why code references this table

### Maintenance
- **Reduced cognitive load**: Developers won't wonder what recipe_sources is for
- **Clearer intent**: Code only contains what's actually used
- **Better for new contributors**: Smaller, focused schema

### Performance
- **Minimal impact**: No queries use this table, so no performance gain
- **Saves storage**: One fewer table index to maintain

---

## Risk Analysis

### Low Risk Because:
1. **No active usage**: Zero calls to storage functions from anywhere
2. **No dependencies**: No foreign keys reference this table
3. **No API endpoints**: No web routes expose this functionality
4. **No tests**: No tests depend on it (all tests for this module are broken anyway)
5. **Already deprecated**: Audit infrastructure was already removed in migration 021
6. **Easy rollback**: Migration 021 was reversed; migration 026 can be easily reversed too

### Rollback Plan
If needed:
1. Run migration `gleam/migrations_pg/rollback/026_restore_recipe_sources.sql`
2. Restore `RecipeSource` type and storage functions from git history
3. Re-add imports to any code that needs them

---

## Timeline & Dependencies

### Dependencies
- **Before removing**: Must complete Tandoor migration (currently in progress)
- **No blocking**: This removal doesn't block any other work

### Recommended Timing
- **When**: After Tandoor migration is deployed and verified
- **Why**: Cleaner to remove as part of post-Tandoor cleanup
- **How long**: 2 hours total (mostly migration file creation + testing)

---

## Conclusion

The `recipe_sources` table represents **architectural debt** from an earlier multi-source recipe design that was never implemented. The system has evolved to use Tandoor as the exclusive recipe source, with recipes stored as JSON within meal plans.

**Recommendation**: **REMOVE** the table via a new migration after Tandoor migration completes. This will:
- Reduce schema complexity
- Eliminate dead code
- Clarify system intent
- Improve maintainability

**Next Steps**:
1. Get approval on this recommendation
2. Create migration 026 to drop the table
3. Remove storage functions and types from Gleam code
4. Update documentation
5. Deploy as part of post-Tandoor cleanup
