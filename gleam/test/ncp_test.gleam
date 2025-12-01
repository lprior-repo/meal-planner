import gleam/list
import gleam/string
import gleeunit/should
import meal_planner/ncp.{
  AdjustmentPlan, DeviationResult, NutritionData, NutritionGoals, NutritionState,
  RecipeSuggestion, ReconciliationResult, ScoredRecipe,
  average_nutrition_history, calculate_deviation, deviation_is_within_tolerance,
  deviation_max, format_reconcile_output, format_status_output,
  generate_adjustments, generate_reason, get_default_goals,
  nutrition_goals_validate, run_reconciliation, score_recipe_for_deviation,
  select_top_recipes,
}
import meal_planner/types.{Macros}

pub fn nutrition_goals_validate_valid_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )
  nutrition_goals_validate(goals) |> should.be_ok()
}

pub fn nutrition_goals_validate_zero_protein_test() {
  let goals =
    NutritionGoals(
      daily_protein: 0.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )
  nutrition_goals_validate(goals) |> should.be_error()
}

pub fn nutrition_goals_validate_negative_fat_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: -10.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )
  nutrition_goals_validate(goals) |> should.be_error()
}

pub fn calculate_deviation_over_test() {
  let goals =
    NutritionGoals(
      daily_protein: 100.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )
  let actual =
    NutritionData(protein: 120.0, fat: 60.0, carbs: 220.0, calories: 2200.0)
  let dev = calculate_deviation(goals, actual)
  // (120-100)/100*100 = 20%
  dev.protein_pct |> should.equal(20.0)
  // (60-50)/50*100 = 20%
  dev.fat_pct |> should.equal(20.0)
  // (220-200)/200*100 = 10%
  dev.carbs_pct |> should.equal(10.0)
  // (2200-2000)/2000*100 = 10%
  dev.calories_pct |> should.equal(10.0)
}

pub fn calculate_deviation_under_test() {
  let goals =
    NutritionGoals(
      daily_protein: 100.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )
  let actual =
    NutritionData(protein: 80.0, fat: 40.0, carbs: 180.0, calories: 1800.0)
  let dev = calculate_deviation(goals, actual)
  // (80-100)/100*100 = -20%
  dev.protein_pct |> should.equal(-20.0)
  dev.fat_pct |> should.equal(-20.0)
  dev.carbs_pct |> should.equal(-10.0)
  dev.calories_pct |> should.equal(-10.0)
}

pub fn deviation_is_within_tolerance_true_test() {
  let dev =
    DeviationResult(
      protein_pct: 5.0,
      fat_pct: -3.0,
      carbs_pct: 8.0,
      calories_pct: 4.0,
    )
  deviation_is_within_tolerance(dev, 10.0) |> should.be_true()
}

pub fn deviation_is_within_tolerance_false_test() {
  let dev =
    DeviationResult(
      protein_pct: 15.0,
      fat_pct: -3.0,
      carbs_pct: 8.0,
      calories_pct: 4.0,
    )
  deviation_is_within_tolerance(dev, 10.0) |> should.be_false()
}

pub fn deviation_max_test() {
  let dev =
    DeviationResult(
      protein_pct: -25.0,
      fat_pct: 10.0,
      carbs_pct: 15.0,
      calories_pct: 5.0,
    )
  // abs(-25) = 25 is max
  deviation_max(dev) |> should.equal(25.0)
}

// ============================================================================
// Default Goals Tests
// ============================================================================

pub fn get_default_goals_test() {
  let goals = get_default_goals()
  goals.daily_protein |> should.equal(180.0)
  goals.daily_fat |> should.equal(60.0)
  goals.daily_carbs |> should.equal(250.0)
  goals.daily_calories |> should.equal(2500.0)
}

// ============================================================================
// Average Nutrition History Tests
// ============================================================================

pub fn average_nutrition_history_empty_test() {
  let avg = average_nutrition_history([])
  avg.protein |> should.equal(0.0)
  avg.fat |> should.equal(0.0)
  avg.carbs |> should.equal(0.0)
  avg.calories |> should.equal(0.0)
}

pub fn average_nutrition_history_single_day_test() {
  let history = [
    NutritionState(
      date: "2025-01-15",
      consumed: NutritionData(
        protein: 150.0,
        fat: 60.0,
        carbs: 200.0,
        calories: 2000.0,
      ),
      synced_at: "",
    ),
  ]
  let avg = average_nutrition_history(history)
  avg.protein |> should.equal(150.0)
  avg.fat |> should.equal(60.0)
  avg.carbs |> should.equal(200.0)
  avg.calories |> should.equal(2000.0)
}

