# TandoorFood Type Inconsistency Analysis

**Bead ID:** meal-planner-27a
**Analyst:** Agent 1 - Type Analysis
**Date:** 2025-12-14

## Executive Summary

There are **two distinct Food type definitions** in the codebase serving different purposes:

1. **TandoorFood** (2 fields) - Used for **ingredient references** in recipes
2. **Food** (8 fields) - Used for **standalone food entities** from the Food API

The current type confusion exists because:
- Some API functions claim to return `TandoorFood` but actually use the wrong decoder
- The decoders are mismatched with the declared return types
- The two types serve different API endpoints and use cases

## Type Definitions

### 1. TandoorFood (Simple Food Reference)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types.gleam` (lines 64-67)

```gleam
/// Food item referenced by ingredient
pub type TandoorFood {
  TandoorFood(id: Int, name: String)
}
```

**Purpose:** Lightweight food reference used **within recipe ingredients**
**API Context:** Embedded in recipe JSON responses
**Fields:** 2 (id, name only)

**Decoder:** `recipe_decoder.food_decoder()` in `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/recipe/recipe_decoder.gleam` (lines 116-121)

```gleam
pub fn food_decoder() -> decode.Decoder(TandoorFood) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)

  decode.success(TandoorFood(id: id, name: name))
}
```

### 2. Food (Complete Food Entity)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types/food/food.gleam` (lines 10-30)

```gleam
/// Complete food type with full metadata
/// Used for detailed food views and full food data operations
pub type Food {
  Food(
    /// Tandoor food ID
    id: Int,
    /// Food name
    name: String,
    /// Optional plural form of the food name
    plural_name: Option(String),
    /// Food description
    description: String,
    /// Optional associated recipe (for recipe-based foods)
    recipe: Option(FoodSimple),
    /// Whether food is on hand (in inventory)
    food_onhand: Option(Bool),
    /// Optional supermarket category reference
    supermarket_category: Option(Int),
    /// Whether to ignore this food in shopping lists
    ignore_shopping: Bool,
  )
}
```

**Purpose:** Full food entity from **Food API endpoints** (`/api/food/`)
**API Context:** Direct food CRUD operations
**Fields:** 8 (id, name, plural_name, description, recipe, food_onhand, supermarket_category, ignore_shopping)

**Decoder:** `food_decoder.food_decoder()` in `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/food/food_decoder.gleam` (lines 50-73)

```gleam
pub fn food_decoder() -> decode.Decoder(Food) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.field("plural_name", decode.optional(decode.string))
  use description <- decode.field("description", decode.string)
  use recipe <- decode.field("recipe", decode.optional(food_simple_decoder()))
  use food_onhand <- decode.field("food_onhand", decode.optional(decode.bool))
  use supermarket_category <- decode.field("supermarket_category", decode.optional(decode.int))
  use ignore_shopping <- decode.field("ignore_shopping", decode.bool)

  decode.success(Food(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
    recipe: recipe,
    food_onhand: food_onhand,
    supermarket_category: supermarket_category,
    ignore_shopping: ignore_shopping,
  ))
}
```

## API Function Analysis

### Functions Using WRONG Type (TandoorFood when they should use Food)

#### ❌ create_food (INCORRECT)
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/create.gleam`
**Declared Return Type:** `Result(TandoorFood, TandoorError)` (line 32)
**Actual Decoder Used:** `recipe_decoder.food_decoder()` which returns `TandoorFood` with 2 fields (line 37)
**Problem:** Creates a food via `/api/food/` which returns 8-field JSON, but uses 2-field decoder

```gleam
pub fn create_food(
  config: ClientConfig,
  food_data: TandoorFoodCreateRequest,
) -> Result(TandoorFood, TandoorError) {  // ❌ Wrong type
  let path = "/api/food/"
  let body = food_encoder.encode_food_create(food_data) |> json.to_string

  use resp <- result.try(crud_helpers.execute_post(config, path, body))
  crud_helpers.parse_json_single(resp, recipe_decoder.food_decoder())  // ❌ Wrong decoder
}
```

**Should be:** `Result(Food, TandoorError)` using `food_decoder.food_decoder()`

#### ❌ update_food (INCORRECT)
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/update.gleam`
**Declared Return Type:** `Result(TandoorFood, TandoorError)` (line 35)
**Actual Decoder Used:** `recipe_decoder.food_decoder()` which returns `TandoorFood` with 2 fields (line 40)
**Problem:** Updates a food via `/api/food/{id}/` which returns 8-field JSON, but uses 2-field decoder

```gleam
pub fn update_food(
  config: ClientConfig,
  food_id food_id: Int,
  food_data food_data: TandoorFoodCreateRequest,
) -> Result(TandoorFood, TandoorError) {  // ❌ Wrong type
  let path = "/api/food/" <> int.to_string(food_id) <> "/"
  let body = food_encoder.encode_food_create(food_data) |> json.to_string

  use resp <- result.try(crud_helpers.execute_patch(config, path, body))
  crud_helpers.parse_json_single(resp, recipe_decoder.food_decoder())  // ❌ Wrong decoder
}
```

**Should be:** `Result(Food, TandoorError)` using `food_decoder.food_decoder()`

