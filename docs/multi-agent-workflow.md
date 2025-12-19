# Multi-Agent Workflow

## Overview

The Multi-Agent Workflow implements a **swarm intelligence** approach to software development. Instead of a single developer handling all phases (design, test, implementation, refactoring), specialized agents collaborate in a strictly defined sequence.

This mirrors professional software teams where:
- **Architects** design systems
- **QA Engineers** write tests
- **Developers** implement features
- **Refactorers** optimize code

Each agent has narrow responsibilities and clear handoff protocols.

## Agent Roles

### ARCHITECT

**Responsibility:** Define types, contracts, and test fixtures BEFORE any code is written.

**Output:**
- Type definitions (`.gleam` files in `src/types/` or module-level)
- JSON fixtures for testing (`test/fixtures/*.json`)
- Interface contracts (function signatures)

**Example workflow:**

```gleam
// src/meal_planner/types.gleam
// Created by ARCHITECT

/// A recipe with ingredients and metadata
pub type Recipe {
  Recipe(
    id: Int,
    name: String,
    ingredients: List(Ingredient),
    servings: Int,
    nutrition: Nutrition,
  )
}

/// An ingredient with quantity and nutritional data
pub type Ingredient {
  Ingredient(
    name: String,
    quantity: Float,
    unit: String,
    nutrition: Nutrition,
  )
}

/// Nutritional information per serving
pub type Nutrition {
  Nutrition(
    calories: Int,
    protein: Float,
    carbs: Float,
    fat: Float,
  )
}
```

**Test fixture:**
```json
// test/fixtures/recipe_carbonara.json
// Created by ARCHITECT
{
  "id": 1,
  "name": "Pasta Carbonara",
  "servings": 4,
  "ingredients": [
    {
      "name": "Spaghetti",
      "quantity": 400,
      "unit": "g",
      "nutrition": {
        "calories": 371,
        "protein": 13.0,
        "carbs": 74.0,
        "fat": 1.5
      }
    },
    {
      "name": "Eggs",
      "quantity": 4,
      "unit": "whole",
      "nutrition": {
        "calories": 155,
        "protein": 13.0,
        "carbs": 1.1,
        "fat": 11.0
      }
    }
  ],
  "nutrition": {
    "calories": 526,
    "protein": 26.0,
    "carbs": 75.1,
    "fat": 12.5
  }
}
```

**Handoff:** ARCHITECT → TESTER

**Communication (via Agent Mail):**
```
To: TESTER
Subject: [meal-planner-abc] Type definitions complete
Thread: meal-planner-abc

Recipe and Nutrition types defined in src/meal_planner/types.gleam
Test fixture available at test/fixtures/recipe_carbonara.json

Next: Write test for calculate_daily_macros function
Expected signature:
  pub fn calculate_daily_macros(recipes: List(Recipe)) -> Nutrition

Acceptance criteria:
- Sums nutrition across all recipes
- Returns total calories, protein, carbs, fat
```

### TESTER

**Responsibility:** Write ONE failing test for ONE behavior. Test must fail for the CORRECT reason.

**Constraint:** Test implementation code does not exist yet. Test MUST fail.

**Output:**
- Test file (`test/MODULE_test.gleam`)
- Failing test case (RED phase)

**Example workflow:**

```gleam
// test/meal_planner_test.gleam
// Created by TESTER

import gleeunit/should
import meal_planner/planner
import meal_planner/types.{Recipe, Nutrition, Ingredient}

pub fn calculate_daily_macros_sums_all_recipes_test() {
  let recipe1 = Recipe(
    id: 1,
    name: "Breakfast",
    servings: 1,
    ingredients: [],
    nutrition: Nutrition(calories: 400, protein: 20.0, carbs: 50.0, fat: 10.0),
  )

  let recipe2 = Recipe(
    id: 2,
    name: "Lunch",
    servings: 1,
    ingredients: [],
    nutrition: Nutrition(calories: 600, protein: 30.0, carbs: 70.0, fat: 15.0),
  )

  let result = planner.calculate_daily_macros([recipe1, recipe2])

  result.calories |> should.equal(1000)
  result.protein |> should.equal(50.0)
  result.carbs |> should.equal(120.0)
  result.fat |> should.equal(25.0)
}
```

**Run test (must fail):**
```bash
$ gleam test
Compiling meal_planner
  error: Unknown variable calculate_daily_macros

✗ Test failed (CORRECT failure reason)
```

