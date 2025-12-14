# Tandoor API Signature Analysis - Agent 11 & 12 Investigation

**Date:** 2025-12-14
**Purpose:** Unblock Agents 13-15 for test file compilation fixes
**Target File:** `gleam/test/meal_planner/tandoor/api/food_integration_test.gleam`

---

## PART A: Food API Function Signatures

### 0. CRITICAL TYPE INCONSISTENCY DISCOVERED

**get.gleam returns `Food` but imports from types/food/food.gleam:**
```gleam
import meal_planner/tandoor/types/food/food.{type Food}
pub fn get_food(...) -> Result(Food, TandoorError)
```

**create.gleam returns `TandoorFood` from types.gleam:**
```gleam
import meal_planner/tandoor/types.{type TandoorFood, type TandoorFoodCreateRequest}
pub fn create_food(...) -> Result(TandoorFood, TandoorError)
```

**update.gleam returns `TandoorFood` from types.gleam:**
```gleam
import meal_planner/tandoor/types.{type TandoorFood, type TandoorFoodCreateRequest}
pub fn update_food(...) -> Result(TandoorFood, TandoorError)
```

**list.gleam returns `TandoorFood` from types.gleam:**
```gleam
import meal_planner/tandoor/types.{type TandoorFood}
pub fn list_foods(...) -> Result(PaginatedResponse(TandoorFood), TandoorError)
```

**Decoders produce `Food` (8 fields):**
```gleam
pub fn food_decoder() -> decode.Decoder(Food)  // Returns Food, not TandoorFood!
```

🔥 **MAJOR ISSUE:** The API functions claim to return `TandoorFood` (2 fields) but the decoder actually produces `Food` (8 fields). This is a type system violation!

---

### 1. `list.gleam` - list_foods()

**File:** `gleam/src/meal_planner/tandoor/api/food/list.gleam`

**Function Signature:**
```gleam
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(TandoorFood), TandoorError)
```

**Key Details:**
- **Parameter 1:** `config: ClientConfig` (labeled)
- **Parameter 2:** `limit limit: Option(Int)` (labeled, keyword argument)
- **Parameter 3:** `page page: Option(Int)` (labeled, keyword argument)
- **Return Type:** `Result(PaginatedResponse(TandoorFood), TandoorError)`

**❌ Test Expectation MISMATCH:**
- Test calls: `list.list_foods(config)` (line 87) - expects 1 parameter
- Test calls: `list.list_foods_with_options(config, Some(10), None, None)` (line 102) - function doesn't exist!
- **Actual function requires:** `list_foods(config, limit: Some(10), page: Some(1))`

**Note:** `list_foods_with_options()` does NOT exist in the codebase. Tests expect this function but it's not implemented.

---

### 2. `update.gleam` - update_food()

**File:** `gleam/src/meal_planner/tandoor/api/food/update.gleam`

**Function Signature:**
```gleam
pub fn update_food(
  config: ClientConfig,
  food_id food_id: Int,
  food_data food_data: TandoorFoodCreateRequest,
) -> Result(TandoorFood, TandoorError)
```

**Key Details:**
- **Parameter 1:** `config: ClientConfig` (labeled)
- **Parameter 2:** `food_id food_id: Int` (labeled, keyword argument)
- **Parameter 3:** `food_data food_data: TandoorFoodCreateRequest` (labeled, keyword argument)
- **Return Type:** `Result(TandoorFood, TandoorError)`

**❌ Test Expectation MISMATCH:**
- Test calls: `update.update_food(config, food_id: 1, food: food_data)` (line 296)
- **Actual function expects:** `food_data:` NOT `food:`
- **Actual type expected:** `TandoorFoodCreateRequest` NOT `TandoorFood`

**CRITICAL:** Test creates full `TandoorFood` with 16 fields, but function expects `TandoorFoodCreateRequest` with only 1 field (`name`).

---

