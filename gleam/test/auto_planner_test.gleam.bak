import gleam/list
import gleeunit/should
import meal_planner/auto_planner.{
  type AutoPlanConfig, type RecipeScore, AutoPlanConfig, RecipeScore,
  filter_by_diet_principles, generate_auto_plan, rank_by_score, score_recipe,
}
import shared/types.{
  type FodmapLevel, type Recipe, Ingredient, Low, Macros, Medium, Recipe,
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn create_test_macros(protein: Float, fat: Float, carbs: Float) -> Macros {
  Macros(protein: protein, fat: fat, carbs: carbs)
}

fn create_vertical_recipe(
  id: String,
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Recipe {
  Recipe(
    id: id,
    name: name,
    ingredients: [Ingredient("test", "100g")],
    instructions: ["Cook it"],
    macros: create_test_macros(protein, fat, carbs),
    servings: 1,
    category: "main",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn create_non_vertical_recipe(
  id: String,
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  fodmap: FodmapLevel,
) -> Recipe {
  Recipe(
    id: id,
    name: name,
    ingredients: [Ingredient("test", "100g")],
    instructions: ["Cook it"],
    macros: create_test_macros(protein, fat, carbs),
    servings: 1,
    category: "main",
    fodmap_level: fodmap,
    vertical_compliant: False,
  )
}

fn create_config(
  protein: Float,
  fat: Float,
  carbs: Float,
  variety: Float,
) -> AutoPlanConfig {
  AutoPlanConfig(
    diet_principles: ["vertical_diet"],
    macro_targets: create_test_macros(protein, fat, carbs),
    recipe_count: 4,
    variety_factor: variety,
  )
}

// ============================================================================
// Tests: filter_by_diet_principles
// ============================================================================

pub fn filter_by_vertical_diet_test() {
  let recipes = [
    create_vertical_recipe("1", "Steak & Rice", 40.0, 20.0, 50.0),
    create_non_vertical_recipe("2", "Pasta", 15.0, 5.0, 60.0, Medium),
    create_vertical_recipe("3", "Chicken & White Rice", 35.0, 10.0, 45.0),
    create_non_vertical_recipe("4", "Bean Chili", 20.0, 8.0, 40.0, Medium),
  ]

  let filtered = filter_by_diet_principles(recipes, ["vertical_diet"])

  filtered
  |> list.length
  |> should.equal(2)

  filtered
  |> list.map(fn(r) { r.id })
  |> should.equal(["1", "3"])
}

pub fn filter_by_vertical_diet_requires_low_fodmap_test() {
  let recipes = [
    // Marked vertical but has medium FODMAP - should be filtered out
    Recipe(
      id: "1",
      name: "Questionable Dish",
      ingredients: [Ingredient("test", "100g")],
      instructions: ["Cook it"],
      macros: create_test_macros(30.0, 15.0, 40.0),
      servings: 1,
      category: "main",
      fodmap_level: Medium,
      vertical_compliant: True,
    ),
    // Proper vertical diet recipe
    create_vertical_recipe("2", "Good Dish", 30.0, 15.0, 40.0),
  ]

  let filtered = filter_by_diet_principles(recipes, ["vertical_diet"])

  filtered
  |> list.length
  |> should.equal(1)

  filtered
  |> list.first
  |> should.be_ok
  |> fn(r) { r.id }
  |> should.equal("2")
}

pub fn filter_empty_principles_returns_all_test() {
  let recipes = [
    create_vertical_recipe("1", "Recipe 1", 30.0, 15.0, 40.0),
    create_non_vertical_recipe("2", "Recipe 2", 25.0, 10.0, 35.0, Medium),
  ]

  let filtered = filter_by_diet_principles(recipes, [])

  filtered
  |> list.length
  |> should.equal(2)
}

// ============================================================================
// Tests: score_recipe
// ============================================================================

pub fn score_recipe_perfect_vertical_compliance_test() {
  let recipe = create_vertical_recipe("1", "Perfect Steak", 40.0, 20.0, 50.0)
  let config = create_config(40.0, 20.0, 50.0, 0.5)
  let already_selected = []

  let score = score_recipe(recipe, config, already_selected)

  // Perfect vertical diet compliance (low FODMAP + marked compliant)
  score.diet_compliance
  |> should.equal(1.0)

  // Perfect macro match
  score.macro_match
  |> should.equal(1.0)

  // High variety (no similar recipes selected)
  score.variety_score
  |> should.equal(1.0)

  // Overall score should be 1.0
  score.overall_score
  |> should.equal(1.0)
}

pub fn score_recipe_non_vertical_zero_compliance_test() {
  let recipe = create_non_vertical_recipe("1", "Pasta", 15.0, 5.0, 60.0, Medium)
  let config = create_config(40.0, 20.0, 50.0, 0.5)
  let already_selected = []

  let score = score_recipe(recipe, config, already_selected)

  // Zero vertical diet compliance (medium FODMAP + not marked compliant)
  score.diet_compliance
  |> should.equal(0.0)
}

pub fn score_recipe_macro_match_calculation_test() {
  // Recipe: P=40, F=20, C=50 (total = 110)
  // Target: P=50, F=25, C=55 (total = 130)
  // Differences: |40-50|=10, |20-25|=5, |50-55|=5 (total diff = 20)
  // Average diff = 20/3 = 6.67
  // Average target = 130/3 = 43.33
  // Match = 1 - (6.67 / 43.33) = 1 - 0.154 = 0.846
  let recipe = create_vertical_recipe("1", "Close Match", 40.0, 20.0, 50.0)
  let config = create_config(50.0, 25.0, 55.0, 0.5)
  let already_selected = []

  let score = score_recipe(recipe, config, already_selected)

  // Should be around 0.85 for macro match
  score.macro_match
  |> should.be_close_to(0.85, 0.01)
}

pub fn score_recipe_variety_penalty_for_similar_proteins_test() {
  let recipe = create_vertical_recipe("3", "Chicken Breast", 40.0, 10.0, 45.0)
  let already_selected = [
    create_vertical_recipe("1", "Chicken Thighs", 35.0, 15.0, 40.0),
    create_vertical_recipe("2", "Steak", 45.0, 20.0, 50.0),
  ]
  let config = create_config(40.0, 15.0, 45.0, 0.5)

  let score = score_recipe(recipe, config, already_selected)

  // Should have lower variety score due to similar name (chicken)
  score.variety_score
  |> should.be_less_than(1.0)
}

// ============================================================================
// Tests: rank_by_score
// ============================================================================

pub fn rank_by_score_orders_by_overall_score_test() {
  let recipe1 = create_vertical_recipe("1", "Low Score", 20.0, 10.0, 30.0)
  let recipe2 = create_vertical_recipe("2", "High Score", 40.0, 20.0, 50.0)
  let recipe3 = create_vertical_recipe("3", "Medium Score", 30.0, 15.0, 40.0)

  let scores = [
    RecipeScore(
      recipe: recipe1,
      diet_compliance: 0.5,
      macro_match: 0.6,
      variety_score: 0.7,
      overall_score: 0.6,
    ),
    RecipeScore(
      recipe: recipe2,
      diet_compliance: 1.0,
      macro_match: 1.0,
      variety_score: 1.0,
      overall_score: 1.0,
    ),
    RecipeScore(
      recipe: recipe3,
      diet_compliance: 0.8,
      macro_match: 0.8,
      variety_score: 0.8,
      overall_score: 0.8,
    ),
  ]

  let ranked = rank_by_score(scores)

  ranked
  |> list.map(fn(r) { r.id })
  |> should.equal(["2", "3", "1"])
}

// ============================================================================
// Tests: generate_auto_plan
// ============================================================================

pub fn generate_auto_plan_returns_4_recipes_test() {
  let available_recipes = [
    create_vertical_recipe("1", "Steak & Rice", 40.0, 20.0, 50.0),
    create_vertical_recipe("2", "Chicken & Rice", 35.0, 10.0, 45.0),
    create_vertical_recipe("3", "Salmon & Rice", 38.0, 22.0, 48.0),
    create_vertical_recipe("4", "Ground Beef & Rice", 42.0, 25.0, 52.0),
    create_vertical_recipe("5", "Turkey & Rice", 36.0, 12.0, 46.0),
    create_non_vertical_recipe("6", "Pasta", 15.0, 5.0, 60.0, Medium),
  ]

  let config = create_config(40.0, 20.0, 50.0, 0.5)

  let result = generate_auto_plan(available_recipes, config)

  result
  |> should.be_ok
  |> list.length
  |> should.equal(4)
}

pub fn generate_auto_plan_selects_best_matches_test() {
  let available_recipes = [
    // Perfect match
    create_vertical_recipe("1", "Perfect Steak", 40.0, 20.0, 50.0),
    // Close match
    create_vertical_recipe("2", "Good Chicken", 38.0, 19.0, 48.0),
    // Far from target
    create_vertical_recipe("3", "Low Protein", 20.0, 10.0, 30.0),
    // Good match
    create_vertical_recipe("4", "Salmon", 39.0, 21.0, 49.0),
    // Another good match
    create_vertical_recipe("5", "Turkey", 41.0, 20.0, 51.0),
  ]

  let config = create_config(40.0, 20.0, 50.0, 0.3)

  let result = generate_auto_plan(available_recipes, config)

  let selected =
    result
    |> should.be_ok

  // Should NOT include the low protein recipe
  selected
  |> list.map(fn(r) { r.id })
  |> list.contains("3")
  |> should.be_false
}

pub fn generate_auto_plan_ensures_variety_test() {
  let available_recipes = [
    create_vertical_recipe("1", "Chicken Breast", 40.0, 20.0, 50.0),
    create_vertical_recipe("2", "Chicken Thighs", 40.0, 20.0, 50.0),
    create_vertical_recipe("3", "Chicken Wings", 40.0, 20.0, 50.0),
    create_vertical_recipe("4", "Steak", 40.0, 20.0, 50.0),
    create_vertical_recipe("5", "Salmon", 40.0, 20.0, 50.0),
    create_vertical_recipe("6", "Turkey", 40.0, 20.0, 50.0),
  ]

  let config = create_config(40.0, 20.0, 50.0, 0.8)

  let result = generate_auto_plan(available_recipes, config)

  let selected =
    result
    |> should.be_ok

  // With high variety factor (0.8), should prefer diverse protein sources
  // Should not select all three chicken recipes
  let chicken_count =
    selected
    |> list.filter(fn(r) {
      r.name == "Chicken Breast"
      || r.name == "Chicken Thighs"
      || r.name == "Chicken Wings"
    })
    |> list.length

  chicken_count
  |> should.be_less_than(3)
}

pub fn generate_auto_plan_fails_with_insufficient_recipes_test() {
  let available_recipes = [
    create_vertical_recipe("1", "Only Recipe", 40.0, 20.0, 50.0),
    // Need 4 but only have 1 vertical-compliant
    create_non_vertical_recipe("2", "Not Compliant", 30.0, 15.0, 40.0, Medium),
  ]

  let config = create_config(40.0, 20.0, 50.0, 0.5)

  let result = generate_auto_plan(available_recipes, config)

  result
  |> should.be_error
}

pub fn generate_auto_plan_filters_by_diet_principles_test() {
  let available_recipes = [
    create_vertical_recipe("1", "Steak", 40.0, 20.0, 50.0),
    create_vertical_recipe("2", "Chicken", 35.0, 10.0, 45.0),
    create_non_vertical_recipe("3", "Pasta", 15.0, 5.0, 60.0, Medium),
    create_vertical_recipe("4", "Salmon", 38.0, 22.0, 48.0),
    create_vertical_recipe("5", "Turkey", 36.0, 12.0, 46.0),
  ]

  let config = create_config(40.0, 20.0, 50.0, 0.5)

  let result = generate_auto_plan(available_recipes, config)

  let selected =
    result
    |> should.be_ok

  // Should only include vertical-compliant recipes
  selected
  |> list.all(fn(r) { r.vertical_compliant && r.fodmap_level == Low })
  |> should.be_true
}

// ============================================================================
// Helper Assertions
// ============================================================================

fn should_be_close_to(value: Float, target: Float, tolerance: Float) -> Float {
  let diff = case value >. target {
    True -> value -. target
    False -> target -. value
  }

  case diff <=. tolerance {
    True -> value
    False -> {
      should.fail()
      value
    }
  }
}

fn should_be_less_than(value: Float, max: Float) -> Float {
  case value <. max {
    True -> value
    False -> {
      should.fail()
      value
    }
  }
}
