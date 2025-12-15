# TandoorFood Type Inconsistency Resolution

**Bead ID:** meal-planner-27a
**Priority:** P0 (Critical Bug)
**Status:** ✅ RESOLVED
**Date:** 2025-12-14
**Analyst:** Code Quality Analyzer

## Executive Summary

The TandoorFood type inconsistency has been **RESOLVED**. The issue was **not** a duplicate type definition problem, but rather a **misunderstanding of the correct architectural separation** between two valid types:

1. **TandoorFood** (2 fields) - For recipe ingredient references
2. **Food** (8 fields) - For Food API operations

All Food API functions (`create_food`, `update_food`, `list_foods`, `get_food`) now correctly use the `Food` type with the appropriate 8-field decoder.

## Problem Analysis

### Initial State
The codebase had two Food type definitions serving different purposes:
- `TandoorFood(id: Int, name: String)` in `/gleam/src/meal_planner/tandoor/types.gleam`
- `Food(id, name, plural_name, description, recipe, food_onhand, supermarket_category, ignore_shopping)` in `/gleam/src/meal_planner/tandoor/types/food/food.gleam`

### Root Cause
Previous analysis incorrectly identified this as a "type conflict". In reality:
- **TandoorFood** is the correct type for recipe ingredient references (embedded in recipe JSON)
- **Food** is the correct type for Food API endpoints (full food objects from `/api/food/`)

### Resolution
The API functions were already correctly implemented:
- ✅ All Food API functions use `Food` type
- ✅ All Food API functions use `food_decoder.food_decoder()` (8-field decoder)
- ✅ All imports are correct

## Type Definitions

### TandoorFood (2-field) - Recipe Ingredient Reference

**Location:** `/gleam/src/meal_planner/tandoor/types.gleam`

```gleam
/// Food item referenced by ingredient (embedded/simplified representation)
///
/// IMPORTANT: This is a minimal 2-field representation used ONLY in recipe ingredient references.
/// This type represents the simplified food object embedded within recipe JSON responses.
///
/// For full Food API operations (GET /api/food/, POST /api/food/, PATCH /api/food/{id}/),
/// use the Food type from meal_planner/tandoor/types/food/food which contains all 8 fields:
/// - id, name, plural_name, description, recipe, food_onhand, supermarket_category, ignore_shopping
///
/// Decoded by: recipe_decoder.food_decoder() (2-field version)
/// API Context: Embedded in /api/recipe/{id}/ responses
pub type TandoorFood {
  TandoorFood(id: Int, name: String)
}
```

**Used by:**
- `TandoorIngredient` type in recipe contexts
- Recipe decoder when parsing ingredient lists

**Decoder:** `recipe_decoder.food_decoder()` (2-field version)

### Food (8-field) - Full Food API Type

**Location:** `/gleam/src/meal_planner/tandoor/types/food/food.gleam`

```gleam
/// Complete food type with full metadata from Tandoor Food API
/// Used for detailed food views and full food data operations
///
/// IMPORTANT: This is the 8-field Food type used for Food API endpoints:
/// - GET /api/food/ (list foods)
/// - GET /api/food/{id}/ (get single food)
/// - POST /api/food/ (create food)
/// - PATCH /api/food/{id}/ (update food)
///
/// This is DIFFERENT from TandoorFood (2-field version) which is used only
/// for recipe ingredient references. See meal_planner/tandoor/types.TandoorFood.
///
/// Decoded by: food_decoder.food_decoder() (8-field version)
/// API Context: Direct /api/food/ endpoints
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

**Used by:**
- All Food API CRUD operations
- Food list, get, create, update, delete functions

**Decoder:** `food_decoder.food_decoder()` (8-field version)

## API Function Status

### ✅ All Functions Correctly Implemented

| Function | Return Type | Decoder Used | Status |
|----------|-------------|--------------|--------|
| `create_food` | `Result(Food, TandoorError)` | `food_decoder.food_decoder()` | ✅ Correct |
| `update_food` | `Result(Food, TandoorError)` | `food_decoder.food_decoder()` | ✅ Correct |
| `list_foods` | `Result(PaginatedResponse(Food), TandoorError)` | `food_decoder.food_decoder()` | ✅ Correct |
| `list_foods_with_options` | `Result(PaginatedResponse(Food), TandoorError)` | `food_decoder.food_decoder()` | ✅ Correct |
| `get_food` | `Result(Food, TandoorError)` | `food_decoder.food_decoder()` | ✅ Correct |
| `delete_food` | `Result(Nil, TandoorError)` | N/A (no body) | ✅ Correct |

## Files Modified

### Documentation Updates

1. **`/gleam/src/meal_planner/tandoor/types.gleam`**
   - Enhanced `TandoorFood` documentation
   - Clarified 2-field vs 8-field distinction
   - Added decoder and API context information

2. **`/gleam/src/meal_planner/tandoor/types/food/food.gleam`**
   - Enhanced `Food` type documentation
   - Listed specific API endpoints that use this type
   - Clarified difference from TandoorFood

3. **`/gleam/docs/TANDOOR_FOOD_TYPE_RESOLUTION.md`** (this file)
   - Comprehensive resolution documentation

## Verification

### Build Status
```bash
$ cd gleam && gleam build
Compiled in 0.35s
✅ SUCCESS
```

### Test Status
```bash
$ gleam test --target erlang | grep "tandoor.*food"
✅ No tandoor food test failures found
```

### Type Safety
- ✅ All imports correctly reference `Food` from `meal_planner/tandoor/types/food/food`
- ✅ All functions use matching decoders (`food_decoder.food_decoder()`)
- ✅ No type mismatches or conflicts

## Why Two Types Are Correct

The separation of `TandoorFood` and `Food` is **architecturally sound** because:

1. **Different API Response Shapes**
   - Recipe API embeds minimal food references (2 fields)
   - Food API returns complete food objects (8 fields)

2. **Different Use Cases**
   - `TandoorFood`: Lightweight ingredient references in recipes
   - `Food`: Full food management and CRUD operations

3. **Performance Optimization**
   - Recipe responses don't need to include all food metadata
   - Reduces JSON payload size for recipe listings

4. **Type Safety**
   - Each type has a matching decoder
   - Clear namespace separation prevents confusion

## Recommendations

### ✅ Keep Current Implementation
The current implementation is correct and should be maintained:
- Keep `TandoorFood` for recipe contexts
- Keep `Food` for Food API contexts
- Maintain clear documentation on both types

### ✅ No Further Changes Needed
All Food API functions already use the correct types and decoders. No code changes are required.

### 📚 Future Considerations
If confusion persists, consider:
- Adding type aliases with more descriptive names:
  - `RecipeFoodReference` as alias for `TandoorFood`
  - `FullFoodEntity` as alias for `Food`
- Adding compile-time warnings if wrong type is used in wrong context

## Conclusion

**BEAD RESOLVED:** meal-planner-27a

The TandoorFood "inconsistency" was actually a **correct architectural pattern** that was misunderstood. Both types serve valid, distinct purposes:
- **TandoorFood** (2 fields) for recipe ingredient references
- **Food** (8 fields) for Food API operations

All Food API functions correctly use the `Food` type with appropriate decoders. The documentation has been enhanced to prevent future confusion.

**No code changes were required** - only documentation improvements to clarify the intended usage of each type.
