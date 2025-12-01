import gleeunit/should
import meal_planner/types.{
  Active, Gain, Lose, Maintain, Moderate, Sedentary, UserProfile,
  daily_calorie_target, daily_fat_target, daily_macro_targets,
  daily_protein_target,
}
import meal_planner/user_profile.{
  InvalidInput, ParseError, create_profile, create_profile_from_strings,
  format_user_profile, parse_bodyweight, parse_meals_per_day,
  profile_error_to_string, validate_activity_level, validate_bodyweight,
  validate_goal, validate_meals_per_day,
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

// Validation tests

pub fn validate_bodyweight_valid_test() {
  validate_bodyweight(180.0) |> should.be_ok() |> should.equal(180.0)
}

pub fn validate_bodyweight_minimum_test() {
  validate_bodyweight(80.0) |> should.be_ok() |> should.equal(80.0)
}

pub fn validate_bodyweight_maximum_test() {
  validate_bodyweight(500.0) |> should.be_ok() |> should.equal(500.0)
}

pub fn validate_bodyweight_too_low_test() {
  validate_bodyweight(79.0)
  |> should.be_error()
  |> should.equal(InvalidInput("bodyweight too low: minimum 80 lbs"))
}

pub fn validate_bodyweight_too_high_test() {
  validate_bodyweight(501.0)
  |> should.be_error()
  |> should.equal(InvalidInput("bodyweight too high: maximum 500 lbs"))
}

pub fn validate_activity_level_sedentary_test() {
  validate_activity_level("sedentary")
  |> should.be_ok()
  |> should.equal(Sedentary)
}

pub fn validate_activity_level_moderate_test() {
  validate_activity_level("moderate")
  |> should.be_ok()
  |> should.equal(Moderate)
}

pub fn validate_activity_level_active_test() {
  validate_activity_level("active") |> should.be_ok() |> should.equal(Active)
}

pub fn validate_activity_level_case_insensitive_test() {
  validate_activity_level("SEDENTARY")
  |> should.be_ok()
  |> should.equal(Sedentary)
  validate_activity_level("MoDeRaTe")
  |> should.be_ok()
  |> should.equal(Moderate)
  validate_activity_level("ACTIVE") |> should.be_ok() |> should.equal(Active)
}

pub fn validate_activity_level_invalid_test() {
  validate_activity_level("invalid")
  |> should.be_error()
  |> should.equal(InvalidInput(
    "invalid activity level: must be sedentary, moderate, or active",
  ))
}

pub fn validate_goal_gain_test() {
  validate_goal("gain") |> should.be_ok() |> should.equal(Gain)
}

pub fn validate_goal_maintain_test() {
  validate_goal("maintain") |> should.be_ok() |> should.equal(Maintain)
}

pub fn validate_goal_lose_test() {
  validate_goal("lose") |> should.be_ok() |> should.equal(Lose)
}

pub fn validate_goal_case_insensitive_test() {
  validate_goal("GAIN") |> should.be_ok() |> should.equal(Gain)
  validate_goal("MaInTaIn") |> should.be_ok() |> should.equal(Maintain)
  validate_goal("LOSE") |> should.be_ok() |> should.equal(Lose)
}

pub fn validate_goal_invalid_test() {
  validate_goal("invalid")
  |> should.be_error()
  |> should.equal(InvalidInput("invalid goal: must be gain, maintain, or lose"))
}

pub fn validate_meals_per_day_valid_test() {
  validate_meals_per_day(3) |> should.be_ok() |> should.equal(3)
}

pub fn validate_meals_per_day_minimum_test() {
  validate_meals_per_day(2) |> should.be_ok() |> should.equal(2)
}

pub fn validate_meals_per_day_maximum_test() {
  validate_meals_per_day(6) |> should.be_ok() |> should.equal(6)
}

pub fn validate_meals_per_day_too_low_test() {
  validate_meals_per_day(1)
  |> should.be_error()
  |> should.equal(InvalidInput("meals per day too low: minimum 2"))
}

pub fn validate_meals_per_day_too_high_test() {
  validate_meals_per_day(7)
  |> should.be_error()
  |> should.equal(InvalidInput("meals per day too high: maximum 6"))
}

pub fn profile_error_to_string_invalid_input_test() {
  profile_error_to_string(InvalidInput("test error"))
  |> should.equal("Invalid input: test error")
}

pub fn profile_error_to_string_parse_error_test() {
  profile_error_to_string(ParseError("parse failed"))
  |> should.equal("Parse error: parse failed")
}

pub fn format_user_profile_test() {
  let profile =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Maintain,
      meals_per_day: 3,
    )
  let formatted = format_user_profile(profile)
  formatted
  |> should.equal(
    "==== YOUR VERTICAL DIET PROFILE ====\n"
    <> "Bodyweight: 180.0 lbs\n"
    <> "Activity Level: Moderate\n"
    <> "Goal: Maintain\n"
    <> "Meals per Day: 3\n"
    <> "====================================",
  )
}

