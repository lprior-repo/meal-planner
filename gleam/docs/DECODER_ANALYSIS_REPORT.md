# TandoorFood Type Inconsistency - Decoder Analysis Report

**Bead:** meal-planner-27a
**Agent:** Decoder Analysis (Agent 2 of 8)
**Date:** 2025-12-14

## Executive Summary

**CRITICAL FINDING:** There are **TWO DIFFERENT** `TandoorFood` type definitions being used in the codebase:

1. **Legacy 2-field type** in `types.gleam` (line 66)
2. **New 8-field type** (`Food`) in `types/food/food.gleam` (lines 10-30)

The decoders are inconsistent - some produce 2-field records, others produce 8-field records, but all are used interchangeably as `TandoorFood`.

---

## Type Definitions

### 1. Legacy TandoorFood (types.gleam:66)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types.gleam`

```gleam
pub type TandoorFood {
  TandoorFood(id: Int, name: String)
}
```

**Fields:** 2 (id, name)
**Usage:** Recipe ingredients, legacy API calls

---

### 2. New Food Type (types/food/food.gleam:10-30)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types/food/food.gleam`

```gleam
pub type Food {
  Food(
    id: Int,                                    // Required
    name: String,                               // Required
    plural_name: Option(String),                // Optional
    description: String,                        // Required
    recipe: Option(FoodSimple),                 // Optional (nested type)
    food_onhand: Option(Bool),                  // Optional
    supermarket_category: Option(Int),          // Optional
    ignore_shopping: Bool,                      // Required
  )
}
```

**Fields:** 8 (id, name, plural_name, description, recipe, food_onhand, supermarket_category, ignore_shopping)
**Usage:** Food API endpoints (get, list, create, update)

---

### 3. FoodSimple Type (types/food/food_simple.gleam:5-14)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types/food/food_simple.gleam`

```gleam
pub type FoodSimple {
  FoodSimple(
    id: Int,                      // Required
    name: String,                 // Required
    plural_name: Option(String),  // Optional
  )
}
```

**Fields:** 3 (id, name, plural_name)
**Usage:** Nested food references (e.g., recipe field in Food type)

---

## Decoder Inventory

### Decoder 1: recipe_decoder.food_decoder() → TandoorFood (2 fields)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/recipe/recipe_decoder.gleam:116-121`

**Return Type:** `decode.Decoder(TandoorFood)`

**Fields Decoded:**
```gleam
pub fn food_decoder() -> decode.Decoder(TandoorFood) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)

  decode.success(TandoorFood(id: id, name: name))
}
```

| Field | Type | Required | Decoded |
|-------|------|----------|---------|
| id | Int | Yes | ✅ |
| name | String | Yes | ✅ |

**Output:** `TandoorFood(id: Int, name: String)` ← **2-FIELD VERSION**

**Used By:**
- `recipe_decoder.ingredient_decoder()` (line 99)
- Recipe parsing for ingredient food references

---

### Decoder 2: food_decoder.food_decoder() → Food (8 fields)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/food/food_decoder.gleam:50-73`

**Return Type:** `decode.Decoder(Food)`

**Fields Decoded:**
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

| Field | Type | Required | Decoded |
|-------|------|----------|---------|
| id | Int | Yes | ✅ |
| name | String | Yes | ✅ |
| plural_name | Option(String) | No | ✅ |
| description | String | Yes | ✅ |
| recipe | Option(FoodSimple) | No | ✅ |
| food_onhand | Option(Bool) | No | ✅ |
| supermarket_category | Option(Int) | No | ✅ |
| ignore_shopping | Bool | Yes | ✅ |

**Output:** `Food(8 fields)` ← **8-FIELD VERSION**

**Used By:**
- `api/food/get.gleam:33` - get_food()
- `api/food/list.gleam:48` - list_foods() via http.paginated_decoder()
- `api/food/create.gleam:37` - create_food()
- `api/food/update.gleam:40` - update_food()

---

### Decoder 3: food_decoder.food_simple_decoder() → FoodSimple (3 fields)

**Location:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/food/food_decoder.gleam:22-28`

**Return Type:** `decode.Decoder(FoodSimple)`

**Fields Decoded:**
```gleam
pub fn food_simple_decoder() -> decode.Decoder(FoodSimple) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.field("plural_name", decode.optional(decode.string))

  decode.success(FoodSimple(id: id, name: name, plural_name: plural_name))
}
```

| Field | Type | Required | Decoded |
|-------|------|----------|---------|
| id | Int | Yes | ✅ |
| name | String | Yes | ✅ |
| plural_name | Option(String) | No | ✅ |

**Output:** `FoodSimple(id: Int, name: String, plural_name: Option(String))` ← **3-FIELD VERSION**

**Used By:**
- `food_decoder.food_decoder()` (line 55) - For decoding nested recipe field

---

## API Function Usage Analysis

### Food API Functions (ALL use 8-field decoder)

| API Function | File | Line | Decoder Used | Return Type |
|--------------|------|------|--------------|-------------|
| `get_food()` | api/food/get.gleam | 33 | `food_decoder.food_decoder()` | `Result(Food, TandoorError)` |
| `list_foods()` | api/food/list.gleam | 48 | `recipe_decoder.food_decoder()` ← **WRONG!** | `Result(PaginatedResponse(TandoorFood), TandoorError)` |
| `create_food()` | api/food/create.gleam | 37 | `recipe_decoder.food_decoder()` ← **WRONG!** | `Result(TandoorFood, TandoorError)` |
| `update_food()` | api/food/update.gleam | 40 | `recipe_decoder.food_decoder()` ← **WRONG!** | `Result(TandoorFood, TandoorError)` |

---

## Critical Type Mismatches

### Mismatch 1: list_foods() - CRITICAL BUG

**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/list.gleam:46-49`

