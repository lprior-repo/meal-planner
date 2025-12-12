# Design: Mealie to Tandoor Migration

## Context
Mealie has reliability issues and poor API performance. Tandoor is a proven alternative with:
- More stable API (v1.5+ well-documented)
- Better performance (faster recipe retrieval)
- Active maintenance and community
- Feature parity for our use case (recipes, ingredients, nutrition)

**Urgency**: Production issues with Mealie require immediate migration.

## Goals
- Zero data loss during migration
- Minimal downtime (< 1 hour for data migration)
- Maintain all existing features (auto planner, food logging, recipe scoring)
- Clean removal of Mealie code

## Non-Goals
- Supporting both Mealie and Tandoor simultaneously (clean swap, no feature flag)
- Bidirectional sync (Tandoor is single source of truth)
- Preserving Mealie-specific features we don't use

## Decisions

### Decision 1: API Client Architecture
**Choice**: Mirror current Mealie client structure for Tandoor

**Rationale**:
- Minimizes refactoring in calling code
- Proven patterns (retry, fallback, connectivity checks)
- Similar API shapes (REST, JSON, pagination)

**Modules to create**:
```
tandoor/client.gleam      # HTTP client, API calls
tandoor/types.gleam       # TandoorRecipe, TandoorIngredient, etc.
tandoor/mapper.gleam      # tandoor_to_recipe conversion
tandoor/fallback.gleam    # Graceful degradation
tandoor/retry.gleam       # Exponential backoff
tandoor/connectivity.gleam # Health checks
tandoor/sync.gleam        # Data sync utilities
```

### Decision 2: Data Migration Strategy
**Choice**: One-time batch migration script + live cutover

**Approach**:
1. **Pre-migration**: Run Tandoor alongside Mealie (both systems live)
2. **Bulk transfer**: Script to copy all recipes from Mealie → Tandoor
3. **Database migration**: Update `food_logs.source_type` and `recipe_json` fields
4. **Cutover**: Deploy new code pointing to Tandoor
5. **Cleanup**: Remove Mealie container and code

**Migration script**: `gleam/src/scripts/migrate_mealie_to_tandoor.gleam`
- Fetch all recipes from Mealie API
- Transform to Tandoor format
- POST to Tandoor API
- Log mapping (Mealie slug → Tandoor ID)
- Update database references

### Decision 3: Database Schema Changes
**Choice**: Rename source type and update JSON format in single migration

**Migration 025**:
```sql
-- Update source_type constraint
ALTER TABLE food_logs DROP CONSTRAINT food_logs_source_type_check;
UPDATE food_logs SET source_type = 'tandoor_recipe' WHERE source_type = 'mealie_recipe';
ALTER TABLE food_logs ADD CONSTRAINT food_logs_source_type_check
  CHECK (source_type IN ('tandoor_recipe', 'custom_food', 'usda_food'));

-- Update recipe_json format (convert Mealie JSON → Tandoor JSON)
-- This may require application-level migration for complex transformations
```

**Trade-off**: Application-level migration safer for JSON transformation than SQL

### Decision 4: Recipe ID Mapping
**Choice**: Store mapping table during migration, use for reference updates

**Approach**:
```gleam
// Temporary mapping for migration
type RecipeMapping {
  RecipeMapping(
    mealie_slug: String,
    tandoor_id: Int,
    migrated_at: Time,
  )
}
```

Store in `recipe_migration_log` table for audit trail and rollback capability.

### Decision 5: API Differences Handling
**Key differences** (Tandoor vs Mealie):

| Feature | Mealie | Tandoor | Handling |
|---------|--------|---------|----------|
| Recipe ID | slug (string) | id (integer) | Map in conversion |
| Ingredients | nested objects | simpler structure | Transform in mapper |
| Nutrition | optional strings | structured data | Prefer Tandoor format |
| Pagination | query params | cursor-based | Update client logic |
| Auth | Bearer token | Token header | Similar, easy swap |