// Parse functions tests

pub fn parse_bodyweight_valid_test() {
  parse_bodyweight("180.0") |> should.be_ok() |> should.equal(180.0)
}

pub fn parse_bodyweight_with_whitespace_test() {
  parse_bodyweight("  200.5  ") |> should.be_ok() |> should.equal(200.5)
}

pub fn parse_bodyweight_invalid_number_test() {
  parse_bodyweight("not a number")
  |> should.be_error()
  |> should.equal(ParseError("invalid bodyweight: must be a number"))
}

pub fn parse_bodyweight_out_of_range_test() {
  parse_bodyweight("50.0")
  |> should.be_error()
  |> should.equal(InvalidInput("bodyweight too low: minimum 80 lbs"))
}

pub fn parse_meals_per_day_valid_test() {
  parse_meals_per_day("4") |> should.be_ok() |> should.equal(4)
}

pub fn parse_meals_per_day_with_whitespace_test() {
  parse_meals_per_day("  3  ") |> should.be_ok() |> should.equal(3)
}

pub fn parse_meals_per_day_invalid_number_test() {
  parse_meals_per_day("not a number")
  |> should.be_error()
  |> should.equal(ParseError("invalid meals per day: must be a number"))
}

pub fn parse_meals_per_day_out_of_range_test() {
  parse_meals_per_day("10")
  |> should.be_error()
  |> should.equal(InvalidInput("meals per day too high: maximum 6"))
}

// Profile creation tests

pub fn create_profile_valid_test() {
  let result = create_profile(180.0, Moderate, Maintain, 3)
  result |> should.be_ok()
  let profile = case result {
    Ok(p) -> p
    Error(_) -> panic as "Expected Ok"
  }
  profile.bodyweight |> should.equal(180.0)
  profile.activity_level |> should.equal(Moderate)
  profile.goal |> should.equal(Maintain)
  profile.meals_per_day |> should.equal(3)
}

pub fn create_profile_invalid_bodyweight_test() {
  create_profile(50.0, Moderate, Maintain, 3)
  |> should.be_error()
  |> should.equal(InvalidInput("bodyweight too low: minimum 80 lbs"))
}

pub fn create_profile_invalid_meals_test() {
  create_profile(180.0, Moderate, Maintain, 10)
  |> should.be_error()
  |> should.equal(InvalidInput("meals per day too high: maximum 6"))
}

pub fn create_profile_from_strings_valid_test() {
  let result = create_profile_from_strings("180.0", "moderate", "maintain", "3")
  result |> should.be_ok()
  let profile = case result {
    Ok(p) -> p
    Error(_) -> panic as "Expected Ok"
  }
  profile.bodyweight |> should.equal(180.0)
  profile.activity_level |> should.equal(Moderate)
  profile.goal |> should.equal(Maintain)
  profile.meals_per_day |> should.equal(3)
}

pub fn create_profile_from_strings_all_variations_test() {
  // Test with different valid inputs
  create_profile_from_strings("200.5", "active", "gain", "4")
  |> should.be_ok()

  create_profile_from_strings("150.0", "sedentary", "lose", "2")
  |> should.be_ok()

  create_profile_from_strings("250.0", "MODERATE", "MAINTAIN", "5")
  |> should.be_ok()
}

pub fn create_profile_from_strings_invalid_bodyweight_test() {
  create_profile_from_strings("not a number", "moderate", "maintain", "3")
  |> should.be_error()
  |> should.equal(ParseError("invalid bodyweight: must be a number"))
}

pub fn create_profile_from_strings_invalid_activity_test() {
  create_profile_from_strings("180.0", "invalid", "maintain", "3")
  |> should.be_error()
  |> should.equal(InvalidInput(
    "invalid activity level: must be sedentary, moderate, or active",
  ))
}

pub fn create_profile_from_strings_invalid_goal_test() {
  create_profile_from_strings("180.0", "moderate", "invalid", "3")
  |> should.be_error()
  |> should.equal(InvalidInput("invalid goal: must be gain, maintain, or lose"))
}

pub fn create_profile_from_strings_invalid_meals_test() {
  create_profile_from_strings("180.0", "moderate", "maintain", "not a number")
  |> should.be_error()
  |> should.equal(ParseError("invalid meals per day: must be a number"))
}
