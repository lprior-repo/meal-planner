import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/auto_planner/recipe_scorer
import meal_planner/diet_validator.{VerticalDiet}
import meal_planner/types.{type Recipe, High, Ingredient, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data
// ============================================================================

fn sample_recipe_compliant() -> Recipe {
  Recipe(
    id: "rec-001",
    name: "Grilled Chicken with Rice",
    ingredients: [
      Ingredient(name: "Chicken breast", quantity: "200g"),
      Ingredient(name: "White rice", quantity: "150g"),
      Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      Ingredient(name: "Salt", quantity: "1 tsp"),
    ],
    instructions: ["Grill chicken", "Cook rice", "Season and serve"],
    macros: Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
    servings: 1,
    category: "Main Course",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn sample_recipe_non_compliant() -> Recipe {
  Recipe(
    id: "rec-002",
    name: "Pasta with Beans",
    ingredients: [
      Ingredient(name: "Pasta", quantity: "200g"),
      Ingredient(name: "Kidney beans", quantity: "100g"),
    ],
    instructions: ["Boil pasta", "Add beans", "Serve"],
    macros: Macros(protein: 20.0, fat: 5.0, carbs: 80.0),
    servings: 1,
    category: "Main Course",
    fodmap_level: High,
    vertical_compliant: False,
  )
}

fn sample_recipe_high_protein() -> Recipe {
  Recipe(
    id: "rec-003",
    name: "Steak and Vegetables",
    ingredients: [
      Ingredient(name: "Beef steak", quantity: "300g"),
      Ingredient(name: "Broccoli", quantity: "150g"),
      Ingredient(name: "Carrots", quantity: "100g"),
      Ingredient(name: "Spinach", quantity: "50g"),
      Ingredient(name: "Butter", quantity: "1 tbsp"),
    ],
    instructions: ["Grill steak", "Steam vegetables", "Serve hot"],
    macros: Macros(protein: 60.0, fat: 25.0, carbs: 20.0),
    servings: 1,
    category: "Main Course",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

// ============================================================================
// Scoring Tests
// ============================================================================

pub fn score_recipe_basic_test() {
  let recipe = sample_recipe_compliant()
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let weights = recipe_scorer.default_weights()

  let score =
    recipe_scorer.score_recipe(recipe, [VerticalDiet], targets, weights)

  // Should have perfect macro match and good compliance
  score.recipe_id
  |> should.equal("rec-001")

  score.macro_match_score
  |> should.equal(1.0)

  score.diet_compliance_score
  |> should.equal(1.0)

  // Total score should be high (diet + macro + variety with weights)
  score.total_score
  |> fn(s) { s >. 0.8 }
  |> should.be_true
}

pub fn score_recipe_with_deviation_test() {
  let recipe = sample_recipe_compliant()
  let targets = Macros(protein: 50.0, fat: 10.0, carbs: 40.0)
  let weights = recipe_scorer.default_weights()

  let score =
    recipe_scorer.score_recipe(recipe, [VerticalDiet], targets, weights)

  // Macro match should be less than perfect
  score.macro_match_score
  |> fn(s) { s <. 1.0 }
  |> should.be_true

  score.macro_match_score
  |> fn(s) { s >. 0.0 }
  |> should.be_true
}

pub fn score_recipe_non_compliant_test() {
  let recipe = sample_recipe_non_compliant()
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let weights = recipe_scorer.default_weights()

  let score =
    recipe_scorer.score_recipe(recipe, [VerticalDiet], targets, weights)

  // Should have low diet compliance score (50% or below since 1 of 2 ingredients is high-FODMAP)
  score.diet_compliance_score
  |> fn(s) { s <=. 0.5 }
  |> should.be_true

  // High-FODMAP ingredients are added to warnings (not violations - only seed oils are violations)
  // So we check warnings are not empty OR total score is low
  score.total_score
  |> fn(s) { s <. 0.8 }
  |> should.be_true
}

// ============================================================================
// Macro Match Tests
// ============================================================================

pub fn macro_match_perfect_test() {
  let recipe_macros = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)

  let score = recipe_scorer.score_macro_match(recipe_macros, targets)

  score
  |> should.equal(1.0)
}

pub fn macro_match_slight_deviation_test() {
  let recipe_macros = Macros(protein: 42.0, fat: 14.0, carbs: 52.0)
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)

  let score = recipe_scorer.score_macro_match(recipe_macros, targets)

  // Should be close to 1.0 but not perfect
  score
  |> fn(s) { s >. 0.9 }
  |> should.be_true

  score
  |> fn(s) { s <. 1.0 }
  |> should.be_true
}

pub fn macro_match_large_deviation_test() {
  let recipe_macros = Macros(protein: 20.0, fat: 5.0, carbs: 80.0)
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)

  let score = recipe_scorer.score_macro_match(recipe_macros, targets)

  // Should be significantly lower
  score
  |> fn(s) { s <. 0.5 }
  |> should.be_true

  score
  |> fn(s) { s >=. 0.0 }
  |> should.be_true
}

pub fn macro_deviation_calculation_test() {
  let deviation = recipe_scorer.macro_deviation(50.0, 40.0)

  // 50 vs 40 = 25% deviation
  deviation
  |> should.equal(25.0)
}

// ============================================================================
// Variety Tests
// ============================================================================

pub fn variety_score_many_ingredients_test() {
  let recipe = sample_recipe_high_protein()
  let score = recipe_scorer.score_variety(recipe)

  // 5 ingredients should give max variety score
  score
  |> should.equal(1.0)
}

pub fn variety_score_few_ingredients_test() {
  let recipe = sample_recipe_non_compliant()
  let score = recipe_scorer.score_variety(recipe)

  // 2 ingredients should give low variety score
  score
  |> should.equal(0.4)
}

pub fn variety_penalty_no_overlap_test() {
  let selected = [sample_recipe_compliant()]
  let candidate = sample_recipe_high_protein()

  let penalty = recipe_scorer.calculate_variety_penalty(selected, candidate)

  // Different ingredients = low penalty
  penalty
  |> fn(p) { p <. 0.5 }
  |> should.be_true
}

pub fn variety_penalty_complete_overlap_test() {
  let selected = [sample_recipe_compliant()]
  let candidate = sample_recipe_compliant()

  let penalty = recipe_scorer.calculate_variety_penalty(selected, candidate)

  // Same recipe = high penalty
  penalty
  |> should.equal(1.0)
}

// ============================================================================
// Ranking Tests
// ============================================================================

pub fn score_and_rank_recipes_test() {
  let recipes = [
    sample_recipe_compliant(),
    sample_recipe_non_compliant(),
    sample_recipe_high_protein(),
  ]
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let weights = recipe_scorer.default_weights()

  let scored =
    recipe_scorer.score_and_rank_recipes(
      recipes,
      [VerticalDiet],
      targets,
      weights,
    )

  // Should return all recipes
  scored
  |> list.length
  |> should.equal(3)

  // First recipe should have highest score
  let assert [first, ..] = scored
  let assert [_, second, ..] = scored

  first.total_score
  |> fn(s) { s >=. second.total_score }
  |> should.be_true
}

// ============================================================================
// Filtering Tests
// ============================================================================

pub fn filter_by_score_test() {
  let recipes = [
    sample_recipe_compliant(),
    sample_recipe_non_compliant(),
  ]
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let weights = recipe_scorer.default_weights()

  let scored =
    recipe_scorer.score_and_rank_recipes(
      recipes,
      [VerticalDiet],
      targets,
      weights,
    )

  let filtered = recipe_scorer.filter_by_score(scored, 0.7)

  // Should filter out low-scoring recipes
  filtered
  |> list.length
  |> fn(n) { n < list.length(scored) }
  |> should.be_true
}

pub fn filter_compliant_only_test() {
  let recipes = [
    sample_recipe_compliant(),
    sample_recipe_non_compliant(),
  ]
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let weights = recipe_scorer.default_weights()

  let scored =
    recipe_scorer.score_and_rank_recipes(
      recipes,
      [VerticalDiet],
      targets,
      weights,
    )

  let filtered = recipe_scorer.filter_compliant_only(scored)

  // Should only include compliant recipes
  filtered
  |> list.all(fn(score) { list.is_empty(score.violations) })
  |> should.be_true
}

pub fn take_top_n_test() {
  let recipes = [
    sample_recipe_compliant(),
    sample_recipe_non_compliant(),
    sample_recipe_high_protein(),
  ]
  let targets = Macros(protein: 40.0, fat: 15.0, carbs: 50.0)
  let weights = recipe_scorer.default_weights()

  let scored =
    recipe_scorer.score_and_rank_recipes(
      recipes,
      [VerticalDiet],
      targets,
      weights,
    )

  let top_2 = recipe_scorer.take_top_n(scored, 2)

  top_2
  |> list.length
  |> should.equal(2)
}

// ============================================================================
// Weights Tests
// ============================================================================

pub fn default_weights_sum_test() {
  let weights = recipe_scorer.default_weights()

  let sum = weights.diet_compliance +. weights.macro_match +. weights.variety

  // Weights should sum to 1.0
  sum
  |> should.equal(1.0)
}

pub fn strict_compliance_weights_test() {
  let weights = recipe_scorer.strict_compliance_weights()

  // Diet compliance should be highest
  weights.diet_compliance
  |> fn(w) { w >. weights.macro_match }
  |> should.be_true

  weights.diet_compliance
  |> fn(w) { w >. weights.variety }
  |> should.be_true
}

pub fn performance_weights_test() {
  let weights = recipe_scorer.performance_weights()

  // Macro match should be highest
  weights.macro_match
  |> fn(w) { w >. weights.diet_compliance }
  |> should.be_true

  weights.macro_match
  |> fn(w) { w >. weights.variety }
  |> should.be_true
}