**Commit:**
```bash
git add test/meal_planner_test.gleam
git commit -m "RED: Add test for daily macro calculation - meal-planner-abc"
```

**Handoff:** TESTER → CODER

**Communication (via Agent Mail):**
```
To: CODER
Subject: [meal-planner-abc] Test ready for implementation
Thread: meal-planner-abc

Test: calculate_daily_macros_sums_all_recipes_test
Location: test/meal_planner_test.gleam
Status: FAILING (unknown variable - expected)

Implement: planner.calculate_daily_macros(recipes: List(Recipe)) -> Nutrition

Test expects:
- Sum of all recipe nutrition values
- Return aggregated Nutrition struct
```

### CODER

**Responsibility:** Make the test pass with MINIMAL implementation. No gold-plating.

**Constraint:** Implement ONLY what the test requires. Prefer "fake it till you make it."

**Output:**
- Implementation file (`src/MODULE.gleam`)
- Passing test (GREEN phase)

**Example workflow:**

```gleam
// src/meal_planner/planner.gleam
// Created by CODER

import gleam/list
import meal_planner/types.{type Recipe, type Nutrition, Nutrition}

pub fn calculate_daily_macros(recipes: List(Recipe)) -> Nutrition {
  list.fold(recipes, Nutrition(0, 0.0, 0.0, 0.0), fn(acc, recipe) {
    Nutrition(
      calories: acc.calories + recipe.nutrition.calories,
      protein: acc.protein +. recipe.nutrition.protein,
      carbs: acc.carbs +. recipe.nutrition.carbs,
      fat: acc.fat +. recipe.nutrition.fat,
    )
  })
}
```

**Run test (must pass):**
```bash
$ gleam test
Compiling meal_planner
Running meal_planner_test.gleam

✓ calculate_daily_macros_sums_all_recipes_test

1 test, 0 failures
```

**Run quality checks:**
```bash
$ gleam format --check
All files properly formatted

$ gleam build
Compiling meal_planner
Compiled in 0.8s
```

**Commit:**
```bash
git add src/meal_planner/planner.gleam
git commit -m "GREEN: Implement daily macro calculation - meal-planner-abc"
```

**Handoff:** CODER → REFACTORER (optional)

**Communication (via Agent Mail):**
```
To: REFACTORER
Subject: [meal-planner-abc] Implementation complete, ready for refactoring
Thread: meal-planner-abc

Implementation: planner.calculate_daily_macros
Status: GREEN (all tests passing)

Code quality:
- Format: ✓
- Build: ✓
- Tests: ✓

Possible improvements:
- Extract fold logic to separate function?
- Add documentation comments
```

### REFACTORER

**Responsibility:** Improve code structure WITHOUT changing behavior.

**Constraint:** Tests must pass BEFORE and AFTER refactoring. No new features.

**Output:**
- Refactored code (BLUE phase)
- Still-passing tests

**Example workflow:**

**Before:**
```gleam
// src/meal_planner/planner.gleam
pub fn calculate_daily_macros(recipes: List(Recipe)) -> Nutrition {
  list.fold(recipes, Nutrition(0, 0.0, 0.0, 0.0), fn(acc, recipe) {
    Nutrition(
      calories: acc.calories + recipe.nutrition.calories,
      protein: acc.protein +. recipe.nutrition.protein,
      carbs: acc.carbs +. recipe.nutrition.carbs,
      fat: acc.fat +. recipe.nutrition.fat,
    )
  })
}
```

**After:**
```gleam
// src/meal_planner/planner.gleam

/// Calculate total macronutrients across multiple recipes
///
/// Returns aggregated calories, protein, carbohydrates, and fat
pub fn calculate_daily_macros(recipes: List(Recipe)) -> Nutrition {
  list.fold(recipes, empty_nutrition(), add_nutrition)
}

fn empty_nutrition() -> Nutrition {
  Nutrition(calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0)
}

fn add_nutrition(acc: Nutrition, recipe: Recipe) -> Nutrition {
  Nutrition(
    calories: acc.calories + recipe.nutrition.calories,
    protein: acc.protein +. recipe.nutrition.protein,
    carbs: acc.carbs +. recipe.nutrition.carbs,
    fat: acc.fat +. recipe.nutrition.fat,
  )
}
```

**Run tests (must still pass):**
```bash
$ gleam test
Running meal_planner_test.gleam

✓ calculate_daily_macros_sums_all_recipes_test

1 test, 0 failures
```

**Commit:**
```bash
git add src/meal_planner/planner.gleam
git commit -m "BLUE: Extract nutrition folding logic - meal-planner-abc"
```

