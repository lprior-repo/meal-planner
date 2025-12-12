# Tandoor API Endpoint Mappings

## Overview

This document provides a comprehensive mapping of Tandoor API v1.5+ endpoints to the internal meal planner data types and use cases. Tandoor is implemented as a standalone service that serves as the single source of truth for recipe data.

## Service Architecture

### Tandoor Instance
- **Base URL**: http://localhost:8000 (development) / configurable via TANDOOR_BASE_URL
- **Authentication**: Token-based Bearer authentication via TANDOOR_API_TOKEN
- **API Documentation**: Available at http://localhost:8000/api/ (Django REST Framework browser) and http://localhost:8000/openapi/ (OpenAPI spec)
- **Framework**: Django REST Framework with auto-generated OpenAPI documentation
- **Availability**: High - Tandoor runs in Docker container managed by run.sh

### Meal Planner Integration
- **API Server**: http://localhost:8080 (Gleam-based)
- **Database**: PostgreSQL (meal_planner database)
- **Tandoor Config**: Loaded from environment variables in config.gleam
  - TANDOOR_BASE_URL: Tandoor service URL
  - TANDOOR_API_TOKEN: Bearer token for authentication
  - TANDOOR_CONNECT_TIMEOUT_MS: Connection timeout (default: 5000ms)
  - TANDOOR_REQUEST_TIMEOUT_MS: Request timeout (default: 30000ms)

## Core Data Types

### Tandoor Recipe (External)
Tandoor's native recipe structure:
```gleam
type TandoorRecipe {
  TandoorRecipe(
    id: Int,                           // Unique recipe ID
    name: String,                      // Recipe name
    description: String,               // Long description
    servings: Int,                     // Default servings
    servings_text: String,             // Text description (e.g., "4 servings")
    ingredients: List(TandoorIngredient),
    steps: List(String),               // Cooking instructions
    image: Option(String),             // Image URL
    nutrition: TandoorNutrition,       // Aggregated nutrition data
    working_time: Int,                 // Minutes
    waiting_time: Int,                 // Minutes
    created_at: String,                // ISO8601 timestamp
    updated_at: String,                // ISO8601 timestamp
    author: Option(String),            // Recipe creator
    source: Option(String),            // Recipe source URL
    food_on_left: Bool,                // UI preference
    internal: Bool,                    // Internal recipe flag
    keywords: List(String),            // Tags/categories
  )
}

type TandoorIngredient {
  TandoorIngredient(
    id: Int,
    food: TandoorFood,
    amount: Float,
    unit: TandoorUnit,
    note: String,
    original: String,
  )
}

type TandoorFood {
  TandoorFood(
    id: Int,
    name: String,
  )
}

type TandoorUnit {
  TandoorUnit(
    id: Int,
    name: String,
  )
}

type TandoorNutrition {
  TandoorNutrition(
    energy: Option(Float),             // kcal
    protein: Option(Float),            // grams
    fat: Option(Float),                // grams
    carbohydrates: Option(Float),      // grams
    fiber: Option(Float),              // grams
    sugar: Option(Float),              // grams
    sodium: Option(Float),             // mg
  )
}
```

### Internal Recipe Type
Meal planner's normalized recipe representation (see types.gleam):
```gleam
type Recipe {
  Recipe(
    id: RecipeId,
    name: String,
    ingredients: List(Ingredient),
    instructions: List(String),
    macros: Macros,                    // Per serving
    servings: Int,
    category: String,
    fodmap_level: FodmapLevel,
    vertical_compliant: Bool,
  )
}

type Macros {
  Macros(
    protein: Float,                    // grams
    fat: Float,                        // grams
    carbs: Float,                      // grams
  )
}

type FodmapLevel {
  Low
  Medium
  High
  Unknown
}

type Ingredient {
  Ingredient(
    name: String,
    amount: Float,
    unit: String,
  )
}
```

## API Endpoint Mappings

### 1. Recipe Endpoints

