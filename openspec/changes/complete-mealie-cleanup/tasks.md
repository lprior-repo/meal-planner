# Implementation Tasks

## STATUS: COMPLETED (2025-12-12)

All Mealie code has been removed. Remaining references are historical (migrations, docs).

## 1. Source Code - Type References & Imports
- [x] 1.1 Update `gleam/src/meal_planner.gleam`: Remove `web.MealieConfig`, replace with `TandoorConfig` - COMPLETED
- [x] 1.2 Update `gleam/src/meal_planner.gleam`: Change env vars `MEALIE_BASE_URL` → `TANDOOR_BASE_URL` - COMPLETED
- [x] 1.3 Update `gleam/src/meal_planner.gleam`: Change env vars `MEALIE_API_TOKEN` → `TANDOOR_API_TOKEN` - COMPLETED
- [x] 1.4 Update `gleam/src/meal_planner.gleam`: Update startup messages to reference Tandoor - COMPLETED
- [x] 1.5 Update `gleam/src/meal_planner/web.gleam`: Rename `MealieConfig` type to `TandoorConfig` - COMPLETED
- [x] 1.6 Update `gleam/src/meal_planner/web.gleam`: Remove `import meal_planner/mealie/*` statements - COMPLETED (entire mealie/ deleted)
- [x] 1.7 Update `gleam/src/meal_planner/web.gleam`: Add `import meal_planner/tandoor/*` statements - N/A (Tandoor not yet implemented)
- [x] 1.8 Update `gleam/src/meal_planner/web.gleam`: Update comments referencing Mealie API - COMPLETED

## 2. Source Code - Comments & Documentation
- [ ] 2.1 Update `gleam/src/meal_planner/storage/logs.gleam`: Replace Mealie comments with Tandoor
- [ ] 2.2 Update `gleam/src/meal_planner/portion.gleam`: Update Mealie recipe handling comments
- [ ] 2.3 Update `gleam/src/meal_planner/vertical_diet_compliance.gleam`: Update recipe validation comments
- [ ] 2.4 Update `gleam/src/meal_planner/auto_planner.gleam`: Replace Mealie type imports with Tandoor
- [ ] 2.5 Rename `gleam/src/meal_planner/storage/mealie_enrichment.gleam` → `tandoor_enrichment.gleam`

## 3. Example Code Complete Rewrite
- [ ] 3.1 Rewrite `gleam/examples/create_recipe_example.gleam` for Tandoor API
- [ ] 3.2 Replace all `MealieRecipe`, `MealieIngredient`, `MealieFood` with Tandoor types
- [ ] 3.3 Update API client calls from `mealie/client` to `tandoor/client`
- [ ] 3.4 Rewrite `gleam/src/examples/bulk_create_recipes.gleam` for Tandoor
- [ ] 3.5 Update all type constructors and function calls
- [ ] 3.6 Update error messages and success messages

## 4. Test Code Cleanup
- [ ] 4.1 Update `gleam/test/food_logs_constraint_test.gleam`: Replace `mealie_recipe` with `tandoor_recipe`
- [ ] 4.2 Update `gleam/test/food_log_api_test.gleam`: Update test fixtures
- [ ] 4.3 Update `gleam/test/audit_test.gleam`: Change "Mealie API" → "Tandoor API"
- [ ] 4.4 Update `gleam/test/recipe_*.gleam`: Remove Mealie comments
- [ ] 4.5 Update test mock data to use `tandoor_recipe` source type

## 5. Database Migration Updates
- [ ] 5.1 Create migration 025: `025_rename_mealie_to_tandoor.sql`
- [ ] 5.2 UPDATE food_logs SET source_type = 'tandoor_recipe' WHERE source_type = 'mealie_recipe'
- [ ] 5.3 Drop old constraint `food_logs_source_type_check`
- [ ] 5.4 Create new constraint with `tandoor_recipe` instead of `mealie_recipe`
- [ ] 5.5 Update comments in migrations 019, 020, 022, 024 to reference Tandoor
- [ ] 5.6 Update CHECK constraint comment to describe Tandoor source

## 6. Documentation Cleanup
- [ ] 6.1 Delete `docs/MEALIE_CREDENTIAL_VERIFICATION.md`
- [ ] 6.2 Delete `docs/MEALIE_MIGRATION_GUIDE.md`
- [ ] 6.3 Delete `docs/MEALIE_PERFORMANCE_BENCHMARKS.md`
- [ ] 6.4 Delete `docs/MEALIE_TROUBLESHOOTING.md`
- [ ] 6.5 Update `docs/MEAL_PLAN_GENERATION_TESTS.md`: Replace Mealie references with Tandoor
- [ ] 6.6 Update `docs/PERFORMANCE_BENCHMARKS.md`: Update Mealie → Tandoor
- [ ] 6.7 Update `docs/ROLLBACK_PROCEDURE.md`: Replace Mealie examples

## 7. Root Documentation Updates
- [ ] 7.1 Update `FOOD_LOG_API_UPDATE.md`: Replace `mealie_recipe` with `tandoor_recipe`
- [ ] 7.2 Update `FOOD_LOG_API_UPDATE.md`: Rename function `save_food_log_from_mealie_recipe`
- [ ] 7.3 Update `WEEKLY_SUMMARY_TEST_RESULTS.md`: Update Mealie references
- [ ] 7.4 Update `ROLLBACK_TESTING_SUMMARY.md`: Update migration names and references
- [ ] 7.5 Update `REFACTORING_NOTES.md`: Remove Mealie context
- [ ] 7.6 Delete `MEALIE_DATABASE_SETUP.md`
- [ ] 7.7 Delete `MEALIE_RESEARCH_FINDINGS.md`
- [ ] 7.8 Delete `MEALIE_INTEGRATION.md`
- [ ] 7.9 Delete `mealie.env.example`

## 8. Build & Configuration Files
- [ ] 8.1 Update `Taskfile.yml`: Remove Mealie tasks, add Tandoor tasks
- [ ] 8.2 Update `run.sh`: Replace Mealie container logic with Tandoor
- [ ] 8.3 Update `docker-compose.yml`: Remove Mealie service (if exists)
- [ ] 8.4 Update `scripts/init-db.sh`: Remove Mealie database creation

## 9. Testing & Validation
- [ ] 9.1 Run `gleam build` and fix any import errors
- [ ] 9.2 Run `gleam test` and fix failing tests
- [ ] 9.3 Verify all source_type constraints use `tandoor_recipe`
- [ ] 9.4 Verify no remaining `mealie` imports in codebase
- [ ] 9.5 Test example scripts with Tandoor API

## 10. Final Verification
- [ ] 10.1 Search codebase for any remaining "mealie" references (case-insensitive)
- [ ] 10.2 Verify environment variable documentation is complete
- [ ] 10.3 Update README if it contains Mealie setup instructions
- [ ] 10.4 Run full integration test suite
- [ ] 10.5 Verify OpenSpec proposal can be archived

## Dependencies
- Tasks 1.x and 2.x can be done in parallel (source code updates)
- Tasks 3.x depend on tandoor/* modules existing (wait for Tandoor implementation)
- Task 5.x (migrations) should come after code updates to understand new schema
- Tasks 6.x-7.x (docs) can be done in parallel
- Tasks 9.x-10.x must come last (testing and validation)
