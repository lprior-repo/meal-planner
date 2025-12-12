# Change: Complete Mealie Codebase Cleanup

## Why
While Mealie source files and Docker containers have been removed, the codebase is still littered with Mealie references in:
- Import statements and type references
- Database migrations and SQL comments
- Configuration and environment variable handling
- Example code and documentation
- Test code and test fixtures
- API comments and function names

This creates confusion, prevents successful builds, and leaves dead code that could mislead future development. A comprehensive cleanup is needed to fully remove all Mealie integration code.

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
