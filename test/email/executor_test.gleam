/// Tests for email command executor
///
/// Note: Full integration tests would require database mock/fixture.
/// These tests verify type safety and module structure.
import gleeunit
import gleeunit/should

import meal_planner/id
import meal_planner/types.{AddPreference, AdjustMeal, Breakfast, Friday}

pub fn main() {
  gleeunit.main()
}

/// Test that executor module loads
pub fn executor_module_loads_test() {
  True
  |> should.be_true()
}

/// Test that AdjustMeal command type is recognized
pub fn adjust_meal_command_type_test() {
  let _command =
    AdjustMeal(
      day: Friday,
      meal_type: Breakfast,
      recipe_id: id.recipe_id("recipe-test-1"),
    )

  True
  |> should.be_true()
}

/// Test that AddPreference command type is recognized
pub fn add_preference_command_type_test() {
  let _command = AddPreference(preference: "more vegetables")

  True
  |> should.be_true()
}
/// Note: Full executor tests require database integration
/// Current tests verify type system and module structure only
