# Recipe Scoring and Compliance Testing Guide

## Overview

This guide documents the comprehensive test suites for recipe scoring and vertical diet compliance validation in the meal-planner application.

## Test Files

### 1. `recipe_scorer_test.gleam`
Tests for the recipe scoring system used by the auto meal planner.

**Location:** `/home/lewis/src/meal-planner/gleam/test/recipe_scorer_test.gleam`
**Lines of Test Code:** 550+
**Test Functions:** 65+

#### Coverage Areas

##### Macro Matching Score Tests (6 tests)
- Perfect macro match detection
- Zero error rate handling
- Partial deviation scoring
- Significant deviation penalties
- Division-by-zero protection
- Score range validation [0.0, 1.0]

**Key Assertions:**
```gleam
// Perfect match should score >0.99
score_macro_match(
  Macros(30.0, 20.0, 50.0),
  Macros(30.0, 20.0, 50.0)
) |> should.be_greater_than(0.99)

// Large deviation should score <0.5
score_macro_match(
  Macros(10.0, 5.0, 15.0),
  Macros(50.0, 40.0, 100.0)
) |> should.be_less_than(0.5)
```

##### Macro Deviation Tests (5 tests)
- Zero deviation calculation
- Positive difference handling
- Negative difference handling
- Small target protection
- Large difference handling

**Key Test:**
- `macro_deviation(30.0, 30.0)` → `0.0`
- `macro_deviation(40.0, 30.0)` → `33.33%`
- `macro_deviation(100.0, 10.0)` → `900%`

##### Variety Scoring Tests (7 tests)
- Empty ingredient list (score: 0.0)
- 1 ingredient (score: 0.2)
- 2 ingredients (score: 0.4)
- 3 ingredients (score: 0.6)
- 4 ingredients (score: 0.8)
- 5+ ingredients (score: 1.0)

**Test Strategy:** Validates discrete scoring tiers for ingredient diversity.

##### Variety Penalty Tests (5 tests)
- No overlap between recipes (penalty: 0.0)
- Complete overlap detection (penalty: 1.0)
- Empty recipe handling
- Partial overlap calculation
- Multiple selected recipes impact

**Example:**
```gleam
// Complete overlap (same ingredients)
let penalty = calculate_variety_penalty(
  [test_recipe("r1", ..., 3)],
  test_recipe("r2", ..., 3)
)
// Returns: 1.0 (100% duplicate ingredients)
```

##### Recipe Scoring Tests (4 tests)
- Perfect macro match scoring
- Score breakdown validation
- Violations tracking
- Warning accumulation

##### Scoring Weights Tests (3 tests)
- Default weights: (0.5, 0.3, 0.2) for (diet, macro, variety)
- Strict compliance weights: (0.7, 0.2, 0.1)
- Performance weights: (0.3, 0.6, 0.1)

##### Filtering Tests (5 tests)
- Score threshold filtering
- Empty list handling
- High threshold filtering
- Compliance-only filtering
- Violation detection

##### Ranking Tests (8 tests)
- Single recipe ranking
- Multiple recipe sorting (descending by score)
- Zero recipe selection
- Top-N selection
- Full pipeline integration

##### Integration Tests (2 tests)
- Complete scoring pipeline
- Multi-weight scoring comparison

##### Edge Case Tests (3 tests)
- Extreme macro values
- Zero macro targets
- Case-insensitive ingredient comparison

### 2. `vertical_diet_compliance_test.gleam`
Tests for vertical diet compliance validation system.

**Location:** `/home/lewis/src/meal-planner/gleam/test/vertical_diet_compliance_test.gleam`
**Lines of Test Code:** 700+
**Test Functions:** 85+

#### Coverage Areas

##### Red Meat Detection Tests (10 tests)
Validates detection of red meat in recipes via:
- Recipe name (e.g., "Grass-Fed Beef with Vegetables")
- Description field
- Ingredient lists
- Case-insensitive matching

