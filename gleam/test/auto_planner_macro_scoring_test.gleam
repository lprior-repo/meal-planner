import gleeunit
import gleeunit/should
import meal_planner/auto_planner
import meal_planner/id
import meal_planner/types.{
  type Ingredient, type Macros, type Recipe, Ingredient, Low, Macros, Recipe,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a test recipe with specific macros
fn create_recipe(
  id_str: String,
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Recipe {
  Recipe(
    id: id.recipe_id(id_str),
    name: name,
    ingredients: [Ingredient(name: "test", quantity: "1 serving")],
    instructions: ["Cook it"],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "Test",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Create test macros
fn test_macros(protein: Float, fat: Float, carbs: Float) -> Macros {
  Macros(protein: protein, fat: fat, carbs: carbs)
}

// ============================================================================
// Tests: calculate_macro_match_score with per-recipe division
// ============================================================================

/// Test perfect macro match for single recipe
pub fn calculate_macro_match_score_perfect_match_single_recipe_test() {
  let recipe = create_recipe("r1", "Perfect", 30.0, 20.0, 50.0)
  let targets = test_macros(30.0, 20.0, 50.0)
  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  // Perfect match should give score close to 1.0
  // e^(-2 * 0) = e^0 = 1.0
  score
  |> should.be_close_to(1.0, 0.01)
}

/// Test macro match for 3-recipe plan where recipe is perfect for 1/3 portion
pub fn calculate_macro_match_score_perfect_match_three_recipes_test() {
  let recipe = create_recipe("r1", "OneThird", 10.0, 6.667, 16.667)
  let targets = test_macros(30.0, 20.0, 50.0)
  // Target per recipe: 30/3=10, 20/3=6.667, 50/3=16.667
  let score = auto_planner.calculate_macro_match_score(recipe, targets, 3)

  // Should be very close to 1.0
  score
  |> should.be_close_to(1.0, 0.05)
}

/// Test macro match when recipe is off by 50% for single recipe
pub fn calculate_macro_match_score_50_percent_deviation_test() {
  let recipe = create_recipe("r1", "HighProtein", 45.0, 20.0, 50.0)
  // Protein is 45 vs target 30 = 50% deviation
  let targets = test_macros(30.0, 20.0, 50.0)
  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  // 50% dev = 0.5
  // e^(-2 * 0.5) = e^(-1) ≈ 0.368
  score
  |> should.be_close_to(0.368, 0.02)
}

/// Test macro match with 100% deviation
pub fn calculate_macro_match_score_100_percent_deviation_test() {
  let recipe = create_recipe("r1", "VeryDifferent", 60.0, 20.0, 50.0)
  // Protein is 60 vs target 30 = 100% deviation
  let targets = test_macros(30.0, 20.0, 50.0)
  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  // 100% dev = 1.0
  // e^(-2 * 1.0) = e^(-2) ≈ 0.135
  score
  |> should.be_close_to(0.135, 0.02)
}

/// Test that score is bounded between 0 and 1
pub fn calculate_macro_match_score_bounded_test() {
  let recipe = create_recipe("r1", "Extreme", 500.0, 500.0, 500.0)
  let targets = test_macros(30.0, 20.0, 50.0)
  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  // Score should always be between 0 and 1
  score
  |> should.be_greater_than(-0.01)
  score
  |> should.be_less_than(1.01)
}

/// Test averaging of three macro deviations
pub fn calculate_macro_match_score_averaging_deviations_test() {
  // Recipe: protein perfect, fat 50% off, carbs 50% off
  let recipe = create_recipe("r1", "Mixed", 30.0, 30.0, 75.0)
  let targets = test_macros(30.0, 20.0, 50.0)
  // Protein: 0% dev
  // Fat: 50% dev (30 vs 20)
  // Carbs: 50% dev (75 vs 50)
  // Avg: (0 + 0.5 + 0.5) / 3 = 0.333
  // e^(-2 * 0.333) = e^(-0.667) ≈ 0.513
  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  score
  |> should.be_close_to(0.513, 0.05)
}

/// Test that lower recipe count leads to tighter per-recipe targets
pub fn calculate_macro_match_score_recipe_count_affects_targets_test() {
  let recipe = create_recipe("r1", "Test", 50.0, 10.0, 50.0)
  let targets = test_macros(100.0, 20.0, 100.0)

  // With 1 recipe: targets stay at 100/20/100
  // With 2 recipes: targets become 50/10/50
  let score_one = auto_planner.calculate_macro_match_score(recipe, targets, 1)
  let score_two = auto_planner.calculate_macro_match_score(recipe, targets, 2)

  // Score with 2 recipes should be much better (closer to target per recipe)
  score_two
  |> should.be_greater_than(score_one)
}

// ============================================================================
// Tests: calculate_variety_score
// ============================================================================

/// Test variety score for new unique recipe
pub fn calculate_variety_score_first_recipe_test() {
  let recipe = create_recipe("r1", "First", 30.0, 20.0, 50.0)

  let score = auto_planner.calculate_variety_score(recipe, [])

  score
  |> should.equal(1.0)
}

/// Test variety score degrades for repeated categories
pub fn calculate_variety_score_repeated_categories_test() {
  let recipe = create_recipe("r1", "Chicken", 30.0, 20.0, 50.0)
  let same_cat =
    create_recipe("r2", "Chicken2", 30.0, 20.0, 50.0)
    |> fn(r) { Recipe(..r, category: "Chicken") }

  let score_first = auto_planner.calculate_variety_score(same_cat, [])
  let score_second = auto_planner.calculate_variety_score(recipe, [same_cat])
  let score_third =
    auto_planner.calculate_variety_score(recipe, [same_cat, same_cat])

  // First should be 1.0, second should be 0.4, third should be 0.2
  score_first
  |> should.equal(1.0)
  score_second
  |> should.equal(0.4)
  score_third
  |> should.equal(0.2)
}

/// Test variety score for different categories
pub fn calculate_variety_score_different_categories_test() {
  let chicken = create_recipe("r1", "Chicken", 30.0, 20.0, 50.0)
  let beef =
    create_recipe("r2", "Beef", 30.0, 20.0, 50.0)
    |> fn(r) { Recipe(..r, category: "Beef") }

  let score = auto_planner.calculate_variety_score(beef, [chicken])

  // Different category should get full score
  score
  |> should.equal(1.0)
}

// ============================================================================
// Tests: score_recipe
// ============================================================================

/// Test comprehensive recipe scoring
pub fn score_recipe_comprehensive_test() {
  let recipe = create_recipe("r1", "Good", 30.0, 20.0, 50.0)
  let config =
    auto_planner.AutoPlanConfig(
      user_id: "user1",
      diet_principles: [],
      macro_targets: test_macros(30.0, 20.0, 50.0),
      recipe_count: 1,
      variety_factor: 1.0,
    )

  let scored = auto_planner.score_recipe(recipe, config, [])

  // Perfect recipe with no prior selections
  scored.macro_match_score
  |> should.be_close_to(1.0, 0.01)
  scored.variety_score
  |> should.equal(1.0)
  scored.diet_compliance_score
  |> should.equal(1.0)

  // Overall should reflect weighted average: 1.0*0.4 + 1.0*0.35 + 1.0*0.25 = 1.0
  scored.overall_score
  |> should.be_close_to(1.0, 0.01)
}

/// Test scoring with vertical diet principle
pub fn score_recipe_vertical_diet_compliance_test() {
  let compliant_recipe =
    create_recipe("r1", "Compliant", 30.0, 20.0, 50.0)
    |> fn(r) { Recipe(..r, vertical_compliant: True) }

  let non_compliant_recipe =
    create_recipe("r2", "NonCompliant", 30.0, 20.0, 50.0)
    |> fn(r) { Recipe(..r, vertical_compliant: False) }

  let config =
    auto_planner.AutoPlanConfig(
      user_id: "user1",
      diet_principles: [auto_planner.VerticalDiet],
      macro_targets: test_macros(30.0, 20.0, 50.0),
      recipe_count: 1,
      variety_factor: 1.0,
    )

  let compliant_score = auto_planner.score_recipe(compliant_recipe, config, [])
  let non_compliant_score =
    auto_planner.score_recipe(non_compliant_recipe, config, [])

  // Compliant should have diet score of 1.0
  compliant_score.diet_compliance_score
  |> should.equal(1.0)

  // Non-compliant should have diet score of 0.0
  non_compliant_score.diet_compliance_score
  |> should.equal(0.0)

  // Non-compliant overall score should be much lower
  non_compliant_score.overall_score
  |> should.be_less_than(compliant_score.overall_score)
}

// ============================================================================
// Tests: Edge Cases
// ============================================================================

/// Test handling of zero targets (should not crash)
pub fn calculate_macro_match_score_zero_targets_test() {
  let recipe = create_recipe("r1", "Test", 10.0, 5.0, 15.0)
  let targets = test_macros(0.0, 0.0, 0.0)

  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  // Should not crash and should return a valid score
  score
  |> should.be_greater_than_or_equal(0.0)
  score
  |> should.be_less_than_or_equal(1.0)
}

/// Test handling of very large macro values
pub fn calculate_macro_match_score_large_values_test() {
  let recipe = create_recipe("r1", "BigRecipe", 1000.0, 500.0, 2000.0)
  let targets = test_macros(1000.0, 500.0, 2000.0)

  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  // Should still get a good score for matching values
  score
  |> should.be_close_to(1.0, 0.01)
}

/// Test handling of very small macro values
pub fn calculate_macro_match_score_small_values_test() {
  let recipe = create_recipe("r1", "SmallRecipe", 0.5, 0.2, 1.0)
  let targets = test_macros(0.5, 0.2, 1.0)

  let score = auto_planner.calculate_macro_match_score(recipe, targets, 1)

  // Should still get a good score for matching values
  score
  |> should.be_close_to(1.0, 0.01)
}

/// Test with high recipe count (large per-recipe divisions)
pub fn calculate_macro_match_score_high_recipe_count_test() {
  let recipe = create_recipe("r1", "SmallPortion", 2.5, 1.667, 4.167)
  let targets = test_macros(30.0, 20.0, 50.0)
  // Target per recipe: 30/12=2.5, 20/12=1.667, 50/12=4.167

  let score = auto_planner.calculate_macro_match_score(recipe, targets, 12)

  // Should be close to perfect for 12-recipe meal plan
  score
  |> should.be_close_to(1.0, 0.05)
}
