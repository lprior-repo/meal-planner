/// NCP Reconciliation Module Tests
/// Tests for reconciliation logic, adjustment generation, and recipe scoring
import gleam/float
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/ncp/reconciliation
import meal_planner/ncp/types.{
  DeviationResult, NutritionData, NutritionGoals, NutritionState, ScoredRecipe,
}
import meal_planner/types/macros.{Macros}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Default Goals Tests
// ============================================================================

pub fn get_default_goals_test() {
  let goals = reconciliation.get_default_goals()

  goals.daily_protein |> should.equal(180.0)
  goals.daily_fat |> should.equal(60.0)
  goals.daily_carbs |> should.equal(250.0)
  goals.daily_calories |> should.equal(2500.0)
}

// ============================================================================
// Recipe Scoring Tests
// ============================================================================

pub fn score_recipe_for_deviation_exact_match_test() {
  // When deviation is very small, score should be low (0.1)
  let deviation =
    DeviationResult(
      protein_pct: 0.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )

  let macros = Macros(protein: 30.0, fat: 10.0, carbs: 40.0)

  let score = reconciliation.score_recipe_for_deviation(deviation, macros)

  score |> should.equal(0.1)
}

pub fn score_recipe_for_deviation_all_over_test() {
  // When over on all macros, adding food is bad (score 0.1)
  let deviation =
    DeviationResult(
      protein_pct: 10.0,
      fat_pct: 10.0,
      carbs_pct: 10.0,
      calories_pct: 10.0,
    )

  let macros = Macros(protein: 30.0, fat: 10.0, carbs: 40.0)

  let score = reconciliation.score_recipe_for_deviation(deviation, macros)

  score |> should.equal(0.1)
}

pub fn score_recipe_for_deviation_protein_deficit_test() {
  // When protein is in deficit, high protein recipe should score well
  let deviation =
    DeviationResult(
      protein_pct: -30.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  // 40g protein = max protein score (0.5)
  let macros = Macros(protein: 40.0, fat: 5.0, carbs: 10.0)

  let score = reconciliation.score_recipe_for_deviation(deviation, macros)

  // Should get close to 0.5 for protein + small base score
  score |> float.loosely_equals(0.5, 0.2) |> should.be_true
}

pub fn score_recipe_for_deviation_balanced_deficit_test() {
  // When all macros in deficit, recipe providing all should score high
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: -15.0,
      carbs_pct: -25.0,
      calories_pct: -20.0,
    )

  let macros = Macros(protein: 40.0, fat: 25.0, carbs: 50.0)

  let score = reconciliation.score_recipe_for_deviation(deviation, macros)

  // Should get protein (0.5) + fat (0.25) + carbs (0.25) + base = ~1.0
  score |> float.loosely_equals(1.0, 0.1) |> should.be_true
}

// ============================================================================
// Recipe Selection Tests
// ============================================================================

pub fn select_top_recipes_empty_list_test() {
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let recipes = []

  let suggestions = reconciliation.select_top_recipes(deviation, recipes, 3)

  suggestions |> should.equal([])
}

pub fn select_top_recipes_sorts_by_score_test() {
  let deviation =
    DeviationResult(
      protein_pct: -30.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let recipes = [
    ScoredRecipe(
      name: "Low Protein Snack",
      macros: Macros(protein: 5.0, fat: 10.0, carbs: 20.0),
    ),
    ScoredRecipe(
      name: "High Protein Meal",
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 30.0),
    ),
    ScoredRecipe(
      name: "Medium Protein",
      macros: Macros(protein: 20.0, fat: 5.0, carbs: 25.0),
    ),
  ]

  let suggestions = reconciliation.select_top_recipes(deviation, recipes, 3)

  // First suggestion should be the high protein meal
  case suggestions {
    [first, ..] -> first.recipe_name |> should.equal("High Protein Meal")
    _ -> should.fail()
  }
}