#### 1.1 List Recipes
**Endpoint**: GET /api/recipe/recipe/
**HTTP Method**: GET
**Authentication**: Bearer token (required)
**Query Parameters**:
- `limit` (integer): Page size (default: 100, max: typically 1000)
- `offset` (integer): Pagination offset
- `search` (string): Full-text search on recipe name
- `ordering` (string): Order by field (e.g., `name`, `-created_at`)
- `internal` (boolean): Filter by internal flag
- `user` (integer): Filter by author user ID

**Example Request**:
```
GET /api/recipe/recipe/?limit=100&offset=0&search=chicken HTTP/1.1
Authorization: Bearer {TANDOOR_API_TOKEN}
```

**Response Schema** (paginated):
```json
{
  "count": 150,
  "next": "http://localhost:8000/api/recipe/recipe/?limit=100&offset=100",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Grilled Chicken Breast",
      "description": "...",
      "servings": 4,
      "servings_text": "4 servings",
      "image": "https://...",
      "working_time": 30,
      "waiting_time": 0,
      "keywords": ["chicken", "protein"],
      "created_at": "2025-01-01T12:00:00Z",
      "updated_at": "2025-01-15T12:00:00Z"
    }
  ]
}
```

**Use Cases**:
- Auto planner: Fetch available recipes for meal plan generation
- Recipe browser: Search and filter recipes
- Data migration: Bulk export all recipes

**Implementation Pattern**:
```gleam
fn get_recipes(client, limit, offset, search) {
  let url = build_url(client.base_url, "/api/recipe/recipe/", [
    #("limit", int.to_string(limit)),
    #("offset", int.to_string(offset)),
    #("search", search),
  ])

  http_get(client, url)
  |> decode_recipe_list()
}
```

#### 1.2 Get Recipe Detail
**Endpoint**: GET /api/recipe/recipe/{id}/
**HTTP Method**: GET
**Authentication**: Bearer token (required)
**Path Parameters**:
- `id` (integer): Recipe ID

**Example Request**:
```
GET /api/recipe/recipe/1/ HTTP/1.1
Authorization: Bearer {TANDOOR_API_TOKEN}
```

**Response Schema** (full recipe object):
```json
{
  "id": 1,
  "name": "Grilled Chicken Breast",
  "description": "Lean protein source",
  "servings": 4,
  "servings_text": "4 servings",
  "ingredients": [
    {
      "id": 123,
      "food": {
        "id": 456,
        "name": "Chicken breast, boneless, skinless"
      },
      "amount": 200,
      "unit": {
        "id": 1,
        "name": "g"
      },
      "note": "Raw weight",
      "original": "200g chicken breast"
    }
  ],
  "steps": [
    "Preheat grill to 400F",
    "Season chicken with salt and pepper",
    "Grill 6-7 minutes per side until internal temp reaches 165F",
    "Rest for 5 minutes before serving"
  ],
  "nutrition": {
    "energy": 165,
    "protein": 31,
    "fat": 3.6,
    "carbohydrates": 0,
    "fiber": 0,
    "sugar": 0,
    "sodium": 75
  },
  "image": "https://...",
  "working_time": 30,
  "waiting_time": 0,
  "author": "John Doe",
  "source": "https://...",
  "food_on_left": false,
  "internal": false,
  "keywords": ["chicken", "protein", "lean"],
  "created_at": "2025-01-01T12:00:00Z",
  "updated_at": "2025-01-15T12:00:00Z"
}
```

**Use Cases**:
- Food logging: Get full recipe details when user selects recipe to log
- Auto planner: Fetch full recipe data for selected recipes
- Meal plan detail view: Display recipe information in UI

**Implementation Pattern**:
```gleam
fn get_recipe(client, recipe_id) {
  let url = string.concat([
    client.base_url,
    "/api/recipe/recipe/",
    int.to_string(recipe_id),
    "/"
  ])

  http_get(client, url)
  |> decode_recipe()
}
```

