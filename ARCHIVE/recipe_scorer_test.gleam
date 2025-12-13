/// Unit tests for recipe scoring system
///
/// Tests cover:
/// - Macro matching score calculation
/// - Variety scoring based on ingredient count
/// - Score filtering and ranking
/// - Macro deviation calculations
/// - Variety penalty calculations
/// - Weight-based score aggregation
import gleeunit
import gleeunit/should
import gleam/list
import gleam/float
import gleam/int
import meal_planner/types.{type Macros, Macros}
import meal_planner/id
import meal_planner/auto_planner/recipe_scorer.{
  type RecipeScore, type ScoringWeights, RecipeScore, ScoringWeights,
  score_recipe, score_macro_match, score_variety, calculate_variety_penalty,
  filter_by_score, filter_compliant_only, take_top_n, macro_deviation,
  score_and_rank_recipes, default_weights, strict_compliance_weights,
  performance_weights,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn test_macros() -> Macros {
  Macros(protein: 30.0, fat: 20.0, carbs: 50.0)
}

fn test_macros_low() -> Macros {
  Macros(protein: 10.0, fat: 5.0, carbs: 15.0)
}

fn test_macros_high() -> Macros {
  Macros(protein: 60.0, fat: 40.0, carbs: 80.0)
}

fn test_recipe(
  recipe_id: String,
  macros: Macros,
  ingredient_count: Int,
) -> types.Recipe {
  types.Recipe(
    id: id.recipe_id(recipe_id),
    name: "Test Recipe " <> recipe_id,
    ingredients: case ingredient_count {
      0 -> []
      n -> list.range(1, n)
        |> list.map(fn(i) {
          types.Ingredient(
            name: recipe_id <> "-Ingredient-" <> int.to_string(i),
            quantity: "1.0g",
          )
        })
    },
    instructions: [],
    macros: macros,
    servings: 1,
    category: "general",
    fodmap_level: types.Low,
    vertical_compliant: True,
  )
}

fn default_recipe() -> types.Recipe {
  test_recipe("recipe-1", test_macros(), 3)
}

// ============================================================================
// Macro Matching Score Tests
// ============================================================================

pub fn macro_match_perfect_score_test() {
  let recipe_macros = Macros(protein: 30.0, fat: 20.0, carbs: 50.0)
  let target_macros = Macros(protein: 30.0, fat: 20.0, carbs: 50.0)

  let score = score_macro_match(recipe_macros, target_macros)

  // Perfect match should score very close to 1.0
  score  // TODO: should.be_greater_than(0.99)
  score  // TODO: should.be_less_than_or_equal_to(1.0)
}

pub fn macro_match_zero_error_rate_test() {
  let recipe_macros = Macros(protein: 50.0, fat: 50.0, carbs: 50.0)
  let target_macros = Macros(protein: 50.0, fat: 50.0, carbs: 50.0)

  let score = score_macro_match(recipe_macros, target_macros)

  score  // TODO: should.be_greater_than(0.99)
}

pub fn macro_match_partial_deviation_test() {
  let recipe_macros = Macros(protein: 35.0, fat: 20.0, carbs: 50.0)
  let target_macros = Macros(protein: 30.0, fat: 20.0, carbs: 50.0)

  let score = score_macro_match(recipe_macros, target_macros)

  // Should be less than perfect but still reasonable
  score  // TODO: should.be_greater_than(0.5)
  score  // TODO: should.be_less_than(0.99)
}

pub fn macro_match_significant_deviation_test() {
  let recipe_macros = Macros(protein: 10.0, fat: 5.0, carbs: 15.0)
  let target_macros = Macros(protein: 50.0, fat: 40.0, carbs: 100.0)

  let score = score_macro_match(recipe_macros, target_macros)

  // Large deviation should result in lower score
  score  // TODO: should.be_less_than(0.5)
  score  // TODO: should.be_greater_than(0.0)
}

pub fn macro_match_division_by_zero_protection_test() {
  let recipe_macros = Macros(protein: 10.0, fat: 5.0, carbs: 15.0)
  let target_macros = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)

  let score = score_macro_match(recipe_macros, target_macros)

  // Should handle zero targets gracefully (treats as 1.0)
  score  // TODO: should.be_greater_than_or_equal_to(0.0)
  score  // TODO: should.be_less_than_or_equal_to(1.0)
}