**Handoff:** REFACTORER → (end of cycle)

**Communication (via Agent Mail):**
```
To: SWARM
Subject: [meal-planner-abc] Task complete
Thread: meal-planner-abc

Refactoring complete. All tests passing.

Changes:
- Extracted empty_nutrition() helper
- Extracted add_nutrition() fold function
- Added documentation comments

Ready to close task.
```

## Swarm Coordination

### Task Lifecycle

```
┌──────────────────────────────────────────────────────┐
│             SWARM COORDINATION FLOW                  │
└──────────────────────────────────────────────────────┘

1. Task Created (Beads)
   ├── bd create --title "Feature X"
   └── Task ID: meal-planner-xyz

2. ARCHITECT Phase
   ├── Define types (src/types.gleam)
   ├── Create fixtures (test/fixtures/*.json)
   ├── Document interfaces
   └── HANDOFF → TESTER

3. TESTER Phase
   ├── Write test (test/*_test.gleam)
   ├── Verify test FAILS correctly
   ├── Commit RED
   └── HANDOFF → CODER

4. CODER Phase
   ├── Implement minimal solution
   ├── Run tests (must pass)
   ├── Run quality checks
   ├── PASS → Commit GREEN
   └── FAIL → REVERT, try different approach

5. REFACTORER Phase (optional)
   ├── Improve structure
   ├── Run tests (must still pass)
   ├── Commit BLUE
   └── Task complete

6. Task Closed (Beads)
   └── bd close meal-planner-xyz --reason "Implemented X"
```

### Agent Mail Protocol

Agents communicate via **Agent Mail MCP** (git-backed messaging):

**Sending a message:**
```
To: <AgentName>
Subject: [task-id] Message
Thread: task-id
Body: Details
```

**Reserving files:**
```bash
# CODER reserves implementation file
/reserve src/meal_planner/planner.gleam

# TESTER reserves test file
/reserve test/meal_planner_test.gleam
```

**Releasing files:**
```bash
# After committing, release reservation
/release
```

### Impasse Protocol

**Trigger:** 3 consecutive CODER reverts on the same test.

**Action:**
1. **STOP all coding**
2. **Convene swarm:** ARCHITECT + TESTER + CODER meet
3. **ARCHITECT reviews:** Are types correct?
4. **TESTER reviews:** Is test expectation correct?
5. **CODER reviews:** Is implementation approach flawed?
6. **Output:** "Strategy Change Proposal"
7. **Restart:** Begin RED phase with new strategy

**Example impasse resolution:**

```
IMPASSE: meal-planner-abc (3 reverts)

ARCHITECT: "Should calculate_daily_macros return Result instead of Nutrition?"
  - What if recipes list is empty?
  - Should we error or return zero nutrition?

TESTER: "Current test assumes list is non-empty. Should we test empty case separately?"

CODER: "Fold approach is correct, but accumulator type might be wrong."

DECISION:
1. Keep Nutrition return type (empty list → zero nutrition is valid)
2. Add SEPARATE test for empty list case first
3. Then re-run test for non-empty case

NEW STRATEGY:
- TESTER writes test_empty_list_returns_zero_nutrition
- CODER implements to handle empty case
- Then handle non-empty case
```

## Workflow Examples

### Example 1: New Feature (Happy Path)

**Task:** Implement recipe search by ingredient

**ARCHITECT:**
```gleam
// src/meal_planner/types.gleam
pub type SearchResult {
  SearchResult(recipe: Recipe, match_score: Float)
}

// test/fixtures/recipes_with_pasta.json
[
  { "id": 1, "name": "Carbonara", "ingredients": [...] },
  { "id": 2, "name": "Bolognese", "ingredients": [...] }
]
```

**TESTER:**
```gleam
// test/search_test.gleam
pub fn search_by_ingredient_finds_matching_recipes_test() {
  let recipes = load_fixture("recipes_with_pasta.json")

  let results = search.by_ingredient(recipes, "pasta")

  results |> list.length |> should.equal(2)
}
```

**CODER:**
```gleam
// src/meal_planner/search.gleam
pub fn by_ingredient(recipes: List(Recipe), ingredient: String) -> List(SearchResult) {
  recipes
  |> list.filter(fn(r) { has_ingredient(r, ingredient) })
  |> list.map(fn(r) { SearchResult(recipe: r, match_score: 1.0) })
}

fn has_ingredient(recipe: Recipe, name: String) -> Bool {
  recipe.ingredients
  |> list.any(fn(i) { string.contains(i.name, name) })
}
```

