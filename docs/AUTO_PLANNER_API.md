# Auto Planner API Reference

## Quick Start

```gleam
import meal_planner/auto_planner
import shared/types.{Macros}

// 1. Create configuration
let config = auto_planner.AutoPlanConfig(
  diet_principles: [auto_planner.VerticalDiet],
  macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
  recipe_count: 4,
  variety_factor: 0.7,
  user_id: "user-123",
)

// 2. Generate plan
let result = auto_planner.generate_auto_plan(recipes, config)

// 3. Use plan
case result {
  Ok(plan) -> {
    // Access plan.recipes, plan.total_macros, plan.id
  }
  Error(msg) -> {
    // Handle error
  }
}
```

## Public API

### Main Functions

#### `generate_auto_plan`
```gleam
pub fn generate_auto_plan(
  available_recipes: List(Recipe),
  config: AutoPlanConfig,
) -> Result(AutoMealPlan, String)
```
**Purpose**: Generate an optimized meal plan

**Parameters:**
- `available_recipes`: Pool of recipes to select from
- `config`: Configuration with diet rules, macro targets, etc.

**Returns:**
- `Ok(AutoMealPlan)`: Successfully generated plan
- `Error(String)`: Description of why plan couldn't be generated

**Errors:**
- "Insufficient recipes after diet filtering..." - Not enough valid recipes
- Other validation errors from diet filtering

---

#### `filter_by_diet_principles`
```gleam
pub fn filter_by_diet_principles(
  recipes: List(Recipe),
  principles: List(DietPrinciple),
) -> List(Recipe)
```
**Purpose**: Filter recipes by diet compliance

**Parameters:**
- `recipes`: Input recipe list
- `principles`: Diet rules to apply (empty list = no filtering)

**Returns:** Filtered recipe list

**Example:**
```gleam
let vertical_only =
  all_recipes
  |> filter_by_diet_principles([VerticalDiet])
```

---

#### `score_recipe`
```gleam
pub fn score_recipe(
  recipe: Recipe,
  config: AutoPlanConfig,
  already_selected: List(Recipe),
) -> RecipeScore
```
**Purpose**: Calculate comprehensive score for a recipe

**Parameters:**
- `recipe`: Recipe to score
- `config`: Scoring configuration
- `already_selected`: Previously selected recipes (for variety scoring)

**Returns:** `RecipeScore` with component scores

**Score Components:**
- `diet_compliance_score`: 0.0 or 1.0
- `macro_match_score`: 0.0-1.0 (how close to ideal macros)
- `variety_score`: 0.0-1.0 (uniqueness vs already selected)
- `overall_score`: Weighted average (40% diet, 35% macro, 25% variety)

---

#### `select_top_n`
```gleam
pub fn select_top_n(
  scored_recipes: List(RecipeScore),
  count: Int,
  variety_factor: Float,
) -> List(Recipe)
```
**Purpose**: Select best N recipes with variety consideration

**Parameters:**
- `scored_recipes`: Pre-scored recipe list
- `count`: Number of recipes to select
- `variety_factor`: 0.0-1.0 (0=ignore variety, 1=maximize variety)

**Returns:** Selected recipe list

**Algorithm:**
- Greedy selection
- Re-scores remaining recipes at each step
- Balances original score with variety based on factor

---

#### `calculate_macro_match_score`
```gleam
pub fn calculate_macro_match_score(
  recipe: Recipe,
  targets: Macros,
  recipe_count: Int,
) -> Float
```
**Purpose**: Score how well recipe matches target macros

**Parameters:**
- `recipe`: Recipe to score
- `targets`: Daily macro targets
- `recipe_count`: Expected number of recipes in plan

**Returns:** Score 0.0-1.0 (higher = better match)

**Logic:**
- Calculates per-meal targets: `daily_target / recipe_count`
- Measures deviation of recipe from per-meal target
- Weights: protein 40%, fat 30%, carbs 30%

---

#### `calculate_variety_score`
```gleam
pub fn calculate_variety_score(
  recipe: Recipe,
  already_selected: List(Recipe),
) -> Float
```
**Purpose**: Score recipe variety vs already selected

**Parameters:**
- `recipe`: Recipe to score
- `already_selected`: Currently selected recipes

**Returns:** Score 0.0-1.0 (higher = more unique)

**Penalties:**
- Same category: 0.5 penalty for 1 match, 1.0 for 2+
- Same protein type: 0.3 penalty for 1 match, 0.7 for 2+
- Combined: `1.0 - (category_penalty * 0.6 + protein_penalty * 0.4)`

---

## Types Reference

### `DietPrinciple`
```gleam
pub type DietPrinciple {
  VerticalDiet
}
```
**Values:**
- `VerticalDiet`: Requires `vertical_compliant: True` and `fodmap_level: Low`

**Future:** Could add `Keto`, `Paleo`, `Mediterranean`, etc.

---

