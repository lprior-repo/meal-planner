import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/types.{
  type ActivityLevel, type Goal, type UserProfile, Active, Gain, Lose, Maintain,
  Moderate, Sedentary, UserProfile, daily_calorie_target, daily_carb_target,
  daily_fat_target, daily_macro_targets, daily_protein_target,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// UserProfile Creation Tests
// ============================================================================

pub fn create_user_profile_test() {
  let profile =
    UserProfile(
      id: "user123",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  profile.id |> should.equal("user123")
  profile.bodyweight |> should.equal(180.0)
  profile.activity_level |> should.equal(Moderate)
  profile.goal |> should.equal(Maintain)
  profile.meals_per_day |> should.equal(3)
}

pub fn create_sedentary_profile_test() {
  let profile =
    UserProfile(
      id: "user456",
      bodyweight: 150.0,
      activity_level: Sedentary,
      goal: Lose,
      meals_per_day: 4,
      micronutrient_goals: None,
    )

  profile.activity_level |> should.equal(Sedentary)
  profile.goal |> should.equal(Lose)
}

pub fn create_active_profile_test() {
  let profile =
    UserProfile(
      id: "user789",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 5,
      micronutrient_goals: None,
    )

  profile.activity_level |> should.equal(Active)
  profile.goal |> should.equal(Gain)
}

// ============================================================================
// Protein Target Tests
// ============================================================================

pub fn protein_target_active_test() {
  let profile =
    UserProfile(
      id: "user1",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Active users get 1.0g per lb
  daily_protein_target(profile) |> should.equal(180.0)
}

pub fn protein_target_gain_test() {
  let profile =
    UserProfile(
      id: "user2",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Gain goal gets 1.0g per lb
  daily_protein_target(profile) |> should.equal(180.0)
}

pub fn protein_target_sedentary_test() {
  let profile =
    UserProfile(
      id: "user3",
      bodyweight: 180.0,
      activity_level: Sedentary,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Sedentary gets 0.8g per lb
  daily_protein_target(profile) |> should.equal(144.0)
}

pub fn protein_target_lose_test() {
  let profile =
    UserProfile(
      id: "user4",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Lose,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Lose goal gets 0.8g per lb
  daily_protein_target(profile) |> should.equal(144.0)
}

pub fn protein_target_moderate_maintain_test() {
  let profile =
    UserProfile(
      id: "user5",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Moderate + Maintain gets 0.9g per lb
  daily_protein_target(profile) |> should.equal(162.0)
}

// ============================================================================
// Fat Target Tests
// ============================================================================

pub fn fat_target_test() {
  let profile =
    UserProfile(
      id: "user6",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Fat is always 0.3g per lb
  daily_fat_target(profile) |> should.equal(54.0)
}

pub fn fat_target_different_weight_test() {
  let profile =
    UserProfile(
      id: "user7",
      bodyweight: 150.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 4,
      micronutrient_goals: None,
    )

  // Fat is always 0.3g per lb
  daily_fat_target(profile) |> should.equal(45.0)
}

// ============================================================================
// Calorie Target Tests
// ============================================================================

pub fn calorie_target_sedentary_maintain_test() {
  let profile =
    UserProfile(
      id: "user8",
      bodyweight: 180.0,
      activity_level: Sedentary,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Sedentary: 180 * 12 = 2160
  daily_calorie_target(profile) |> should.equal(2160.0)
}

pub fn calorie_target_moderate_maintain_test() {
  let profile =
    UserProfile(
      id: "user9",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Moderate: 180 * 15 = 2700
  daily_calorie_target(profile) |> should.equal(2700.0)
}

pub fn calorie_target_active_maintain_test() {
  let profile =
    UserProfile(
      id: "user10",
      bodyweight: 180.0,
      activity_level: Active,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Active: 180 * 18 = 3240
  daily_calorie_target(profile) |> should.equal(3240.0)
}

pub fn calorie_target_gain_test() {
  let profile =
    UserProfile(
      id: "user11",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Moderate + Gain: (180 * 15) * 1.15 = 3105
  daily_calorie_target(profile) |> should.equal(3105.0)
}

pub fn calorie_target_lose_test() {
  let profile =
    UserProfile(
      id: "user12",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Lose,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Moderate + Lose: (180 * 15) * 0.85 = 2295
  daily_calorie_target(profile) |> should.equal(2295.0)
}

// ============================================================================
// Carb Target Tests
// ============================================================================

pub fn carb_target_test() {
  let profile =
    UserProfile(
      id: "user13",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  // Total calories: 2700
  // Protein: 162g * 4cal/g = 648 cal
  // Fat: 54g * 9cal/g = 486 cal
  // Remaining: 2700 - 648 - 486 = 1566 cal
  // Carbs: 1566 / 4 = 391.5g
  daily_carb_target(profile) |> should.equal(391.5)
}

pub fn carb_target_active_gain_test() {
  let profile =
    UserProfile(
      id: "user14",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 5,
      micronutrient_goals: None,
    )

  // Total calories: (200 * 18) * 1.15 = 4140
  // Protein: 200g * 4cal/g = 800 cal
  // Fat: 60g * 9cal/g = 540 cal
  // Remaining: 4140 - 800 - 540 = 2800 cal
  // Carbs: 2800 / 4 = 700g
  daily_carb_target(profile) |> should.equal(700.0)
}

// ============================================================================
// Daily Macro Targets Tests
// ============================================================================

pub fn daily_macro_targets_test() {
  let profile =
    UserProfile(
      id: "user15",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  let targets = daily_macro_targets(profile)

  targets.protein |> should.equal(162.0)
  targets.fat |> should.equal(54.0)
  targets.carbs |> should.equal(391.5)
}

pub fn daily_macro_targets_sedentary_lose_test() {
  let profile =
    UserProfile(
      id: "user16",
      bodyweight: 150.0,
      activity_level: Sedentary,
      goal: Lose,
      meals_per_day: 4,
      micronutrient_goals: None,
    )

  let targets = daily_macro_targets(profile)

  // Protein: 0.8 * 150 = 120g
  targets.protein |> should.equal(120.0)

  // Fat: 0.3 * 150 = 45g
  targets.fat |> should.equal(45.0)

  // Calories: (150 * 12) * 0.85 = 1530
  // Protein cals: 120 * 4 = 480
  // Fat cals: 45 * 9 = 405
  // Remaining: 1530 - 480 - 405 = 645
  // Carbs: 645 / 4 = 161.25g
  targets.carbs |> should.equal(161.25)
}

pub fn daily_macro_targets_active_gain_test() {
  let profile =
    UserProfile(
      id: "user17",
      bodyweight: 200.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 5,
      micronutrient_goals: None,
    )

  let targets = daily_macro_targets(profile)

  // Protein: 1.0 * 200 = 200g
  targets.protein |> should.equal(200.0)

  // Fat: 0.3 * 200 = 60g
  targets.fat |> should.equal(60.0)

  // Calories: (200 * 18) * 1.15 = 4140
  // Protein cals: 200 * 4 = 800
  // Fat cals: 60 * 9 = 540
  // Remaining: 4140 - 800 - 540 = 2800
  // Carbs: 2800 / 4 = 700g
  targets.carbs |> should.equal(700.0)
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn low_bodyweight_test() {
  let profile =
    UserProfile(
      id: "user18",
      bodyweight: 100.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
      micronutrient_goals: None,
    )

  let targets = daily_macro_targets(profile)

  targets.protein |> should.equal(90.0)
  targets.fat |> should.equal(30.0)
}

pub fn high_bodyweight_test() {
  let profile =
    UserProfile(
      id: "user19",
      bodyweight: 250.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 6,
      micronutrient_goals: None,
    )

  let targets = daily_macro_targets(profile)

  targets.protein |> should.equal(250.0)
  targets.fat |> should.equal(75.0)
}

pub fn multiple_meals_per_day_test() {
  let profile =
    UserProfile(
      id: "user20",
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 6,
      micronutrient_goals: None,
    )

  // meals_per_day doesn't affect macro calculations, just for user planning
  let targets = daily_macro_targets(profile)

  targets.protein |> should.equal(162.0)
  profile.meals_per_day |> should.equal(6)
}