**Mapper changes**:
- `mealie_to_recipe` → `tandoor_to_recipe`
- Handle different JSON schemas
- Preserve macro calculations (same output type)

### Decision 6: Configuration Management
**Choice**: Environment variables for Tandoor connection

```bash
# New (add to .env)
TANDOOR_BASE_URL=http://localhost:8000
TANDOOR_API_TOKEN=your-tandoor-token

# Deprecated (remove after migration)
MEALIE_BASE_URL=http://localhost:9000
MEALIE_API_TOKEN=your-mealie-token
```

Update `config.gleam` to read Tandoor vars, validate presence.

## Risks & Trade-offs

### Risk 1: Data Loss During Migration
**Mitigation**:
- Dry-run mode for migration script (test without writing)
- Database backup before migration
- Keep Mealie running until verified successful
- Recipe mapping log for audit trail

### Risk 2: API Incompatibilities
**Mitigation**:
- Comprehensive API testing before cutover
- Fallback plan (revert to Mealie if critical issues)
- Feature parity check (ensure Tandoor supports all needed endpoints)

### Risk 3: Downtime During Migration
**Mitigation**:
- Run migration during low-traffic window
- Pre-warm Tandoor with recipe data
- Fast database UPDATE (indexed on source_type)
- Estimated downtime: 30-60 minutes

### Risk 4: Nutrition Data Format Differences
**Mitigation**:
- Map Tandoor nutrition to our internal Macros type
- Validate macro calculations match expected values
- Property tests for conversion accuracy

## Migration Plan

### Phase 1: Preparation (Day 1)
1. Install Tandoor (Docker container, port 8000)
2. Create Tandoor API token
3. Implement Tandoor client modules (7 files)
4. Write migration script
5. Test Tandoor API integration (unit tests)

### Phase 2: Data Migration (Day 2)
1. Run migration script in dry-run mode
2. Verify recipe mapping correctness
3. Backup PostgreSQL database
4. Run migration script (Mealie → Tandoor recipe transfer)
5. Verify all recipes migrated successfully

### Phase 3: Code Update (Day 2-3)
1. Replace Mealie imports with Tandoor imports (34 files)
2. Update auto_planner to use TandoorRecipe
3. Update storage/tandoor_enrichment
4. Run test suite (update tests for Tandoor)
5. Fix any failing tests

### Phase 4: Database Migration (Day 3)
1. Run migration 025 (source_type update)
2. Verify food_logs updated correctly
3. Test food logging with Tandoor recipes
4. Test auto planner end-to-end

### Phase 5: Deployment & Cleanup (Day 4)
1. Deploy updated code to production
2. Verify Tandoor integration working
3. Monitor for errors (24 hours)
4. Remove Mealie container
5. Delete Mealie code (`gleam/src/meal_planner/mealie/`)
6. Remove Mealie env vars from config

## Rollback Strategy

If critical issues discovered:
1. Revert code deployment (git revert)
2. Rollback database migration:
   ```sql
   UPDATE food_logs SET source_type = 'mealie_recipe'
   WHERE source_type = 'tandoor_recipe';
   ```
3. Restart Mealie container
4. Investigate Tandoor issues offline

## Open Questions

1. **Tandoor Instance**: Is Tandoor already running? What port?
2. **API Token**: Do we have Tandoor API credentials?
3. **Recipe Count**: How many recipes need migration? (affects migration time)
4. **Custom Fields**: Are there Mealie-specific fields we need to preserve?
5. **Image Migration**: Should we migrate recipe images? (bandwidth/storage consideration)
6. **User Mapping**: Do Tandoor users map 1:1 to our app users?

## Success Criteria

- ✅ All recipes migrated from Mealie to Tandoor (100% coverage)
- ✅ Zero data loss (food logs, meal plans preserved)
- ✅ Auto planner works with Tandoor recipes
- ✅ Food logging works with Tandoor source type
- ✅ All tests pass (360 tests green)
- ✅ No Mealie code references remain
- ✅ Performance equal or better than Mealie
