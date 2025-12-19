# Fractal Quality Loop

## Overview

The Fractal Quality Loop is a multi-layered validation system that ensures code quality at every scale: from individual functions to entire system architectures. Quality checks recursively apply at each level, creating a self-similar pattern of validation (hence "fractal").

## Core Concept

Quality is not a single gate at the end of development—it's a continuous recursive process embedded in every development action:

```
Individual Function → Module → Package → System
        ↓                ↓         ↓         ↓
     [Tests]        [Tests]   [Tests]   [Tests]
     [Format]       [Format]  [Format]  [Format]
     [Types]        [Types]   [Types]   [Types]
```

Each layer validates itself before composition into the next layer.

## The Loop Structure

### Layer 1: Function Level (Atomic)
**Validation:**
- Type signatures are explicit and correct
- `gleam format --check` passes
- Unit test exists and passes
- No `todo` or `panic` without justification

**Example:**
```gleam
// Good: Atomic function with type, test, and format
pub fn calculate_macros(recipe: Recipe) -> Macros {
  Macros(
    protein: recipe.ingredients
      |> list.map(fn(i) { i.protein })
      |> list.fold(0.0, float.add),
    carbs: recipe.ingredients
      |> list.map(fn(i) { i.carbs })
      |> list.fold(0.0, float.add),
    fat: recipe.ingredients
      |> list.map(fn(i) { i.fat })
      |> list.fold(0.0, float.add),
  )
}
```

**Test (must exist):**
```gleam
// test/nutrition_test.gleam
pub fn calculate_macros_sums_ingredients_test() {
  let recipe = Recipe(ingredients: [
    Ingredient(protein: 10.0, carbs: 5.0, fat: 2.0),
    Ingredient(protein: 15.0, carbs: 8.0, fat: 3.0),
  ])

  let result = calculate_macros(recipe)

  result.protein |> should.equal(25.0)
  result.carbs |> should.equal(13.0)
  result.fat |> should.equal(5.0)
}
```

### Layer 2: Module Level
**Validation:**
- All public functions have documentation (`///`)
- Module documentation exists (`////`)
- Integration tests verify module contracts
- Opaque types enforce invariants

**Example:**
```gleam
//// Nutrition module for calculating recipe macronutrients
////
//// This module provides functions for aggregating and analyzing
//// nutritional data from recipe ingredients.

import gleam/list
import gleam/float
import gleam/option.{type Option, Some, None}

/// Calculate total macronutrients from recipe ingredients
///
/// Returns aggregated protein, carbohydrates, and fat values
pub fn calculate_macros(recipe: Recipe) -> Macros {
  // Implementation
}

/// Validate recipe meets nutritional targets
///
/// Returns Ok(recipe) if targets met, Error with details if not
pub fn validate_targets(
  recipe: Recipe,
  targets: NutritionTargets,
) -> Result(Recipe, String) {
  // Implementation
}
```

### Layer 3: Package Level
**Validation:**
- `gleam build` succeeds
- `gleam test` passes (all module tests)
- No circular dependencies
- Public API is coherent and minimal

**Checkpoint:**
```bash
# Must all succeed before integration
gleam format --check
gleam build
gleam test
```

### Layer 4: System Level
**Validation:**
- End-to-end tests verify user workflows
- Integration tests verify external service contracts
- Performance benchmarks pass thresholds
- Documentation matches implementation

## Fractal Properties

### Self-Similarity
Quality checks at function level mirror system level:
- Function has test → Module has tests → System has tests
- Function is typed → Module is typed → System is typed
- Function is formatted → Module is formatted → System is formatted

### Recursion
Each quality check can invoke deeper checks:
```
System test fails
  → Module test fails
    → Function test fails
      → Type error found
        → Fix type
      → Function test passes
    → Module test passes
  → System test passes
```

### Composition
Quality guarantees compose:
- If all functions are correct → Module is correct
- If all modules are correct → Package is correct
- If all packages are correct → System is correct

## Integration with TCR

The Fractal Quality Loop is enforced by TCR (Test/Commit/Revert):

