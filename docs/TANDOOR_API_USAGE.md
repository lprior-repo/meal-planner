# Tandoor API Usage Guide

This document provides comprehensive examples and patterns for integrating with Tandoor via the meal planner application.

## Table of Contents

1. [Configuration](#configuration)
2. [API Endpoints](#api-endpoints)
3. [Authentication](#authentication)
4. [Query Recipes](#query-recipes)
5. [Create Recipes](#create-recipes)
6. [Log Food](#log-food)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)
9. [Examples](#examples)

## Configuration

### Environment Variables

The meal planner loads Tandoor configuration from the following environment variables:

```bash
# Tandoor server URL
TANDOOR_BASE_URL=http://localhost:8000

# API token for authentication
TANDOOR_API_TOKEN=your-token-here

# Connection timeout in milliseconds
TANDOOR_CONNECT_TIMEOUT_MS=5000

# Request timeout in milliseconds
TANDOOR_REQUEST_TIMEOUT_MS=30000
```

### Configuration Structure

In Gleam, this is represented as:

```gleam
pub type TandoorConfig {
  TandoorConfig(
    base_url: String,           // e.g., "http://localhost:8000"
    api_token: String,          // API token for authentication
    connect_timeout_ms: Int,    // Default: 5000ms
    request_timeout_ms: Int,    // Default: 30000ms
  )
}
```

### Loading Configuration

```gleam
import meal_planner/config

let cfg = config.load()
let tandoor_cfg = cfg.tandoor

// Check if Tandoor is configured
case config.has_tandoor_integration(cfg) {
  True -> io.println("Tandoor is configured")
  False -> io.println("Tandoor not configured")
}
```

## API Endpoints

### Base URL

```
http://localhost:8000
```

### Authentication

All API requests require the `Authorization: Token` header:

```
Authorization: Token {TANDOOR_API_TOKEN}
```

### Recipe Endpoints

#### List Recipes

```http
GET /api/recipes/
Authorization: Token {TANDOOR_API_TOKEN}

Query Parameters:
  limit=100  - Maximum results (default: 20)
  offset=0   - Pagination offset
  search=... - Search query
```

**Response:**

```json
{
  "count": 150,
  "next": "http://localhost:8000/api/recipes/?offset=100",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Grilled Chicken Breast",
      "slug": "grilled-chicken-breast",
      "author": "user@example.com",
      "description": "Simple grilled chicken",
      "servings": 1,
      "servings_text": "1 breast",
      "prep_time": 5,
      "cook_time": 15,
      "keywords": ["protein", "keto"],
      "nutrition": {
        "energy": 165,
        "protein": 31,
        "fat": 3.6,
        "carbohydrates": 0
      }
    }
  ]
}
```

#### Get Recipe Details

```http
GET /api/recipes/{id}/
Authorization: Token {TANDOOR_API_TOKEN}
```

**Response:**

```json
{
  "id": 1,
  "name": "Grilled Chicken Breast",
  "slug": "grilled-chicken-breast",
  "author": "user@example.com",
  "description": "Simple grilled chicken",
  "servings": 1,
  "servings_text": "1 breast",
  "prep_time": 5,
  "cook_time": 15,
  "keywords": ["protein", "keto"],
  "steps": [
    {
      "step": 1,
      "instruction": "Preheat grill to medium-high",
      "ingredients": []
    },
    {
      "step": 2,
      "instruction": "Season chicken with salt and pepper",
      "ingredients": [
        {
          "id": 1,
          "ingredient": "Chicken Breast",
          "amount": 200,
          "unit": "g"
        }
      ]
    }
  ],
  "nutrition": {
    "energy": 165,
    "protein": 31,
    "fat": 3.6,
    "carbohydrates": 0,
    "fiber": 0,
    "sugar": 0,
    "sodium": 75,
    "cholesterol": 85
  }
}
```

#### Create Recipe

```http
POST /api/recipes/
Authorization: Token {TANDOOR_API_TOKEN}
Content-Type: application/json

{
  "name": "Chicken Stir Fry",
  "description": "Quick weeknight dinner",
  "keywords": ["protein", "vegetables", "quick"],
  "prep_time": 10,
  "cook_time": 20,
  "servings": 2,
  "servings_text": "2 servings",
  "steps": [
    {
      "step": 1,
      "instruction": "Heat oil in wok"
    }
  ],
  "nutrition": {
    "energy": 350,
    "protein": 28,
    "fat": 12,
    "carbohydrates": 35
  }
}
```

#### Update Recipe

```http
PUT /api/recipes/{id}/
Authorization: Token {TANDOOR_API_TOKEN}
Content-Type: application/json

{
  "name": "Updated Recipe Name",
  "nutrition": {
    "energy": 400,
    "protein": 30,
    "fat": 15,
    "carbohydrates": 40
  }
}
```

#### Delete Recipe

```http
DELETE /api/recipes/{id}/
Authorization: Token {TANDOOR_API_TOKEN}
```

## Authentication

### Token Generation

To get a Tandoor API token:

1. Log in to Tandoor at `http://localhost:8000`
2. Navigate to Profile → Settings
3. Under "API Token", click "Show" to view or "Regenerate" for new token
4. Copy the token and set `TANDOOR_API_TOKEN` environment variable

### Token Format

The token is a long alphanumeric string, typically 40 characters:

```
TANDOOR_API_TOKEN=1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b
```

### Using Token in Requests

All API requests require the Authorization header:

```bash
curl -H "Authorization: Token {TANDOOR_API_TOKEN}" \
     http://localhost:8000/api/recipes/
```

## Query Recipes

### Search for Recipes

To find recipes by name or keyword:

```http
GET /api/recipes/?search=chicken&limit=10
Authorization: Token {TANDOOR_API_TOKEN}
```

### Retrieve All Recipes with Pagination

```gleam
// Pseudo-code showing pagination pattern
pub fn get_all_recipes(config: TandoorConfig) -> List(Recipe) {
  let limit = 100
  let mut all_recipes = []
  let mut offset = 0
  let mut has_more = True

  while has_more {
    let url = config.base_url
      <> "/api/recipes/?limit="
      <> int.to_string(limit)
      <> "&offset="
      <> int.to_string(offset)

    case http_get(url, config.api_token) {
      Ok(response) if response.count > offset + limit -> {
        all_recipes = list.append(all_recipes, response.results)
        offset = offset + limit
      }
      Ok(response) -> {
        all_recipes = list.append(all_recipes, response.results)
        has_more = False
      }
      Error(e) -> {
        // Handle error
        has_more = False
      }
    }
  }

  all_recipes
}
```

### Cache Recipes Locally

```gleam
// Store recipes in PostgreSQL for fast access
pub fn cache_recipes(conn: pog.Connection, recipes: List(Recipe)) -> Result(Nil, Error) {
  // Batch insert all recipes
  case pog.query(
    "INSERT INTO tandoor_recipes (id, name, slug, protein, fat, carbs, servings)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       protein = EXCLUDED.protein,
       fat = EXCLUDED.fat,
       carbs = EXCLUDED.carbs"
  )
  |> pog.execute(conn)
  {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(DatabaseError(e))
  }
}
```

## Create Recipes

### Basic Recipe Creation

```http
POST /api/recipes/
Authorization: Token {TANDOOR_API_TOKEN}
Content-Type: application/json

{
  "name": "Salmon with Roasted Vegetables",
  "description": "Healthy high-protein meal",
  "keywords": ["protein", "omega-3", "vegetables"],
  "prep_time": 10,
  "cook_time": 20,
  "servings": 1,
  "servings_text": "1 plate",
  "steps": [
    {
      "step": 1,
      "instruction": "Preheat oven to 400°F"
    },
    {
      "step": 2,
      "instruction": "Place salmon and vegetables on sheet pan"
    },
    {
      "step": 3,
      "instruction": "Bake for 18-20 minutes"
    }
  ],
  "nutrition": {
    "energy": 420,
    "protein": 40,
    "fat": 25,
    "carbohydrates": 8,
    "fiber": 2,
    "sugar": 1,
    "sodium": 100,
    "cholesterol": 80
  }
}
```

### Batch Create Recipes

```gleam
pub fn batch_create_recipes(
  config: TandoorConfig,
  recipes: List(RecipeInput),
) -> Result(List(Recipe), Error) {
  recipes
  |> list.map(create_recipe(config, _))
  |> result.all
}

fn create_recipe(config: TandoorConfig, input: RecipeInput) -> Result(Recipe, Error) {
  let url = config.base_url <> "/api/recipes/"
  let body = json.encode(input)

  case http_post(url, config.api_token, body) {
    Ok(response) -> Ok(json.decode(response, Recipe))
    Error(e) -> Error(e)
  }
}
```

## Log Food

### Create Food Log Entry from Tandoor Recipe

When logging meals from Tandoor recipes, use the `save_food_log_from_tandoor_recipe` function:

```gleam
import meal_planner/storage/logs

pub type FoodLogInput {
  FoodLogInput(
    recipe_slug: String,        // Tandoor recipe slug
    recipe_name: String,        // Tandoor recipe name
    servings: Float,            // Portion size (e.g., 1.5)
    protein: Float,             // Macros for selected servings
    fat: Float,
    carbs: Float,
    meal_type: String,          // "breakfast", "lunch", "dinner", "snack"
    // Optional micronutrients
    fiber: Option(Float),
    sugar: Option(Float),
    sodium: Option(Float),
    // ... other micronutrients
  )
}

// Save food log from Tandoor recipe
let input = FoodLogInput(
  recipe_slug: "grilled-chicken-breast",
  recipe_name: "Grilled Chicken Breast",
  servings: 1.5,
  protein: 46.5,  // 31 * 1.5
  fat: 5.4,       // 3.6 * 1.5
  carbs: 0.0,     // 0 * 1.5
  meal_type: "lunch",
  fiber: None,
  sugar: None,
  sodium: None,
)

case logs.save_food_log_from_tandoor_recipe(conn, input) {
  Ok(log_id) -> io.println("Logged: " <> log_id)
  Error(e) -> io.println("Error: " <> error.to_string(e))
}
```

### Daily Logging Workflow

```gleam
pub fn log_daily_meal(
  conn: pog.Connection,
  recipe_id: String,
  recipe_name: String,
  servings: Float,
  protein: Float,
  fat: Float,
  carbs: Float,
  meal_type: String,
) -> Result(String, StorageError) {
  let log_input = FoodLogInput(
    recipe_slug: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    protein: protein,
    fat: fat,
    carbs: carbs,
    meal_type: meal_type,
    fiber: None,
    sugar: None,
    sodium: None,
    cholesterol: None,
    vitamin_a: None,
    vitamin_c: None,
    vitamin_d: None,
    vitamin_e: None,
    vitamin_k: None,
    vitamin_b6: None,
    vitamin_b12: None,
    folate: None,
    thiamin: None,
    riboflavin: None,
    niacin: None,
    calcium: None,
    iron: None,
    magnesium: None,
    phosphorus: None,
    potassium: None,
    zinc: None,
  )

  logs.save_food_log_from_tandoor_recipe(conn, log_input)
}
```

## Error Handling

### HTTP Status Codes

| Status | Meaning | Handling |
|--------|---------|----------|
| 200 | Success | Process response normally |
| 400 | Bad Request | Validate input parameters |
| 401 | Unauthorized | Check TANDOOR_API_TOKEN |
| 403 | Forbidden | User lacks permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource |
| 500 | Server Error | Retry with backoff |
| 503 | Service Unavailable | Tandoor is down, retry later |

### Retry Strategy

```gleam
pub fn http_get_with_retry(
  url: String,
  token: String,
  max_retries: Int,
) -> Result(String, Error) {
  retry_with_backoff(
    fn() { http_get(url, token) },
    max_retries,
    1000,  // Initial backoff: 1 second
  )
}

fn retry_with_backoff(
  operation: fn() -> Result(String, Error),
  retries_left: Int,
  backoff_ms: Int,
) -> Result(String, Error) {
  case operation() {
    Ok(result) -> Ok(result)
    Error(e) if retries_left > 0 -> {
      sleep_ms(backoff_ms)
      retry_with_backoff(
        operation,
        retries_left - 1,
        backoff_ms * 2,
      )
    }
    Error(e) -> Error(e)
  }
}
```

### Common Errors

**401 Unauthorized**

```
Cause: Invalid or missing TANDOOR_API_TOKEN
Solution:
  1. Generate new token in Tandoor UI
  2. Set TANDOOR_API_TOKEN environment variable
  3. Restart application
```

**404 Not Found**

```
Cause: Recipe or resource doesn't exist
Solution:
  1. Check recipe ID is correct
  2. Verify recipe wasn't deleted
  3. Refresh recipe cache
```

**409 Conflict**

```
Cause: Duplicate resource (e.g., recipe with same name)
Solution:
  1. Check if resource already exists
  2. Update instead of create if exists
  3. Use unique names for recipes
```

**Connection Timeout**

```
Cause: Request exceeded TANDOOR_CONNECT_TIMEOUT_MS
Solution:
  1. Increase TANDOOR_CONNECT_TIMEOUT_MS
  2. Check network connectivity
  3. Verify Tandoor is running
```

**Request Timeout**

```
Cause: Response took longer than TANDOOR_REQUEST_TIMEOUT_MS
Solution:
  1. Increase TANDOOR_REQUEST_TIMEOUT_MS
  2. Optimize queries (reduce limit, add filters)
  3. Check Tandoor performance
```

## Best Practices

### 1. Caching

Always cache recipes locally for better performance:

```gleam
// Refresh cache every hour
pub const CACHE_TTL_SECONDS = 3600

pub fn sync_recipes_if_needed(
  conn: pog.Connection,
  config: TandoorConfig,
) -> Result(Nil, Error) {
  case should_refresh_cache(conn) {
    True -> {
      let recipes = get_all_recipes(config)?
      cache_recipes(conn, recipes)
    }
    False -> Ok(Nil)
  }
}
```

### 2. Portion Validation

Always validate portion sizes:

```gleam
pub fn validate_servings(servings: Float) -> Result(Nil, Error) {
  case servings {
    s if s <= 0.0 -> Error("Servings must be > 0")
    s if s > 100.0 -> Error("Servings too large (max 100)")
    _ -> Ok(Nil)
  }
}
```

### 3. Macro Calculations

Round macros to reasonable precision:

```gleam
pub fn calculate_macros(
  recipe: Recipe,
  servings: Float,
) -> Macros {
  Macros(
    protein: recipe.protein *. servings |> float.round_to(1),
    fat: recipe.fat *. servings |> float.round_to(1),
    carbs: recipe.carbs *. servings |> float.round_to(1),
  )
}
```

### 4. Batch Operations

Use batch operations for better performance:

```gleam
pub fn batch_log_meals(
  conn: pog.Connection,
  meals: List(MealInput),
) -> Result(List(String), Error) {
  let start_transaction = "BEGIN"
  let end_transaction = "COMMIT"

  try <- result.try(execute(conn, start_transaction))

  let results = meals
    |> list.map(save_food_log_from_tandoor_recipe(conn, _))

  case results |> list.all(result.is_ok) {
    True -> {
      try <- result.try(execute(conn, end_transaction))
      Ok(results |> list.filter_map(result.to_option))
    }
    False -> {
      try <- result.try(execute(conn, "ROLLBACK"))
      Error("Batch insert failed")
    }
  }
}
```

### 5. Denormalization

Store denormalized data for readability:

```gleam
// Include recipe_name in food_log for quick access
pub type FoodLog {
  FoodLog(
    id: String,
    recipe_id: String,
    recipe_name: String,      // Denormalized from Tandoor
    source_type: String,      // "tandoor_recipe"
    source_id: String,        // Recipe slug
    servings: Float,
    macros: Macros,
    meal_type: String,
    logged_at: String,
  )
}
```

## Examples

### Example 1: List Recent Recipes

```gleam
pub fn get_recent_recipes(
  config: TandoorConfig,
  limit: Int,
) -> Result(List(Recipe), Error) {
  let url = config.base_url
    <> "/api/recipes/?limit="
    <> int.to_string(limit)
    <> "&ordering=-created_at"

  case http_get(url, config.api_token) {
    Ok(json_response) ->
      json_response
      |> json.decode(List(Recipe))
      |> result.map_error(fn(e) { ParseError(e) })
    Error(e) -> Error(e)
  }
}
```

### Example 2: Search for Healthy Recipes

```gleam
pub fn search_recipes(
  config: TandoorConfig,
  query: String,
) -> Result(List(Recipe), Error) {
  let url = config.base_url
    <> "/api/recipes/?search="
    <> uri.encode(query)
    <> "&limit=20"

  http_get(url, config.api_token)
  |> result.try(fn(response) {
    json.decode(response, PaginatedRecipes)
    |> result.map(fn(paginated) { paginated.results })
  })
}
```

### Example 3: Create Weekly Meal Plan

```gleam
pub fn create_weekly_meal_plan(
  conn: pog.Connection,
  config: TandoorConfig,
  plan: WeeklyPlanInput,
) -> Result(Nil, Error) {
  plan.meals
  |> list.try_each(fn(meal_input) {
    // Fetch recipe from Tandoor cache
    let recipe = get_cached_recipe(conn, meal_input.recipe_id)?

    // Log the meal
    let log_input = FoodLogInput(
      recipe_slug: recipe.slug,
      recipe_name: recipe.name,
      servings: meal_input.servings,
      protein: recipe.protein *. meal_input.servings,
      fat: recipe.fat *. meal_input.servings,
      carbs: recipe.carbs *. meal_input.servings,
      meal_type: meal_input.meal_type,
      fiber: None,
      sugar: None,
      sodium: None,
      cholesterol: None,
      vitamin_a: None,
      vitamin_c: None,
      vitamin_d: None,
      vitamin_e: None,
      vitamin_k: None,
      vitamin_b6: None,
      vitamin_b12: None,
      folate: None,
      thiamin: None,
      riboflavin: None,
      niacin: None,
      calcium: None,
      iron: None,
      magnesium: None,
      phosphorus: None,
      potassium: None,
      zinc: None,
    )

    logs.save_food_log_from_tandoor_recipe(conn, log_input)
    |> result.map(fn(_) { Nil })
  })
}
```

## See Also

- [API.md](./API.md) - General API documentation
- [examples/tandoor_api_query_example.gleam](../gleam/examples/tandoor_api_query_example.gleam)
- [examples/tandoor_recipe_creation_example.gleam](../gleam/examples/tandoor_recipe_creation_example.gleam)
- [examples/tandoor_food_logging_example.gleam](../gleam/examples/tandoor_food_logging_example.gleam)