pub fn average_nutrition_history_multiple_days_test() {
  let history = [
    NutritionState(
      date: "2025-01-13",
      consumed: NutritionData(
        protein: 100.0,
        fat: 40.0,
        carbs: 150.0,
        calories: 1500.0,
      ),
      synced_at: "",
    ),
    NutritionState(
      date: "2025-01-14",
      consumed: NutritionData(
        protein: 200.0,
        fat: 80.0,
        carbs: 250.0,
        calories: 2500.0,
      ),
      synced_at: "",
    ),
  ]
  let avg = average_nutrition_history(history)
  // (100 + 200) / 2 = 150
  avg.protein |> should.equal(150.0)
  // (40 + 80) / 2 = 60
  avg.fat |> should.equal(60.0)
  // (150 + 250) / 2 = 200
  avg.carbs |> should.equal(200.0)
  // (1500 + 2500) / 2 = 2000
  avg.calories |> should.equal(2000.0)
}

// ============================================================================
// Recipe Scoring Tests
// ============================================================================

pub fn score_recipe_low_total_deviation_test() {
  // When total deviation is < 5%, score should be 0.1
  let deviation =
    DeviationResult(
      protein_pct: 1.0,
      fat_pct: 1.0,
      carbs_pct: 1.0,
      calories_pct: 1.0,
    )
  let macros = Macros(protein: 30.0, fat: 10.0, carbs: 40.0)
  let score = score_recipe_for_deviation(deviation, macros)
  score |> should.equal(0.1)
}

pub fn score_recipe_all_over_test() {
  // When over on all macros, adding food is bad - score 0.1
  let deviation =
    DeviationResult(
      protein_pct: 10.0,
      fat_pct: 10.0,
      carbs_pct: 10.0,
      calories_pct: 10.0,
    )
  let macros = Macros(protein: 30.0, fat: 10.0, carbs: 40.0)
  let score = score_recipe_for_deviation(deviation, macros)
  score |> should.equal(0.1)
}

pub fn score_recipe_protein_deficit_test() {
  // When under on protein, high protein recipes should score well
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: 5.0,
      carbs_pct: 5.0,
      calories_pct: 0.0,
    )
  let macros = Macros(protein: 40.0, fat: 5.0, carbs: 10.0)
  let score = score_recipe_for_deviation(deviation, macros)
  // Should get protein bonus (0.5 * min(40/40, 1.0) = 0.5)
  { score >=. 0.4 } |> should.be_true()
}

pub fn score_recipe_fat_deficit_test() {
  // When under on fat, recipes with fat should help
  let deviation =
    DeviationResult(
      protein_pct: 5.0,
      fat_pct: -20.0,
      carbs_pct: 5.0,
      calories_pct: 0.0,
    )
  let macros = Macros(protein: 10.0, fat: 25.0, carbs: 10.0)
  let score = score_recipe_for_deviation(deviation, macros)
  // Should get fat bonus
  { score >=. 0.2 } |> should.be_true()
}

pub fn score_recipe_carb_deficit_test() {
  // When under on carbs, recipes with carbs should help
  let deviation =
    DeviationResult(
      protein_pct: 5.0,
      fat_pct: 5.0,
      carbs_pct: -20.0,
      calories_pct: 0.0,
    )
  let macros = Macros(protein: 10.0, fat: 5.0, carbs: 50.0)
  let score = score_recipe_for_deviation(deviation, macros)
  // Should get carb bonus
  { score >=. 0.2 } |> should.be_true()
}

pub fn score_recipe_fat_penalty_test() {
  // When over on fat, high fat recipes should be penalized
  let deviation =
    DeviationResult(
      protein_pct: -10.0,
      fat_pct: 15.0,
      carbs_pct: 0.0,
      calories_pct: 5.0,
    )
  let macros = Macros(protein: 10.0, fat: 25.0, carbs: 10.0)
  let score = score_recipe_for_deviation(deviation, macros)
  // Should have fat penalty applied
  { score <. 0.5 } |> should.be_true()
}

// ============================================================================
// Select Top Recipes Tests
// ============================================================================

pub fn select_top_recipes_empty_test() {
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )
  let suggestions = select_top_recipes(deviation, [], 3)
  suggestions |> list.length |> should.equal(0)
}

