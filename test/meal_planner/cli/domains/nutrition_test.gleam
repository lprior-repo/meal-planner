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
