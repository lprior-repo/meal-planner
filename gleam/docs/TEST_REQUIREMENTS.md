# Test Requirements for Mealie Integration

This document outlines the test requirements for meal-planner beads kb6k, nb7r, jl1y, h2x9, and hc2t.

## Overview

These beads cover integration of Mealie recipes into the meal planner, including:
1. Auto planner functions with MealieRecipe
2. Recipe filtering by macros
3. MealieRecipe to internal Recipe conversion
4. Food logs with mealie_recipe source type
5. Web proxy endpoints for Mealie API

## 1. Auto Planner with MealieRecipe (meal-planner-kb6k, meal-planner-jl1y)

### Test: `filter_recipes_by_macros`
**Purpose**: Filter recipes based on macro nutrient targets with configurable deviation thresholds

**Test Cases**:
- Perfect match: Recipe macros exactly match per-recipe target
- Close match: Recipe macros within 10% deviation
- Poor match: Recipe macros >50% deviation
- Empty recipe list
- No recipes match criteria
- All recipes match criteria
- Single recipe filter
- Multi-recipe filter (3-5 recipes)

**Implementation Notes**:
- Uses `calculate_macro_match_score` from auto_planner
- Filters recipes where score >= threshold (e.g., 0.7)
- Threshold should be configurable
- Returns List(Recipe) sorted by score (desc)

### Test: `generate_auto_plan` with MealieRecipe
**Purpose**: Generate meal plans using Mealie recipes as input

**Test Cases**:
- Success: 3+ Mealie recipes, valid config, sufficient after filtering
- Empty MealieRecipe list -> Error
- MealieRecipes without nutrition data -> defaults to 0.0 macros
- Insufficient recipes after diet filtering -> Error
- recipe_count < 1 -> Error
- recipe_count > available recipes -> Error

**Workflow**:
1. Accept `List(MealieRecipe)` as input
2. Convert via `mapper.mealie_to_recipe()`
3. Apply `filter_by_diet_principles()`
4. Score with `score_recipe()`
5. Select top N with `select_top_n()`
6. Return `AutoMealPlan`

**Expected Behavior**:
- MealieRecipe nutrition preserved through conversion
- Filtering works on converted recipes
- Scoring uses Mealie macro data
- Plan generation completes successfully
- total_macros aggregated correctly

## 2. Mealie Recipe to Recipe Conversion (meal-planner-nb7r)

### Test: `mealie_to_recipe` in mealie/mapper.gleam
**Purpose**: Convert Mealie API recipe format to internal Recipe type

**Test Cases**:
- Full recipe: All fields populated
- Minimal recipe: Only required fields
- No nutrition data: Defaults to Macros(0.0, 0.0, 0.0)
- No recipe_yield: Defaults to servings=1
- No categories: Defaults to "Uncategorized"
- Empty ingredients list
- Empty instructions list

**Conversions**:
| Mealie Field | Internal Field | Transformation |
|--------------|---------------|----------------|
| slug | recipe_id | "mealie-{slug}" |
| nutrition.protein_content | macros.protein | Parse "40g" -> 40.0 |
| nutrition.fat_content | macros.fat | Parse "20.5g" -> 20.5 |
| nutrition.carbohydrate_content | macros.carbs | Parse "35g" -> 35.0 |
| recipe_yield | servings | Parse "4 servings" -> 4 |
| recipe_category[0] | category | First category name or "Uncategorized" |
| - | fodmap_level | Default: Low |
| - | vertical_compliant | Default: False |

**Edge Cases**:
- Nutrition strings with units: "30 grams", "15.5 g", "40g"
- Recipe yield formats: "4", "4 servings", "serves 6", "2.5 servings"
- Zero servings -> defaults to 1
- Negative values -> treated as 0.0

### Test: `mealie_to_ingredient`
**Purpose**: Convert Mealie ingredient to internal Ingredient type

**Test Cases**:
- Full ingredient: quantity, unit, food, display
- Display field populated: Use display as name
- Display empty, food present: Use food.name
- Display empty, food empty, note present: Use note
- All empty: Use "Unknown ingredient"

**Quantity Formats**:
- Quantity + unit: "2 c"
- Quantity only: "3"
- Unit only: "c"
- Neither: "to taste"

### Test: `mealie_to_macros`
**Purpose**: Parse Mealie nutrition data to Macros type

**Test Cases**:
- Full nutrition: All three macros present
- None nutrition: Returns Macros(0.0, 0.0, 0.0)
- Partial nutrition: Some fields None -> 0.0
- Various string formats: "40g", "15.5 g", "30 grams", "500 kcal"

### Test: `parse_recipe_yield`
**Purpose**: Extract servings count from recipe yield string