pub fn select_top_recipes_limits_results_test() {
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let recipes = [
    ScoredRecipe(
      name: "Recipe 1",
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 20.0),
    ),
    ScoredRecipe(
      name: "Recipe 2",
      macros: Macros(protein: 35.0, fat: 10.0, carbs: 20.0),
    ),
    ScoredRecipe(
      name: "Recipe 3",
      macros: Macros(protein: 25.0, fat: 10.0, carbs: 20.0),
    ),
    ScoredRecipe(
      name: "Recipe 4",
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 20.0),
    ),
  ]

  let suggestions = reconciliation.select_top_recipes(deviation, recipes, 2)

  // Should only get 2 suggestions
  list.length(suggestions) |> should.equal(2)
}

// ============================================================================
// Reason Generation Tests
// ============================================================================

pub fn generate_reason_high_protein_deficit_test() {
  let deviation =
    DeviationResult(
      protein_pct: -15.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let macros = Macros(protein: 25.0, fat: 10.0, carbs: 20.0)

  let reason = reconciliation.generate_reason(deviation, macros)

  reason |> should.equal("High protein to address deficit")
}

pub fn generate_reason_high_carbs_deficit_test() {
  let deviation =
    DeviationResult(
      protein_pct: 0.0,
      fat_pct: 0.0,
      carbs_pct: -15.0,
      calories_pct: -10.0,
    )

  let macros = Macros(protein: 10.0, fat: 5.0, carbs: 35.0)

  let reason = reconciliation.generate_reason(deviation, macros)

  reason |> should.equal("Good carbs to address deficit")
}

pub fn generate_reason_high_fat_deficit_test() {
  let deviation =
    DeviationResult(
      protein_pct: 0.0,
      fat_pct: -15.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let macros = Macros(protein: 10.0, fat: 20.0, carbs: 15.0)

  let reason = reconciliation.generate_reason(deviation, macros)

  reason |> should.equal("Healthy fats to address deficit")
}

pub fn generate_reason_balanced_test() {
  let deviation =
    DeviationResult(
      protein_pct: -5.0,
      fat_pct: -5.0,
      carbs_pct: -5.0,
      calories_pct: -5.0,
    )

  let macros = Macros(protein: 15.0, fat: 10.0, carbs: 20.0)

  let reason = reconciliation.generate_reason(deviation, macros)

  reason |> should.equal("Balanced macros")
}

// ============================================================================
// Adjustment Generation Tests
// ============================================================================

pub fn generate_adjustments_creates_plan_test() {
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let recipes = [
    ScoredRecipe(
      name: "High Protein",
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 20.0),
    ),
  ]

  let plan = reconciliation.generate_adjustments(deviation, recipes, 1)

  plan.deviation |> should.equal(deviation)
  list.length(plan.suggestions) |> should.equal(1)
}

// ============================================================================
// Full Reconciliation Tests
// ============================================================================

pub fn run_reconciliation_complete_flow_test() {
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 90.0,
        fat: 30.0,
        carbs: 125.0,
        calories: 1250.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
  ]

  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let recipes = [
    ScoredRecipe(
      name: "Protein Shake",
      macros: Macros(protein: 40.0, fat: 5.0, carbs: 10.0),
    ),
  ]

  let result =
    reconciliation.run_reconciliation(
      history,
      goals,
      recipes,
      10.0,
      3,
      "2025-01-01",
    )

  result.date |> should.equal("2025-01-01")
  result.goals |> should.equal(goals)
  result.within_tolerance |> should.be_false

  // Average consumed should match history (single entry)
  result.average_consumed.protein |> should.equal(90.0)
  result.average_consumed.fat |> should.equal(30.0)
  result.average_consumed.carbs |> should.equal(125.0)

  // Should have suggestions since not within tolerance
  list.length(result.plan.suggestions) |> should.equal(1)
}

pub fn run_reconciliation_within_tolerance_test() {
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 180.0,
        fat: 60.0,
        carbs: 250.0,
        calories: 2500.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
  ]

  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let recipes = []

  let result =
    reconciliation.run_reconciliation(
      history,
      goals,
      recipes,
      10.0,
      3,
      "2025-01-01",
    )

  result.within_tolerance |> should.be_true
}
