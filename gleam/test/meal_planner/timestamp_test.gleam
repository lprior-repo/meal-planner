/// Simple test to verify timestamp generation is working correctly
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/auto_planner
import meal_planner/auto_planner/types as auto_types
import meal_planner/id
import meal_planner/types

pub fn main() {
  gleeunit.main()
}

pub fn timestamp_format_test() {
  // Test that generate_auto_plan creates valid ISO8601 timestamps with UTC
  let recipes = [
    types.Recipe(
      id: id.recipe_id("test-1"),
      name: "Test Recipe",
      category: "protein",
      fodmap_level: types.Low,
      vertical_compliant: True,
      macros: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      servings: 1,
      instructions: [],
      ingredients: [],
    ),
  ]

  let config =
    auto_types.AutoPlanConfig(
      user_id: "test-user",
      recipe_count: 1,
      macro_targets: types.Macros(protein: 30.0, fat: 10.0, carbs: 40.0),
      diet_principles: [],
      variety_factor: 1.0,
    )

  let result = auto_planner.generate_auto_plan(recipes, config)

  result
  |> should.be_ok

  case result {
    Ok(plan) -> {
      // Verify timestamp format: YYYY-MM-DDTHH:MM:SSZ
      // Should be 20 characters long
      let timestamp_length = string.length(plan.generated_at)
      timestamp_length
      |> should.equal(20)

      // Check that it ends with Z (UTC indicator)
      let has_utc_marker = string.ends_with(plan.generated_at, "Z")
      has_utc_marker
      |> should.be_true

      // Verify the format by checking specific character positions
      // Format: 2025-12-12T11:41:10Z
      //         0123456789012345678901
      let char_at_4 = string.slice(plan.generated_at, 4, 1)
      let char_at_7 = string.slice(plan.generated_at, 7, 1)
      let char_at_10 = string.slice(plan.generated_at, 10, 1)
      let char_at_13 = string.slice(plan.generated_at, 13, 1)
      let char_at_16 = string.slice(plan.generated_at, 16, 1)

      char_at_4
      |> should.equal("-")

      char_at_7
      |> should.equal("-")

      char_at_10
      |> should.equal("T")

      char_at_13
      |> should.equal(":")

      char_at_16
      |> should.equal(":")
    }
    Error(_) -> panic as "Expected Ok result"
  }
}