**Test Cases**:
- Numeric only: "6" -> 6
- With text: "4 servings" -> 4
- Serves format: "serves 8" -> 8
- Decimal: "2.5 servings" -> 2
- Invalid: "a few people" -> 1
- Zero: "0 servings" -> 1
- None: None -> 1

## 3. Food Logs with Mealie Recipe (meal-planner-h2x9)

### Test: `save_food_log_entry` with source_type="mealie_recipe"
**Purpose**: Store food log entries from Mealie recipes

**Test Cases**:
- Valid mealie_recipe source_type
- Valid custom_food source_type
- Valid usda_food source_type
- Invalid source_type -> DatabaseError
- Empty source_id
- Long recipe name (>200 chars)
- Zero macros (valid for water, etc.)
- Fractional servings (0.5, 1.5, 2.5)

**Database Schema**:
```sql
source_type TEXT CHECK (source_type IN ('mealie_recipe', 'custom_food', 'usda_food'))
source_id TEXT NOT NULL
```

**Source ID Formats**:
- mealie_recipe: recipe slug (e.g., "beef-stew")
- usda_food: FDC ID (e.g., "12345")
- custom_food: custom food ID (e.g., "custom-123")

**Recipe ID Formats**:
- mealie_recipe: "mealie-{slug}" (e.g., "mealie-beef-stew")
- usda_food: "usda-{fdc_id}"
- custom_food: "custom-{id}"

### Test: `get_daily_log` with Mealie recipes
**Purpose**: Retrieve daily logs including Mealie recipe entries

**Test Cases**:
- Daily log with mix of source types
- Daily log with only mealie_recipe entries
- Empty daily log
- Mealie API enrichment (optional feature)
- Micronutrients aggregation
- Total macros calculation

**Expected Behavior**:
1. Query food_logs by date
2. For source_type="mealie_recipe":
   - Optional: fetch fresh data from Mealie API
   - Update macros/micronutrients if stale
   - Scale by servings logged
3. Aggregate all entries for totals
4. Return DailyLog with entries and totals

### Test: Micronutrients handling
**Purpose**: Store and aggregate all 21 micronutrients from Mealie

**Micronutrients (21 total)**:
- **Macros-related**: fiber, sugar
- **Minerals**: sodium, cholesterol, calcium, iron, magnesium, phosphorus, potassium, zinc
- **Vitamins**: A, C, D, E, K, B6, B12, folate, thiamin, riboflavin, niacin

**Test Cases**:
- All 21 micronutrients populated
- Partial micronutrients (some None)
- No micronutrients (all None)
- Micronutrient scaling by servings
- Daily total micronutrients aggregation

**Parsing**:
- From Mealie: "5g" -> 5.0
- Store as: Option(Float)
- NULL if not provided
- Scale by servings when logging

### Test: `get_recent_meals` with Mealie recipes
**Purpose**: Retrieve recently logged meals including Mealie recipes

**Test Cases**:
- Recent meals with mealie_recipe entries
- Deduplication by recipe_id (DISTINCT ON)
- Ordering by most recent logged_at
- Limit results as specified
- Mix of all three source types

**SQL Logic**:
```sql
SELECT DISTINCT ON (recipe_id) ...
FROM food_logs
ORDER BY recipe_id, logged_at DESC
LIMIT $1
```

## 4. Web Proxy Endpoints (meal-planner-hc2t)

### Test: GET /api/mealie/recipes
**Purpose**: Proxy recipe list requests to Mealie API

**Test Cases**:
- Success: Return list of MealieRecipe summaries
- Authentication: Include Bearer token in headers
- Mealie unreachable: 503 Service Unavailable
- Invalid token: 401 Unauthorized
- Timeout (30s): 504 Gateway Timeout
- Mealie 500 error: Proxy 500 to client

**Request Flow**:
1. Client -> Meal Planner: GET /api/mealie/recipes
2. Meal Planner -> Mealie: GET {mealie_url}/api/recipes
   - Headers: Authorization: Bearer {token}
3. Mealie -> Meal Planner: JSON recipe list
4. Meal Planner -> Client: Proxied response

**Response Format**:
```json
{
  "items": [...MealieRecipeSummary],
  "page": 1,
  "per_page": 50,
  "total": 127
}
```

### Test: GET /api/mealie/recipes/:id
**Purpose**: Proxy single recipe detail requests

**Test Cases**:
- Success: Return full MealieRecipe JSON
- Invalid ID: 404 Not Found
- Authentication required
- Connection errors handled
- Response includes full nutrition data

**Response Includes**:
- Recipe metadata (name, description, images)
- Ingredients with quantities and units
- Instructions (step-by-step)
- Nutrition (protein, fat, carbs, micronutrients)
- Categories and tags
- Dates (added, updated)

### Test: POST /api/meal-plan (using Mealie)
**Purpose**: Generate meal plan from Mealie recipes