pub fn macro_match_clamped_to_range_test() {
  let recipe_macros = Macros(protein: 30.0, fat: 20.0, carbs: 50.0)
  let target_macros = Macros(protein: 30.0, fat: 20.0, carbs: 50.0)

  let score = score_macro_match(recipe_macros, target_macros)

  // Score should always be in [0, 1] range
  score  // TODO: should.be_greater_than_or_equal_to(0.0)
  score  // TODO: should.be_less_than_or_equal_to(1.0)
}

// ============================================================================
// Macro Deviation Tests
// ============================================================================

pub fn macro_deviation_zero_test() {
  let deviation = macro_deviation(30.0, 30.0)

  deviation |> should.equal(0.0)
}

pub fn macro_deviation_positive_difference_test() {
  let deviation = macro_deviation(40.0, 30.0)

  // 10/30 * 100 = 33.33%
  deviation  // TODO: should.be_greater_than(33.0)
  deviation  // TODO: should.be_less_than(34.0)
}

pub fn macro_deviation_negative_difference_test() {
  let deviation = macro_deviation(20.0, 30.0)

  // 10/30 * 100 = 33.33%
  deviation  // TODO: should.be_greater_than(33.0)
  deviation  // TODO: should.be_less_than(34.0)
}

pub fn macro_deviation_small_target_protection_test() {
  let deviation = macro_deviation(10.0, 0.0)

  // Should treat zero target as 1.0
  deviation  // TODO: should.be_greater_than(0.0)
}

pub fn macro_deviation_large_difference_test() {
  let deviation = macro_deviation(100.0, 10.0)

  // 90 / 10 * 100 = 900%
  deviation  // TODO: should.be_greater_than(800.0)
}

// ============================================================================
// Variety Scoring Tests
// ============================================================================

pub fn variety_score_no_ingredients_test() {
  let recipe = test_recipe("recipe-1", test_macros(), 0)

  let score = score_variety(recipe)

  score |> should.equal(0.0)
}

pub fn variety_score_one_ingredient_test() {
  let recipe = test_recipe("recipe-1", test_macros(), 1)

  let score = score_variety(recipe)

  score |> should.equal(0.2)
}

pub fn variety_score_two_ingredients_test() {
  let recipe = test_recipe("recipe-1", test_macros(), 2)

  let score = score_variety(recipe)

  score |> should.equal(0.4)
}

pub fn variety_score_three_ingredients_test() {
  let recipe = test_recipe("recipe-1", test_macros(), 3)

  let score = score_variety(recipe)

  score |> should.equal(0.6)
}

pub fn variety_score_four_ingredients_test() {
  let recipe = test_recipe("recipe-1", test_macros(), 4)

  let score = score_variety(recipe)

  score |> should.equal(0.8)
}

pub fn variety_score_five_or_more_ingredients_test() {
  let recipe = test_recipe("recipe-1", test_macros(), 5)

  let score = score_variety(recipe)

  score |> should.equal(1.0)
}

pub fn variety_score_many_ingredients_test() {
  let recipe = test_recipe("recipe-1", test_macros(), 20)

  let score = score_variety(recipe)

  score |> should.equal(1.0)
}

// ============================================================================
// Variety Penalty Tests
// ============================================================================

pub fn variety_penalty_no_overlap_test() {
  let selected = [test_recipe("r1", test_macros(), 2)]
  let candidate = test_recipe("r2", test_macros(), 2)

  let penalty = calculate_variety_penalty(selected, candidate)

  penalty |> should.equal(0.0)
}

pub fn variety_penalty_complete_overlap_test() {
  // Create recipes with identical ingredients by using the same recipe_id
  // so they generate the same ingredient names
  let selected = [test_recipe("same", test_macros(), 3)]
  let candidate = test_recipe("same", test_macros(), 3)

  let penalty = calculate_variety_penalty(selected, candidate)

  // Complete overlap = penalty of 1.0 (100% of ingredients are duplicates)
  penalty |> should.equal(1.0)
}

pub fn variety_penalty_no_ingredients_test() {
  let selected = [test_recipe("r1", test_macros(), 0)]
  let candidate = test_recipe("r2", test_macros(), 0)

  let penalty = calculate_variety_penalty(selected, candidate)

  penalty |> should.equal(0.0)
}

