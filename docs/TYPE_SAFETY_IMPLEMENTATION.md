# Type Safety Enhancement Implementation - meal-planner-c3wt

## Summary

This document outlines the partial implementation of type safety enhancements for the meal planner codebase, specifically replacing string-based IDs with typed wrappers.

## Work Completed

### 1. Created Opaque Type Module (`meal_planner/id.gleam`)

Implemented a comprehensive ID type module with the following opaque types:

- **FdcId**: Food Data Central ID (Int-based) for USDA database identifiers
- **RecipeId**: Recipe identifier (String-based) for meal planner recipes
- **UserId**: User account identifier (String-based)
- **CustomFoodId**: User-created food identifier (String-based)
- **LogEntryId**: Food log entry identifier (String-based)

#### Features Implemented:

**Constructors**:
- Unsafe constructors: `fdc_id()`, `recipe_id()`, etc. - for trusted sources
- Validated constructors: `fdc_id_validated()`, etc. - with validation logic
  - FdcId validation: ensures positive integers
  - String ID validation: ensures non-empty strings

**Accessors**:
- `*_to_string()`: Convert ID to String for display
- `fdc_id_to_int()`: Extract raw Int from FdcId
- `fdc_id_from_string()`: Parse FdcId from String with validation

**JSON Support**:
- Encoders: `*_to_json()` for all ID types
- Decoders: `*_decoder()` with built-in validation

**Equality**:
- `*_equal()` functions for type-safe ID comparison

### 2. Updated Core Types (`meal_planner/types.gleam`)

Modified core data types to use the new typed IDs:

```gleam
pub type CustomFood {
  CustomFood(
    id: CustomFoodId,        // was: String
    user_id: UserId,         // was: String
    ...
  )
}

pub type Recipe {
  Recipe(
    id: RecipeId,            // was: String
    ...
  )
}

pub type UserProfile {
  UserProfile(
    id: UserId,              // was: String
    ...
  )
}

pub type FoodLogEntry {
  FoodLogEntry(
    id: LogEntryId,          // was: String
    recipe_id: RecipeId,     // was: String
    ...
  )
}

pub type FoodSource {
  RecipeSource(recipe_id: RecipeId)           // was: String
  CustomFoodSource(custom_food_id: CustomFoodId, user_id: UserId)  // was: String, String
  UsdaFoodSource(fdc_id: FdcId)               // was: Int
}

pub type FoodSearchResult {
  UsdaFoodResult(
    fdc_id: FdcId,           // was: Int
    ...
  )
  ...
}
```

**Updated JSON Encoders**:
- `recipe_to_json()`: Uses `id.recipe_id_to_json()`
- `user_profile_to_json()`: Uses `id.user_id_to_json()`
- `food_log_entry_to_json()`: Uses `id.log_entry_id_to_json()` and `id.recipe_id_to_json()`
- `custom_food_to_json()`: Uses `id.custom_food_id_to_json()` and `id.user_id_to_json()`
- `food_search_result_to_json()`: Uses `id.fdc_id_to_json()`

**Updated JSON Decoders**:
- `custom_food_decoder()`: Uses `id.custom_food_id_decoder()` and `id.user_id_decoder()`
- `recipe_decoder()`: Uses `id.recipe_id_decoder()`
- `user_profile_decoder()`: Uses `id.user_id_decoder()`
- `food_log_entry_decoder()`: Uses `id.log_entry_id_decoder()` and `id.recipe_id_decoder()`

### 3. Phantom Types (Design Only - Not Implemented)

Designed but did not implement phantom type states for database tracking:

```gleam
pub type Validated
pub type Unvalidated
pub type Persisted
pub type New

pub opaque type IdWithState(id_type, state) {
  IdWithState(id: id_type)
}
```

This would enable compile-time tracking of ID states, e.g.:
- `IdWithState(RecipeId, New)`: Recipe ID not yet in database
- `IdWithState(RecipeId, Persisted)`: Recipe ID confirmed in database
- `IdWithState(RecipeId, Validated)`: Recipe ID validated but not yet persisted

## Work Remaining

### Storage Layer Updates

Multiple storage modules need to be updated to use typed IDs:

