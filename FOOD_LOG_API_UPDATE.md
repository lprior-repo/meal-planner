# Food Log API Update - Tandoor Recipe Slug Support

## Task: meal-planner-5qes
Update food log API to accept Tandoor recipe slugs

## Changes Made

### 1. Updated Source Type Validation in `storage/logs.gleam`
- The existing validation function already supports 'tandoor_recipe' source type
- Database constraint was updated in migration 022 to support 'tandoor_recipe'
- All legacy 'recipe' entries were migrated to 'tandoor_recipe' in the database

### 2. Added `FoodLogInput` Type in `storage/logs.gleam`
A new public type for accepting food log entries via API:
```gleam
pub type FoodLogInput {
  FoodLogInput(
    date: String,                      // ISO 8601 format (YYYY-MM-DD)
    recipe_slug: String,               // Tandoor recipe slug (e.g., "chicken-stir-fry")
    recipe_name: String,               // Human-readable recipe name
    servings: Float,                   // Number of servings
    protein: Float,                    // Grams of protein
    fat: Float,                        // Grams of fat
    carbs: Float,                      // Grams of carbohydrates
    meal_type: String,                 // One of: breakfast, lunch, dinner, snack
    // Optional micronutrients
    fiber: Option(Float),
    sugar: Option(Float),
    sodium: Option(Float),
    cholesterol: Option(Float),
    vitamin_a: Option(Float),
    vitamin_c: Option(Float),
    vitamin_d: Option(Float),
    vitamin_e: Option(Float),
    vitamin_k: Option(Float),
    vitamin_b6: Option(Float),
    vitamin_b12: Option(Float),
    folate: Option(Float),
    thiamin: Option(Float),
    riboflavin: Option(Float),
    niacin: Option(Float),
    calcium: Option(Float),
    iron: Option(Float),
    magnesium: Option(Float),
    phosphorus: Option(Float),
    potassium: Option(Float),
    zinc: Option(Float),
  )
}
```

### 3. Added `save_food_log_from_tandoor_recipe` Function
A new public function in `storage/logs.gleam` that:
- Accepts a `FoodLogInput` with Tandoor recipe slug
- Automatically sets `source_type` to 'tandoor_recipe'
- Sets `source_id` to the recipe slug
- Generates a unique entry ID using recipe slug + random suffix
- Parses meal type correctly
- Handles optional micronutrients
- Saves the entry to the database
- Returns the generated entry ID on success

Function signature:
```gleam
pub fn save_food_log_from_tandoor_recipe(
  conn: pog.Connection,
  input: FoodLogInput,
) -> Result(String, StorageError)
```

### 4. Created `food_log_api.gleam` Module
A new module for HTTP API handling that includes:
- `CreateFoodLogRequest` type for deserializing JSON requests
- `CreateFoodLogResponse` type for serializing JSON responses
- `handle_create_food_log` handler for POST requests
- Comprehensive input validation:
  - Date format validation (ISO 8601 YYYY-MM-DD)
  - Recipe slug cannot be empty
  - Recipe name cannot be empty
  - Servings must be > 0
  - Macros must be non-negative
  - Meal type must be one of: breakfast, lunch, dinner, snack

### 5. Added Comprehensive Tests in `food_log_api_test.gleam`
Tests cover:
- Creating FoodLogInput with valid Tandoor slugs
- All meal types (breakfast, lunch, dinner, snack)
- Full micronutrient data
- ISO 8601 date format validation
- Various Tandoor slug formats
- Edge case: no micronutrients
- Macro value edge cases
- Partial micronutrient data

## Database Schema Integration
The existing `food_logs` table already supports this change:
- `source_type` column: Tracks source (tandoor_recipe, custom_food, usda_food)
- `source_id` column: Stores the recipe slug or food ID
- Composite index on (source_type, source_id) for efficient queries
- Created in migration 006, updated in migration 022

## Source Tracking
The food_logs table now properly distinguishes between:
- **tandoor_recipe**: Recipes from Tandoor API (identified by slug)
- **custom_food**: User-created custom food items
- **usda_food**: Foods from USDA FoodData Central (identified by FDC ID)

## Example Usage

### Creating a food log entry:
```gleam
let input = logs.FoodLogInput(
  date: "2025-12-12",
  recipe_slug: "chicken-stir-fry",
  recipe_name: "Chicken Stir Fry",
  servings: 1.5,
  protein: 35.5,
  fat: 12.3,
  carbs: 45.2,
  meal_type: "dinner",
  fiber: Some(3.2),
  sugar: None,
  // ... other micronutrients ...
)

case logs.save_food_log_from_tandoor_recipe(conn, input) {
  Ok(entry_id) ->
    io.println("Logged meal with ID: " <> entry_id)
  Error(err) ->
    io.println("Failed to log meal: " <> string.inspect(err))
}
```

## HTTP API Endpoint (when integrated into web.gleam)
```
POST /api/food-logs
Content-Type: application/json

{
  "date": "2025-12-12",
  "recipe_slug": "chicken-stir-fry",
  "recipe_name": "Chicken Stir Fry",
  "servings": 1.5,
  "protein": 35.5,
  "fat": 12.3,
  "carbs": 45.2,
  "meal_type": "dinner",
  "fiber": 3.2,
  "sugar": null,
  "sodium": null,
  ...
}

Response (201 Created):
{
  "id": "chicken-stir-fry-123456",
  "recipe_name": "Chicken Stir Fry",
  "servings": 1.5
}
```

## Files Modified
1. `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage/logs.gleam`
   - Added `int` module import
   - Added `FoodLogInput` type
   - Added `save_food_log_from_tandoor_recipe` function

## Files Created
1. `/home/lewis/src/meal-planner/gleam/src/meal_planner/food_log_api.gleam`
   - New HTTP API handler module
   - Includes validation, encoding/decoding, and request handlers

2. `/home/lewis/src/meal-planner/gleam/test/food_log_api_test.gleam`
   - Comprehensive test suite with 8 test cases
   - Tests input validation and edge cases

## Validation Rules
- **date**: Must be ISO 8601 format (YYYY-MM-DD)
- **recipe_slug**: Cannot be empty, must be valid Tandoor slug
- **recipe_name**: Cannot be empty
- **servings**: Must be > 0
- **protein, fat, carbs**: Must be >= 0
- **meal_type**: One of: breakfast, lunch, dinner, snack
- **micronutrients**: Optional, can be any non-negative float

## Future Integration Steps
1. Add API endpoint to `web.gleam`:
   ```gleam
   ["api", "food-logs"] -> handle_create_food_log(req, conn)
   ```
2. Integrate database connection pool into request handling
3. Add authorization/authentication checks if needed
4. Consider adding endpoints for:
   - GET /api/food-logs/:date (retrieve daily logs)
   - DELETE /api/food-logs/:id (delete log entry)
   - GET /api/food-logs/recipes/:slug (query logs by recipe)

## Testing Results
All unit tests pass for the FoodLogInput type and API logic.
Compilation successful (warnings only for unused code in other modules).

## Database Backward Compatibility
- All changes are backward compatible
- Existing 'recipe' entries were automatically migrated to 'tandoor_recipe'
- No data loss or downtime required
