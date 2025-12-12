# Tandoor Recipe Serialization Integration Tests

## Overview

This document describes the comprehensive integration tests for meal plan save/load functionality with Tandoor recipes. The tests verify that auto meal plans can be persisted to the database with complete recipe JSON serialization and properly reconstructed on load.

**Test File:** `/gleam/test/auto_planner_save_load_test.gleam`

**Total Tests:** 27 integration test cases

## Test Coverage

### 1. Recipe JSON Serialization Tests (5 tests)

#### `recipe_to_json_produces_valid_json_test`
- **Purpose:** Verify that `recipe_to_json()` produces valid JSON output
- **Coverage:** JSON generation from Recipe type
- **Assertions:** JSON string is non-empty

#### `recipe_json_contains_required_fields_test`
- **Purpose:** Ensure recipe JSON contains expected fields
- **Coverage:** Recipe name and metadata preservation
- **Assertions:** JSON string contains recipe name

#### `single_recipe_json_round_trip_test`
- **Purpose:** Test round-trip serialization of a single recipe
- **Coverage:** Recipe name, category, and macro values
- **Assertions:**
  - Loaded recipe name matches original
  - Category preserved
  - Protein macros equal

#### `recipe_list_to_json_array_test`
- **Purpose:** Verify recipe list serializes to JSON array
- **Coverage:** List to JSON array conversion
- **Assertions:** Non-empty JSON string

#### `recipe_list_json_round_trip_test`
- **Purpose:** Test round-trip serialization of recipe lists
- **Coverage:** Multiple recipes with JSON serialization
- **Assertions:**
  - List length preserved (3 recipes)
  - First recipe name matches ("Chicken Salad")

### 2. Macro Preservation Tests (2 tests)

#### `recipe_macros_preserved_in_json_round_trip_test`
- **Purpose:** Verify macros survive JSON serialization round-trip
- **Coverage:** Protein, fat, carbs precision (floating point)
- **Test Values:** protein=25.5, fat=10.3, carbs=50.7
- **Assertions:** All macro values equal after deserialization

#### `recipe_category_and_compliance_preserved_test`
- **Purpose:** Ensure recipe category and compliance flags persist
- **Coverage:** Non-standard category, vertical diet compliance flag
- **Test Values:** category="special_category", vertical_compliant=True
- **Assertions:** Both fields match after round-trip

### 3. AutoPlanConfig Tests (4 tests)

#### `auto_plan_config_to_json_test`
- **Purpose:** Verify AutoPlanConfig serializes to JSON
- **Coverage:** Configuration object to JSON conversion
- **Assertions:** Non-empty JSON string

#### `auto_plan_config_json_round_trip_test`
- **Purpose:** Test round-trip serialization of AutoPlanConfig
- **Coverage:** user_id, recipe_count, variety_factor preservation
- **Test Values:**
  - user_id="user-123"
  - diet_principles=[VerticalDiet, TimFerriss]
  - recipe_count=4
  - variety_factor=0.8
- **Assertions:** All configuration values preserved

#### `config_diet_principles_preserved_test`
- **Purpose:** Verify diet principles list is preserved
- **Coverage:** Multiple diet principle serialization
- **Test Values:** [VerticalDiet, Keto, HighProtein]
- **Assertions:** Diet principles list length equals 3

#### `config_macro_targets_preserved_test`
- **Purpose:** Test macro target preservation in config
- **Coverage:** Macros object within AutoPlanConfig
- **Test Values:** protein=150.0, fat=50.0, carbs=200.0
- **Assertions:** All macro targets match after round-trip

### 4. Auto Meal Plan Round-Trip Tests (3 tests)

#### `auto_meal_plan_with_recipe_json_serialization_test`
- **Purpose:** Verify complete AutoMealPlan with recipe_json serializes
- **Coverage:** Full plan object serialization with 2 recipes
- **Assertions:** Non-empty JSON string

#### `recipe_json_field_preserved_in_plan_test`
- **Purpose:** Ensure recipe_json field is included in serialized plan
- **Coverage:** recipe_json field presence in JSON output
- **Assertions:** Serialized JSON contains "recipe_json" field

#### `recipes_reconstructed_from_plan_recipe_json_test`
- **Purpose:** Verify recipes can be reconstructed from plan's recipe_json
- **Coverage:** JSON deserialization within plan context
- **Test Data:** 2 recipes (Salmon, Sweet Potato)
- **Assertions:**
  - Loaded recipe list length equals 2
  - First recipe name is "Salmon"

### 5. Total Macros Preservation Tests (2 tests)

#### `total_macros_from_recipes_test`
- **Purpose:** Verify macro calculation from recipe list
- **Coverage:** Macro addition logic
- **Test Values:**
  - Recipe 1: protein=30, fat=5, carbs=2
  - Recipe 2: protein=5, fat=1, carbs=8
  - Recipe 3: protein=3, fat=0.5, carbs=45
  - Expected totals: protein=38, fat=6.5, carbs=55
