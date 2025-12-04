//// Tests for profile handlers

import gleeunit/should
import meal_planner/types.{Macros, Preferences, Profile}

pub fn profile_creation_test() {
  let profile = UserProfile(
    user_id: "test-user",
    macros: Macros(protein: 150.0, fat: 65.0, carbs: 200.0),
    preferences: Preferences(
      dark_mode: True,
      measurement_system: "metric",
    ),
  )

  profile.user_id
  |> should.equal("test-user")

  profile.macros.protein
  |> should.equal(150.0)

  profile.preferences.dark_mode
  |> should.equal(True)
}

pub fn macros_calories_calculation_test() {
  let macros = Macros(protein: 100.0, fat: 50.0, carbs: 150.0)
  
  // Protein: 100 * 4 = 400
  // Fat: 50 * 9 = 450
  // Carbs: 150 * 4 = 600
  // Total: 1450
  let calories = types.macros_calories(macros)
  
  calories
  |> should.equal(1450.0)
}