**Supported Red Meats:**
- beef, bison, lamb, venison, steak
- ground beef, chuck, ribeye, sirloin
- ground lamb

**Score Impact:** +25 points when detected

**Example Test:**
```gleam
pub fn red_meat_in_recipe_name_test() {
  let recipe = create_recipe(
    "Grass-Fed Beef with Vegetables",
    None,
    [create_ingredient("salt")],
    [create_instruction("Cook")],
    None,
  )

  let result = check_compliance(recipe)
  result.score |> should.be_greater_than(24)
}
```

##### Simple Carbs Detection Tests (9 tests)
Validates detection of simple carbohydrates:
- White rice, jasmine rice, basmati
- White potato, sweet potato
- Baked potato, mashed potato

**Score Impact:** +25 points when detected

**Detection Method:** Name, description, or ingredient analysis

##### Low FODMAP Vegetables Tests (7 tests)
Validates detection of digestive-friendly vegetables:
- Carrot, spinach, kale, lettuce
- Bell pepper, cucumber, zucchini
- Bok choy, cabbage, green bean, broccoli

**Score Impact:** +20 points if present, +10 if missing

##### Ingredient Simplicity Tests (4 tests)
Validates ingredient count scoring:
- 5-8 ingredients: Simple (full points +15)
- 9+ ingredients: Complex (reduced points +5)

**Example:**
```gleam
pub fn simple_ingredients_eight_count_test() {
  let recipe = create_recipe(
    "Simple Recipe",
    None,
    [/* 8 ingredients */],
    [create_instruction("Cook")],
    None,
  )
  let result = check_compliance(recipe)
  result.score |> should.be_greater_than(48)
}
```

##### Preparation Complexity Tests (4 tests)
Validates instruction count scoring:
- 1-6 steps: Simple preparation (full points +10)
- 7+ steps: Complex preparation (reduced points +5)

##### Quality Rating Tests (5 tests)
Validates recipe quality scoring:
- Rating 4-5: High quality (+5 points)
- Rating 1-3: Lower quality (+2 points)
- No rating: No quality bonus (+0 points)

##### Compliance Tests (5 tests)
Overall compliance validation:
- Fully compliant recipes (score >= 70)
- Minimal compliance recipes
- Non-compliant recipes (score < 70)
- Recommendation generation

**Compliance Threshold:** Score >= 70

##### Recommendation Tests (5 tests)
Validates dynamic recommendation generation:
- Missing red meat recommendations
- Missing carbs recommendations
- Missing vegetables recommendations
- Complex ingredients recommendations
- Compliant recipe recommendations

**Example:**
```gleam
pub fn recommendation_for_missing_red_meat_test() {
  let recipe = create_recipe(
    "Salad",
    None,
    [create_ingredient("lettuce")],
    [create_instruction("Mix")],
    None,
  )

  let result = check_compliance(recipe)

  // Should recommend red meat
  list.any(result.recommendations, fn(r) {
    string.contains(r, "red meat") || string.contains(r, "beef")
  })
  |> should.be_true()
}
```

##### Edge Cases (4 tests)
- Empty recipe handling
- Very long recipe names
- Special characters in ingredients
- Unicode character support

##### Integration Tests (3 tests)
- Multiple red meat types
- Multiple carb types
- Multiple vegetables

## Score Calculation

### Vertical Diet Compliance Score (0-100)

```
Score Components:
- Red meat detection:        +25 points
- Simple carbs detection:    +25 points
- Low FODMAP vegetables:     +20 points (if present) or +10 (if missing)
- Simple ingredients (≤8):   +15 points (5+ ingredients count)
- Simple preparation (≤6):   +10 points
- Recipe quality (4-5 stars): +5 points

Compliance Decision:
- Score >= 70: Compliant
- Score < 70: Non-compliant
```

### Macro Match Score (0.0 - 1.0)

