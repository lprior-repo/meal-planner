# Change: Migrate from Mealie to Tandoor Recipe Manager

## Why
Mealie has proven unreliable and unsuitable for production use. Tandoor is a more mature, actively maintained recipe management system with better API stability, performance, and features. This migration is **urgent** due to ongoing Mealie issues affecting user experience.

## What Changes
- **BREAKING**: Replace entire Mealie API integration with Tandoor API client
- Migrate all existing recipe data from Mealie to Tandoor
- Update database schema: `mealie_recipe` → `tandoor_recipe` source type
- Replace all 7 Mealie modules with Tandoor equivalents
- Update 34+ files that import/reference Mealie
- Migrate food logs and auto planner data to use Tandoor recipe references
- Update configuration (Tandoor URL, API tokens)

## Impact
- **Affected specs**:
  - `tandoor-integration` (ADDED - new capability)
  - `mealie-integration` (REMOVED - deprecated)
- **Affected code**:
  - `gleam/src/meal_planner/tandoor/` - NEW module (7 files)
  - `gleam/src/meal_planner/mealie/` - DELETE (7 files)
  - `gleam/src/meal_planner/auto_planner.gleam` - Update imports
  - `gleam/src/meal_planner/storage/mealie_enrichment.gleam` - Rename to tandoor_enrichment
  - `gleam/test/mealie_*.gleam` - Rename to tandoor_* tests
  - `gleam/migrations_pg/025_migrate_mealie_to_tandoor.sql` - NEW migration
- **Database changes**:
  - Migrate `food_logs.source_type` from `mealie_recipe` to `tandoor_recipe`
  - Update `recipe_json` fields to Tandoor format
  - Update `recipe_sources` table configuration
- **Configuration**:
  - Add `TANDOOR_BASE_URL` env var
  - Add `TANDOOR_API_TOKEN` env var
  - Remove `MEALIE_BASE_URL` and `MEALIE_API_TOKEN`
- **Beads tasks**:
  - All 7 Mealie integration test tasks need conversion to Tandoor
  - Recipe sources table analysis (may keep for Tandoor)
