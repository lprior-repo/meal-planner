# Capability: Codebase Cleanup

## ADDED Requirements

### Requirement: Remove All Mealie References
The codebase SHALL NOT contain any references to "Mealie" in source code, configuration, or documentation, except where referring to the historical migration from Mealie to Tandoor.

#### Scenario: Source code imports are Tandoor-only
- **WHEN** scanning all `.gleam` source files
- **THEN** no `import meal_planner/mealie/*` statements exist
- **AND** all imports reference `import meal_planner/tandoor/*` instead

#### Scenario: Configuration uses Tandoor naming
- **WHEN** reading configuration types
- **THEN** `MealieConfig` type does NOT exist
- **AND** `TandoorConfig` type IS used for recipe service configuration

#### Scenario: Environment variables reference Tandoor
- **WHEN** checking environment variable usage
- **THEN** `MEALIE_BASE_URL` is NOT referenced
- **AND** `MEALIE_API_TOKEN` is NOT referenced
- **AND** `TANDOOR_BASE_URL` IS used
- **AND** `TANDOOR_API_TOKEN` IS used

#### Scenario: Database schema uses Tandoor source type
- **WHEN** querying `food_logs.source_type` check constraint
- **THEN** `mealie_recipe` is NOT a valid value
- **AND** `tandoor_recipe` IS a valid value
- **AND** constraint allows `['tandoor_recipe', 'custom_food', 'usda_food']`

#### Scenario: Documentation is Mealie-free
- **WHEN** listing files in `docs/` directory
- **THEN** no files match pattern `MEALIE_*.md`
- **AND** no files in root match pattern `MEALIE_*.md`

#### Scenario: Examples use Tandoor API
- **WHEN** reading `gleam/examples/*.gleam` files
- **THEN** no references to `MealieRecipe` type exist
- **AND** `TandoorRecipe` types ARE used

#### Scenario: Test fixtures reference Tandoor
- **WHEN** checking test files for source_type values
- **THEN** test assertions use `tandoor_recipe`
- **AND** test assertions do NOT use `mealie_recipe`

### Requirement: Preserve Migration History
The codebase SHALL retain references to Mealie in migration files and historical documentation to maintain audit trail.

#### Scenario: Migration files preserve context
- **WHEN** reading migration SQL files
- **THEN** comments MAY reference historical context "migrated from Mealie to Tandoor"
- **AND** migration 022 MAY contain "rename recipe to mealie_recipe" in filename
- **AND** migration 025 SHALL contain "rename mealie_recipe to tandoor_recipe"

#### Scenario: Rollback migrations preserve history
- **WHEN** reading `gleam/migrations_pg/rollback/*.sql` files
- **THEN** rollback files MAY reference Mealie for historical accuracy
- **AND** rollback comments explain original Mealie-based implementation

### Requirement: Build Success Without Mealie Modules
The codebase SHALL compile successfully without any `mealie/*` modules present.

#### Scenario: Gleam build succeeds
- **WHEN** running `gleam build`
- **THEN** build completes without import errors
- **AND** no "module meal_planner/mealie/client not found" errors occur

#### Scenario: Tests run without Mealie imports
- **WHEN** running `gleam test`
- **THEN** no test files import from `meal_planner/mealie/*`
- **AND** all tests pass or fail independently of Mealie modules