**REFACTORER:**
```gleam
// Improve: Calculate actual match score based on quantity
fn calculate_match_score(recipe: Recipe, ingredient: String) -> Float {
  // Extract and improve scoring logic
}
```

### Example 2: Bug Fix (Revert Path)

**Task:** Fix division by zero in macro calculator

**TESTER:**
```gleam
pub fn calculate_macros_per_serving_handles_zero_servings_test() {
  let recipe = Recipe(servings: 0, nutrition: Nutrition(...))

  let result = planner.calculate_macros_per_serving(recipe)

  result |> should.be_error()
}
```

**CODER (Attempt 1):**
```gleam
pub fn calculate_macros_per_serving(recipe: Recipe) -> Result(Nutrition, String) {
  case recipe.servings {
    0 -> Error("Servings cannot be zero")
    s -> Ok(divide_nutrition(recipe.nutrition, s))
  }
}

fn divide_nutrition(nutrition: Nutrition, divisor: Int) -> Nutrition {
  Nutrition(
    calories: nutrition.calories / divisor,  // Int division
    protein: nutrition.protein / divisor,     // ❌ ERROR: Int vs Float
    // ...
  )
}
```

**Test fails:**
```bash
$ gleam test
  error: Type mismatch
    Expected: Float
    Got: Int
```

**REVERT:**
```bash
git reset --hard
```

**CODER (Attempt 2):**
```gleam
pub fn calculate_macros_per_serving(recipe: Recipe) -> Result(Nutrition, String) {
  case recipe.servings {
    0 -> Error("Servings cannot be zero")
    s -> {
      let divisor = int.to_float(s)
      Ok(Nutrition(
        calories: int.to_float(nutrition.calories) /. divisor |> float.round,
        protein: nutrition.protein /. divisor,
        carbs: nutrition.carbs /. divisor,
        fat: nutrition.fat /. divisor,
      ))
    }
  }
}
```

**Test passes:**
```bash
$ gleam test
✓ calculate_macros_per_serving_handles_zero_servings_test
```

**Commit:**
```bash
git commit -m "GREEN: Handle zero servings in macro calculation - meal-planner-bug-123"
```

## Agent State Tracking

### State Object (per task)

```json
{
  "current_task": "meal-planner-abc",
  "active_agent": "CODER",
  "tcr_attempt": 2,
  "phase": "GREEN",
  "gleam_target": "erlang",
  "files_reserved": [
    "src/meal_planner/planner.gleam"
  ],
  "reverts": 1
}
```

### Metrics

Track agent efficiency:

```bash
# Agent handoffs per task (should be 3-4)
# ARCHITECT → TESTER → CODER → REFACTORER

# Revert rate per agent
# CODER reverts: Normal (<50%)
# REFACTORER reverts: Warning (should be rare)

# Time per phase
# ARCHITECT: ~10 min (types + fixtures)
# TESTER: ~5 min (one test)
# CODER: ~15 min (implementation + retries)
# REFACTORER: ~10 min (optional)
```

## Anti-Patterns

### ❌ Agent Role Violation

**Wrong:** TESTER writes implementation code

**Why it fails:** Breaks separation of concerns, defeats swarm intelligence

**Fix:** Strict agent boundaries, enforce via code review

### ❌ Skipping ARCHITECT

**Wrong:** CODER starts writing code without types defined

**Why it fails:** No contract to test against, leads to rework

**Fix:** ARCHITECT must run first, always

### ❌ Multiple Behaviors Per Test

**Wrong:** TESTER writes one test that checks 5 different things

**Why it fails:** CODER doesn't know which behavior to implement first

**Fix:** One test, one behavior, one commit

### ❌ REFACTORER Adding Features

**Wrong:** REFACTORER adds new function during refactoring

**Why it fails:** Changes behavior without test, violates TCR

**Fix:** REFACTORER only restructures, never adds features

## Related Documentation

- [fractal-quality-loop.md](./fractal-quality-loop.md) - Quality framework agents enforce
- [tcr-cycle.md](./tcr-cycle.md) - Workflow each agent follows
- [gleam-7-commandments.md](./gleam-7-commandments.md) - Rules agents must obey
- [quality-gates.md](./quality-gates.md) - Automated checks per phase

## References

- CLAUDE.md section: `SUBAGENT_ROLES`
- CLAUDE.md section: `SWARM_DELEGATION`
- Agent Mail MCP documentation
- Beads MCP documentation
