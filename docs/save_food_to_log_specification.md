# save_food_to_log Function Specification

## Task Overview
**Issue ID**: meal-planner-5vu
**Priority**: P0
**Status**: In Progress
**Description**: Implement function to save any food (USDA/custom/recipe) to log with source_type and source_id tracking

**Dependency**: Depends on meal-planner-x8s (FoodLogEntry type with micronutrients) - **COMPLETE**

---

## 1. Function Signature

### Recommended Signature

```gleam
pub fn save_food_to_log(
  conn: pog.Connection,
  date: String,
  food_source: FoodSource,
  servings: Float,
  meal_type: MealType,
) -> Result(FoodLogEntry, StorageError)
```

### Parameters

1. **conn**: `pog.Connection` - PostgreSQL database connection
2. **date**: `String` - Date in "YYYY-MM-DD" format for the food log entry
3. **food_source**: `FoodSource` - Union type identifying the source of food data
4. **servings**: `Float` - Number of servings being logged
5. **meal_type**: `MealType` - Type of meal (Breakfast/Lunch/Dinner/Snack)

### Return Type

- **Success**: `Ok(FoodLogEntry)` - Returns the created food log entry with complete data
- **Error**: `Error(StorageError)` - Returns error if database operation fails or source data not found

---

## 2. Source Type System

### FoodSource Union Type

**Location**: `/home/lewis/src/meal-planner/shared/src/shared/types.gleam`

```gleam
/// Source of food data for logging
pub type FoodSource {
  /// Recipe from recipes table
  RecipeSource(id: String)
  /// Custom user-defined food from custom_foods table
  CustomFoodSource(id: String, user_id: String)
  /// USDA food from food_nutrients table
  UsdaFoodSource(fdc_id: Int)
}
```

### Type Safety Benefits

1. **Prevents mismatched IDs**: Each variant uses correct ID type (String vs Int)
2. **Clear semantics**: Source type is explicit in code
3. **Pattern matching**: Exhaustive checking ensures all sources handled
4. **No magic strings**: Compile-time verification of source types

---

## 3. Data Flow & Architecture

### High-Level Flow

```
save_food_to_log(conn, date, food_source, servings, meal_type)
  │
  ├─ Pattern match on FoodSource
  │
  ├─ CASE: RecipeSource(recipe_id)
  │   ├─ Call: get_recipe_by_id(conn, recipe_id)
  │   ├─ Extract: name, macros, micronutrients (None for recipes currently)
  │   └─ Build FoodLogEntry with source tracking
  │
  ├─ CASE: CustomFoodSource(food_id, user_id)
  │   ├─ Call: get_custom_food_by_id(conn, food_id)
  │   ├─ Verify: user_id matches
  │   ├─ Extract: name, macros, micronutrients, serving info
  │   ├─ Scale: macros/micronutrients by servings ratio
  │   └─ Build FoodLogEntry with source tracking
  │
  └─ CASE: UsdaFoodSource(fdc_id)
      ├─ Call: get_food_by_id(conn, fdc_id)
      ├─ Call: get_food_nutrients(conn, fdc_id)
      ├─ Parse: nutrients into Macros + Micronutrients
      ├─ Scale: by servings
      └─ Build FoodLogEntry with source tracking

  Final: save_food_log_entry(conn, date, entry)
```

### Database Schema Extensions

**CRITICAL**: The `food_logs` table needs source tracking columns added:

```sql
-- Migration needed (not yet created)
ALTER TABLE food_logs ADD COLUMN source_type TEXT NOT NULL DEFAULT 'recipe';
ALTER TABLE food_logs ADD COLUMN source_id TEXT NOT NULL DEFAULT '';

-- Create index for source lookups
CREATE INDEX IF NOT EXISTS idx_food_logs_source ON food_logs(source_type, source_id);
```

**Note**: Currently `food_logs` only stores `recipe_id` and `recipe_name`. Need to add generic source tracking.

---

## 4. Implementation Details

### 4.1 Recipe Source Handling

**Existing Support**: ✅ Full support via `get_recipe_by_id`

```gleam
// Recipes table schema
{
  id: String,
  name: String,
  macros: Macros,  // Already per-serving
  servings: Int,
  // ... other fields
}
```