### `AutoPlanConfig`
```gleam
pub type AutoPlanConfig {
  AutoPlanConfig(
    diet_principles: List(DietPrinciple),
    macro_targets: Macros,
    recipe_count: Int,
    variety_factor: Float,
    user_id: String,
  )
}
```
**Fields:**
- `diet_principles`: Diet rules to enforce (empty list = no restrictions)
- `macro_targets`: Daily macro goals (Macros type from shared/types)
- `recipe_count`: Number of recipes to select (typically 4)
- `variety_factor`: 0.0-1.0 diversity preference
- `user_id`: User identifier for plan

**Typical Values:**
```gleam
// Bodybuilder (less variety, optimized macros)
AutoPlanConfig(
  diet_principles: [VerticalDiet],
  macro_targets: Macros(protein: 200.0, fat: 70.0, carbs: 300.0),
  recipe_count: 4,
  variety_factor: 0.3,  // Low variety OK
  user_id: "user-456",
)

// Food enthusiast (maximum variety)
AutoPlanConfig(
  diet_principles: [VerticalDiet],
  macro_targets: Macros(protein: 150.0, fat: 50.0, carbs: 200.0),
  recipe_count: 4,
  variety_factor: 0.9,  // High variety
  user_id: "user-789",
)
```

---

### `RecipeScore`
```gleam
pub type RecipeScore {
  RecipeScore(
    recipe: Recipe,
    diet_compliance_score: Float,
    macro_match_score: Float,
    variety_score: Float,
    overall_score: Float,
  )
}
```
**Fields:**
- `recipe`: The scored recipe
- `diet_compliance_score`: 0.0-1.0 (typically 0.0 or 1.0)
- `macro_match_score`: 0.0-1.0 (deviation from ideal)
- `variety_score`: 0.0-1.0 (uniqueness)
- `overall_score`: Weighted average (use for sorting)

**Score Weights:**
```gleam
overall_score =
  diet_compliance_score * 0.4 +
  macro_match_score * 0.35 +
  variety_score * 0.25
```

---

### `AutoMealPlan`
```gleam
pub type AutoMealPlan {
  AutoMealPlan(
    id: String,
    recipes: List(Recipe),
    config: AutoPlanConfig,
    generated_at: String,
    total_macros: Macros,
  )
}
```
**Fields:**
- `id`: Unique plan identifier (format: `auto-plan-{user_id}-{timestamp}`)
- `recipes`: Selected recipes (length = config.recipe_count)
- `config`: Configuration used to generate plan
- `generated_at`: ISO 8601 timestamp
- `total_macros`: Sum of all recipe macros

**Usage:**
```gleam
case generate_auto_plan(recipes, config) {
  Ok(plan) -> {
    // Access recipes
    plan.recipes
    |> list.each(fn(r) { io.println(r.name) })

    // Check total macros
    io.println("Total protein: " <> float.to_string(plan.total_macros.protein))

    // Save plan
    save_to_database(plan.id, plan)
  }
  Error(msg) -> io.println("Error: " <> msg)
}
```

---

## Common Patterns

### Pattern 1: Basic Meal Plan Generation
```gleam
import meal_planner/auto_planner
import meal_planner/vertical_diet_recipes
import shared/types.{Macros}

pub fn create_daily_plan(user_id: String, targets: Macros) {
  let config = auto_planner.AutoPlanConfig(
    diet_principles: [auto_planner.VerticalDiet],
    macro_targets: targets,
    recipe_count: 4,
    variety_factor: 0.7,
    user_id: user_id,
  )

  let recipes = vertical_diet_recipes.all_recipes()

  auto_planner.generate_auto_plan(recipes, config)
}
```

---

### Pattern 2: Multiple Diet Principles (Future)
```gleam
// When more diets are added:
let config = auto_planner.AutoPlanConfig(
  diet_principles: [auto_planner.VerticalDiet, auto_planner.Keto],
  macro_targets: targets,
  recipe_count: 4,
  variety_factor: 0.7,
  user_id: user_id,
)
```

---

### Pattern 3: Custom Recipe Filtering
```gleam
// Pre-filter recipes before auto-planning
let recipes =
  all_recipes
  |> list.filter(fn(r) { r.servings <= 2 })  // Small portions only
  |> list.filter(fn(r) { types.macros_calories(r.macros) <. 600.0 })  // Low cal
  |> auto_planner.filter_by_diet_principles([auto_planner.VerticalDiet])

let result = auto_planner.generate_auto_plan(recipes, config)
```

---

### Pattern 4: Score Analysis
```gleam
// Analyze why certain recipes were selected
let scored =
  recipes
  |> list.map(fn(r) { auto_planner.score_recipe(r, config, []) })
  |> list.sort(fn(a, b) { float.compare(b.overall_score, a.overall_score) })

// Examine top scorer
case list.first(scored) {
  Ok(top) -> {
    io.println("Best recipe: " <> top.recipe.name)
    io.println("Diet score: " <> float.to_string(top.diet_compliance_score))
    io.println("Macro score: " <> float.to_string(top.macro_match_score))
    io.println("Variety score: " <> float.to_string(top.variety_score))
  }
  Error(_) -> Nil
}
```

---

