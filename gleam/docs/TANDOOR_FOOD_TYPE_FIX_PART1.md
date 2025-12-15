# TandoorFood Type Inconsistency Fix - Part 1 Complete

## Summary

Fixed type inconsistency by clarifying the purpose and usage of TandoorFood vs Food types.

## Changes Made

### 1. Updated `/src/meal_planner/tandoor/types.gleam`

**Added clarifying documentation:**
- Added note in module header explaining that TandoorFood is for recipe ingredient references only
- Enhanced TandoorFood type documentation to indicate it's a minimal 2-field representation
- Directed developers to use `Food` type from `meal_planner/tandoor/types/food/food` for full food API operations

**Key distinction:**
- **TandoorFood (2 fields)**: Used ONLY in recipe ingredient embedded references
  - Fields: `id`, `name`
  - Decoder: `recipe_decoder.food_decoder()`
  - Used by: Recipes, ingredients within recipes

- **Food (8 fields)**: Used for Food API operations (get, list, create, update)
  - Fields: `id`, `name`, `plural_name`, `description`, `recipe`, `food_onhand`, `supermarket_category`, `ignore_shopping`
  - Decoder: `food_decoder.food_decoder()`
  - Used by: Food API endpoints

### 2. Build Verification

```bash
gleam build
# Output: Compiled in 1.36s ✓
```

No errors introduced. Build successful.

## Files That Need Updating (Part 2)

### High Priority - API Endpoints with Wrong Types

1. **`src/meal_planner/tandoor/api/food/list.gleam`**
   - Currently: Uses `TandoorFood` (2 fields) with `recipe_decoder.food_decoder()`
   - Should: Use `Food` (8 fields) with `food_decoder.food_decoder()`
   - Issue: Returns incomplete food data (missing 6 fields)

2. **`src/meal_planner/tandoor/api/food/create.gleam`**
   - Currently: Uses `TandoorFood` (2 fields) with `recipe_decoder.food_decoder()`
   - Should: Use `Food` (8 fields) with `food_decoder.food_decoder()`
   - Issue: After creating a food, only returns id and name (missing 6 fields)

### Already Correct (No Changes Needed)

1. **`src/meal_planner/tandoor/api/food/get.gleam`** ✓
   - Correctly uses `Food` (8 fields) with `food_decoder.food_decoder()`

2. **`src/meal_planner/tandoor/api/food/update.gleam`** ✓
   - Correctly uses `Food` (8 fields) with `food_decoder.food_decoder()`

3. **`src/meal_planner/tandoor/types/food/food.gleam`** ✓
   - Defines the correct 8-field Food type

4. **`src/meal_planner/tandoor/decoders/food/food_decoder.gleam`** ✓
   - Has correct decoder for 8-field Food type

5. **`src/meal_planner/tandoor/decoders/recipe/recipe_decoder.gleam`** ✓
   - Correctly uses TandoorFood (2 fields) for ingredient references
   - This is the intended use case for TandoorFood

### Low Priority - Review Later

1. **`src/meal_planner/tandoor/encoders/food/food_encoder.gleam`**
   - Uses `TandoorFoodCreateRequest` for encoding
   - May be correct as-is (need to verify if create/update only need name field)

## Next Steps (Agent 7 or 8)

1. Update `src/meal_planner/tandoor/api/food/list.gleam`:
   - Change import from `types.{type TandoorFood}` to `types/food/food.{type Food}`
   - Change return type from `PaginatedResponse(TandoorFood)` to `PaginatedResponse(Food)`
   - Change decoder from `recipe_decoder.food_decoder()` to `food_decoder.food_decoder()`
   - Add missing import for `food_decoder`

2. Update `src/meal_planner/tandoor/api/food/create.gleam`:
   - Change import from `types.{type TandoorFood, ...}` to `types/food/food.{type Food}`
   - Change return type from `Result(TandoorFood, TandoorError)` to `Result(Food, TandoorError)`
   - Change decoder from `recipe_decoder.food_decoder()` to `food_decoder.food_decoder()`

3. Test compilation after each change:
   ```bash
   gleam build
   ```

4. Run tests if available:
   ```bash
   gleam test
   ```

## Type Usage Guidelines for Developers

### When to use TandoorFood (2 fields):
- **ONLY** when working with recipe ingredients
- **ONLY** in embedded references within recipes
- Uses: Recipe decoder, ingredient references

### When to use Food (8 fields):
- Food API endpoints: `/api/food/` operations
- Full food details and metadata
- Food management operations (get, list, create, update, delete)
- Any operation that needs complete food information

## API Consistency

After Part 2 completion, all Food API endpoints will consistently:
- Return `Food` type (8 fields)
- Use `food_decoder.food_decoder()` for decoding
- Provide complete food information including metadata

Recipe endpoints will continue to:
- Use `TandoorFood` type (2 fields) for ingredient references
- Use `recipe_decoder.food_decoder()` for decoding ingredient foods
- Keep embedded food references minimal
