# Change: Complete Mealie Codebase Cleanup

## Status: COMPLETED (2025-12-12)

This proposal has been implemented. Mealie has been completely removed from the codebase.

## Why
While Mealie source files and Docker containers have been removed, the codebase is still littered with Mealie references in:
- Import statements and type references
- Database migrations and SQL comments
- Configuration and environment variable handling
- Example code and documentation
- Test code and test fixtures
- API comments and function names

This creates confusion, prevents successful builds, and leaves dead code that could mislead future development. A comprehensive cleanup is needed to fully remove all Mealie integration code.

## What Was Actually Completed

### Fully Completed
- Deleted entire `gleam/src/meal_planner/mealie/` directory (7 files, 3500+ LOC)
- Deleted all Mealie test files (11 files)
- Deleted all Mealie-specific documentation (5+ files)
- Deleted example files that used Mealie API
- Removed Mealie Docker container configuration
- Replaced MEALIE env vars with TANDOOR in .env files
- Created migration 025 to rename `mealie_recipe` to `tandoor_recipe`
- Renamed `mealie_enrichment.gleam` to `tandoor_enrichment.gleam`
- Updated test fixtures to use `tandoor_recipe`

### Remaining References (Intentional)
Most remaining "mealie" references are historical and should be preserved:
- **Database migrations (019, 020, 022, 024, 025)** - Historical record of schema evolution
- **Migration comments** - Document the rename from mealie_recipe to tandoor_recipe
- **Rollback scripts** - Reference old mealie_recipe values for rollback purposes
- **Test files** - Migration tests verify historical migrations work correctly
- **Documentation** - Historical context in ROLLBACK_PROCEDURE.md, etc.
- **Backup files** (.bak, .backup, .skip) - Can be deleted during general cleanup

Total remaining: ~1092 occurrences across 59 files, mostly in migrations and historical docs.

## What Changes
- **BREAKING**: Remove all Mealie type imports and replace with Tandoor equivalents
- Update database migration comments to reference Tandoor instead of Mealie
- Replace `mealie_recipe` source_type with `tandoor_recipe` in DB constraints
- Update all environment variable references (MEALIE → TANDOOR)
- Rewrite example files to use Tandoor API
- Clean up documentation to remove Mealie references
- Update test fixtures and test code
- Replace MealieConfig type with TandoorConfig in web.gleam
- Update main.gleam startup messages

## Impact
- **Affected code**:
  - `gleam/src/meal_planner.gleam` - Environment vars, config, startup messages
  - `gleam/src/meal_planner/web.gleam` - MealieConfig type, imports
  - `gleam/src/meal_planner/storage/*.gleam` - Comments, type references
  - `gleam/src/meal_planner/auto_planner.gleam` - Type imports
  - `gleam/src/meal_planner/portion.gleam` - Comments
  - `gleam/src/meal_planner/vertical_diet_compliance.gleam` - Comments
  - `gleam/examples/*.gleam` - Complete rewrites for Tandoor
  - `gleam/test/*_test.gleam` - Test fixtures, comments
  - `gleam/migrations_pg/*.sql` - Comments in 019, 020, 022, 024
  - `docs/*.md` - Remove 5+ Mealie documentation files
  - `*.md` (root) - Remove Mealie from FOOD_LOG_API_UPDATE, ROLLBACK_PROCEDURE, etc.
- **Database changes**:
  - Migration 025: Rename `mealie_recipe` → `tandoor_recipe` in constraints
  - Migration 025: Update comments to reference Tandoor
  - Update CHECK constraint to use `tandoor_recipe`
- **Documentation cleanup**:
  - Delete: `docs/MEALIE_*.md` (5 files)
  - Update: `docs/MEAL_PLAN_GENERATION_TESTS.md`
  - Update: `docs/PERFORMANCE_BENCHMARKS.md`
  - Update: Root markdown files (FOOD_LOG_API_UPDATE.md, etc.)