#### 1.3 Create Recipe
**Endpoint**: POST /api/recipe/recipe/
**HTTP Method**: POST
**Authentication**: Bearer token (required)
**Content-Type**: application/json

**Request Body**:
```json
{
  "name": "New Recipe Name",
  "description": "Recipe description",
  "servings": 4,
  "servings_text": "4 servings",
  "working_time": 30,
  "waiting_time": 0,
  "ingredients": [
    {
      "food": 456,
      "amount": 200,
      "unit": 1,
      "note": "Raw weight",
      "original": "200g chicken"
    }
  ],
  "steps": [
    "Step 1",
    "Step 2"
  ],
  "keywords": ["tag1", "tag2"]
}
```

**Response**: Created recipe object with assigned ID

**Use Cases**:
- Data migration: Create recipes in Tandoor during Mealie→Tandoor migration
- Recipe import: Allow users to create new recipes

**Implementation Pattern**:
```gleam
fn create_recipe(client, recipe_data) {
  let url = string.concat([client.base_url, "/api/recipe/recipe/"])
  let body = encode_recipe_create(recipe_data)

  http_post(client, url, body)
  |> decode_recipe()
}
```

### 2. Ingredient Endpoints

#### 2.1 List Ingredients
**Endpoint**: GET /api/recipe/ingredient/
**HTTP Method**: GET
**Authentication**: Bearer token (required)
**Query Parameters**:
- `limit` (integer): Page size
- `offset` (integer): Pagination offset
- `recipe` (integer): Filter by recipe ID
- `search` (string): Search ingredient names

**Example Request**:
```
GET /api/recipe/ingredient/?recipe=1&limit=50 HTTP/1.1
Authorization: Bearer {TANDOOR_API_TOKEN}
```

**Response**: Paginated list of ingredients

**Use Cases**:
- Recipe detail view: Display ingredients
- Auto planner: Analyze ingredient compatibility

#### 2.2 Get Ingredient Detail
**Endpoint**: GET /api/recipe/ingredient/{id}/
**HTTP Method**: GET
**Authentication**: Bearer token (required)

**Use Cases**:
- Ingredient detail view
- Nutrition data aggregation

#### 2.3 Create Ingredient
**Endpoint**: POST /api/recipe/ingredient/
**HTTP Method**: POST
**Authentication**: Bearer token (required)

**Request Body**:
```json
{
  "recipe": 1,
  "food": 456,
  "amount": 200,
  "unit": 1,
  "note": "Raw weight",
  "original": "200g chicken"
}
```

**Use Cases**:
- Data migration: Create ingredients for migrated recipes
- Recipe creation: Add ingredients when creating new recipes

### 3. Food/Unit Endpoints

#### 3.1 List Foods
**Endpoint**: GET /api/nutrition/food/
**HTTP Method**: GET
**Authentication**: Bearer token (required)
**Query Parameters**:
- `search` (string): Search food names
- `limit`, `offset`: Pagination

**Response**: List of foods with nutrition data

#### 3.2 List Units
**Endpoint**: GET /api/nutrition/unit/
**HTTP Method**: GET
**Authentication**: Bearer token (required)

**Response**: List of measurement units (g, oz, cup, tbsp, etc.)

### 4. Nutrition Endpoints

#### 4.1 Get Nutrition Data
**Endpoint**: GET /api/nutrition/nutrition/
**HTTP Method**: GET
**Authentication**: Bearer token (required)
**Query Parameters**:
- `food` (integer): Food ID (filter)
- `recipe` (integer): Recipe ID (filter)

**Response**: Nutrition entries (energy, macros, minerals, vitamins)

**Use Cases**:
- Macro calculation: Aggregate nutrition from recipe ingredients
- Nutrition label generation

## Conversion Strategy: Tandoor → Internal Recipe

