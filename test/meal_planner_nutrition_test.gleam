/// Tests for Nutrition Control Plane MVP
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/mvp_recipes
import meal_planner/ncp

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// MVP Recipe Validation Tests
// ============================================================================

pub fn all_recipes_exist_test() {
  let recipes = mvp_recipes.all_recipes()
  list.length(recipes)
  |> should.be_greater_than(0)
}

pub fn recipes_have_valid_macros_test() {
  let recipes = mvp_recipes.all_recipes()
  let all_valid =
    list.all(recipes, fn(recipe) {
      recipe.macros.protein >=. 0.0
      && recipe.macros.fat >=. 0.0
      && recipe.macros.carbs >=. 0.0
    })
  all_valid
  |> should.equal(True)
}

pub fn recipes_have_non_empty_names_test() {
  let recipes = mvp_recipes.all_recipes()
  let all_have_names = list.all(recipes, fn(recipe) { recipe.name != "" })
  all_have_names
  |> should.equal(True)
}

pub fn default_goals_are_positive_test() {
  let goals = ncp.get_default_goals()
  goals.daily_protein
  |> should.be_greater_than(0.0)
  goals.daily_fat
  |> should.be_greater_than(0.0)
  goals.daily_carbs
  |> should.be_greater_than(0.0)
  goals.daily_calories
  |> should.be_greater_than(0.0)
}

// ============================================================================
// NCP Algorithm Tests
// ============================================================================

pub fn deviation_calculation_protein_low_test() {
  let consumed =
    ncp.NutritionData(protein: 50.0, fat: 50.0, carbs: 100.0, calories: 1200.0)
  let goals = ncp.get_default_goals()
  let deviation = ncp.calculate_deviation(goals, consumed)

  // Protein consumed (50) is less than goal (let's say 150), so it should be negative
  deviation.protein_pct
  |> should.be_less_than(0.0)
}

pub fn deviation_calculation_protein_high_test() {
  let consumed =
    ncp.NutritionData(protein: 300.0, fat: 50.0, carbs: 100.0, calories: 1800.0)
  let goals = ncp.get_default_goals()
  let deviation = ncp.calculate_deviation(goals, consumed)

  // Protein consumed (300) is more than goal, so it should be positive
  deviation.protein_pct
  |> should.be_greater_than(0.0)
}

pub fn deviation_within_tolerance_test() {
  let consumed =
    ncp.NutritionData(protein: 150.0, fat: 65.0, carbs: 200.0, calories: 1850.0)
  let goals = ncp.get_default_goals()
  let deviation = ncp.calculate_deviation(goals, consumed)

  // With realistic consumption, should be within 10% tolerance
  let on_track = ncp.deviation_is_within_tolerance(deviation, 10.0)
  on_track
  |> should.equal(True)
}

pub fn select_top_recipes_returns_array_test() {
  let consumed =
    ncp.NutritionData(protein: 50.0, fat: 50.0, carbs: 100.0, calories: 1200.0)
  let goals = ncp.get_default_goals()
  let deviation = ncp.calculate_deviation(goals, consumed)
  let recipes = mvp_recipes.all_recipes()

  let suggestions = ncp.select_top_recipes(deviation, recipes, 3)

  // Should return at most 3 suggestions
  list.length(suggestions)
  |> should.be_less_than_or_equal(3)

  // All suggestions should have positive scores
  list.all(suggestions, fn(s) { s.score >. 0.0 })
  |> should.equal(True)
}

pub fn select_top_recipes_less_than_available_test() {
  let consumed =
    ncp.NutritionData(protein: 75.0, fat: 50.0, carbs: 150.0, calories: 1400.0)
  let goals = ncp.get_default_goals()
  let deviation = ncp.calculate_deviation(goals, consumed)
  let recipes = mvp_recipes.all_recipes()

  let suggestions = ncp.select_top_recipes(deviation, recipes, 1)

  // Should return at most 1 suggestion
  list.length(suggestions)
  |> should.be_less_than_or_equal(1)
}

// ============================================================================
// Edge Cases
// ============================================================================

pub fn deviation_on_zero_consumption_test() {
  let consumed =
    ncp.NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
  let goals = ncp.get_default_goals()
  let deviation = ncp.calculate_deviation(goals, consumed)

  // All deviations should be negative (under goal)
  deviation.protein_pct
  |> should.be_less_than(0.0)
  deviation.fat_pct
  |> should.be_less_than(0.0)
  deviation.carbs_pct
  |> should.be_less_than(0.0)
}

pub fn deviation_exceeds_tolerance_test() {
  let consumed =
    ncp.NutritionData(
      protein: 300.0,
      fat: 200.0,
      carbs: 500.0,
      calories: 4000.0,
    )
  let goals = ncp.get_default_goals()
  let deviation = ncp.calculate_deviation(goals, consumed)

  // With very high consumption, should exceed 10% tolerance
  let on_track = ncp.deviation_is_within_tolerance(deviation, 10.0)
  on_track
  |> should.equal(False)
}