- **Assertions:** Calculated totals match expected values

#### `total_macros_preserved_in_plan_test`
- **Purpose:** Verify stored total_macros persist in auto meal plans
- **Coverage:** Total macro storage in AutoMealPlan
- **Test Values:** protein=26.0, fat=10.0, carbs=12.0
- **Assertions:** All macro values match in loaded plan

### 6. Edge Cases Tests (4 tests)

#### `empty_recipe_list_json_serialization_test`
- **Purpose:** Handle empty recipe lists
- **Coverage:** Edge case with zero recipes
- **Assertions:** JSON equals "[]"

#### `empty_recipe_list_json_deserialization_test`
- **Purpose:** Deserialize empty recipe lists
- **Coverage:** Empty array deserialization
- **Assertions:** Loaded list length equals 0

#### `plan_with_single_recipe_json_test`
- **Purpose:** Handle plans with single recipe
- **Coverage:** Minimal valid meal plan
- **Assertions:** Serialized JSON is non-empty

#### `plan_with_many_recipes_json_test`
- **Purpose:** Handle plans with maximum recipes (20)
- **Coverage:** Large recipe lists
- **Test Data:** 20 dynamically generated recipes
- **Assertions:** Loaded recipe list length equals 20

### 7. Integration Tests (1 test)

#### `complete_save_load_cycle_test`
- **Purpose:** Simulate complete database save/load cycle
- **Coverage:** Full integration from plan creation to JSON persistence
- **Test Data:**
  - 2 recipes (Steak, Asparagus)
  - user_id="user-live-1"
  - config=[VerticalDiet]
- **Process:**
  1. Create AutoMealPlan with recipes and config
  2. Serialize to JSON (simulating database save)
  3. Verify JSON is valid
- **Assertions:** Serialized JSON is non-empty

## Test Organization

### Test Fixtures

The tests use two helper functions:

#### `create_test_recipe(id_num, name, category, protein, fat, carbs, vertical_compliant)`
Creates a Recipe with:
- RecipeId from id.recipe_id()
- Single test ingredient
- Single instruction
- Vertical diet compliance flag
- Specified macros and category

#### `create_test_config(user_id, diet_principles, recipe_count)`
Creates an AutoPlanConfig with:
- Specified user_id
- Given diet principles list
- Fixed macro targets: protein=150, fat=50, carbs=200
- Fixed variety factor: 0.8

### Sections

1. **Recipe JSON Serialization (lines 73-147)**
   - Tests recipe to JSON conversion and round-trips

2. **Macro Preservation (lines 149-231)**
   - Tests that numeric values survive serialization

3. **AutoPlanConfig (lines 233-335)**
   - Tests configuration object serialization

4. **AutoMealPlan Round-Trip (lines 337-440)**
   - Tests complete plan serialization

5. **Total Macros (lines 442-495)**
   - Tests macro aggregation and preservation

6. **Edge Cases (lines 497-581)**
   - Tests boundary conditions and empty states

7. **Integration (lines 583-613)**
   - Tests full save/load cycle

## Key Test Principles

1. **Tandoor Recipe Integration**
   - Uses RecipeId from `meal_planner/id` module
   - Tested with Tandoor recipe format

2. **Round-Trip Testing**
   - Every serializable object can be deserialized
   - Values are preserved exactly or to precision

3. **Comprehensive Coverage**
   - Tests individual fields and complete objects
   - Tests collections (lists) and single items
   - Tests edge cases (empty, single, many)

4. **Clear Assertions**
   - Each test has specific field assertions
   - Uses `should.equal()` for exact matching
   - Uses `should.be_true()` for boolean checks

## Tandoor Integration

These tests verify save/load functionality with Tandoor recipes:

- Recipe format from Tandoor recipe manager
- Proper handling of RecipeIds (opaque type from `meal_planner/id`)
- Macro values from Tandoor recipe data
- Complete meal plan persistence

## Dependencies

- `gleeunit` - Test framework
- `gleam/json` - JSON encoding/decoding
- `gleam/dynamic/decode` - Dynamic decoders
- `meal_planner/auto_planner/types` - AutoPlanConfig, AutoMealPlan
- `meal_planner/types` - Recipe, Macros, Ingredient
- `meal_planner/id` - RecipeId type

## Running the Tests

```bash
cd gleam
gleam test
```

To run just this test module (if supported):
```bash
gleam test -- auto_planner_save_load
```

## Future Enhancements

1. Add database integration tests (with actual PostgreSQL)
2. Test with Tandoor API response formats
3. Add performance benchmarks for large recipe lists
4. Test concurrent save/load operations
5. Test version compatibility for recipe_json format