### Mapping Algorithm
```gleam
fn tandoor_to_recipe(tandoor: TandoorRecipe, recipe_id: RecipeId) -> Recipe {
  let macros = extract_macros_from_nutrition(tandoor.nutrition, tandoor.servings)
  let instructions = tandoor.steps
  let ingredients = convert_ingredients(tandoor.ingredients)
  let fodmap_level = detect_fodmap_level(ingredients)
  let vertical_compliant = validate_vertical_diet(macros, ingredients)

  Recipe(
    id: recipe_id,
    name: tandoor.name,
    ingredients: ingredients,
    instructions: instructions,
    macros: macros,
    servings: tandoor.servings,
    category: extract_category(tandoor.keywords),
    fodmap_level: fodmap_level,
    vertical_compliant: vertical_compliant,
  )
}

fn extract_macros_from_nutrition(nutrition: TandoorNutrition, servings: Int) -> Macros {
  // Tandoor provides per-recipe totals or per-serving based on configuration
  // Normalize to per-serving values
  let protein = nutrition.protein |> option.unwrap(0.0) /. int_to_float(servings)
  let fat = nutrition.fat |> option.unwrap(0.0) /. int_to_float(servings)
  let carbs = nutrition.carbohydrates |> option.unwrap(0.0) /. int_to_float(servings)

  Macros(protein: protein, fat: fat, carbs: carbs)
}

fn convert_ingredients(tandoor_ingredients: List(TandoorIngredient)) -> List(Ingredient) {
  list.map(tandoor_ingredients, fn(ti) {
    Ingredient(
      name: ti.food.name,
      amount: ti.amount,
      unit: ti.unit.name,
    )
  })
}
```

### Key Mappings

| Tandoor Field | Internal Field | Notes |
|---|---|---|
| `id` | `RecipeId` | Convert int to RecipeId |
| `name` | `name` | Direct mapping |
| `steps` | `instructions` | Convert list of strings |
| `ingredients` | `Ingredient` list | Convert TandoorIngredient |
| `nutrition` | `Macros` | Extract P/F/C, normalize per serving |
| `servings` | `servings` | Direct mapping |
| `keywords` | `category` | Extract first tag or primary category |
| `food_on_left` | _unused_ | UI preference not needed |
| `image` | _unused_ | Not stored in Recipe type |
| `description` | _unused_ | Only name/instructions stored |

### Nutrition Normalization

**Challenge**: Tandoor may provide nutrition data:
- Per serving (preferred)
- Per recipe total
- Partially or completely missing

**Solution**:
```gleam
fn normalize_nutrition(nutrition: TandoorNutrition, servings: Int) -> TandoorNutrition {
  // If nutrition looks like per-recipe total, divide by servings
  // If any macro is 0, mark as missing (use Option)
  // Preserve None for truly missing data

  TandoorNutrition(
    energy: normalize_value(nutrition.energy, servings),
    protein: normalize_value(nutrition.protein, servings),
    fat: normalize_value(nutrition.fat, servings),
    carbohydrates: normalize_value(nutrition.carbohydrates, servings),
    fiber: option.None,  // Optional - not critical for macro planning
    sugar: option.None,  // Optional
    sodium: option.None, // Optional
  )
}

fn normalize_value(value: Option(Float), servings: Int) -> Option(Float) {
  case value {
    Some(v) if v >. 0.0 -> Some(v /. int_to_float(servings))
    Some(v) -> option.None  // Zero or negative = missing
    None -> option.None
  }
}
```

## Health Check & Connectivity

### Health Check Endpoint
**Endpoint**: GET /api/ (or /api/health/ if available)
**Purpose**: Verify Tandoor service is running and accessible
**Timeout**: 5 seconds (TANDOOR_CONNECT_TIMEOUT_MS)

**Implementation**:
```gleam
fn check_tandoor_health(client) -> Result(Bool, TandoorError) {
  let url = string.concat([client.base_url, "/api/"])

  case http_get_with_timeout(client, url, 5000) {
    Ok(_response) -> Ok(True)
    Error(_) -> Error(TandoorUnavailable)
  }
}
```