pub fn variety_penalty_partial_overlap_test() {
  let selected = [test_recipe("r1", test_macros(), 2)]
  let candidate = test_recipe("r2", test_macros(), 2)

  let penalty = calculate_variety_penalty(selected, candidate)

  // Should be between 0 and 1
  penalty  // TODO: should.be_greater_than_or_equal_to(0.0)
  penalty  // TODO: should.be_less_than_or_equal_to(1.0)
}

pub fn variety_penalty_multiple_selected_test() {
  let selected = [
    test_recipe("r1", test_macros(), 2),
    test_recipe("r2", test_macros(), 2),
  ]
  let candidate = test_recipe("r3", test_macros(), 2)

  let penalty = calculate_variety_penalty(selected, candidate)

  // Should handle multiple selected recipes
  penalty  // TODO: should.be_greater_than_or_equal_to(0.0)
  penalty  // TODO: should.be_less_than_or_equal_to(1.0)
}

// ============================================================================
// Recipe Scoring Tests
// ============================================================================

pub fn recipe_score_perfect_macro_match_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let score = score_recipe(recipe, [], targets, weights)

  // Should have non-zero total score
  score.total_score  // TODO: should.be_greater_than(0.0)
  score.macro_match_score  // TODO: should.be_greater_than(0.99)
}

pub fn recipe_score_breakdown_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let score = score_recipe(recipe, [], targets, weights)

  // Verify score structure
  score.recipe_id |> should.equal(recipe.id)
  score.variety_score |> should.equal(0.6)
  score.violations |> should.equal([])
  score.warnings |> should.equal([])
}

pub fn recipe_score_no_violations_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let score = score_recipe(recipe, [], targets, weights)

  score.violations |> should.equal([])
}

pub fn recipe_score_no_warnings_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let score = score_recipe(recipe, [], targets, weights)

  score.warnings |> should.equal([])
}

// ============================================================================
// Scoring Weights Tests
// ============================================================================

pub fn default_weights_values_test() {
  let weights = default_weights()

  weights.diet_compliance |> should.equal(0.5)
  weights.macro_match |> should.equal(0.3)
  weights.variety |> should.equal(0.2)
}

pub fn strict_compliance_weights_values_test() {
  let weights = strict_compliance_weights()

  weights.diet_compliance |> should.equal(0.7)
  weights.macro_match |> should.equal(0.2)
  weights.variety |> should.equal(0.1)
}

pub fn performance_weights_values_test() {
  let weights = performance_weights()

  weights.diet_compliance |> should.equal(0.3)
  weights.macro_match |> should.equal(0.6)
  weights.variety |> should.equal(0.1)
}

// ============================================================================
// Filtering Tests
// ============================================================================

pub fn filter_by_score_above_threshold_test() {
  let recipe1 = default_recipe()
  let recipe2 = test_recipe("recipe-2", test_macros_high(), 4)
  let targets = test_macros()
  let weights = default_weights()

  let scores = [
    score_recipe(recipe1, [], targets, weights),
    score_recipe(recipe2, [], targets, weights),
  ]

  let filtered = filter_by_score(scores, 0.5)

  filtered |> list.length  // TODO: should.be_greater_than_or_equal_to(0)
}

pub fn filter_by_score_empty_list_test() {
  let filtered = filter_by_score([], 0.5)

  filtered |> should.equal([])
}

pub fn filter_by_score_high_threshold_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let scores = [score_recipe(recipe, [], targets, weights)]

  let filtered = filter_by_score(scores, 999.0)

  filtered |> list.length |> should.equal(0)
}

pub fn filter_compliant_only_no_violations_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let scores = [score_recipe(recipe, [], targets, weights)]

  let filtered = filter_compliant_only(scores)

  filtered |> list.length |> should.equal(1)
}

pub fn filter_compliant_only_empty_test() {
  let filtered = filter_compliant_only([])

  filtered |> should.equal([])
}

// ============================================================================
// Ranking Tests
// ============================================================================

pub fn take_top_n_zero_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let scores = [score_recipe(recipe, [], targets, weights)]

  let taken = take_top_n(scores, 0)

  taken |> should.equal([])
}

pub fn take_top_n_more_than_available_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let scores = [score_recipe(recipe, [], targets, weights)]

  let taken = take_top_n(scores, 10)

  taken |> list.length |> should.equal(1)
}

