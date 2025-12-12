# Mealie Integration Specification

## REMOVED Requirements

### Requirement: Mealie API Client
**Reason**: Migrating to Tandoor due to Mealie reliability issues

**Migration**: All Mealie API client functionality replaced by `tandoor/client.gleam` module

### Requirement: Mealie to Internal Recipe Mapping
**Reason**: No longer using Mealie as recipe source

**Migration**: `mealie_to_recipe()` function replaced by `tandoor_to_recipe()` with equivalent functionality

### Requirement: Mealie Connectivity and Health Checks
**Reason**: Mealie service being decommissioned

**Migration**: `mealie/connectivity.gleam` replaced by `tandoor/connectivity.gleam`

### Requirement: Mealie Retry Logic
**Reason**: Mealie-specific retry logic no longer needed

**Migration**: `mealie/retry.gleam` replaced by `tandoor/retry.gleam` with similar exponential backoff strategy

### Requirement: Mealie Fallback Handling
**Reason**: Removing Mealie fallback mechanisms

**Migration**: `mealie/fallback.gleam` replaced by `tandoor/fallback.gleam` with equivalent graceful degradation

### Requirement: Auto Planner with Mealie Recipes
**Reason**: Auto planner migrating to Tandoor recipe source

**Migration**:
- `filter_mealie_recipes_by_diet()` → `filter_tandoor_recipes_by_diet()`
- `MealieRecipe` type → `TandoorRecipe` type
- All auto planner Mealie integration replaced with Tandoor equivalent

### Requirement: Food Logging with Mealie Source
**Reason**: Mealie source type deprecated in favor of Tandoor

**Migration**:
- Database: `source_type = 'mealie_recipe'` → `source_type = 'tandoor_recipe'`
- Code: All references to `mealie_recipe` source type updated to `tandoor_recipe`
- `recipe_json` field format updated from Mealie JSON schema to Tandoor schema

### Requirement: Mealie Recipe Sync
**Reason**: Sync logic being replaced for Tandoor

**Migration**: `mealie/sync.gleam` replaced by `tandoor/sync.gleam` with Tandoor-specific sync strategies