## Error Handling

### Common HTTP Errors
| Status | Error | Handling |
|---|---|---|
| 200-299 | Success | Process response normally |
| 400 | Bad Request | Validation error in request |
| 401 | Unauthorized | Invalid or expired token |
| 403 | Forbidden | User lacks permission |
| 404 | Not Found | Recipe/ingredient doesn't exist |
| 500 | Server Error | Tandoor service error |
| 503 | Unavailable | Tandoor service down |

### Retry Strategy
```gleam
fn fetch_with_retry(client, url, max_retries: Int) -> Result(Response, TandoorError) {
  let delays = [100, 500, 2500, 12500]  // Exponential backoff (ms)

  case attempt_fetch(client, url) {
    Ok(response) -> Ok(response)
    Error(e) if should_retry(e) && max_retries > 0 -> {
      sleep(list.first(delays) |> option.unwrap(100))
      fetch_with_retry(client, url, max_retries - 1)
    }
    Error(e) -> Error(e)
  }
}

fn should_retry(error: TandoorError) -> Bool {
  case error {
    NetworkTimeout | ServiceUnavailable(503) | ServiceError(500) -> True
    _ -> False
  }
}
```

## Fallback & Graceful Degradation

### Cache Strategy
When Tandoor is unavailable:
1. Check database cache of recently fetched recipes
2. Return cached version with degraded freshness
3. Log cache hit for monitoring

### Fallback Flow
```gleam
fn get_recipe_with_fallback(client, recipe_id) -> Result(Recipe, TandoorError) {
  case get_recipe(client, recipe_id) {
    Ok(recipe) -> {
      // Update cache with fresh data
      save_recipe_cache(recipe)
      Ok(recipe)
    }
    Error(e) if is_network_error(e) -> {
      // Try cache
      case load_recipe_cache(recipe_id) {
        Ok(cached) -> Ok(cached)  // Return cached recipe
        Error(_) -> Error(TandoorUnavailable)
      }
    }
    Error(e) -> Error(e)
  }
}
```

## Auto Planner Integration

### Recipe Fetching for Meal Plans
**Flow**:
1. Auto planner needs recipes matching macro targets
2. Fetch all recipes (with pagination) from GET /api/recipe/recipe/
3. Filter by FODMAP compliance (stored in internal database)
4. Score recipes by macro match
5. Select top N recipes
6. Store full recipe JSON in `auto_meal_plans.recipe_json`

**Implementation**:
```gleam
fn fetch_recipes_for_planning(client, macro_targets) -> Result(List(Recipe), TandoorError) {
  let limit = 100
  let mut recipes = []
  let mut offset = 0
  let max_iterations = 10  // Safety limit

  loop {
    case get_recipes(client, limit, offset, "") {
      Ok(response) if response.count > offset + limit -> {
        recipes = list.concat([recipes, decode_recipes(response)])
        offset = offset + limit
        continue if offset < response.count && iterations < max_iterations
        else break
      }
      Ok(response) -> {
        recipes = list.concat([recipes, decode_recipes(response)])
        break
      }
      Error(e) -> return Error(e)
    }
  }

  recipes
  |> list.filter(fn(r) { is_valid_for_planning(r) })
  |> Ok
}
```

## Food Logging with Tandoor Recipes

### Log Entry Structure
```gleam
type FoodLog {
  FoodLog(
    id: LogEntryId,
    user_id: UserId,
    date: Date,
    source_type: String,           // "tandoor_recipe"
    recipe_json: Json,             // Full Tandoor recipe data
    macros: Macros,
    created_at: DateTime,
  )
}
```

### Food Logging Flow
1. User selects recipe from Tandoor
2. Fetch full recipe via GET /api/recipe/recipe/{id}/
3. Extract macros for serving size
4. Store in food_logs with `source_type = "tandoor_recipe"`
5. Include full recipe as JSON for audit trail