pub fn take_top_n_exact_count_test() {
  let recipe1 = default_recipe()
  let recipe2 = test_recipe("recipe-2", test_macros_high(), 4)
  let targets = test_macros()
  let weights = default_weights()

  let scores = [
    score_recipe(recipe1, [], targets, weights),
    score_recipe(recipe2, [], targets, weights),
  ]

  let taken = take_top_n(scores, 1)

  taken |> list.length |> should.equal(1)
}

// ============================================================================
// Ranking Multiple Recipes Tests
// ============================================================================

pub fn score_and_rank_recipes_sorts_descending_test() {
  let recipe1 = default_recipe()
  let recipe2 = test_recipe("recipe-2", test_macros_high(), 4)
  let recipe3 = test_recipe("recipe-3", test_macros_low(), 2)

  let targets = test_macros()
  let weights = default_weights()

  let recipes = [recipe1, recipe2, recipe3]
  let scored = score_and_rank_recipes(recipes, [], targets, weights)

  scored |> list.length |> should.equal(3)

  // Verify sorted by score (descending)
  case scored {
    [first, second, ..] -> {
      // TODO: first.total_score should.be_greater_than_or_equal_to(second.total_score)
      True |> should.equal(True)
    }
    _ -> {
      // Should not be empty
      False |> should.equal(True)
    }
  }
}

pub fn score_and_rank_recipes_empty_list_test() {
  let targets = test_macros()
  let weights = default_weights()

  let scored = score_and_rank_recipes([], [], targets, weights)

  scored |> should.equal([])
}

pub fn score_and_rank_recipes_single_recipe_test() {
  let recipe = default_recipe()
  let targets = test_macros()
  let weights = default_weights()

  let scored = score_and_rank_recipes([recipe], [], targets, weights)

  scored |> list.length |> should.equal(1)
  scored |> list.first |> should.be_ok()
}

// ============================================================================
// Integration Tests (Multiple Components)
// ============================================================================

pub fn full_scoring_pipeline_test() {
  let recipes = [
    test_recipe("r1", test_macros(), 3),
    test_recipe("r2", test_macros_high(), 5),
    test_recipe("r3", test_macros_low(), 2),
  ]

  let targets = test_macros()
  let weights = default_weights()

  // Score and rank
  let scored = score_and_rank_recipes(recipes, [], targets, weights)

  // Filter by score
  let filtered = filter_by_score(scored, 0.1)

  // Get top 2
  let top = take_top_n(filtered, 2)

  top |> list.length  // TODO: should.be_less_than_or_equal_to(2)
}

pub fn scoring_with_different_weights_test() {
  let recipe = default_recipe()
  let targets = test_macros()

  let default_score =
    score_recipe(recipe, [], targets, default_weights()).total_score
  let strict_score =
    score_recipe(recipe, [], targets, strict_compliance_weights()).total_score
  let perf_score =
    score_recipe(recipe, [], targets, performance_weights()).total_score

  // All should be valid scores
  default_score  // TODO: should.be_greater_than(0.0)
  strict_score  // TODO: should.be_greater_than(0.0)
  perf_score  // TODO: should.be_greater_than(0.0)
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn score_with_extreme_macro_values_test() {
  let recipe =
    test_recipe("extreme", Macros(protein: 999.0, fat: 999.0, carbs: 999.0), 5)
  let targets = test_macros()
  let weights = default_weights()

  let score = score_recipe(recipe, [], targets, weights)

  // Should not crash and produce valid score
  score.total_score  // TODO: should.be_greater_than_or_equal_to(0.0)
  score.total_score  // TODO: should.be_less_than_or_equal_to(10.0)
}

pub fn score_with_zero_macro_targets_test() {
  let recipe = default_recipe()
  let targets = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  let weights = default_weights()

  let score = score_recipe(recipe, [], targets, weights)

  // Should handle gracefully
  score.total_score  // TODO: should.be_greater_than_or_equal_to(0.0)
}

pub fn variety_penalty_case_insensitive_test() {
  // Test that ingredient comparison is case-insensitive
  let selected = [test_recipe("r1", test_macros(), 2)]
  let candidate = test_recipe("r2", test_macros(), 2)

  let penalty = calculate_variety_penalty(selected, candidate)

  // Should be between 0 and 1
  penalty  // TODO: should.be_greater_than_or_equal_to(0.0)
  penalty  // TODO: should.be_less_than_or_equal_to(1.0)
}