#### ❌ list_foods (INCORRECT)
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/list.gleam`
**Declared Return Type:** `Result(PaginatedResponse(TandoorFood), TandoorError)` (line 33)
**Actual Decoder Used:** `recipe_decoder.food_decoder()` which returns `TandoorFood` with 2 fields (line 48)
**Problem:** Lists foods via `/api/food/` which returns 8-field JSON, but uses 2-field decoder

```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(TandoorFood), TandoorError) {  // ❌ Wrong type
  // ... query parameter building ...

  use resp <- result.try(crud_helpers.execute_get(config, "/api/food/", params))
  crud_helpers.parse_json_single(
    resp,
    http.paginated_decoder(recipe_decoder.food_decoder()),  // ❌ Wrong decoder
  )
}
```

**Should be:** `Result(PaginatedResponse(Food), TandoorError)` using `food_decoder.food_decoder()`

### Functions Using CORRECT Type (Food)

#### ✅ get_food (CORRECT)
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/get.gleam`
**Declared Return Type:** `Result(Food, TandoorError)` (line 29)
**Actual Decoder Used:** `food_decoder.food_decoder()` which returns `Food` with 8 fields (line 33)
**Status:** ✅ Correctly uses Food type and matching decoder

```gleam
pub fn get_food(
  config: ClientConfig,
  food_id food_id: Int,
) -> Result(Food, TandoorError) {  // ✅ Correct type
  let path = "/api/food/" <> int.to_string(food_id) <> "/"

  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(resp, food_decoder.food_decoder())  // ✅ Correct decoder
}
```

#### ✅ delete_food (N/A)
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/delete.gleam`
**Returns:** `Result(Nil, TandoorError)` - No food data returned
**Status:** ✅ Not applicable - DELETE returns no body

## Recommendation

### The Two Types Are BOTH Valid and Should Coexist

**TandoorFood** and **Food** serve **different API contexts**:

1. **TandoorFood (2 fields)** - Used for ingredient references in recipes
   - Should remain in `types.gleam` as part of recipe types
   - Used by `TandoorIngredient` type
   - Decoded by `recipe_decoder.food_decoder()`

2. **Food (8 fields)** - Used for Food API endpoints
   - Should remain in `types/food/food.gleam`
   - Used by Food API CRUD operations
   - Decoded by `food_decoder.food_decoder()`

### Required Fixes

**Fix the 3 functions that use the wrong type:**

1. **create_food** - Change return type from `TandoorFood` to `Food`, use `food_decoder.food_decoder()`
2. **update_food** - Change return type from `TandoorFood` to `Food`, use `food_decoder.food_decoder()`
3. **list_foods** - Change return type from `PaginatedResponse(TandoorFood)` to `PaginatedResponse(Food)`, use `food_decoder.food_decoder()`

### Why Not Alias?

These types should **NOT** be aliased because:

1. They represent **different API response shapes**
2. They are used in **different contexts** (recipe ingredients vs. standalone foods)
3. The Tandoor API likely returns different JSON structures for:
   - `/api/recipe/{id}/` - embeds 2-field food in ingredients
   - `/api/food/{id}/` - returns full 8-field food object

### Naming Clarity

To avoid future confusion, consider:

1. **Keep** `TandoorFood` for recipe context (it's already well-named)
2. **Keep** `Food` for food API context (it's in the food namespace)
3. **Document** the distinction in both type definitions

The namespace separation (`meal_planner/tandoor/types.TandoorFood` vs `meal_planner/tandoor/types/food/food.Food`) already provides clarity.

## Impact Analysis

### Files That Need Changes

1. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/create.gleam`
   - Line 10-12: Import `Food` from `meal_planner/tandoor/types/food/food`
   - Line 9: Import `food_decoder` from `meal_planner/tandoor/decoders/food/food_decoder`
   - Line 32: Change return type to `Result(Food, TandoorError)`
   - Line 37: Change decoder to `food_decoder.food_decoder()`

2. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/update.gleam`
   - Line 11-12: Import `Food` from `meal_planner/tandoor/types/food/food`
   - Line 9: Import `food_decoder` from `meal_planner/tandoor/decoders/food/food_decoder`
   - Line 35: Change return type to `Result(Food, TandoorError)`
   - Line 40: Change decoder to `food_decoder.food_decoder()`

3. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/list.gleam`
   - Line 11-12: Import `Food` from `meal_planner/tandoor/types/food/food` (remove `TandoorFood` import)
   - Line 9: Import `food_decoder` from `meal_planner/tandoor/decoders/food/food_decoder`
   - Line 33: Change return type to `Result(PaginatedResponse(Food), TandoorError)`
   - Line 48: Change decoder to `food_decoder.food_decoder()`

### Files That Are Correct (No Changes Needed)

1. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/get.gleam` ✅
2. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/delete.gleam` ✅
3. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types.gleam` ✅
4. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types/food/food.gleam` ✅
5. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/recipe/recipe_decoder.gleam` ✅
6. `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/food/food_decoder.gleam` ✅

## Test Strategy

After fixes, verify:

1. **Unit tests** for each fixed function to ensure correct type returns
2. **Integration tests** with mock Tandoor API responses
3. **Type compilation** to ensure no type mismatches in calling code

## Conclusion

The type inconsistency is **not** a case of duplicate types, but rather a case of:
- **Correct separation** of concerns (TandoorFood for recipes, Food for Food API)
- **Incorrect usage** in 3 API functions that should return `Food` but claim to return `TandoorFood`

The fix is straightforward: update the 3 incorrect functions to use the correct `Food` type and `food_decoder.food_decoder()`.