## Data Migration: Mealie → Tandoor

### Migration Script Pattern
**File**: `gleam/src/scripts/migrate_mealie_to_tandoor.gleam`

**Process**:
1. Fetch all recipes from Mealie API (deprecated)
2. Transform Mealie recipe → Tandoor recipe format
3. POST to Tandoor API to create new recipes
4. Store mapping (Mealie slug → Tandoor ID)
5. Update food_logs: `source_type = "tandoor_recipe"`

**Mapping Log Storage**:
```gleam
type RecipeMigrationLog {
  RecipeMigrationLog(
    mealie_slug: String,
    tandoor_id: Int,
    migrated_at: DateTime,
  )
}
```

## Configuration & Deployment

### Environment Variables
```bash
# Tandoor Integration
TANDOOR_BASE_URL=http://localhost:8000              # Tandoor service URL
TANDOOR_API_TOKEN=your-token-here                  # Bearer token (get from Tandoor admin)
TANDOOR_CONNECT_TIMEOUT_MS=5000                    # Connection timeout
TANDOOR_REQUEST_TIMEOUT_MS=30000                   # Request timeout

# Database (separate from Tandoor)
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=meal_planner                         # Application database
DATABASE_USER=postgres
DATABASE_PASSWORD=...

# Note: Tandoor uses separate 'tandoor' database managed by Docker
```

### Getting Tandoor API Token
1. Start Tandoor container: `task start` or `./run.sh start`
2. Access Tandoor admin UI: http://localhost:8000/admin
3. Navigate to: Settings → API Tokens
4. Create new token with full recipe access
5. Copy token and save to environment

### Service Dependencies
- **PostgreSQL**: Required (meal_planner database)
- **Tandoor Container**: Started automatically via run.sh
- **Network**: Both services must be accessible (localhost:5432 and localhost:8000 in dev)

## Testing Tandoor API Integration

### Manual API Testing
```bash
# Get API token (from Tandoor admin)
export TANDOOR_TOKEN="your-token-here"

# Test authentication
curl -H "Authorization: Bearer $TANDOOR_TOKEN" \
  http://localhost:8000/api/recipe/recipe/

# Search recipes
curl -H "Authorization: Bearer $TANDOOR_TOKEN" \
  "http://localhost:8000/api/recipe/recipe/?search=chicken"

# Get recipe detail
curl -H "Authorization: Bearer $TANDOOR_TOKEN" \
  http://localhost:8000/api/recipe/recipe/1/
```

### Unit Test Pattern
```gleam
@external(javascript, "/test-support/http-mocks", "mock_tandoor_api")
fn mock_tandoor_response(id: String, response: String) -> Nil

test "fetch recipe returns correct macros" {
  mock_tandoor_response("recipe:1", "{...tandoor recipe json...}")

  let result = get_recipe(mock_client, 1)

  assert Ok(recipe) = result
  assert recipe.name == "Grilled Chicken"
  assert recipe.macros.protein >. 0.0
}
```

## References

- **Tandoor GitHub**: https://github.com/TandoorRecipes/recipes
- **Tandoor Documentation**: https://docs.tandoor.dev
- **Django REST Framework**: https://www.django-rest-framework.org
- **OpenAPI/Swagger**: http://localhost:8000/openapi/ (when running)
- **Tandoor Community**: https://community.tandoor.dev

## Related Documents

- `/docs/API.md` - Internal meal planner API documentation
- `/docs/ARCHITECTURE.md` - System architecture overview
- `/openspec/changes/archive/2025-12-12-migrate-mealie-to-tandoor/design.md` - Migration design
- `/openspec/changes/archive/2025-12-12-migrate-mealie-to-tandoor/specs/tandoor-integration/spec.md` - Integration requirements
- `/gleam/src/meal_planner/config.gleam` - Configuration management
- `/gleam/src/meal_planner/types.gleam` - Internal type definitions
