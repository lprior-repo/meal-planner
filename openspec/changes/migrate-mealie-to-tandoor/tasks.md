# Implementation Tasks

## 1. Tandoor Setup & Investigation
- [ ] 1.1 Install Tandoor via Docker (port 8000)
- [ ] 1.2 Create Tandoor API token and test access
- [ ] 1.3 Read Tandoor API docs and identify endpoint mappings
- [ ] 1.4 Document API differences (Mealie vs Tandoor)
- [ ] 1.5 Test sample recipe CRUD operations manually

## 2. Tandoor Client Implementation
- [ ] 2.1 Create `tandoor/types.gleam` (TandoorRecipe, TandoorIngredient, etc.)
- [ ] 2.2 Create `tandoor/client.gleam` (HTTP client with auth)
- [ ] 2.3 Implement `get_recipes`, `get_recipe_by_id`, `create_recipe`
- [ ] 2.4 Implement pagination handling (cursor-based)
- [ ] 2.5 Create `tandoor/mapper.gleam` (`tandoor_to_recipe` conversion)
- [ ] 2.6 Create `tandoor/connectivity.gleam` (health checks)
- [ ] 2.7 Create `tandoor/retry.gleam` (exponential backoff)
- [ ] 2.8 Create `tandoor/fallback.gleam` (graceful degradation)
- [ ] 2.9 Create `tandoor/sync.gleam` (data sync utilities)

## 3. Migration Script Development
- [ ] 3.1 Create `scripts/migrate_mealie_to_tandoor.gleam`
- [ ] 3.2 Implement Mealie recipe fetching (all recipes)
- [ ] 3.3 Implement Mealie → Tandoor format transformation
- [ ] 3.4 Implement Tandoor recipe creation (batch POST)
- [ ] 3.5 Create recipe mapping log (Mealie slug → Tandoor ID)
- [ ] 3.6 Add dry-run mode for testing
- [ ] 3.7 Add progress reporting (X of Y recipes migrated)
- [ ] 3.8 Test migration script on sample data

## 4. Configuration Updates
- [ ] 4.1 Add `TANDOOR_BASE_URL` to `config.gleam`
- [ ] 4.2 Add `TANDOOR_API_TOKEN` to `config.gleam`
- [ ] 4.3 Update `.env.example` with Tandoor vars
- [ ] 4.4 Update `README.md` with Tandoor setup instructions
- [ ] 4.5 Update `CLAUDE.md` to reference Tandoor (not Mealie)

## 5. Code Migration (Replace Mealie with Tandoor)
- [ ] 5.1 Update `auto_planner.gleam` imports (mealie → tandoor)
- [ ] 5.2 Update `auto_planner/types.gleam` (MealieRecipe → TandoorRecipe)
- [ ] 5.3 Rename `storage/mealie_enrichment.gleam` → `storage/tandoor_enrichment.gleam`
- [ ] 5.4 Update all imports in 34+ files (find/replace mealie → tandoor)
- [ ] 5.5 Update `web.gleam` routes (if any Mealie-specific endpoints)
- [ ] 5.6 Update `portion.gleam` (Mealie recipe handling)
- [ ] 5.7 Update `vertical_diet_compliance.gleam` (recipe validation)

## 6. Test Migration
- [ ] 6.1 Rename `mealie_mapper_test.gleam` → `tandoor_mapper_test.gleam`
- [ ] 6.2 Update tests for Tandoor API responses
- [ ] 6.3 Rename `mealie_client_test.gleam` → `tandoor_client_test.gleam`
- [ ] 6.4 Update mock data to Tandoor JSON format
- [ ] 6.5 Rename `mealie_connectivity_test.gleam` → `tandoor_connectivity_test.gleam`
- [ ] 6.6 Rename `mealie_retry_test.gleam` → `tandoor_retry_test.gleam`
- [ ] 6.7 Rename `mealie_fallback_test.gleam` → `tandoor_fallback_test.gleam`
- [ ] 6.8 Update all test assertions for Tandoor behavior
- [ ] 6.9 Run test suite and fix failures (gleam test)

## 7. Database Migration
- [ ] 7.1 Create migration 025: `025_migrate_mealie_to_tandoor.sql`
- [ ] 7.2 Backup production database (pg_dump)
- [ ] 7.3 Update `food_logs.source_type` constraint (remove mealie_recipe, add tandoor_recipe)
- [ ] 7.4 Migrate existing data: UPDATE source_type mealie_recipe → tandoor_recipe
- [ ] 7.5 Update `recipe_json` fields to Tandoor format (application-level migration)
- [ ] 7.6 Update `recipe_sources` table (change Mealie config → Tandoor config)
- [ ] 7.7 Test database migration on staging environment
- [ ] 7.8 Verify data integrity after migration

## 8. Data Migration Execution
- [ ] 8.1 Run migration script in dry-run mode
- [ ] 8.2 Verify recipe count matches (Mealie source vs Tandoor destination)
- [ ] 8.3 Run migration script for real (Mealie → Tandoor transfer)
- [ ] 8.4 Verify all recipes created in Tandoor
- [ ] 8.5 Save recipe mapping log for audit
- [ ] 8.6 Spot-check recipe data accuracy (nutrition, ingredients)

## 9. Integration Testing
- [ ] 9.1 Test auto planner with Tandoor recipes (end-to-end)
- [ ] 9.2 Test food logging with tandoor_recipe source type
- [ ] 9.3 Test recipe filtering by macros
- [ ] 9.4 Test recipe scoring and compliance validation
- [ ] 9.5 Test meal plan save/load with Tandoor recipes
- [ ] 9.6 Manual testing via web UI (create meal plan, log food)

## 10. Documentation & Examples
- [ ] 10.1 Update `examples/create_recipe_example.gleam` for Tandoor
- [ ] 10.2 Update `examples/bulk_create_recipes.gleam` for Tandoor
- [ ] 10.3 Add Tandoor API usage examples
- [ ] 10.4 Document migration process in `docs/migrations/mealie-to-tandoor.md`

## 11. Cleanup & Removal
- [ ] 11.1 Delete `gleam/src/meal_planner/mealie/` directory (7 files)
- [ ] 11.2 Delete old Mealie test files
- [ ] 11.3 Remove Mealie container (Docker)
- [ ] 11.4 Remove `MEALIE_BASE_URL` and `MEALIE_API_TOKEN` from .env
- [ ] 11.5 Remove Mealie references from docs
- [ ] 11.6 Remove Mealie dependencies from `gleam.toml` (if any)

## 12. Deployment & Monitoring
- [ ] 12.1 Deploy to staging environment
- [ ] 12.2 Run smoke tests on staging
- [ ] 12.3 Deploy to production
- [ ] 12.4 Monitor logs for Tandoor API errors (24 hours)
- [ ] 12.5 Verify auto planner working in production
- [ ] 12.6 Verify food logging working in production
- [ ] 12.7 Performance comparison (Tandoor vs Mealie response times)

## Dependencies
- Tasks 2.x must complete before 5.x (need Tandoor client before code migration)
- Tasks 3.x must complete before 8.x (need migration script before execution)
- Tasks 7.x must complete before 8.x (database schema ready before data migration)
- Tasks 8.x must complete before 12.x (data migrated before deployment)
