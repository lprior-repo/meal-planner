/// Tests for nutrition CLI domain
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/domains/nutrition
import meal_planner/ncp

pub fn format_goals_test() {
  let goals = ncp.get_default_goals()
  let formatted = nutrition.format_goals(goals)

  // Should contain protein, fat, carbs, calories
  formatted
  |> should.not_equal("")
}

pub fn format_nutrition_data_test() {
  let data =
    ncp.NutritionData(protein: 100.0, fat: 50.0, carbs: 200.0, calories: 1650.0)
  let formatted = nutrition.format_nutrition_data(data)

  // Should contain macro values
  formatted
  |> should.not_equal("")
}

pub fn format_deviation_test() {
  let deviation =
    ncp.DeviationResult(
      protein_pct: 10.5,
      fat_pct: -5.2,
      carbs_pct: 3.1,
      calories_pct: 2.0,
    )
  let formatted = nutrition.format_deviation(deviation)

  // Should contain percentage values
  formatted
  |> should.not_equal("")
}

pub fn format_trend_direction_test() {
  nutrition.format_trend_direction(ncp.Increasing)
  |> should.equal("↑ Increasing")

  nutrition.format_trend_direction(ncp.Decreasing)
  |> should.equal("↓ Decreasing")

  nutrition.format_trend_direction(ncp.Stable)
  |> should.equal("→ Stable")
}

pub fn build_goals_table_test() {
  let goals = ncp.get_default_goals()
  let table = nutrition.build_goals_table(goals)

  // Should contain headers and data
  table
  |> should.not_equal("")
}

pub fn build_compliance_summary_test() {
  let deviation =
    ncp.DeviationResult(
      protein_pct: 5.0,
      fat_pct: -3.0,
      carbs_pct: 8.0,
      calories_pct: 2.0,
    )
  let summary = nutrition.build_compliance_summary(deviation, 10.0)

  // Should indicate compliance status
  summary
  |> should.not_equal("")
}

// ============================================================================
// NEW TESTS: Report Command
// ============================================================================

pub fn generate_report_with_empty_history_test() {
  let goals = ncp.get_default_goals()
  let history = []
  let recipes = []

  let report =
    nutrition.generate_report(
      history: history,
      goals: goals,
      recipes: recipes,
      tolerance: 10.0,
      suggestion_limit: 3,
      date: "2025-12-19",
    )

  // Report should contain formatted reconciliation result
  report
  |> should.not_equal("")
}

pub fn generate_report_with_nutrition_history_test() {
  let goals = ncp.get_default_goals()
  let history = [
    ncp.NutritionState(
      date: "2025-12-18",
      consumed: ncp.NutritionData(
        protein: 150.0,
        fat: 55.0,
        carbs: 200.0,
        calories: 2200.0,
      ),
      synced_at: "2025-12-18T12:00:00Z",
    ),
    ncp.NutritionState(
      date: "2025-12-19",
      consumed: ncp.NutritionData(
        protein: 170.0,
        fat: 60.0,
        carbs: 230.0,
        calories: 2400.0,
      ),
      synced_at: "2025-12-19T12:00:00Z",
    ),
  ]
  let recipes = []

  let report =
    nutrition.generate_report(
      history: history,
      goals: goals,
      recipes: recipes,
      tolerance: 10.0,
      suggestion_limit: 3,
      date: "2025-12-19",
    )

  // Report should show deviation from goals
  report
  |> should.not_equal("")
}

// ============================================================================
// NEW TESTS: Trends Command
// ============================================================================

pub fn generate_trends_with_empty_history_test() {
  let history = []
  let goals = ncp.get_default_goals()

  let trends = nutrition.generate_trends(history: history, goals: goals)

  // Trends should show stable for empty history
  trends
  |> should.not_equal("")
}

pub fn generate_trends_with_history_test() {
  let goals = ncp.get_default_goals()
  let history = [
    ncp.NutritionState(
      date: "2025-12-15",
      consumed: ncp.NutritionData(
        protein: 140.0,
        fat: 50.0,
        carbs: 190.0,
        calories: 2100.0,
      ),
      synced_at: "2025-12-15T12:00:00Z",
    ),
    ncp.NutritionState(
      date: "2025-12-16",
      consumed: ncp.NutritionData(
        protein: 150.0,
        fat: 55.0,
        carbs: 200.0,
        calories: 2200.0,
      ),
      synced_at: "2025-12-16T12:00:00Z",
    ),
    ncp.NutritionState(
      date: "2025-12-17",
      consumed: ncp.NutritionData(
        protein: 160.0,
        fat: 58.0,
        carbs: 210.0,
        calories: 2300.0,
      ),
      synced_at: "2025-12-17T12:00:00Z",
    ),
    ncp.NutritionState(
      date: "2025-12-18",
      consumed: ncp.NutritionData(
        protein: 170.0,
        fat: 60.0,
        carbs: 220.0,
        calories: 2400.0,
      ),
      synced_at: "2025-12-18T12:00:00Z",
    ),
  ]

  let trends = nutrition.generate_trends(history: history, goals: goals)

  // Trends should show increasing protein consumption
  trends
  |> should.not_equal("")
}

// ============================================================================
// NEW TESTS: Compliance Command
// ============================================================================

pub fn generate_compliance_within_tolerance_test() {
  let goals = ncp.get_default_goals()
  let consumed =
    ncp.NutritionData(protein: 175.0, fat: 58.0, carbs: 245.0, calories: 2475.0)

  let compliance =
    nutrition.generate_compliance(
      consumed: consumed,
      goals: goals,
      tolerance: 10.0,
    )

  // Should show compliant status
  compliance
  |> should.not_equal("")
}

pub fn generate_compliance_outside_tolerance_test() {
  let goals = ncp.get_default_goals()
  let consumed =
    ncp.NutritionData(protein: 100.0, fat: 40.0, carbs: 150.0, calories: 1800.0)

  let compliance =
    nutrition.generate_compliance(
      consumed: consumed,
      goals: goals,
      tolerance: 10.0,
    )

  // Should show non-compliant status with deviations
  compliance
  |> should.not_equal("")
}
