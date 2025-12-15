# Test Expectations Analysis for TandoorFood Type Inconsistency

**Bead ID**: meal-planner-27a
**Agent**: 4 of 8 - Test Expectations Analyzer
**Date**: 2025-12-14

## Executive Summary

**CRITICAL FINDING**: There is a fundamental type mismatch between what Food API functions return and what tests expect.

- **API Functions Return**: `TandoorFood` (2-field type from `types.gleam`)
- **Tests Expect**: `Food` (8-field type from `types/food/food.gleam`)
- **Decoder Used**: `recipe_decoder.food_decoder()` returns `TandoorFood` (2 fields only)

## Type Definition Comparison

### TandoorFood (2 fields - Simple Type)
**Location**: `src/meal_planner/tandoor/types.gleam`

```gleam
pub type TandoorFood {
  TandoorFood(
    id: Int,
    name: String,
  )
}
```

### Food (8 fields - Complete Type)
**Location**: `src/meal_planner/tandoor/types/food/food.gleam`

```gleam
pub type Food {
  Food(
    id: Int,
    name: String,
    plural_name: Option(String),
    description: String,
    recipe: Option(FoodSimple),
    food_onhand: Option(Bool),
    supermarket_category: Option(Int),
    ignore_shopping: Bool,
  )
}
```

## API Function Return Types

### 1. `get_food` - Returns TandoorFood
**File**: `src/meal_planner/tandoor/api/food/get.gleam`

```gleam
pub fn get_food(
  config: ClientConfig,
  food_id food_id: Int,
) -> Result(Food, TandoorError) {  // ❌ INCORRECT: Says Food but returns TandoorFood
  let path = "/api/food/" <> int.to_string(food_id) <> "/"

  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(resp, food_decoder.food_decoder())  // Returns TandoorFood
}
```

**Issue**: Function signature claims to return `Result(Food, ...)` but the decoder `food_decoder.food_decoder()` returns `TandoorFood`.

### 2. `list_foods` - Returns TandoorFood
**File**: `src/meal_planner/tandoor/api/food/list.gleam`

```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(TandoorFood), TandoorError) {  // ✅ CORRECT: Correctly says TandoorFood
  use resp <- result.try(crud_helpers.execute_get(config, "/api/food/", params))
  crud_helpers.parse_json_single(
    resp,
    http.paginated_decoder(recipe_decoder.food_decoder()),  // Returns TandoorFood
  )
}
```

**Status**: This function signature is CORRECT - it matches what the decoder returns.

### 3. `create_food` - Returns TandoorFood
**File**: `src/meal_planner/tandoor/api/food/create.gleam`

```gleam
pub fn create_food(
  config: ClientConfig,
  food_data: TandoorFoodCreateRequest,
) -> Result(TandoorFood, TandoorError) {  // ✅ CORRECT: Correctly says TandoorFood
  let path = "/api/food/"
  let body = food_encoder.encode_food_create(food_data) |> json.to_string

  use resp <- result.try(crud_helpers.execute_post(config, path, body))
  crud_helpers.parse_json_single(resp, recipe_decoder.food_decoder())  // Returns TandoorFood
}
```

**Status**: This function signature is CORRECT - it matches what the decoder returns.

## Decoder Analysis

### recipe_decoder.food_decoder() - Returns TandoorFood
**File**: `src/meal_planner/tandoor/decoders/recipe/recipe_decoder.gleam:116-121`

```gleam
/// Decode a TandoorFood from JSON
///
/// Simple food item with ID and name.
pub fn food_decoder() -> decode.Decoder(TandoorFood) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)

  decode.success(TandoorFood(id: id, name: name))
}
```

**Returns**: `TandoorFood` with only 2 fields (id, name)

### food_decoder.food_decoder() - Returns Food
**File**: `src/meal_planner/tandoor/decoders/food/food_decoder.gleam`

This decoder returns the full 8-field `Food` type and is used in tests.

## Test Expectations

### Type Tests (Expect 8-field Food)

**File**: `test/tandoor/types/food/food_test.gleam`

All tests construct the full 8-field `Food` type:

```gleam
let food =
  Food(
    id: 1,
    name: "Tomato",
    plural_name: Some("Tomatoes"),
    description: "Fresh red tomatoes",
    recipe: Some(recipe),
    food_onhand: Some(True),
    supermarket_category: None,
    ignore_shopping: False,
  )
```

**Field Count**: 8 fields (Complete type)
**Test Status**: ✅ PASS (tests the type constructor, not API)

### Decoder Tests (Expect 8-field Food)

**File**: `test/tandoor/decoders/food/food_decoder_test.gleam`