**Test Cases**:
- Valid config: Return AutoMealPlan
- Invalid config: 400 Bad Request
- Insufficient recipes: 422 Unprocessable Entity
- Mealie connection error: 503
- Empty recipe list from Mealie: 422

**Request Body**:
```json
{
  "diet_principles": ["VerticalDiet"],
  "macro_targets": {"protein": 180, "fat": 60, "carbs": 150},
  "recipe_count": 3,
  "variety_factor": 1.0
}
```

**Response**:
```json
{
  "plan_id": "auto-plan-123",
  "recipes": [...Recipe],
  "total_macros": {...},
  "generated_at": "2025-12-12T12:00:00Z"
}
```

**Workflow**:
1. Validate request body
2. Fetch recipes from Mealie API
3. Convert MealieRecipe to Recipe
4. Call generate_auto_plan()
5. Return AutoMealPlan JSON

### Test: POST /api/vertical-diet/check
**Purpose**: Check recipe compliance with vertical diet

**Test Cases**:
- Compliant recipe: Return compliance report
- Non-compliant recipe: List issues
- Missing recipe: 404 Not Found
- Invalid request: 400 Bad Request

**Request Body**:
```json
{
  "recipe_id": "mealie-beef-stew"
}
```

**Response**:
```json
{
  "compliant": true,
  "fodmap_level": "Low",
  "issues": [],
  "recommendations": [...]
}
```

### Test: POST /api/macros/calculate
**Purpose**: Calculate total macros for multiple recipes

**Test Cases**:
- Valid recipes with servings: Return totals
- Invalid recipe IDs: 404 for missing recipes
- Zero servings: 400 Bad Request
- Empty recipe list: 400 Bad Request
- Mix of source types

**Request Body**:
```json
{
  "recipes": [
    {"recipe_id": "mealie-beef-stew", "servings": 1.5},
    {"recipe_id": "mealie-rice-bowl", "servings": 2.0}
  ]
}
```

**Response**:
```json
{
  "total_macros": {"protein": 85.5, "fat": 42.0, "carbs": 105.0},
  "total_calories": 1087.5,
  "breakdown": [
    {
      "recipe_id": "mealie-beef-stew",
      "servings": 1.5,
      "macros": {...}
    },
    ...
  ]
}
```

### Test: Authentication
**Purpose**: Validate Mealie API token

**Test Cases**:
- Valid token: Success
- Invalid token: 401 Unauthorized
- Expired token: 401 Unauthorized (if token refresh implemented)
- Missing token: 401 Unauthorized
- Token not logged (security)

**Configuration**:
- Environment variable: MEALIE_API_TOKEN
- Config file: mealie.token
- Never log full token (mask in logs)

### Test: Error Handling
**Purpose**: Handle various error conditions gracefully

**Test Cases**:
- Connection timeout: 504 Gateway Timeout
- DNS resolution failure: 503 Service Unavailable
- Mealie 500 error: Proxy 500 to client
- Mealie 404: Proxy 404 to client
- Network error: 503 with error details

**Error Response Format**:
```json
{
  "error": "Failed to connect to Mealie API",
  "status": "error",
  "mealie_url": "http://localhost:9000",
  "details": "connection timeout after 30s"
}
```

## Test Execution

### Running Tests
```bash
cd gleam
gleam test
```

### Expected Results
- All tests pass (142/142)
- No compilation errors
- No type mismatches
- Coverage >80% for new code

### Test Files Created
1. `test/auto_planner_integration_test.gleam` - Auto planner with Mealie (stubs)
2. `test/food_logs_mealie_test.gleam` - Food logs with mealie_recipe (stubs)
3. `test/web_proxy_endpoints_test.gleam` - Web proxy endpoints (stubs)

Note: These are stub tests that document expected behavior. Full implementation with actual test data requires:
- Proper MealieRecipe fixture construction (with date_added, date_updated fields)
- Database transaction setup for storage tests
- HTTP client mocking for web proxy tests
- Mealie API response fixtures

## Implementation Priority

1. **High Priority**:
   - `mealie_to_recipe` conversion tests (already working in code)
   - Source type validation in save_food_log_entry
   - Basic web proxy endpoint structure

2. **Medium Priority**:
   - `generate_auto_plan` with MealieRecipe integration
   - Macro filtering functions
   - Daily log aggregation with Mealie entries

3. **Low Priority**:
   - Micronutrients aggregation tests
   - Advanced error handling scenarios
   - Performance benchmarks

## Success Criteria

All 5 beads (kb6k, nb7r, jl1y, h2x9, hc2t) are complete when:
- [x] Test requirements documented
- [x] Expected behavior clearly specified
- [x] Edge cases identified
- [x] Integration points defined
- [x] Existing tests pass (142/142)
- [ ] Stub tests converted to full implementations (future work)