1. **Write test** (establishes quality expectation)
2. **Run test** (must fail for correct reason)
3. **Implement** (minimal code to pass)
4. **Run test** (must pass)
5. **Run quality checks** (`gleam format --check`, `gleam build`)
6. **If all pass** → Commit (quality locked in)
7. **If any fail** → Revert (prevents quality degradation)

See [tcr-cycle.md](./tcr-cycle.md) for detailed TCR workflow.

## Anti-Patterns

### ❌ Big Bang Validation
**Bad:** Write lots of code, then run tests at the end.

**Why it fails:** Violations accumulate, debugging is exponentially harder.

**Fix:** Validate at every layer during construction.

### ❌ Skipping Function Tests
**Bad:** "I'll test this through integration tests later."

**Why it fails:** Breaks fractal property—no atomic validation layer.

**Fix:** Write function test FIRST (TDD), then implementation.

### ❌ Format After Coding
**Bad:** Write code for hours, then run `gleam format`.

**Why it fails:** Format violations indicate structural problems (too complex, too nested).

**Fix:** Format continuously. If formatter struggles, refactor before continuing.

### ❌ Partial Type Coverage
**Bad:** Using `dynamic` or `todo` as permanent solutions.

**Why it fails:** Type safety is all-or-nothing. One hole breaks guarantees.

**Fix:** Define proper types even if stubbed. Use `Option` and `Result` explicitly.

## Practical Workflow

### Starting a new feature (e.g., `meal-planner-xyz`)

1. **Create Beads task:**
   ```bash
   bd create --title "Implement nutrition tracker"
   bd update meal-planner-xyz --status in_progress
   ```

2. **Define types (ARCHITECT):**
   ```gleam
   // src/nutrition/types.gleam
   pub type NutritionData {
     NutritionData(protein: Float, carbs: Float, fat: Float)
   }
   ```

3. **Write failing test (TESTER):**
   ```gleam
   // test/nutrition_test.gleam
   pub fn sum_nutrition_data_test() {
     let a = NutritionData(protein: 10.0, carbs: 5.0, fat: 2.0)
     let b = NutritionData(protein: 5.0, carbs: 3.0, fat: 1.0)

     let result = sum_nutrition([a, b])

     result |> should.equal(NutritionData(protein: 15.0, carbs: 8.0, fat: 3.0))
   }
   ```

4. **Run test (must fail):**
   ```bash
   gleam test
   # error: Unknown variable sum_nutrition
   ```

5. **Implement minimal solution (CODER):**
   ```gleam
   // src/nutrition/calculator.gleam
   pub fn sum_nutrition(items: List(NutritionData)) -> NutritionData {
     list.fold(items, NutritionData(0.0, 0.0, 0.0), fn(acc, item) {
       NutritionData(
         protein: acc.protein +. item.protein,
         carbs: acc.carbs +. item.carbs,
         fat: acc.fat +. item.fat,
       )
     })
   }
   ```

6. **Run quality loop:**
   ```bash
   gleam format --check  # Layer 1: Format
   gleam build           # Layer 2: Types
   gleam test            # Layer 3: Tests
   ```

7. **If all pass, commit:**
   ```bash
   git add -A
   git commit -m "GREEN: Implement nutrition summation - meal-planner-xyz"
   ```

8. **If any fail, revert:**
   ```bash
   git reset --hard
   # Try different approach
   ```

## Metrics

Track fractal quality health:

```bash
# Function coverage
grep -r "pub fn" src/ | wc -l
grep -r "_test() {" test/ | wc -l

# Format compliance
gleam format --check && echo "100%" || echo "FAIL"

# Type coverage (no dynamics)
rg "dynamic" src/ || echo "100%"

# Build health
gleam build && echo "PASS" || echo "FAIL"
```

## Related Documentation

- [tcr-cycle.md](./tcr-cycle.md) - Test/Commit/Revert enforcement
- [gleam-7-commandments.md](./gleam-7-commandments.md) - Language-specific quality rules
- [multi-agent-workflow.md](./multi-agent-workflow.md) - Agent coordination
- [quality-gates.md](./quality-gates.md) - Automated validation checkpoints

## References

- Beads tasks using Fractal Loop: `meal-planner-*` (all tasks)
- CLAUDE.md section: `GLEAM_7_COMMANDMENTS`
- CLAUDE.md section: `TCR_STRICT_MODE`
