/// Tests for web module dashboard integration
import gleeunit
import gleeunit/should
import shared/types

pub fn main() {
  gleeunit.main()
}

/// Test user profile based macro targets
pub fn user_profile_macro_targets_test() {
  let profile =
    types.UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: types.Moderate,
      goal: types.Maintain,
      meals_per_day: 3,
    )

  let targets = types.daily_macro_targets(profile)

  // Verify targets are calculated correctly for moderate activity, maintain goal
  // Protein: 180 lbs * 0.9 = 162g
  targets.protein |> should.equal(162.0)

  // Fat: 180 lbs * 0.3 = 54g
  targets.fat |> should.equal(54.0)

  // Carbs: (180 * 15 - (162*4 + 54*9)) / 4 = 391.5g
  let expected_carbs = 391.5
  targets.carbs |> should.equal(expected_carbs)
}