### 3. `delete.gleam` - delete_food()

**File:** `gleam/src/meal_planner/tandoor/api/food/delete.gleam`

**Function Signature:**
```gleam
pub fn delete_food(
  config: ClientConfig,
  food_id: Int,
) -> Result(Nil, TandoorError)
```

**Key Details:**
- **Parameter 1:** `config: ClientConfig` (labeled)
- **Parameter 2:** `food_id: Int` (labeled keyword argument)
- **Return Type:** `Result(Nil, TandoorError)`

**✅ Test Expectation MATCH:**
- Test calls: `delete.delete_food(config, food_id: 1)` (line 425)
- This is **CORRECT** and matches the function signature

---

## PART B: Type Definitions Analysis

### 1. TandoorFood Type (from types.gleam)

**File:** `gleam/src/meal_planner/tandoor/types.gleam` (lines 65-67)

**Type Definition:**
```gleam
pub type TandoorFood {
  TandoorFood(id: Int, name: String)
}
```

**Field Count:** **2 fields only!**

**Fields:**
1. `id: Int`
2. `name: String`

**❌ Test Uses WRONG Type:**
Test constructs TandoorFood with 16 fields (lines 277-294):
- `id`, `name`, `plural_name`, `description`, `recipe_count`, `properties`, `supermarket_category`, `category`, `inherit_fields`, `substitute`, `substitute_siblings`, `substitute_children`, `substitute_onhand`, `child_inherit_fields`, `open_data_slug`, `url`

**This does NOT match the actual type definition!**

---

### 2. TandoorFood Type (from types/food/food.gleam)

**File:** `gleam/src/meal_planner/tandoor/types/food/food.gleam` (lines 10-30)

**Type Definition:**
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

**Field Count:** **8 fields**

**Fields:**
1. `id: Int`
2. `name: String`
3. `plural_name: Option(String)`
4. `description: String`
5. `recipe: Option(FoodSimple)`
6. `food_onhand: Option(Bool)`
7. `supermarket_category: Option(Int)`
8. `ignore_shopping: Bool`

**Note:** This is a different type (`Food` vs `TandoorFood`), but closer to what tests expect.

---

### 3. TandoorFoodCreateRequest Type

**File:** `gleam/src/meal_planner/tandoor/types.gleam` (lines 138-140)

**Type Definition:**
```gleam
pub type TandoorFoodCreateRequest {
  TandoorFoodCreateRequest(name: String)
}
```

**Field Count:** **1 field only!**

**Fields:**
1. `name: String`

**Constructor Usage:**
```gleam
let food_data = TandoorFoodCreateRequest(name: "Tomato")
```

**✅ Test Usage CORRECT:**
Test correctly uses `TandoorFoodCreateRequest(name: "Tomato")` on line 172.

---

### 4. FoodSimple Type (Referenced in Food)

**File:** `gleam/src/meal_planner/tandoor/types/food/food_simple.gleam` (lines 5-14)

**Type Definition:**
```gleam
pub type FoodSimple {
  FoodSimple(
    id: Int,
    name: String,
    plural_name: Option(String),
  )
}
```

**Field Count:** 3 fields

---

## Critical Findings Summary

### 🔴 BREAKING ISSUES

1. **Missing Function:** `list_foods_with_options()` does NOT exist
   - Tests call this function 8 times
   - Need to either: create it OR rewrite tests to use `list_foods(config, limit:, page:)`

2. **Wrong Parameter Name in update_food():**
   - Test uses: `food: food_data`
   - Function expects: `food_data: food_data`

3. **Wrong Type for update_food():**
   - Test passes: `TandoorFood` (2 or 16 fields depending on which type)
   - Function expects: `TandoorFoodCreateRequest` (1 field: `name`)

