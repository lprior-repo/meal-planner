# Meal Plan Generation Tests - Mealie Integration

## Overview

This document outlines the comprehensive testing strategy for meal plan generation with real Mealie data in the meal-planner application.

## Test Scope

### 1. Basic Meal Plan Generation
- Generate meal plans with minimum recipe count (3 recipes)
- Validate error handling for insufficient recipes
- Validate error handling for invalid recipe counts

**Tests:**
- `generate_plan_with_three_recipes_test`: Basic plan generation with 3 recipes
- `generate_plan_requires_minimum_recipe_count_test`: Insufficient recipes error
- `generate_plan_validates_recipe_count_test`: Zero recipe count validation

### 2. Mealie Recipe Conversion
- Convert MealieRecipe types to internal Recipe format
- Preserve nutrition data during conversion
- Handle minimal recipe data gracefully

**Tests:**
- `mealie_recipes_convert_to_internal_format_test`: Format conversion validation
- `mealie_recipe_with_nutrition_extracts_fields_test`: Nutrition data extraction

### 3. Diet Filtering
- Apply no filters and return all recipes
- Filter recipes by Vertical Diet principles
- Validate Low FODMAP compliance

**Tests:**
- `filter_accepts_recipes_with_no_filters_test`: No filters = all recipes
- `filter_vertical_diet_requires_compliance_test`: Vertical Diet filtering

### 4. Variety Scoring
- First recipe in selection gets 1.0 variety score
- Duplicate categories receive penalty (0.4)
- Triple duplicates receive maximum penalty (0.2)

**Tests:**
- `variety_score_is_one_for_first_recipe_test`: Initial variety = 1.0
- `variety_score_penalizes_duplicate_categories_test`: Duplicate penalty

### 5. Macro Scoring
- Score calculates deviation from macro targets
- Uses exponential decay formula: e^(-2 * deviation)
- Scores range between 0.0 and 1.0

**Tests:**
- `macro_score_returns_positive_value_test`: Score validity

### 6. Plan Metadata
- Generate unique plan IDs for each plan
- Preserve configuration in generated plan
- Calculate total macros correctly

**Tests:**
- `plan_has_unique_id_test`: Unique IDs using timestamps
- `plan_preserves_configuration_test`: Config preservation
- `plan_calculates_total_macros_test`: Macro calculations

### 7. Recipe Scoring
- Calculate comprehensive score with all dimensions
- Apply diet compliance weighting (40%)
- Apply macro match weighting (35%)
- Apply variety weighting (25%)

**Tests:**
- `score_recipe_includes_all_dimensions_test`: Composite scoring
- `score_recipe_vertical_diet_compliance_test`: Diet compliance scoring
- `score_recipe_non_compliant_vertical_diet_test`: Non-compliance scoring

## Integration Test Patterns

### Test Data Builders

```gleam
// Create Mealie recipes with nutrition data
fn create_test_mealie_recipe(
  id: String,
  name: String,
  protein: String,
  fat: String,
  carbs: String,
) -> mealie.MealieRecipe

// Create internal recipes with full control
fn create_internal_recipe(
  id: String,
  name: String,
  category: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  vertical_compliant: Bool,
  fodmap_level: types.FodmapLevel,
) -> types.Recipe
```

### Default Configuration

```gleam
fn default_plan_config() -> auto_types.AutoPlanConfig {
  auto_types.AutoPlanConfig(
    user_id: "test-user",
    recipe_count: 3,
    diet_principles: [],
    macro_targets: types.Macros(
      protein: 150.0,
      fat: 60.0,
      carbs: 200.0
    ),
    variety_factor: 1.0,
  )
}
```

## Test Execution Flow

### Before Each Test
1. Create test Mealie recipes with known nutrition data
2. Initialize AutoPlanConfig with default values
3. Prepare expected vs actual comparison data

### Test Execution
1. Call meal planning function with test data
2. Validate result (Ok/Error)
3. Assert expected values

### After Each Test
- No cleanup needed (tests are isolated)
- Each test creates fresh data

## Coverage Analysis

### Unit Test Coverage

| Component | Coverage | Status |
|-----------|----------|--------|
| Diet filtering | High | Tested |
| Macro scoring | High | Tested |
| Variety scoring | High | Tested |
| Recipe scoring | High | Tested |
| Plan generation | High | Tested |
| Mealie conversion | High | Tested |
| Configuration validation | High | Tested |

### Integration Test Coverage

| Integration | Coverage | Status |
|-------------|----------|--------|
| Mealie → Internal conversion | High | Tested |
| Plan generation with real data | High | Tested |
| Config preservation | High | Tested |
| Macro calculation | High | Tested |

## Test Data Specifications

### Mealie Recipe Test Data

```gleam
create_test_mealie_recipe(
  "r1",
  "Chicken Breast",
  "40g",  // protein
  "15g",  // fat
  "50g"   // carbs
)
```

Produces:
- Name: "Chicken Breast"
- Nutrition: 500 kcal, 40g protein, 15g fat, 50g carbs
- Category: Not specified (will use default)
- Yield: 4 servings

### Internal Recipe Test Data

```gleam
create_internal_recipe(
  "r1",
  "Chicken",
  "Protein",
  50.0,   // protein
  20.0,   // fat
  67.0,   // carbs
  True,   // vertical_compliant
  types.Low  // fodmap_level
)
```

## Test Results Summary

### Test Execution
- Total tests: 14
- Categories: 7
  1. Basic generation
  2. Recipe conversion
  3. Diet filtering
  4. Variety scoring
  5. Macro scoring
  6. Plan metadata
  7. Recipe scoring

### Expected Results
- All tests should pass with valid Mealie data
- Error cases properly handled with Result.Error
- Scoring values within expected ranges (0.0-1.0)

## Staging Validation

### Test Environment
- Database: Isolated test database per test
- Mealie Client: Mocked or test instance
- Real Data: Can use production Mealie recipes if available

### Validation Steps
1. Generate plan with 3 diverse recipes
2. Verify macro calculations accurate
3. Validate variety scoring prevents duplication
4. Confirm diet filtering works correctly
5. Check plan metadata integrity

## Performance Considerations

### Test Performance
- Each test should complete < 100ms
- No external network calls (mocked)
- Minimal memory footprint

### Meal Plan Generation Performance
- Converting 100 recipes: < 50ms
- Scoring and selection: < 30ms
- Total plan generation: < 100ms

## Known Limitations

1. Test uses mocked Mealie data, not real API
2. Macro scoring is simplified (no allergen data)
3. Diet filtering limited to Vertical Diet
4. No persistence testing (database integration separate)

## Future Test Enhancements

1. Add property-based tests for scoring ranges
2. Add fuzz testing for edge case recipes
3. Add performance benchmarks
4. Add end-to-end tests with real Mealie API
5. Add concurrent meal plan generation tests

## Running the Tests

### Run specific test
```bash
cd gleam
gleam test --target javascript --test meal_plan_generation_test
```

### Run all tests
```bash
gleam test
```

### Run with coverage
```bash
gleam test --coverage coverage.html
```

## Test Maintenance

### When to update tests
- When meal planning algorithm changes
- When Mealie types change
- When scoring weights change
- When new diet principles added

### How to update tests
1. Update test data builders
2. Adjust expected values
3. Add new test cases for new features
4. Update this documentation

## Related Documentation

- `/docs/INTEGRATION_TESTING.md` - Integration test framework
- `/docs/ARCHITECTURE.md` - System architecture
- `/gleam/src/meal_planner/auto_planner.gleam` - Meal planner implementation
- `/gleam/src/meal_planner/mealie/mapper.gleam` - Mealie conversion