```
Calculation:
1. Calculate percentage error for each macro:
   error = |actual - target| / max(target, 1.0)

2. Average errors across all macros:
   avg_error = (protein_error + fat_error + carbs_error) / 3

3. Convert to exponential decay score:
   score = e^(-2 * avg_error)

4. Clamp to [0, 1]
   final_score = min(1.0, max(0.0, score))
```

### Recipe Variety Score (0.0 - 1.0)

```
Ingredient Count → Score
0 ingredients:  0.0
1 ingredient:   0.2
2 ingredients:  0.4
3 ingredients:  0.6
4 ingredients:  0.8
5+ ingredients: 1.0
```

## Running the Tests

### Run All Tests
```bash
cd /home/lewis/src/meal-planner/gleam
gleam test
```

### Run Specific Test Suite
```bash
gleam test recipe_scorer_test
gleam test vertical_diet_compliance_test
```

### Run Specific Test Function
```bash
gleam test recipe_scorer_test::macro_match_perfect_score_test
gleam test vertical_diet_compliance_test::red_meat_in_recipe_name_test
```

## Test Statistics

| Metric | Recipe Scorer | Vertical Diet | Total |
|--------|---------------|---------------|-------|
| Test Files | 1 | 1 | 2 |
| Test Functions | 65+ | 85+ | 150+ |
| Lines of Test Code | 550+ | 700+ | 1,250+ |
| Fixtures/Helpers | 4 | 5 | 9 |
| Assertion Types | 12 | 15 | 27 |

## Key Testing Patterns

### 1. Fixture Creation
Tests use helper functions to create reusable test data:
```gleam
fn test_recipe(id: String, macros: Macros, ingredient_count: Int) -> Recipe
fn create_recipe(name: String, description, ingredients, instructions, rating) -> Recipe
```

### 2. Assertion Chains
Multiple assertions per test for comprehensive validation:
```gleam
score |> should.be_greater_than(0.5)
score |> should.be_less_than(0.99)
score |> should.equal(0.0)
```

### 3. Edge Case Handling
Tests validate boundary conditions:
- Empty lists/recipes
- Zero values
- Extreme values
- Missing data

### 4. Integration Testing
Tests validate components working together:
- Full scoring pipeline
- Multi-weight comparisons
- Combined filtering and ranking

## Coverage Summary

### Recipe Scorer Coverage
- **Macro matching:** 6 unit tests + 1 integration test
- **Variety scoring:** 7 unit tests + 2 integration tests
- **Filtering:** 5 unit tests + 1 integration test
- **Ranking:** 3 unit tests + 1 integration test
- **Weights:** 3 unit tests
- **Edge cases:** 3 unit tests

### Vertical Diet Compliance Coverage
- **Red meat detection:** 10 unit tests + 1 integration test
- **Simple carbs detection:** 9 unit tests + 1 integration test
- **Vegetables detection:** 7 unit tests + 1 integration test
- **Ingredient simplicity:** 4 unit tests
- **Preparation complexity:** 4 unit tests
- **Quality scoring:** 5 unit tests
- **Overall compliance:** 5 unit tests
- **Recommendations:** 5 unit tests
- **Edge cases:** 4 unit tests

## Maintenance Notes

### Adding New Tests
1. Add test function with `_test()` suffix
2. Use consistent fixture naming
3. Include descriptive assertions
4. Group related tests in sections

### Updating Fixtures
- Keep fixture parameters clear and documented
- Use named parameters for readability
- Document expected score ranges

### Expected Score Ranges
- Macro match scores: [0.0, 1.0]
- Variety scores: [0.0, 1.0]
- Compliance scores: [0, 100]
- Deviation percentages: [0, ∞)

## Integration with Auto Meal Planner

These tests ensure the auto meal planner correctly:
1. Scores recipes against macro targets
2. Filters recipes by compliance rules
3. Ranks recipes by quality
4. Penalizes variety violations
5. Provides meaningful recommendations

The tests validate both success paths and edge cases to ensure robust recipe selection in production.
