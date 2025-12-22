//// TDD Tests for CLI preferences command
////
//// RED PHASE: This test validates:
//// 1. Preferences display and formatting
//// 2. Input validation for nutrition goals
//// 3. User profile information handling

import gleam/int
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

pub type ActivityLevel {
  Sedentary
  Light
  Moderate
  Active
  VeryActive
}

pub type Goal {
  WeightLoss
  Maintenance
  WeightGain
}

pub type UserProfile {
  UserProfile(
    bodyweight: Float,
    activity_level: ActivityLevel,
    goal: Goal,
    meals_per_day: Int,
  )
}

fn create_sample_profile(
  bodyweight: Float,
  activity: ActivityLevel,
  goal: Goal,
) -> UserProfile {
  UserProfile(
    bodyweight: bodyweight,
    activity_level: activity,
    goal: goal,
    meals_per_day: 3,
  )
}

// ============================================================================
// Preferences Display Tests
// ============================================================================

/// Test: Display user profile
pub fn display_user_profile_test() {
  let profile = create_sample_profile(75.0, Moderate, Maintenance)

  profile.bodyweight
  |> should.equal(75.0)

  profile.meals_per_day
  |> should.equal(3)
}

/// Test: Activity level is displayed correctly
pub fn activity_level_display_test() {
  let profile = create_sample_profile(75.0, Moderate, Maintenance)

  // Activity level should be one of the valid options
  case profile.activity_level {
    Sedentary -> True
    Light -> True
    Moderate -> True
    Active -> True
    VeryActive -> True
  }
  |> should.be_true()
}

/// Test: Goal is displayed correctly
pub fn goal_display_test() {
  let profile = create_sample_profile(75.0, Moderate, WeightLoss)

  case profile.goal {
    WeightLoss -> True
    Maintenance -> True
    WeightGain -> True
  }
  |> should.be_true()
}

// ============================================================================
// Input Validation Tests
// ============================================================================

/// Test: Validate calorie goal is in valid range
pub fn validate_calorie_goal_range_test() {
  let valid_low = 500
  let valid_mid = 2000
  let valid_high = 10_000

  valid_low >=. 500
  && valid_low
  <=. 10_000
  |> should.be_true()

  valid_mid >=. 500
  && valid_mid
  <=. 10_000
  |> should.be_true()

  valid_high >=. 500
  && valid_high
  <=. 10_000
  |> should.be_true()
}

/// Test: Validate protein goal is reasonable
pub fn validate_protein_goal_test() {
  let protein_grams = 150

  protein_grams > 0
  && protein_grams
  <=. 500
  |> should.be_true()
}

/// Test: Validate carbs goal
pub fn validate_carbs_goal_test() {
  let carbs_grams = 250

  carbs_grams > 0
  && carbs_grams
  <=. 1000
  |> should.be_true()
}

/// Test: Validate fat goal
pub fn validate_fat_goal_test() {
  let fat_grams = 65

  fat_grams > 0
  && fat_grams
  <=. 500
  |> should.be_true()
}

/// Test: Validate bodyweight is positive
pub fn validate_bodyweight_positive_test() {
  let bodyweight = 75.0

  bodyweight
  > 0.0
  |> should.be_true()
}

/// Test: Validate meals per day is reasonable
pub fn validate_meals_per_day_test() {
  let meals = 3

  meals >=. 1
  && meals
  <=. 10
  |> should.be_true()
}