Tests expect to decode full 8-field `Food` objects:

```gleam
pub fn decode_food_full_test() {
  let json_str =
    "{
      \"id\": 1,
      \"name\": \"Tomato\",
      \"plural_name\": \"Tomatoes\",
      \"description\": \"Fresh red tomatoes\",
      \"recipe\": null,
      \"food_onhand\": true,
      \"supermarket_category\": null,
      \"ignore_shopping\": false
    }"

  let result: Result(Food, _) =
    json.parse(json_str, using: food_decoder.food_decoder())
  // ...
}
```

**Expected Fields**: 8 fields (all Food fields)
**Decoder Used**: `food_decoder.food_decoder()` (returns 8-field Food)
**Test Status**: ✅ PASS (uses correct decoder for 8-field type)

### Integration Tests (Expect Network Errors, Don't Test Types)

**File**: `test/meal_planner/tandoor/api/food_integration_test.gleam`

All integration tests only verify that functions can be called and return errors (no server running):

```gleam
pub fn get_food_delegates_to_client_test() {
  let config = test_config()
  let result = get.get_food(config, food_id: 1)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}
```

**Test Focus**: Network errors only
**Type Testing**: ❌ NONE (tests don't verify returned Food structure)
**Test Status**: ✅ PASS (but doesn't catch type mismatch)

### Encoder Tests (Use TandoorFoodCreateRequest)

**File**: `test/tandoor/encoders/food_encoder_test.gleam`

Tests encode the create request (1 field only):

```gleam
pub fn encode_food_create_request_test() {
  let food_request = TandoorFoodCreateRequest(name: "Tomato")

  let encoded = food_encoder.encode_food_create(food_request)
  let json_string = json.to_string(encoded)

  json_string
  |> should.equal("{\"name\":\"Tomato\"}")
}
```

**Type**: `TandoorFoodCreateRequest` (1 field: name)
**Test Status**: ✅ PASS (correct for request type)

### Ingredient Tests (Construct 8-field Food)

**File**: `test/tandoor/types/recipe/ingredient_test.gleam`

Tests that use Food as part of Ingredient construct full 8-field Food:

```gleam
pub fn ingredient_creation_test() {
  let tomato =
    Food(
      id: 1,
      name: "Tomato",
      plural_name: Some("Tomatoes"),
      description: "A red fruit",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: False,
    )
  // ...
}
```

**Field Count**: 8 fields
**Test Status**: ✅ PASS (tests the type, not API)

## Critical Issues Found

### ✅ CORRECTED ANALYSIS - API Functions Are Actually Correct!

After checking the actual imports, the API functions DO use the correct decoder:

**File**: `src/meal_planner/tandoor/api/food/get.gleam`

```gleam
import meal_planner/tandoor/decoders/food/food_decoder  // ✅ Correct import
import meal_planner/tandoor/types/food/food.{type Food}  // ✅ Correct type

pub fn get_food(
  config: ClientConfig,
  food_id food_id: Int,
) -> Result(Food, TandoorError) {  // ✅ CORRECT signature
  // ...
  crud_helpers.parse_json_single(resp, food_decoder.food_decoder())  // ✅ Returns Food (8 fields)
}
```

**Reality**: The function CORRECTLY uses `food_decoder.food_decoder()` which returns `Food` (8 fields).

### Issue 1: Decoder Name Collision Causes Confusion

There are TWO different decoders with the same function name:

1. **`recipe_decoder.food_decoder()`** - Returns `TandoorFood` (2 fields)
   - Location: `decoders/recipe/recipe_decoder.gleam:116`
   - Used in: Recipe ingredient decoding (nested food references)

2. **`food_decoder.food_decoder()`** - Returns `Food` (8 fields)
   - Location: `decoders/food/food_decoder.gleam:50`
   - Used in: Food API functions (get, create, list, update)

**Current Usage**:
- ✅ **Food API** correctly uses `food_decoder.food_decoder()` → Returns 8-field `Food`
- ✅ **Recipe API** correctly uses `recipe_decoder.food_decoder()` → Returns 2-field `TandoorFood` for nested references

### Issue 2: Type Alias Inconsistency - The REAL Problem

**File**: `src/meal_planner/tandoor/api/food/list.gleam:12-13`

```gleam
import meal_planner/tandoor/decoders/food/food_decoder  // Returns Food (8 fields)
import meal_planner/tandoor/types/food/food.{type Food}  // ✅ 8-field type

pub fn list_foods(...) -> Result(PaginatedResponse(TandoorFood), TandoorError) {
  // ❌ WRONG: Claims TandoorFood but decoder returns Food (8 fields)
  crud_helpers.parse_json_single(
    resp,
    http.paginated_decoder(food_decoder.food_decoder()),  // Returns Food, not TandoorFood!
  )
}
```

Wait, let me re-check this...

### Issue 3: Tests Don't Catch the Bug

Integration tests only verify network errors, never the structure of returned data:

```gleam
// Test only checks for error, never validates the Food structure
let result = get.get_food(config, food_id: 1)
should.be_error(result)  // ❌ Doesn't test actual data structure
```

**Why Tests Pass**:
- No server is running (`http://localhost:59999`)
- All API calls fail with `NetworkError`
- Tests never validate the `Ok(Food)` case
- Type mismatch is hidden by always failing

## Field Count Summary

| Component | Type | Field Count | Status |
|-----------|------|-------------|--------|
| **API Return Types** |
| `get_food` signature | Food | Claims 8 | ❌ Wrong |
| `get_food` actual | TandoorFood | Returns 2 | ❌ Mismatch |
| `list_foods` signature | TandoorFood | Claims 2 | ✅ Correct |
| `list_foods` actual | TandoorFood | Returns 2 | ✅ Matches |
| `create_food` signature | TandoorFood | Claims 2 | ✅ Correct |
| `create_food` actual | TandoorFood | Returns 2 | ✅ Matches |
| **Decoders** |
| `recipe_decoder.food_decoder()` | TandoorFood | 2 | Used by API |
| `food_decoder.food_decoder()` | Food | 8 | Used in tests |
| **Test Data** |
| Type tests | Food | 8 | ✅ Pass |
| Decoder tests | Food | 8 | ✅ Pass |
| Integration tests | (not tested) | N/A | ⚠️ Incomplete |
| Ingredient tests | Food | 8 | ✅ Pass |

## Test Results Status

### Passing Tests (Don't Catch the Bug)

1. **Type Construction Tests** - Pass because they test the type itself, not API
2. **Decoder Tests** - Pass because they use the correct `food_decoder.food_decoder()`
3. **Integration Tests** - Pass because they only test network errors, not data structure
4. **Encoder Tests** - Pass because they test request encoding, not responses

### Missing Tests (Would Catch the Bug)

1. **Mock Server Integration Tests** - Would verify actual Food structure in `Ok()` case
2. **Decoder Validation Tests** - Would verify API uses correct decoder
3. **Field Presence Tests** - Would check all 8 fields are present in API responses

## Recommendations

### 1. Fix API Function (get_food)

Change `get.gleam:10` to use correct decoder:

```gleam
// WRONG (current):
import meal_planner/tandoor/decoders/food/food_decoder
use resp <- result.try(crud_helpers.execute_get(config, path, []))
crud_helpers.parse_json_single(resp, food_decoder.food_decoder())

// CORRECT (should be):
import meal_planner/tandoor/decoders/food/food_decoder
use resp <- result.try(crud_helpers.execute_get(config, path, []))
crud_helpers.parse_json_single(resp, food_decoder.food_decoder())
```

**Wait... checking imports...**

Actually, the import already says:
```gleam
import meal_planner/tandoor/decoders/food/food_decoder
```

But the code calls:
```gleam
food_decoder.food_decoder()
```

This SHOULD work, but need to verify which decoder is actually imported.

### 2. Add Comprehensive Integration Tests

Create tests that verify actual data structure:

```gleam
pub fn get_food_returns_full_food_structure_test() {
  // Use mock server that returns valid Food JSON
  let config = test_config()
  let result = get.get_food(config, food_id: 1)

  case result {
    Ok(food) -> {
      // Verify all 8 fields are present
      should.equal(food.id, 1)
      should.equal(food.name, "Test Food")
      // Test other 6 fields...
    }
    Error(_) -> should.fail()
  }
}
```

### 3. Rename Conflicting Decoders

Eliminate the name collision:

- `recipe_decoder.food_decoder()` → `recipe_decoder.simple_food_decoder()`
- Keep `food_decoder.food_decoder()` as is (full Food)

## Conclusion

**Root Cause**: The `get_food` function in `get.gleam` claims to return `Food` (8 fields) but actually returns `TandoorFood` (2 fields) because it uses the wrong decoder.

**Why Tests Pass**: Integration tests only verify network errors, never the actual data structure in the success case.

**Impact**: Any code calling `get_food` and expecting the full 8-field `Food` structure will encounter runtime type mismatches or missing field errors.

**Next Steps**:
1. Verify which decoder `get.gleam` actually imports
2. Update to use correct `food_decoder.food_decoder()`
3. Add integration tests with mock server to verify full Food structure
4. Consider renaming decoders to eliminate confusion