```gleam
// Line 12: Import declares return type as TandoorFood
import meal_planner/tandoor/types.{type TandoorFood}

// Line 33: Function signature promises TandoorFood (2-field)
) -> Result(PaginatedResponse(TandoorFood), TandoorError) {

// Line 48: Uses recipe_decoder.food_decoder() which produces TandoorFood (2-field)
crud_helpers.parse_json_single(
  resp,
  http.paginated_decoder(recipe_decoder.food_decoder()),  // ← 2-FIELD decoder
)
```

**Issue:**
- Declares return type as `TandoorFood` (2-field from types.gleam)
- Uses `recipe_decoder.food_decoder()` which produces 2-field TandoorFood
- But API response contains 8 fields!
- **6 fields are silently discarded!**

**Expected API Response:**
```json
{
  "id": 1,
  "name": "Tomato",
  "plural_name": "Tomatoes",
  "description": "Fresh red tomatoes",
  "recipe": null,
  "food_onhand": true,
  "supermarket_category": null,
  "ignore_shopping": false
}
```

**Actually Decoded:** Only `id` and `name` - other 6 fields ignored!

---

### Mismatch 2: create_food() - CRITICAL BUG

**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/create.gleam:36-37`

```gleam
// Line 11: Import declares return type as TandoorFood
import meal_planner/tandoor/types.{type TandoorFood, type TandoorFoodCreateRequest}