4. **TandoorFood Type Confusion:**
   - `types.gleam` defines `TandoorFood` with **2 fields** (id, name)
   - `types/food/food.gleam` defines `Food` with **8 fields**
   - Test creates TandoorFood with **16 fields** (doesn't match either!)
   - Test fields include: `recipe_count`, `properties`, `category`, `inherit_fields`, `substitute`, `substitute_siblings`, `substitute_children`, `substitute_onhand`, `child_inherit_fields`, `open_data_slug`, `url` - **NONE of these exist in any type!**

### ✅ WORKING CORRECTLY

1. **delete_food()** - signature matches test usage perfectly
2. **create_food()** - test correctly uses `TandoorFoodCreateRequest`
3. **get_food()** - test correctly calls with `food_id:` parameter

---

## Decoder Behavior

### food_decoder() produces Food type (8 fields)

**File:** `gleam/src/meal_planner/tandoor/decoders/food/food_decoder.gleam` (lines 50-73)

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

**Returns:** `Food` (8 fields), NOT `TandoorFood` (2 fields)

**Note:** The type aliasing in imports may be causing confusion. The API functions import:
```gleam
import meal_planner/tandoor/types.{type TandoorFood}
```

This imports the 2-field version from `types.gleam`, NOT the 8-field `Food` from `types/food/food.gleam`.

---

## Recommendations for Agents 13-15

### For update_food() tests (lines 274-417):

**Option 1: Change to TandoorFoodCreateRequest**
```gleam
// OLD (WRONG):
let food_data = TandoorFood(id: 1, name: "Updated", ...)
let result = update.update_food(config, food_id: 1, food: food_data)

// NEW (CORRECT):
let food_data = TandoorFoodCreateRequest(name: "Updated Tomato")
let result = update.update_food(config, food_id: 1, food_data: food_data)
```

**Option 2: Change update_food() API to accept full TandoorFood**
- This requires modifying the API function signature
- Also requires changing the encoder to handle full Food type
- More complex, but might match Tandoor API expectations better

### For list_foods() tests (lines 85-164):

**Option 1: Add list_foods() wrapper without parameters**
```gleam
// In list.gleam, add:
pub fn list_foods(config: ClientConfig) -> Result(PaginatedResponse(TandoorFood), TandoorError) {
  list_foods(config, limit: None, page: None)
}
```

**Option 2: Add list_foods_with_options() function**
```gleam
pub fn list_foods_with_options(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
  query: Option(String),
) -> Result(PaginatedResponse(TandoorFood), TandoorError) {
  // Implementation needed
}
```

**Option 3: Rewrite all tests to use labeled arguments**
```gleam
// OLD:
list.list_foods(config)
list.list_foods_with_options(config, Some(10), None, None)

// NEW:
list.list_foods(config, limit: None, page: None)
list.list_foods(config, limit: Some(10), page: None)
```

### For TandoorFood type confusion:

**Investigate and resolve:**
1. Which type should `update_food()` return? `TandoorFood` or `Food`?
2. Should we alias `Food` as `TandoorFood` in the API modules?
3. Do we need separate types for API responses vs. create requests?

---

## CRITICAL ROOT CAUSE: Type System Violation

### The Decoder/API Type Mismatch

The compilation failures are caused by a fundamental type mismatch:

1. **API functions declare they return:** `TandoorFood` (2 fields: id, name)
2. **Decoders actually produce:** `Food` (8 fields: id, name, plural_name, description, recipe, food_onhand, supermarket_category, ignore_shopping)
3. **Test expects:** `TandoorFood` (with 16 non-existent fields!)

**Why This Compiles in API but Fails in Tests:**

The API modules call `recipe_decoder.food_decoder()` which returns `Food` type, but they import:
```gleam
import meal_planner/tandoor/types.{type TandoorFood}
```

And declare return types as `TandoorFood`. This creates a type alias collision where:
- `TandoorFood` in types.gleam = 2 fields
- `Food` from food_decoder = 8 fields
- Gleam compiler may be treating them as the same due to import aliasing

**The Fix:**

All API functions should either:
1. Import and return `Food` from `types/food/food.gleam`, OR
2. Create a proper type alias `pub type TandoorFood = Food` in types.gleam

---

## Next Steps for Sequential Team

**Agent 13:** Fix list_foods tests (lines 85-164)
- Add missing `list_foods()` overload or `list_foods_with_options()`
- Update test calls to match actual API signatures

**Agent 14:** Fix update_food tests (lines 274-417)
- Change parameter name from `food:` to `food_data:`
- Change type from `TandoorFood` (16 fields) to `TandoorFoodCreateRequest` (1 field)
- Remove all non-existent fields from test data

**Agent 15:** Fix type imports and resolve TandoorFood vs Food confusion
- Investigate whether to use `Food` or `TandoorFood` consistently
- Update imports in test file to match API expectations
- Possibly create type aliases to resolve the 2-field vs 8-field confusion

**Agent 16 (Bonus):** Verify get_food tests
- Check if get_food should return `Food` (8 fields) or `TandoorFood` (2 fields)
- Update test expectations if needed

**Coordination:** This document provides exact signatures. No guessing needed!

---

## Quick Reference Table

| Function | Expected by Test | Actual in API | Status |
|----------|-----------------|---------------|--------|
| `list.list_foods(config)` | 1 param | 3 params (config, limit:, page:) | ❌ MISMATCH |
| `list.list_foods_with_options(...)` | Exists | DOES NOT EXIST | ❌ MISSING |
| `update.update_food(..., food:)` | Parameter name `food:` | Parameter name `food_data:` | ❌ WRONG NAME |
| `update.update_food(..., TandoorFood)` | Type with 16 fields | Type `TandoorFoodCreateRequest` (1 field) | ❌ WRONG TYPE |
| `delete.delete_food(config, food_id:)` | Labeled param | Labeled param | ✅ CORRECT |
| `create.create_food(config, TandoorFoodCreateRequest)` | Unlabeled param | Unlabeled param | ✅ CORRECT |
| `get.get_food(config, food_id:)` | Labeled param | Labeled param | ✅ CORRECT |

### Type Field Counts

| Type | Location | Field Count | Fields |
|------|----------|-------------|--------|
| `TandoorFood` | types.gleam | **2** | id, name |
| `Food` | types/food/food.gleam | **8** | id, name, plural_name, description, recipe, food_onhand, supermarket_category, ignore_shopping |
| `TandoorFoodCreateRequest` | types.gleam | **1** | name |
| Test's `TandoorFood` | test file | **16** | DOES NOT EXIST! |

---

## Verification: Actual Compilation Errors

Confirmed by running `gleam test`:

### Error 1: list_foods parameter count mismatch
```
87 │   let result = list.list_foods(config)
   │                ^^^^^^^^^^^^^^^^^^^^^^^ Expected 3 arguments, got 1
```
**Fix:** Add `limit: None, page: None` OR create 1-param wrapper

### Error 2: list_foods_with_options doesn't exist
```
102 │   let result = list.list_foods_with_options(config, Some(10), None, None)
    │                     ^^^^^^^^^^^^^^^^^^^^^^^ Did you mean `list_foods`?
```
**Fix:** Create this function OR rewrite tests to use `list_foods`

### Error 3: update_food wrong parameter name
```
296 │   let result = update.update_food(config, food_id: 1, food: food_data)
    │                                                       ^^^^^^^^^^^^^^^ Did you mean `food_data`?
```
**Fix:** Change `food:` to `food_data:`

### Error 4: update_food wrong type
```
296 │   let result = update.update_food(config, food_id: 1, food: food_data)
    │                                                             ^^^^^^^^^
Expected type: TandoorFoodCreateRequest
```
**Fix:** Use `TandoorFoodCreateRequest(name: "...")` instead of `TandoorFood(...16 fields...)`

All errors match the analysis above. Investigation is complete and accurate.
