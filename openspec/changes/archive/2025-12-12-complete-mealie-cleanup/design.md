# Design: Complete Mealie Cleanup

## Context
The codebase has been partially migrated from Mealie to Tandoor - the Docker container and source files (gleam/src/meal_planner/mealie/*) have been removed, but extensive references remain throughout:
- Type imports and constructors (MealieRecipe, MealieIngredient, etc.)
- Database schema uses `mealie_recipe` source_type
- Configuration types named `MealieConfig`
- Environment variables `MEALIE_BASE_URL` and `MEALIE_API_TOKEN`
- 20+ documentation files with Mealie examples
- Test fixtures and assertions

This creates a broken build state and confusing codebase.

## Goals
- Remove ALL Mealie references from the codebase
- Replace with Tandoor equivalents where appropriate
- Ensure builds succeed without Mealie modules
- Update database schema to use `tandoor_recipe`
- Provide clear migration path for existing data

## Non-Goals
- Implementing new Tandoor features (separate change)
- Data migration execution (covered in `migrate-mealie-to-tandoor`)
- Performance optimization

## Decisions

### Decision 1: Database Source Type Rename
**What**: Rename `mealie_recipe` to `tandoor_recipe` in food_logs.source_type constraint

**Why**:
- Consistency with new Tandoor integration
- Prevents confusion about data source
- Aligns with existing `tandoor_recipe` type in Tandoor client

**Alternatives considered**:
- Keep `mealie_recipe` as generic "external recipe" → Rejected: Misleading after Mealie removal
- Use `recipe` → Rejected: Too generic, loses provenance information

**Migration approach**:
```sql
UPDATE food_logs SET source_type = 'tandoor_recipe' WHERE source_type = 'mealie_recipe';
ALTER TABLE food_logs DROP CONSTRAINT food_logs_source_type_check;
ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check
  CHECK (source_type IN ('tandoor_recipe', 'custom_food', 'usda_food'));
```

### Decision 2: Configuration Type Rename
**What**: Rename `web.MealieConfig` to `web.TandoorConfig`

**Why**:
- Type name should match the service it configures
- Prevents confusion in code reviews and debugging
- Gleam type system makes this a compile-time safe change

**Implementation**:
```gleam
pub type TandoorConfig {
  TandoorConfig(url: String, token: String)
}

pub type ServerConfig {
  ServerConfig(port: Int, database: DatabaseConfig, tandoor: TandoorConfig)
}
```

### Decision 3: Example Code Strategy
**What**: Completely rewrite example files for Tandoor API

**Why**:
- Examples must demonstrate current working code
- Partial updates would leave broken imports
- Tandoor API differs significantly from Mealie

**Alternatives considered**:
- Delete examples → Rejected: Valuable for users learning the API
- Keep as "legacy" → Rejected: Confusing and unmaintainable

**Approach**:
1. Wait for Tandoor client implementation
2. Rewrite examples using Tandoor types (TandoorRecipe, TandoorIngredient)
3. Update API endpoints and authentication
4. Add error handling specific to Tandoor

### Decision 4: Documentation Cleanup
**What**: Delete Mealie-specific docs, update shared docs

**Files to delete**:
- `docs/MEALIE_*.md` (5 files)
- `MEALIE_*.md` (root, 3 files)
- `mealie.env.example`

**Files to update**:
- `docs/MEAL_PLAN_GENERATION_TESTS.md` → Generic recipe testing guide
- `docs/PERFORMANCE_BENCHMARKS.md` → Update "Mealie database" to "Tandoor database"
- `FOOD_LOG_API_UPDATE.md` → Replace `save_food_log_from_mealie_recipe` with `save_food_log_from_tandoor_recipe`

### Decision 5: Test Fixtures Update
**What**: Update test fixtures to use `tandoor_recipe` source type

**Why**:
- Tests must validate current schema
- Prevents false positives from obsolete constraints
- Documents expected behavior for new developers

**Approach**:
```gleam
// Before
let valid_types = ["mealie_recipe", "custom_food", "usda_food"]

// After
let valid_types = ["tandoor_recipe", "custom_food", "usda_food"]
```

## Risks / Trade-offs

### Risk 1: Breaking Existing Data
**Risk**: Production databases may have `mealie_recipe` entries

**Mitigation**:
- Migration 025 automatically renames data
- Rollback migration provided
- Test on staging before production

### Risk 2: Incomplete Tandoor Implementation
**Risk**: Removing Mealie before Tandoor is fully ready

**Mitigation**:
- This cleanup is separate from Tandoor implementation
- Code will compile without Mealie imports
- Examples can be rewritten once Tandoor client exists

### Risk 3: Documentation Gaps
**Risk**: Deleting docs before Tandoor docs are written

**Mitigation**:
- Generic docs (MEAL_PLAN_GENERATION_TESTS) remain
- Tandoor-specific docs will be added in `migrate-mealie-to-tandoor` change
- README and CLAUDE.md already updated

## Migration Plan

### Phase 1: Code Cleanup (This Change)
1. Remove all Mealie imports
2. Rename MealieConfig → TandoorConfig
3. Update environment variable names
4. Update comments and documentation
5. Delete Mealie-specific docs

### Phase 2: Database Migration
1. Create migration 025
2. Test on staging database
3. Update constraints
4. Verify data integrity

### Phase 3: Example Rewrite (Blocked on Tandoor Client)
1. Wait for `tandoor/client.gleam` implementation
2. Rewrite `create_recipe_example.gleam`
3. Rewrite `bulk_create_recipes.gleam`
4. Test examples against live Tandoor instance

### Phase 4: Validation
1. Run full test suite
2. Verify no "mealie" references in codebase
3. Test builds succeed
4. Deploy to staging

## Open Questions
None - all decisions made with clear rationale.
