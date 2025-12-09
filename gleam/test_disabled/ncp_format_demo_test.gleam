import gleam/io
import gleeunit/should
import meal_planner/ncp.{
  AdjustmentPlan, DeviationResult, NutritionData, NutritionGoals,
  RecipeSuggestion, ReconciliationResult, format_reconcile_output,
  format_status_output,
}

/// Demo test showing NCP status output formatting
pub fn demo_status_output_within_tolerance_test() {
  let result =
    ReconciliationResult(
      date: "2025-12-01",
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

  io.println("\n=== DEMO: Status Output (Within Tolerance) ===")
  io.println(format_status_output(result))

  // Test assertion
  result.within_tolerance |> should.be_true()
}

/// Demo test showing NCP reconcile output with suggestions
pub fn demo_reconcile_output_with_suggestions_test() {
  let result =
    ReconciliationResult(
      date: "2025-12-01",
      average_consumed: NutritionData(
        protein: 120.0,
        fat: 45.0,
        carbs: 180.0,
        calories: 1800.0,
      ),
      goals: NutritionGoals(
        daily_protein: 180.0,
        daily_fat: 60.0,
        daily_carbs: 250.0,
        daily_calories: 2500.0,
      ),
      deviation: DeviationResult(
        protein_pct: -33.3,
        fat_pct: -25.0,
        carbs_pct: -28.0,
        calories_pct: -28.0,
      ),
      plan: AdjustmentPlan(
        deviation: DeviationResult(
          protein_pct: -33.3,
          fat_pct: -25.0,
          carbs_pct: -28.0,
          calories_pct: -28.0,
        ),
        suggestions: [
          RecipeSuggestion(
            recipe_name: "Grilled Chicken with Rice",
            reason: "High protein to address deficit",
            score: 0.85,
          ),
          RecipeSuggestion(
            recipe_name: "Salmon with Sweet Potato",
            reason: "Balanced macros",
            score: 0.72,
          ),
          RecipeSuggestion(
            recipe_name: "Beef Stir Fry",
            reason: "High protein to address deficit",
            score: 0.68,
          ),
        ],
      ),
      within_tolerance: False,
    )

  io.println("\n=== DEMO: Reconcile Output (With Suggestions) ===")
  io.println(format_reconcile_output(result))

  // Test assertion
  result.within_tolerance |> should.be_false()
}