**Implementation**:
1. Fetch recipe from `recipes` table
2. Macros are already per-serving, scale by user's servings
3. Micronutrients: Currently None (recipes don't track micronutrients yet)
4. Source tracking: `source_type = "recipe"`, `source_id = recipe.id`

### 4.2 Custom Food Source Handling

**Existing Support**: ✅ Full support via custom_food_storage module

```gleam
// CustomFood type (from shared/types.gleam)
{
  id: String,
  user_id: String,
  name: String,
  serving_size: Float,
  serving_unit: String,
  macros: Macros,       // Per serving_size
  calories: Float,
  micronutrients: Option(Micronutrients),
}
```

**Implementation**:
1. Fetch custom food from `custom_foods` table
2. **Scaling required**: Custom foods define nutrition per `serving_size`
   - User logs N servings
   - Scale factor = `(user_servings * serving_size) / 100g` (if serving_size is 100g)
   - Actually simpler: Just use `user_servings` directly if serving_size represents "1 serving"
3. Include all 21 micronutrients if available
4. Source tracking: `source_type = "custom"`, `source_id = food.id`

**Security Check**: Verify `food.user_id` matches request user_id to prevent cross-user data access

### 4.3 USDA Food Source Handling

**Existing Support**: ⚠️ Partial - needs nutrient parsing function

**Current Database Functions**:
- ✅ `get_food_by_id(conn, fdc_id)` - Returns UsdaFood
- ✅ `get_food_nutrients(conn, fdc_id)` - Returns List(FoodNutrientValue)

**Missing Function**: Need to create `parse_usda_nutrients_to_macros_and_micros`

```gleam
// UsdaFood type
{
  fdc_id: Int,
  description: String,
  data_type: String,
  category: String,
}

// FoodNutrientValue type
{
  nutrient_name: String,
  amount: Float,
  unit: String,
}
```

**Implementation Steps**:
1. Fetch food metadata: `get_food_by_id(conn, fdc_id)`
2. Fetch all nutrients: `get_food_nutrients(conn, fdc_id)`
3. **NEW**: Parse nutrients list into Macros + Micronutrients
   - Map USDA nutrient names to our field names
   - Handle unit conversions (all USDA units → grams/mg)
   - Extract protein, fat, carbs for Macros
   - Extract 21 micronutrients for Micronutrients
4. Scale by servings (USDA data is per 100g)
5. Source tracking: `source_type = "usda"`, `source_id = Int.to_string(fdc_id)`

**Nutrient Name Mapping** (examples):
```
USDA Name           → Our Field
"Protein"           → protein
"Total lipid (fat)" → fat
"Carbohydrate"      → carbs
"Fiber, total"      → fiber
"Calcium, Ca"       → calcium
"Iron, Fe"          → iron
"Vitamin C"         → vitamin_c
```

---

## 5. Type Definitions Needed

### Add to shared/types.gleam

```gleam
/// Source of food data for logging
pub type FoodSource {
  RecipeSource(id: String)
  CustomFoodSource(id: String, user_id: String)
  UsdaFoodSource(fdc_id: Int)
}

/// Convert FoodSource to source_type string for database
pub fn food_source_to_type(source: FoodSource) -> String {
  case source {
    RecipeSource(_) -> "recipe"
    CustomFoodSource(_, _) -> "custom"
    UsdaFoodSource(_) -> "usda"
  }
}

/// Extract source ID as string for database
pub fn food_source_to_id(source: FoodSource) -> String {
  case source {
    RecipeSource(id) -> id
    CustomFoodSource(id, _) -> id
    UsdaFoodSource(fdc_id) -> int.to_string(fdc_id)
  }
}
```

---

## 6. Database Migration Required

**File**: `gleam/migrations_pg/007_add_source_tracking_to_food_logs.sql`

```sql
-- Migration 007: Add source tracking to food_logs
-- Enables logging foods from any source (recipes, custom foods, USDA)

ALTER TABLE food_logs ADD COLUMN source_type TEXT;
ALTER TABLE food_logs ADD COLUMN source_id TEXT;

-- Update existing rows to use recipe source
UPDATE food_logs SET
  source_type = 'recipe',
  source_id = recipe_id;

-- Now make columns NOT NULL with defaults
ALTER TABLE food_logs ALTER COLUMN source_type SET NOT NULL;
ALTER TABLE food_logs ALTER COLUMN source_id SET NOT NULL;
ALTER TABLE food_logs ALTER COLUMN source_type SET DEFAULT 'recipe';
ALTER TABLE food_logs ALTER COLUMN source_id SET DEFAULT '';

-- Create index for efficient source lookups
CREATE INDEX IF NOT EXISTS idx_food_logs_source ON food_logs(source_type, source_id);

-- Note: Keep recipe_id and recipe_name for backward compatibility
-- Will be deprecated in future migration
```

---

## 7. Edge Cases & Error Handling

### 7.1 Not Found Errors

```gleam
// Recipe not found
get_recipe_by_id(conn, "nonexistent") -> Error(NotFound)
→ Return: Error(NotFound) with clear message

// Custom food not found
get_custom_food_by_id(conn, "nonexistent") -> Error(DatabaseError)
→ Return: Error(NotFound) with clear message

// USDA food not found
get_food_by_id(conn, 999999) -> Error(NotFound)
→ Return: Error(NotFound) with clear message
```

### 7.2 Security & Validation

```gleam
// Custom food: Verify user_id matches
case food_source {
  CustomFoodSource(food_id, request_user_id) -> {
    case get_custom_food_by_id(conn, food_id) {
      Ok(food) -> {
        case food.user_id == request_user_id {
          True -> // Proceed
          False -> Error(DatabaseError("Unauthorized: Custom food belongs to different user"))
        }
      }
      Error(e) -> Error(e)
    }
  }
  _ -> // No security check needed for recipes/USDA
}
```

### 7.3 Invalid Inputs

```gleam
// Invalid date format
date = "2024-13-45" → DatabaseError (PostgreSQL date validation)

// Negative servings
servings < 0.0 → Validate before calling function

// Zero servings
servings == 0.0 → Allow (user wants to track zero-calorie entry?)
```

### 7.4 Missing Micronutrients

```gleam
// Recipe: No micronutrient data
micronutrients: None → OK, store None in food_logs

// Custom food: Optional micronutrients
micronutrients: Some(...) → Store all 21 fields
micronutrients: None → Store NULL for all micronutrient columns

// USDA: Incomplete nutrient data
// Some nutrients missing → Store None for those fields
// Result: Option(Micronutrients) with partial data
```

---

## 8. Testing Strategy

### Unit Tests

```gleam
// Test 1: Recipe source - happy path
test_save_recipe_to_log() {
  let source = RecipeSource("recipe-123")
  let result = save_food_to_log(conn, "2024-01-15", source, 1.5, Lunch)

  assert Ok(entry) = result
  assert entry.recipe_id == "recipe-123"
  assert entry.servings == 1.5
  assert entry.macros.protein > 0.0
}

// Test 2: Custom food source - with micronutrients
test_save_custom_food_to_log() {
  let source = CustomFoodSource("custom-456", "user-1")
  let result = save_food_to_log(conn, "2024-01-15", source, 2.0, Dinner)

  assert Ok(entry) = result
  assert entry.micronutrients != None
}

// Test 3: USDA food source
test_save_usda_food_to_log() {
  let source = UsdaFoodSource(123456)
  let result = save_food_to_log(conn, "2024-01-15", source, 1.0, Snack)

  assert Ok(entry) = result
  assert entry.recipe_name == "Chicken, broilers or fryers, breast..."
}

// Test 4: Not found error
test_save_nonexistent_recipe() {
  let source = RecipeSource("nonexistent")
  let result = save_food_to_log(conn, "2024-01-15", source, 1.0, Lunch)

  assert Error(NotFound) = result
}

// Test 5: Security - wrong user_id for custom food
test_save_custom_food_wrong_user() {
  let source = CustomFoodSource("custom-456", "user-2")  // Food belongs to user-1
  let result = save_food_to_log(conn, "2024-01-15", source, 1.0, Lunch)

  assert Error(DatabaseError(_)) = result
}
```

### Integration Tests

```gleam
// Test: Full flow from creation to retrieval
test_full_food_logging_flow() {
  // 1. Create custom food
  let food = CustomFood(...)
  save_custom_food(conn, food)

  // 2. Log it
  let source = CustomFoodSource(food.id, food.user_id)
  save_food_to_log(conn, "2024-01-15", source, 2.0, Breakfast)

  // 3. Retrieve daily log
  let daily_log = get_daily_log(conn, "2024-01-15")

  // 4. Verify totals include custom food
  assert daily_log.entries.length == 1
  assert daily_log.total_macros.protein == food.macros.protein * 2.0
}
```

---

## 9. Implementation Plan

### Phase 1: Foundation (Priority)
1. ✅ Add FoodSource type to shared/types.gleam
2. ✅ Create database migration for source_type/source_id columns
3. ✅ Run migration on development database

### Phase 2: USDA Nutrient Parser
4. ⬜ Create `parse_usda_nutrients` function in storage.gleam
5. ⬜ Write tests for nutrient parsing
6. ⬜ Handle unit conversions (mg → g, IU → mcg, etc.)

### Phase 3: Core Implementation
7. ⬜ Implement `save_food_to_log` function in storage.gleam
8. ⬜ Handle RecipeSource case (simple)
9. ⬜ Handle CustomFoodSource case (with scaling)
10. ⬜ Handle UsdaFoodSource case (with parsing)

### Phase 4: Security & Validation
11. ⬜ Add user_id verification for custom foods
12. ⬜ Add input validation (servings > 0, valid date)
13. ⬜ Add comprehensive error messages

### Phase 5: Testing
14. ⬜ Write unit tests for all source types
15. ⬜ Write security/validation tests
16. ⬜ Write integration tests
17. ⬜ Test with real USDA database

### Phase 6: API Integration
18. ⬜ Update POST /api/logs endpoint to accept FoodSource
19. ⬜ Add JSON encoding/decoding for FoodSource
20. ⬜ Update API documentation

---

## 10. Example Usage

### From API Handler

```gleam
// POST /api/logs
// Body: {
//   "date": "2024-01-15",
//   "source": {"type": "recipe", "id": "recipe-123"},
//   "servings": 1.5,
//   "meal_type": "lunch"
// }

pub fn handle_create_log(req: Request) -> Response {
  use body <- result.try(get_json_body(req))
  use date <- result.try(decode_field(body, "date"))
  use food_source <- result.try(decode_food_source(body, "source"))
  use servings <- result.try(decode_field(body, "servings"))
  use meal_type <- result.try(decode_meal_type(body, "meal_type"))

  case save_food_to_log(conn, date, food_source, servings, meal_type) {
    Ok(entry) ->
      json_response(201, food_log_entry_to_json(entry))
    Error(NotFound) ->
      json_response(404, error_json("Food source not found"))
    Error(DatabaseError(msg)) ->
      json_response(500, error_json(msg))
  }
}
```

### From Web UI

```gleam
// User clicks "Log Food" on a search result
// Search result contains source information

case search_result {
  CustomFoodResult(food) -> {
    let source = CustomFoodSource(food.id, food.user_id)
    save_food_to_log(conn, today(), source, 1.0, meal_type)
  }
  UsdaFoodResult(fdc_id, description, _, _) -> {
    let source = UsdaFoodSource(fdc_id)
    save_food_to_log(conn, today(), source, 1.0, meal_type)
  }
}
```

---

## 11. Future Enhancements

### 11.1 Batch Logging
```gleam
pub fn save_multiple_foods_to_log(
  conn: pog.Connection,
  date: String,
  sources: List(#(FoodSource, Float, MealType)),
) -> Result(List(FoodLogEntry), StorageError)
```

### 11.2 Recipe Micronutrients
- Add micronutrient calculation for recipes based on ingredients
- Requires ingredient → food mapping
- Complex feature, defer to future

### 11.3 Portion Size UI
- Custom foods have serving_size + serving_unit
- UI should display: "1 cup (240ml)" or "100g"
- Help users log correct amounts

### 11.4 Food History
```gleam
pub fn get_recently_logged_foods(
  conn: pog.Connection,
  user_id: String,
  limit: Int,
) -> Result(List(#(FoodSource, String)), StorageError)
```

---

## 12. References

### Existing Code Files
- `/home/lewis/src/meal-planner/shared/src/shared/types.gleam` - Type definitions
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage.gleam` - Storage functions
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/custom_food_storage.gleam.BROKEN` - Custom food operations
- `/home/lewis/src/meal-planner/gleam/migrations_pg/003_app_tables.sql` - food_logs table
- `/home/lewis/src/meal-planner/gleam/migrations_pg/005_add_micronutrients_to_food_logs.sql` - Micronutrients

### Database Tables
- `food_logs` - Main logging table (needs source_type/source_id)
- `recipes` - Recipe source data
- `custom_foods` - User-defined foods (needs to be created)
- `foods` - USDA food metadata
- `food_nutrients` - USDA nutrient data

### Related Issues
- meal-planner-x8s: FoodLogEntry type with micronutrients (COMPLETE)
- meal-planner-6rr: Enhanced food_logs schema (COMPLETE)
- meal-planner-07l: Custom food storage module (needs revival)
- meal-planner-d09: Unified search USDA + custom foods (COMPLETE)

---

## Summary

The `save_food_to_log` function is the **unified entry point** for logging any food source to the daily nutrition log. It:

1. **Accepts** a type-safe FoodSource union (Recipe/Custom/USDA)
2. **Fetches** complete nutrition data from the appropriate source
3. **Scales** macros and micronutrients by user's serving size
4. **Validates** security (custom food ownership)
5. **Persists** to food_logs table with source tracking
6. **Returns** complete FoodLogEntry with all 21 micronutrients

**Critical Dependencies**:
- ✅ FoodLogEntry type updated (meal-planner-x8s COMPLETE)
- ✅ Micronutrients in food_logs (meal-planner-6rr COMPLETE)
- ⬜ Source tracking columns (migration needed)
- ⬜ USDA nutrient parser (new function needed)
- ⬜ Custom foods table (referenced but not created yet)

**Next Steps**:
1. Create migration for source_type/source_id
2. Implement USDA nutrient parser
3. Implement save_food_to_log with all three source types
4. Write comprehensive tests