### Pattern 5: Variety Experimentation
```gleam
// Generate plans with different variety factors
let configs = [0.0, 0.3, 0.5, 0.7, 1.0]

configs
|> list.map(fn(factor) {
  let cfg = auto_planner.AutoPlanConfig(
    diet_principles: [auto_planner.VerticalDiet],
    macro_targets: targets,
    recipe_count: 4,
    variety_factor: factor,
    user_id: user_id,
  )

  #(factor, auto_planner.generate_auto_plan(recipes, cfg))
})
|> list.each(fn(result) {
  let #(factor, plan_result) = result
  case plan_result {
    Ok(plan) -> {
      let categories = list.map(plan.recipes, fn(r) { r.category })
      let unique = list.unique(categories) |> list.length
      io.println("Factor " <> float.to_string(factor) <> ": " <> int.to_string(unique) <> " unique categories")
    }
    Error(_) -> Nil
  }
})
```

---

## Error Handling

### Common Errors

#### "Insufficient recipes after diet filtering"
**Cause:** Not enough recipes pass diet principles filter
**Solution:**
- Add more recipes to the pool
- Relax diet principles
- Reduce `recipe_count`

```gleam
case auto_planner.generate_auto_plan(recipes, config) {
  Error(msg) if string.contains(msg, "Insufficient") -> {
    // Try with fewer recipes
    let relaxed_config = AutoPlanConfig(..config, recipe_count: 3)
    auto_planner.generate_auto_plan(recipes, relaxed_config)
  }
  result -> result
}
```

#### Empty Recipe Pool
**Cause:** No recipes provided
**Solution:** Load recipes first

```gleam
let recipes = vertical_diet_recipes.all_recipes()
case list.length(recipes) {
  0 -> Error("No recipes available")
  _ -> auto_planner.generate_auto_plan(recipes, config)
}
```

---

## Performance Notes

### Optimization Tips

1. **Pre-filter recipes** if you have many:
```gleam
// Filter before auto-planning
let eligible =
  all_recipes
  |> list.filter(is_vegetarian)
  |> auto_planner.filter_by_diet_principles(principles)
```

2. **Reuse scored recipes** if generating multiple plans:
```gleam
let scored =
  recipes
  |> list.map(fn(r) { auto_planner.score_recipe(r, config, []) })

// Try different variety factors
let plan1 = auto_planner.select_top_n(scored, 4, 0.5)
let plan2 = auto_planner.select_top_n(scored, 4, 0.8)
```

3. **Cache diet-filtered recipes** per principle:
```gleam
// Cache this result
let vertical_recipes =
  all_recipes
  |> auto_planner.filter_by_diet_principles([auto_planner.VerticalDiet])
```

---

## Integration Examples

### Web Endpoint
```gleam
import wisp.{type Request, type Response}
import meal_planner/auto_planner

pub fn handle_generate_plan(req: Request) -> Response {
  use json <- wisp.require_json(req)

  // Parse request
  let config = parse_config(json)
  let recipes = load_recipes()

  // Generate plan
  case auto_planner.generate_auto_plan(recipes, config) {
    Ok(plan) -> {
      plan
      |> plan_to_json
      |> wisp.json_response(200)
    }
    Error(msg) -> {
      wisp.json_response(json.object([
        #("error", json.string(msg)),
      ]), 400)
    }
  }
}
```

### CLI Command
```gleam
import gleam/io
import meal_planner/auto_planner

pub fn main() {
  let config = load_config_from_args()
  let recipes = load_recipes_from_file()

  case auto_planner.generate_auto_plan(recipes, config) {
    Ok(plan) -> {
      io.println("🍽️  Generated Meal Plan")
      io.println("━━━━━━━━━━━━━━━━━━━━━")
      plan.recipes
      |> list.each(fn(r) {
        io.println("✓ " <> r.name)
      })
      io.println("\nTotal Macros:")
      io.println("  Protein: " <> float.to_string(plan.total_macros.protein) <> "g")
      io.println("  Fat: " <> float.to_string(plan.total_macros.fat) <> "g")
      io.println("  Carbs: " <> float.to_string(plan.total_macros.carbs) <> "g")
    }
    Error(msg) -> {
      io.println("❌ Error: " <> msg)
    }
  }
}
```

---

## Testing

### Example Test
```gleam
import gleeunit/should
import meal_planner/auto_planner

pub fn auto_plan_test() {
  let recipes = create_test_recipes()
  let config = auto_planner.AutoPlanConfig(
    diet_principles: [auto_planner.VerticalDiet],
    macro_targets: Macros(protein: 180.0, fat: 60.0, carbs: 250.0),
    recipe_count: 4,
    variety_factor: 0.7,
    user_id: "test-user",
  )

  let result = auto_planner.generate_auto_plan(recipes, config)

  result
  |> should.be_ok

  case result {
    Ok(plan) -> {
      plan.recipes
      |> list.length
      |> should.equal(4)
    }
    Error(_) -> should.fail()
  }
}
```

See `test/auto_planner_test.gleam` for comprehensive test suite.
