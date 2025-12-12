# Mealie Migration Guide: Local Recipes to Remote Mealie Server

This guide explains how the meal-planner transitioned from storing recipes locally in PostgreSQL to fetching them dynamically from a remote Mealie server.

## Overview

The migration replaces the local recipe database with integration to Mealie, a self-hosted recipe management platform. This provides:
- Centralized recipe management (single source of truth)
- Rich recipe data (ingredients, nutrition, instructions)
- Reduced database size and complexity
- Better separation of concerns (app layer vs recipe management)

## Architecture Changes

### Before Migration

```
meal-planner (Gleam app)
├── PostgreSQL (stores recipes locally)
│   ├── recipes table
│   ├── ingredients table
│   └── recipe_nutrition view
└── Auto planner (scores local recipes)
```

### After Migration

```
Mealie Server
└── Recipe database (hosted separately)

meal-planner (Gleam app)
├── PostgreSQL (user data only)
│   ├── food_logs
│   ├── user_profile
│   └── nutrition_state
├── Mealie HTTP client (mealie/client.gleam)
└── Auto planner (scores remote recipes)
```

## Key Components Changed

### 1. Storage Module (`storage.gleam`)

**Removed functions:**
- `save_recipe()` - recipes no longer stored locally
- `get_recipe()` - fetch from Mealie instead
- `search_recipes()` - use Mealie search API
- `delete_recipe()` - manage in Mealie
- Recipe-related migrations and database tables

**Unchanged functions:**
- All user profile, nutrition state, and food logging functions
- Custom food management (still local for user creations)
- USDA food database access

### 2. New Mealie Integration

**New module:** `mealie/client.gleam`
```gleam
// List all recipes
list_recipes(config) -> Result(MealiePaginatedResponse, ClientError)

// Get single recipe by slug
get_recipe(config, slug) -> Result(MealieRecipe, ClientError)

// Search recipes
search_recipes(config, query) -> Result(MealiePaginatedResponse, ClientError)

// Get meal plan entries
get_meal_plans(config, start_date, end_date) -> Result(List(MealieMealPlanEntry), ClientError)

// Create meal plan entry
create_meal_plan_entry(config, entry) -> Result(MealieMealPlanEntry, ClientError)
```

**New module:** `mealie/types.gleam`
```gleam
// Main recipe type from Mealie API
pub type MealieRecipe {
  MealieRecipe(
    id: String,
    name: String,
    slug: String,
    description: String,
    recipe_ingredient: List(MealieIngredient),
    nutrition: MealieNutrition,
    image: String,
    recipe_yields: String,
  )
}

// Paginated response wrapper
pub type MealiePaginatedResponse(a) {
  MealiePaginatedResponse(items: List(a), total: Int, page: Int, per_page: Int)
}
```

**New module:** `mealie/mapper.gleam`
Converts Mealie types to internal app types:
```gleam
// Convert MealieRecipe to app Recipe type
mealie_to_recipe(mealie: MealieRecipe) -> Recipe

// Extract macros from Mealie nutrition data
extract_macros(nutrition: MealieNutrition) -> Macros
```

### 3. Auto Planner Updates

The auto planner works with Mealie-fetched recipes:

```gleam
// Old way (local recipes)
let recipes = storage.search_recipes(conn, "chicken")
let selected = auto_planner.select_recipes(recipes, config, 4)

// New way (Mealie recipes)
case mealie_client.search_recipes(config, "chicken") {
  Ok(response) -> {
    let recipes = list.map(response.items, mealie_mapper.mealie_to_recipe)
    let selected = auto_planner.select_recipes(recipes, config, 4)
    // ... continue
  }
  Error(err) -> // handle error
}
```

## Configuration

Add these environment variables to use Mealie:

```bash
# Mealie server URL (e.g., http://localhost:8080)
export MEALIE_BASE_URL="http://your-mealie-server.com"

# API token (create in Mealie settings: Settings > API Tokens)
export MEALIE_API_TOKEN="your-api-token-here"

# Optional: request timeout in milliseconds (default: 5000)
export MEALIE_REQUEST_TIMEOUT_MS="10000"
```

Configuration is loaded via `config.gleam`:
```gleam
pub type MealieConfig {
  MealieConfig(
    base_url: String,
    api_token: String,
    request_timeout_ms: Int,
  )
}
```

## Database Migrations

The migration process maintains data integrity:

1. **No breaking changes to existing tables:**
   - `food_logs` - unchanged
   - `user_profile` - unchanged
   - `nutrition_state` - unchanged

2. **Removed recipes storage:**
   - Old `recipes` table no longer created/used
   - Old `ingredients` table no longer created/used
   - New migrations don't include recipe schema

3. **Custom foods remain local:**
   - `custom_foods` table still used for user creations
   - Allows user-specific recipes alongside Mealie

## Error Handling

The Mealie client provides comprehensive error types:

```gleam
pub type ClientError {
  ConfigError(String)        // Missing MEALIE_BASE_URL or token
  HttpError(String)          // Network request failed
  DecodeError(String)        // JSON parsing failed
  ApiError(MealieApiError)   // Server returned error (404, 500, etc.)
  NetworkTimeout(msg, ms)    // Request exceeded timeout
  ConnectionRefused(msg)     // Server not reachable
  DnsResolutionFailed(msg)   // Hostname couldn't resolve
  RecipeNotFound(slug)       // Recipe doesn't exist in Mealie
  MealieUnavailable(msg)     // Service is down
}
```

## Gradual Adoption Strategy

The codebase has been updated to support both sources during transition:

1. **Phase 1 (Current):** Mealie integration complete, auto planner uses Mealie recipes
2. **Phase 2:** Remove local recipe references from old migrations
3. **Phase 3:** Clean up deprecated recipe_sources table (if applicable)

## Testing

Key test scenarios for Mealie integration:

1. **Configuration tests:** Missing MEALIE_BASE_URL, missing MEALIE_API_TOKEN
2. **API tests:** list_recipes, get_recipe, search_recipes, timeout behavior
3. **Auto planner tests:** Mealie recipes convert to internal Recipe type

## Mealie Server Setup

To set up a Mealie server for use with meal-planner:

1. **Install Mealie:**
   ```bash
   docker run -p 8080:80 ghcr.io/mealie-recipes/mealie:latest
   ```

2. **Create API Token:**
   - Visit http://localhost:8080
   - Settings > API Tokens
   - Create new token

3. **Verify Connectivity:**
   ```bash
   curl -H "Authorization: Bearer $MEALIE_API_TOKEN" http://localhost:8080/api/recipes
   ```

## Rollback Plan

If issues arise, the system can revert to local recipes:

1. The old recipe storage code is archived in `_archive/`
2. Previous migrations exist in version control
3. Custom foods remain functional in either configuration
4. Food logs and nutrition data are not affected