1. **`storage/profile.gleam`**: Update UserProfile queries to use UserId
2. **`storage/recipes.gleam`**: Update Recipe queries to use RecipeId
3. **`storage/foods.gleam`**: Update food queries to use FdcId and CustomFoodId
4. **`storage/logs.gleam`**: Update food log queries to use LogEntryId and RecipeId
5. **`storage.gleam`**: Update main storage interface

### Web Handler Updates

All web handlers need updates for typed IDs:

1. **`web/handlers/recipe.gleam`**: RecipeId in URL params and forms
2. **`web/handlers/food_log.gleam`**: LogEntryId and RecipeId handling
3. **`web/handlers/search.gleam`**: FdcId and CustomFoodId in search results
4. **`web/handlers/profile.gleam`**: UserId handling
5. **`web/handlers/custom_foods.gleam`**: CustomFoodId and UserId handling

### Additional Modules

Other modules that reference IDs:

1. **`food_search.gleam`**: FdcId and CustomFoodId handling
2. **`auto_planner/*.gleam`**: RecipeId handling in planners
3. **`external/recipe_fetcher.gleam`**: RecipeId handling
4. **`ui/**/*.gleam`**: ID handling in UI components

### Testing

1. Update all test files to use typed IDs
2. Add specific tests for ID validation
3. Add tests for ID equality functions
4. Test JSON encoding/decoding with typed IDs

## Benefits Achieved (When Complete)

1. **Type Safety**: Cannot mix RecipeId with UserId or FdcId
2. **Self-Documenting**: Function signatures clearly show ID types needed
3. **Compile-Time Validation**: Type errors caught at compile time, not runtime
4. **Refactoring Safety**: Changing ID representation only requires changes in `id.gleam`
5. **Validation Centralization**: All ID validation logic in one module

## Migration Strategy (Recommended)

To complete this work:

1. **Module-by-Module Approach**:
   - Update one storage module at a time
   - Update corresponding web handlers
   - Run tests after each module
   - Commit working state

2. **Use Type-Driven Development**:
   - Let compiler errors guide you to all places needing updates
   - Fix compilation errors systematically
   - Each fix makes more of the codebase type-safe

3. **Validation Strategy**:
   - Use validated constructors at system boundaries (HTTP handlers, database queries)
   - Use unsafe constructors for internal operations with trusted data
   - Document when and why unsafe constructors are used

4. **Testing Priority**:
   - Test ID validation functions thoroughly
   - Test JSON encoding/decoding round-trips
   - Test database operations with typed IDs
   - Add property tests for ID equality and validation

## Example Usage

### Before (Unsafe):
```gleam
pub fn get_recipe(db: Connection, recipe_id: String) -> Result(Recipe, Error) {
  // Could accidentally pass user_id here!
}

pub fn log_food(user_id: String, recipe_id: String) {
  // IDs could be swapped and compiler won't catch it
}
```

### After (Type-Safe):
```gleam
pub fn get_recipe(db: Connection, recipe_id: RecipeId) -> Result(Recipe, Error) {
  // Only RecipeId accepted - compile error if wrong type passed
}

pub fn log_food(user_id: UserId, recipe_id: RecipeId) {
  // Cannot swap IDs - compiler will reject
}
```

## Files Created/Modified

### Created:
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/id.gleam` (241 lines)

### Modified:
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/types.gleam`:
  - Added import of ID types
  - Updated 5 type definitions
  - Updated 5 JSON encoders
  - Updated 4 JSON decoders

## Compilation Status

- **Core types module**: ✅ Compiles successfully
- **ID module**: ✅ Compiles successfully
- **Storage modules**: ❌ Need updates (cascading type errors)
- **Web handlers**: ❌ Need updates (cascading type errors)
- **UI components**: ❌ Need updates (cascading type errors)

## Next Steps

1. Fix storage/profile.gleam to use UserId
2. Fix storage/recipes.gleam to use RecipeId
3. Fix storage/foods.gleam to use FdcId and CustomFoodId
4. Continue through remaining modules systematically
5. Run full test suite
6. Update documentation

## Notes

This implementation represents a significant architectural improvement that will pay dividends in code quality, maintainability, and bug prevention. The compile-time guarantees provided by opaque types prevent an entire class of ID-related bugs.

The work is approximately 20% complete. The core infrastructure is in place, but systematic updates across ~30-40 modules are required to complete the migration.

---

**Implementation Date**: 2025-12-08
**Bead**: meal-planner-c3wt
**Status**: Partial - Core infrastructure complete, module updates in progress