pub fn select_top_recipes_limit_test() {
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: -10.0,
      carbs_pct: -10.0,
      calories_pct: -10.0,
    )
  let recipes = [
    ScoredRecipe(
      name: "Recipe 1",
      macros: Macros(protein: 30.0, fat: 10.0, carbs: 20.0),
    ),
    ScoredRecipe(
      name: "Recipe 2",
      macros: Macros(protein: 25.0, fat: 8.0, carbs: 15.0),
    ),
    ScoredRecipe(
      name: "Recipe 3",
      macros: Macros(protein: 35.0, fat: 12.0, carbs: 25.0),
    ),
    ScoredRecipe(
      name: "Recipe 4",
      macros: Macros(protein: 20.0, fat: 5.0, carbs: 10.0),
    ),
  ]
  let suggestions = select_top_recipes(deviation, recipes, 2)
  suggestions |> list.length |> should.equal(2)
}

pub fn select_top_recipes_sorted_by_score_test() {
  let deviation =
    DeviationResult(
      protein_pct: -30.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )
  // Recipe with highest protein should score best for protein deficit
  let recipes = [
    ScoredRecipe(
      name: "Low Protein",
      macros: Macros(protein: 10.0, fat: 10.0, carbs: 20.0),
    ),
    ScoredRecipe(
      name: "High Protein",
      macros: Macros(protein: 40.0, fat: 5.0, carbs: 10.0),
    ),
    ScoredRecipe(
      name: "Medium Protein",
      macros: Macros(protein: 25.0, fat: 8.0, carbs: 15.0),
    ),
  ]
  let suggestions = select_top_recipes(deviation, recipes, 3)
  // First suggestion should be the highest protein recipe
  case suggestions {
    [first, ..] -> first.recipe_name |> should.equal("High Protein")
    _ -> should.be_true(False)
  }
}

// ============================================================================
// Generate Reason Tests
// ============================================================================

pub fn generate_reason_protein_deficit_test() {
  let deviation =
    DeviationResult(
      protein_pct: -15.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )
  let macros = Macros(protein: 30.0, fat: 5.0, carbs: 10.0)
  let reason = generate_reason(deviation, macros)
  reason |> should.equal("High protein to address deficit")
}

pub fn generate_reason_carb_deficit_test() {
  let deviation =
    DeviationResult(
      protein_pct: 0.0,
      fat_pct: 0.0,
      carbs_pct: -15.0,
      calories_pct: 0.0,
    )
  let macros = Macros(protein: 10.0, fat: 5.0, carbs: 40.0)
  let reason = generate_reason(deviation, macros)
  reason |> should.equal("Good carbs to address deficit")
}

pub fn generate_reason_fat_deficit_test() {
  let deviation =
    DeviationResult(
      protein_pct: 0.0,
      fat_pct: -15.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )
  let macros = Macros(protein: 10.0, fat: 20.0, carbs: 10.0)
  let reason = generate_reason(deviation, macros)
  reason |> should.equal("Healthy fats to address deficit")
}

pub fn generate_reason_balanced_test() {
  let deviation =
    DeviationResult(
      protein_pct: 0.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )
  let macros = Macros(protein: 10.0, fat: 5.0, carbs: 10.0)
  let reason = generate_reason(deviation, macros)
  reason |> should.equal("Balanced macros")
}

// ============================================================================
// Generate Adjustments Tests
// ============================================================================

pub fn generate_adjustments_empty_recipes_test() {
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )
  let plan = generate_adjustments(deviation, [], 3)
  plan.suggestions |> list.length |> should.equal(0)
  plan.deviation |> should.equal(deviation)
}

pub fn generate_adjustments_with_recipes_test() {
  let deviation =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: -10.0,
      carbs_pct: -10.0,
      calories_pct: -15.0,
    )
  let recipes = [
    ScoredRecipe(
      name: "Chicken Breast",
      macros: Macros(protein: 35.0, fat: 5.0, carbs: 0.0),
    ),
    ScoredRecipe(
      name: "Rice Bowl",
      macros: Macros(protein: 10.0, fat: 2.0, carbs: 45.0),
    ),
  ]
  let plan = generate_adjustments(deviation, recipes, 2)
  plan.suggestions |> list.length |> should.equal(2)
}

// ============================================================================
// Run Reconciliation Tests
// ============================================================================

