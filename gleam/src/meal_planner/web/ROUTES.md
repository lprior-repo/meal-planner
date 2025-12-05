# Routes Module

## Overview

The `routes.gleam` module centralizes all route pattern matching and URL generation logic for the meal-planner application. This module extracts routing definitions from `web.gleam`, improving modularity and maintainability.

## Route Types

The `Route` type defines all application routes:

### Page Routes (SSR)
- `Home` - Root path `/`
- `Recipes` - Recipe listing page `/recipes`
- `RecipesNew` - New recipe form `/recipes/new`
- `RecipesEdit(id)` - Edit recipe form `/recipes/{id}/edit`
- `RecipeDetail(id)` - Recipe detail page `/recipes/{id}`
- `Dashboard` - Main dashboard `/dashboard`
- `Profile` - User profile page `/profile`
- `Foods` - Food search page `/foods`
- `FoodDetail(id)` - Food detail page `/foods/{id}`
- `LogMeal` - Meal logging page `/log`
- `LogMealForm(recipe_id)` - Log specific recipe `/log/{recipe_id}`
- `WeeklyPlan` - Weekly meal plan page `/weekly-plan`

### API Routes
- `ApiRecipes` - Recipes API `/api/recipes`
- `ApiRecipe(id)` - Single recipe API `/api/recipes/{id}`
- `ApiProfile` - Profile API `/api/profile`
- `ApiFoods` - Foods listing API `/api/foods`
- `ApiFoodsSearch` - Foods search API `/api/foods/search`
- `ApiFood(id)` - Single food API `/api/foods/{id}`
- `ApiLogs` - Food logs API `/api/logs`
- `ApiLogEntry(id)` - Log entry API `/api/logs/entry/{id}`
- `ApiSwapMeal(meal_type)` - Swap meal API `/api/swap/{meal_type}`
- `ApiGenerate` - Generate endpoint `/api/generate`
- `ApiSyncTodoist` - Todoist sync `/api/sync/todoist`
- `ApiRecipeSources` - Recipe sources API `/api/recipe-sources`
- `ApiAutoMealPlan` - Auto meal plan API `/api/meal-plans/auto`
- `ApiAutoMealPlanById(id)` - Get meal plan `/api/meal-plans/auto/{id}`
- `ApiFilterFragments` - Filter fragments API `/api/fragments/filters`

### Static Assets
- `StaticAsset(path)` - Static files `/static/{path}`

### Error
- `NotFound` - Unmapped routes (404)

## Functions

### parse_route(segments: List(String)) -> Route
Converts path segments from a request into a `Route` variant.

```gleam
parse_route([]) // -> Home
parse_route(["recipes", "abc123"]) // -> RecipeDetail("abc123")
parse_route(["api", "foods", "search"]) // -> ApiFoodsSearch
```

### route_to_path(route: Route) -> String
Converts a `Route` variant back to its URL path string. Useful for generating links and redirects.

```gleam
route_to_path(Recipes) // -> "/recipes"
route_to_path(RecipeDetail("abc123")) // -> "/recipes/abc123"
route_to_path(ApiFood("fdc999")) // -> "/api/foods/fdc999"
```

### is_api_route(route: Route) -> Bool
Checks if a route is an API route.

```gleam
is_api_route(ApiFoods) // -> True
is_api_route(Recipes) // -> False
```

### is_static_route(route: Route) -> Bool
Checks if a route is a static asset route.

```gleam
is_static_route(StaticAsset(["styles.css"])) // -> True
is_static_route(Home) // -> False
```

### route_params(route: Route) -> List(String)
Extracts parameters from a route (IDs, meal types, etc.).

```gleam
route_params(RecipeDetail("abc123")) // -> ["abc123"]
route_params(ApiSwapMeal("breakfast")) // -> ["breakfast"]
route_params(StaticAsset(["css", "main.css"])) // -> ["css", "main.css"]
```

## Usage Example

### In web.gleam

Before (without routes module):
```gleam
fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  case wisp.path_segments(req) {
    [] -> home_page()
    ["recipes"] -> recipes_page(ctx)
    ["recipes", id] -> recipe_detail_page(id, ctx)
    // ... many more patterns
  }
}
```

After (with routes module):
```gleam
import meal_planner/web/routes

fn handle_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  let segments = wisp.path_segments(req)
  let route = routes.parse_route(segments)

  case route {
    routes.Home -> home_page()
    routes.Recipes -> recipes_page(ctx)
    routes.RecipeDetail(id) -> recipe_detail_page(id, ctx)
    routes.NotFound -> not_found_page()
    // ... other routes
  }
}
```

### URL Generation

```gleam
import meal_planner/web/routes

// Generate a link to a recipe
let recipe_url = routes.route_to_path(routes.RecipeDetail("abc123"))
// recipe_url = "/recipes/abc123"

// Use in HTML
html.a([attribute.href(recipe_url)], [element.text("View Recipe")])
```

### Route Analysis

```gleam
let route = routes.parse_route(["api", "foods", "search"])

case route {
  route if routes.is_api_route(route) ->
    // Handle API route
    api_handler(route)
  route ->
    // Handle page route
    page_handler(route)
}
```

## Testing

Comprehensive test suite in `test/meal_planner/web/routes_test.gleam`:

- **Parse Route Tests**: Verify path segments map to correct Route types
- **Route to Path Tests**: Verify Route types convert to correct paths
- **Round-trip Tests**: Verify path -> route -> path consistency
- **Helper Function Tests**: Verify is_api_route, is_static_route, route_params

Run tests:
```bash
cd gleam
gleam test routes
```

## Integration with web.gleam

The routes module is designed to be integrated gradually:

1. **Current**: Route patterns still in web.gleam
2. **Phase 1**: Import routes module, use for non-API routes
3. **Phase 2**: Extract API routing into separate API route handler
4. **Phase 3**: Consolidate all route handling through routes module

This modular approach allows incremental refactoring without disrupting existing functionality.

## Benefits

- **Modularity**: Route definitions separated from handlers
- **Maintainability**: Single source of truth for URL patterns
- **Type Safety**: Route type system prevents invalid route combinations
- **Testability**: Routes can be tested independently
- **Reusability**: route_to_path enables DRY link generation
- **Discoverability**: All routes visible in one module
