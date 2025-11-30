import gleeunit/should
import meal_planner/types.{
  Active, Gain, Lose, Maintain, Moderate, Sedentary, UserProfile,
  daily_calorie_target, daily_fat_target,
  daily_macro_targets, daily_protein_target,
}

pub fn daily_protein_target_active_gain_test() {
  // Active + gain = 1.0 multiplier
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 4,
    )
  daily_protein_target(u) |> should.equal(200.0)
}

pub fn daily_protein_target_sedentary_lose_test() {
  // Sedentary + lose = 0.8 multiplier
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Sedentary,
      goal: Lose,
      meals_per_day: 3,
    )
  daily_protein_target(u) |> should.equal(160.0)
}

pub fn daily_protein_target_moderate_test() {
  // Moderate = 0.9 multiplier
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
    )
  daily_protein_target(u) |> should.equal(180.0)
}

pub fn daily_fat_target_test() {
  // 0.3g per lb bodyweight
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
    )
  daily_fat_target(u) |> should.equal(60.0)
}

pub fn daily_calorie_target_moderate_maintain_test() {
  // Moderate = 15 cal/lb, maintain = no adjustment
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
    )
  daily_calorie_target(u) |> should.equal(3000.0)
}

pub fn daily_calorie_target_active_gain_test() {
  // Active = 18 cal/lb, gain = 15% surplus
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 4,
    )
  // 200 * 18 * 1.15 = 4140
  daily_calorie_target(u) |> should.equal(4140.0)
}

pub fn daily_calorie_target_sedentary_lose_test() {
  // Sedentary = 12 cal/lb, lose = 15% deficit
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Sedentary,
      goal: Lose,
      meals_per_day: 3,
    )
  // 200 * 12 * 0.85 = 2040
  daily_calorie_target(u) |> should.equal(2040.0)
}

pub fn daily_macro_targets_test() {
  let u =
    UserProfile(
      bodyweight: 200.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
    )
  let targets = daily_macro_targets(u)
  // Protein: 200 * 0.9 = 180
  targets.protein |> should.equal(180.0)
  // Fat: 200 * 0.3 = 60
  targets.fat |> should.equal(60.0)
  // Carbs: (3000 - 180*4 - 60*9) / 4 = (3000 - 720 - 540) / 4 = 1740/4 = 435
  targets.carbs |> should.equal(435.0)
}