pub fn run_reconciliation_within_tolerance_test() {
  let history = [
    NutritionState(
      date: "2025-01-15",
      consumed: NutritionData(
        protein: 175.0,
        fat: 58.0,
        carbs: 245.0,
        calories: 2450.0,
      ),
      synced_at: "",
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
    run_reconciliation(history, goals, recipes, 10.0, 3, "2025-01-15")
  result.within_tolerance |> should.be_true()
  result.date |> should.equal("2025-01-15")
}

pub fn run_reconciliation_outside_tolerance_test() {
  let history = [
    NutritionState(
      date: "2025-01-15",
      consumed: NutritionData(
        protein: 100.0,
        fat: 30.0,
        carbs: 150.0,
        calories: 1500.0,
      ),
      synced_at: "",
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
      name: "High Protein Meal",
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 20.0),
    ),
  ]
  let result =
    run_reconciliation(history, goals, recipes, 10.0, 3, "2025-01-15")
  result.within_tolerance |> should.be_false()
  result.plan.suggestions |> list.length |> should.equal(1)
}

// ============================================================================
// Format Output Tests
// ============================================================================

pub fn format_status_output_contains_header_test() {
  let result =
    ReconciliationResult(
      date: "2025-01-15",
      average_consumed: NutritionData(
        protein: 150.0,
        fat: 55.0,
        carbs: 200.0,
        calories: 2000.0,
      ),
      goals: NutritionGoals(
        daily_protein: 180.0,
        daily_fat: 60.0,
        daily_carbs: 250.0,
        daily_calories: 2500.0,
      ),
      deviation: DeviationResult(
        protein_pct: -16.7,
        fat_pct: -8.3,
        carbs_pct: -20.0,
        calories_pct: -20.0,
      ),
      plan: AdjustmentPlan(
        deviation: DeviationResult(
          protein_pct: -16.7,
          fat_pct: -8.3,
          carbs_pct: -20.0,
          calories_pct: -20.0,
        ),
        suggestions: [],
      ),
      within_tolerance: False,
    )
  let output = format_status_output(result)
  string.contains(output, "NCP NUTRITION STATUS REPORT") |> should.be_true()
  string.contains(output, "2025-01-15") |> should.be_true()
  string.contains(output, "Protein") |> should.be_true()
  string.contains(output, "Fat") |> should.be_true()
  string.contains(output, "Carbs") |> should.be_true()
}

pub fn format_status_output_within_tolerance_test() {
  let result =
    ReconciliationResult(
      date: "2025-01-15",
      average_consumed: NutritionData(
        protein: 175.0,
        fat: 58.0,
        carbs: 245.0,
        calories: 2450.0,
      ),
      goals: NutritionGoals(
        daily_protein: 180.0,
        daily_fat: 60.0,
        daily_carbs: 250.0,
        daily_calories: 2500.0,
      ),
      deviation: DeviationResult(
        protein_pct: -2.8,
        fat_pct: -3.3,
        carbs_pct: -2.0,
        calories_pct: -2.0,
      ),
      plan: AdjustmentPlan(
        deviation: DeviationResult(
          protein_pct: -2.8,
          fat_pct: -3.3,
          carbs_pct: -2.0,
          calories_pct: -2.0,
        ),
        suggestions: [],
      ),
      within_tolerance: True,
    )
  let output = format_status_output(result)
  string.contains(output, "On track") |> should.be_true()
}

pub fn format_reconcile_output_with_suggestions_test() {
  let result =
    ReconciliationResult(
      date: "2025-01-15",
      average_consumed: NutritionData(
        protein: 100.0,
        fat: 40.0,
        carbs: 150.0,
        calories: 1500.0,
      ),
      goals: NutritionGoals(
        daily_protein: 180.0,
        daily_fat: 60.0,
        daily_carbs: 250.0,
        daily_calories: 2500.0,
      ),
      deviation: DeviationResult(
        protein_pct: -44.4,
        fat_pct: -33.3,
        carbs_pct: -40.0,
        calories_pct: -40.0,
      ),
      plan: AdjustmentPlan(
        deviation: DeviationResult(
          protein_pct: -44.4,
          fat_pct: -33.3,
          carbs_pct: -40.0,
          calories_pct: -40.0,
        ),
        suggestions: [
          RecipeSuggestion(
            recipe_name: "Chicken Breast",
            reason: "High protein to address deficit",
            score: 0.8,
          ),
        ],
      ),
      within_tolerance: False,
    )
  let output = format_reconcile_output(result)
  string.contains(output, "ADJUSTMENT PLAN") |> should.be_true()
  string.contains(output, "Chicken Breast") |> should.be_true()
}
