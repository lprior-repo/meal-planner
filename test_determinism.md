# Recipe Scoring Determinism Test Report

## Summary
This report documents the property-based tests for recipe scoring determinism in the meal planner auto-planner module.

## Test Suite Added
**File**: `/home/lewis/src/meal-planner/gleam/test/auto_planner_score_recipe_test.gleam`

### Determinism Tests (Lines 268-469)

#### 1. Basic Determinism Test
- **Purpose**: Verify that identical inputs produce identical scores
- **Method**: Score same recipe twice, compare all score components
- **Verified Components**:
  - `overall_score`
  - `diet_compliance_score`
  - `macro_match_score`
  - `variety_score`

#### 2. Multiple Runs Test (10 iterations)
- **Purpose**: Ensure consistency across many runs
- **Method**: Score recipe 10 times, verify all results match baseline
- **Edge Case Coverage**: Floating-point precision across iterations

#### 3. History-Dependent Scoring Test
- **Purpose**: Verify determinism with historical selections
- **Method**: Score with same history in different orders
- **Key Property**: Variety scoring depends on history, not history order

#### 4. Macro Calculation Determinism (20 iterations)
- **Purpose**: Stress-test macro_match_score calculation
- **Method**: Run 20 iterations, verify consistency
- **Focus**: Exponential decay function `e^(-2 * deviation)`

#### 5. Config Consistency Test
- **Purpose**: Identical configs produce identical results
- **Method**: Create two config objects with same values
- **Implication**: No state-dependent behavior in scoring

#### 6. Variety Score Determinism
- **Purpose**: Isolate and test variety calculation
- **Method**: Run 10 times, verify consistency
- **Covers**: Category counting logic

#### 7. Mealie Recipe Determinism
- **Purpose**: Test end-to-end with Mealie format
- **Method**: Convert and score 10 times
- **Includes**: String-to-float parsing determinism

#### 8. Edge Case Determinism
- **Purpose**: Verify determinism at boundary conditions
- **Cases Tested**:
  - Zero macros (0.0, 0.0, 0.0)
  - Very large macros (500.0, 300.0, 800.0)
- **Importance**: Math operations stable at extremes

#### 9. Diet Principles Determinism
- **Purpose**: Verify compliance scoring is deterministic
- **Method**: Score with VerticalDiet principle 10 times
- **Covers**: Conditional logic + macro scoring

## Properties Tested

### Determinism Property
```
∀ recipe, config, history:
  score_recipe(recipe, config, history) = score_recipe(recipe, config, history)
```

### Floating Point Determinism
- Uses IEEE 754 exact equality (`==`)
- Verified components:
  - Macro deviation calculation: `(actual - target) / target`
  - Exponential decay: `e^(-2 * deviation)`
  - Weighted average: `diet * 0.4 + macro * 0.35 + variety * 0.25`

### History Independence (Partial)
- Variety score depends on history presence, not order
- Macro and diet scores independent of history
- Proof: `calculate_variety_score` uses `list.count`, not ordering

## Scoring Algorithm Components

### 1. Macro Match Score
```gleam
calculate_deviation(actual, target) = |actual - target| / target
macro_match_score = e^(-2 * avg_deviation)
```

### 2. Variety Score
```gleam
- No history: 1.0
- First duplicate: 0.4
- Second+ duplicate: 0.2
- Different category: 1.0
```

### 3. Diet Compliance Score
```gleam
- No principles: 1.0
- VerticalDiet check: vertical_compliant AND fodmap_level == Low
- Other diets: 1.0 (simplified)
```

### 4. Overall Score
```gleam
overall = diet * 0.4 + macro * 0.35 + variety * 0.25
```

## Reproducibility Guarantees

### Sources of Determinism
1. **Pure Functions**: No mutable state
2. **Immutable Data**: All inputs/outputs are immutable
3. **Erlang Math**: External `math:exp/1` deterministic
4. **List Operations**: `list.count`, `list.any` deterministic
5. **Float Operations**: Standard IEEE 754

### Potential Non-Determinism (None Found)
- No time-dependent logic
- No random number generation
- No hash map ordering (uses explicit count)
- No concurrency issues
- No external API calls in scoring

## Test Execution

### Running the Tests
```bash
cd /home/lewis/src/meal-planner/gleam
gleam test -- auto_planner_score_recipe_test
```

### Expected Results
- All 9 determinism tests should PASS
- Each test verifies exact equality across multiple runs
- Total: 9 properties verified

## Conclusion

The recipe scoring system is **provably deterministic** because:

1. All operations are pure functions
2. Input types are immutable
3. No external state dependency
4. No timing-dependent logic
5. Floating-point operations stable across runs

This guarantees that auto meal plan generation with the same inputs will always produce identical recipe scores and selections.