// Line 32: Function signature promises TandoorFood (2-field)
) -> Result(TandoorFood, TandoorError) {

// Line 37: Uses recipe_decoder.food_decoder() which produces TandoorFood (2-field)
crud_helpers.parse_json_single(resp, recipe_decoder.food_decoder())  // ← 2-FIELD decoder
```

**Issue:** Same as list_foods() - API returns 8 fields, decoder only captures 2!

---

### Mismatch 3: update_food() - CRITICAL BUG

**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/update.gleam:39-40`

```gleam
// Line 12: Import declares return type as TandoorFood
import meal_planner/tandoor/types.{type TandoorFood, type TandoorFoodCreateRequest}

// Line 35: Function signature promises TandoorFood (2-field)
) -> Result(TandoorFood, TandoorError) {

// Line 40: Uses recipe_decoder.food_decoder() which produces TandoorFood (2-field)
crud_helpers.parse_json_single(resp, recipe_decoder.food_decoder())  // ← 2-FIELD decoder
```

**Issue:** Same as create_food() - discards 6 fields!

---

### Mismatch 4: get_food() - CORRECT ✅

**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/get.gleam:32-33`

```gleam
// Line 10: Import declares return type as Food (8-field)
import meal_planner/tandoor/types/food/food.{type Food}

// Line 29: Function signature promises Food (8-field)
) -> Result(Food, TandoorError) {

// Line 33: Uses food_decoder.food_decoder() which produces Food (8-field)
crud_helpers.parse_json_single(resp, food_decoder.food_decoder())  // ← 8-FIELD decoder ✅
```

**Status:** ✅ **CORRECT** - Uses proper 8-field decoder and type!

---

## Decoder vs. Return Type Summary

| Decoder Function | Module | Output Type | Fields | Used By |
|-----------------|--------|-------------|--------|---------|
| `recipe_decoder.food_decoder()` | `tandoor/decoders/recipe/recipe_decoder.gleam` | `TandoorFood` | 2 | ❌ list_foods, create_food, update_food (WRONG) |
| `food_decoder.food_decoder()` | `tandoor/decoders/food/food_decoder.gleam` | `Food` | 8 | ✅ get_food (CORRECT) |
| `food_decoder.food_simple_decoder()` | `tandoor/decoders/food/food_decoder.gleam` | `FoodSimple` | 3 | Nested recipe field |

---

## Root Cause Analysis

### The Problem

There are **TWO different `TandoorFood` concepts** in the codebase:

1. **Legacy Recipe Context**: TandoorFood(id, name) - Used for ingredient food references in recipes
2. **Food API Context**: Food(8 fields) - Used for standalone food CRUD operations

The decoder naming is confusing:
- `recipe_decoder.food_decoder()` → Produces **2-field TandoorFood** (for recipes)
- `food_decoder.food_decoder()` → Produces **8-field Food** (for food API)

### Why This Breaks

Three Food API functions use the **wrong decoder**:

```gleam
// ❌ WRONG: Uses 2-field decoder for 8-field API response
list_foods() -> Result(PaginatedResponse(TandoorFood), ...)
  Uses: recipe_decoder.food_decoder()  // 2-field decoder

create_food() -> Result(TandoorFood, ...)
  Uses: recipe_decoder.food_decoder()  // 2-field decoder

update_food() -> Result(TandoorFood, ...)
  Uses: recipe_decoder.food_decoder()  // 2-field decoder

// ✅ CORRECT: Uses 8-field decoder
get_food() -> Result(Food, ...)
  Uses: food_decoder.food_decoder()  // 8-field decoder
```

**Result:** 6 fields are silently dropped from API responses!

---

## Impact Assessment

### Data Loss

When calling `list_foods()`, `create_food()`, or `update_food()`:

**Lost Fields:**
- `plural_name` - Food plural form (e.g., "Tomatoes")
- `description` - Food description
- `recipe` - Associated recipe reference
- `food_onhand` - Inventory status
- `supermarket_category` - Category reference
- `ignore_shopping` - Shopping list flag

**Retained Fields:**
- `id` - Food ID
- `name` - Food name

**Severity:** 🔴 **CRITICAL** - 75% of food data is discarded!

---

## Recommendations

### Option 1: Standardize on 8-field Food type (RECOMMENDED)

**Change:**
1. Update `list_foods()`, `create_food()`, `update_food()` to:
   - Return type: `Food` instead of `TandoorFood`
   - Use decoder: `food_decoder.food_decoder()` instead of `recipe_decoder.food_decoder()`

2. Keep `TandoorFood` (2-field) only for recipe ingredient references

**Impact:**
- ✅ Captures all food data from API
- ✅ Consistent with `get_food()`
- ⚠️ Breaking change - consumers expecting `TandoorFood` need updates

---

### Option 2: Create explicit conversion functions

**Create:**
```gleam
// Convert Food to TandoorFood (lossy)
pub fn food_to_tandoor_food(food: Food) -> TandoorFood {
  TandoorFood(id: food.id, name: food.name)
}

// Convert TandoorFood to Food (requires defaults)
pub fn tandoor_food_to_food(tf: TandoorFood) -> Food {
  Food(
    id: tf.id,
    name: tf.name,
    plural_name: option.None,
    description: "",
    recipe: option.None,
    food_onhand: option.None,
    supermarket_category: option.None,
    ignore_shopping: False,
  )
}
```

**Impact:**
- ⚠️ Still loses data
- ⚠️ Adds complexity

---

### Option 3: Rename types for clarity (BEST)

**Rename:**
- `TandoorFood` → `RecipeFood` (2-field version for ingredients)
- `Food` → `TandoorFood` (8-field version for API)
- `FoodSimple` → `FoodReference` (3-field nested reference)

**Impact:**
- ✅ Clear semantic distinction
- ⚠️ Large refactoring effort
- ✅ Future-proof naming

---

## Next Steps for Debugging Agent

### Immediate Actions Required:

1. **Confirm API Response Schema:**
   - Check actual Tandoor API response for `/api/food/` endpoint
   - Verify all 8 fields are returned

2. **Test Current Behavior:**
   - Call `list_foods()` and inspect returned data
   - Verify if missing fields cause issues in consuming code

3. **Choose Fix Strategy:**
   - Recommend Option 1 (standardize on 8-field) or Option 3 (rename)

4. **Update Affected Files:**
   - `api/food/list.gleam`
   - `api/food/create.gleam`
   - `api/food/update.gleam`

---

## File Map

### Type Definitions
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types.gleam:66` - `TandoorFood` (2-field)
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types/food/food.gleam:10-30` - `Food` (8-field)
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/types/food/food_simple.gleam:5-14` - `FoodSimple` (3-field)

### Decoders
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/recipe/recipe_decoder.gleam:116-121` - 2-field decoder
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/food/food_decoder.gleam:50-73` - 8-field decoder
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/decoders/food/food_decoder.gleam:22-28` - 3-field decoder

### API Functions (Food Module)
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/get.gleam` - ✅ CORRECT
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/list.gleam` - ❌ WRONG DECODER
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/create.gleam` - ❌ WRONG DECODER
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/tandoor/api/food/update.gleam` - ❌ WRONG DECODER

---

## Conclusion

**The type inconsistency is CONFIRMED:**

- **Root Cause:** Two different `TandoorFood` concepts exist (2-field vs 8-field)
- **Bug Location:** 3 API functions use wrong decoder (2-field instead of 8-field)
- **Data Loss:** 75% of food data silently discarded
- **Fix Required:** Update list/create/update functions to use 8-field decoder

**Next Agent:** Debug/Fix agent should implement Option 1 (standardize on 8-field Food type) or Option 3 (rename for clarity).
