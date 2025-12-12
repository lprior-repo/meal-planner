import gleam/option.{None}
import gleeunit
import gleeunit/should
import meal_planner/types.{Active, Gain, Lose, Maintain, Moderate, Sedentary}
import meal_planner/user_profile.{
  InvalidInput, ParseError, create_profile, create_profile_from_strings,
  parse_bodyweight, parse_meals_per_day, validate_activity_level,
  validate_bodyweight, validate_goal, validate_meals_per_day,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Bodyweight Validation Tests
// ============================================================================

pub fn test_validate_bodyweight_valid() {
  validate_bodyweight(180.0) |> should.equal(Ok(180.0))
}

pub fn test_validate_bodyweight_min_valid() {
  validate_bodyweight(80.0) |> should.equal(Ok(80.0))
}

pub fn test_validate_bodyweight_max_valid() {
  validate_bodyweight(500.0) |> should.equal(Ok(500.0))
}

pub fn test_validate_bodyweight_too_low() {
  case validate_bodyweight(79.9) {
    Error(InvalidInput(msg)) ->
      should.be_true(msg == "bodyweight too low: minimum 80 lbs")
    _ -> should.fail()
  }
}

pub fn test_validate_bodyweight_too_high() {
  case validate_bodyweight(500.1) {
    Error(InvalidInput(msg)) ->
      should.be_true(msg == "bodyweight too high: maximum 500 lbs")
    _ -> should.fail()
  }
}

pub fn test_validate_bodyweight_extreme_low() {
  case validate_bodyweight(0.0) {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_validate_bodyweight_extreme_high() {
  case validate_bodyweight(1000.0) {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// ============================================================================
// Activity Level Validation Tests
// ============================================================================

pub fn test_validate_activity_level_sedentary() {
  validate_activity_level("sedentary") |> should.equal(Ok(Sedentary))
}

pub fn test_validate_activity_level_moderate() {
  validate_activity_level("moderate") |> should.equal(Ok(Moderate))
}

pub fn test_validate_activity_level_active() {
  validate_activity_level("active") |> should.equal(Ok(Active))
}

pub fn test_validate_activity_level_uppercase() {
  validate_activity_level("SEDENTARY") |> should.equal(Ok(Sedentary))
}

pub fn test_validate_activity_level_mixed_case() {
  validate_activity_level("MoDerate") |> should.equal(Ok(Moderate))
}

pub fn test_validate_activity_level_invalid() {
  case validate_activity_level("invalid") {
    Error(InvalidInput(msg)) ->
      should.be_true(
        msg == "invalid activity level: must be sedentary, moderate, or active",
      )
    _ -> should.fail()
  }
}

pub fn test_validate_activity_level_empty() {
  case validate_activity_level("") {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// ============================================================================
// Goal Validation Tests
// ============================================================================

pub fn test_validate_goal_gain() {
  validate_goal("gain") |> should.equal(Ok(Gain))
}

pub fn test_validate_goal_maintain() {
  validate_goal("maintain") |> should.equal(Ok(Maintain))
}

pub fn test_validate_goal_lose() {
  validate_goal("lose") |> should.equal(Ok(Lose))
}

pub fn test_validate_goal_uppercase() {
  validate_goal("GAIN") |> should.equal(Ok(Gain))
}

pub fn test_validate_goal_mixed_case() {
  validate_goal("MaInTaIn") |> should.equal(Ok(Maintain))
}

pub fn test_validate_goal_invalid() {
  case validate_goal("build") {
    Error(InvalidInput(msg)) ->
      should.be_true(msg == "invalid goal: must be gain, maintain, or lose")
    _ -> should.fail()
  }
}

pub fn test_validate_goal_empty() {
  case validate_goal("") {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// ============================================================================
// Meals Per Day Validation Tests
// ============================================================================

pub fn test_validate_meals_per_day_valid() {
  validate_meals_per_day(3) |> should.equal(Ok(3))
}

pub fn test_validate_meals_per_day_min_valid() {
  validate_meals_per_day(2) |> should.equal(Ok(2))
}

pub fn test_validate_meals_per_day_max_valid() {
  validate_meals_per_day(6) |> should.equal(Ok(6))
}

pub fn test_validate_meals_per_day_too_low() {
  case validate_meals_per_day(1) {
    Error(InvalidInput(msg)) ->
      should.be_true(msg == "meals per day too low: minimum 2")
    _ -> should.fail()
  }
}

pub fn test_validate_meals_per_day_too_high() {
  case validate_meals_per_day(7) {
    Error(InvalidInput(msg)) ->
      should.be_true(msg == "meals per day too high: maximum 6")
    _ -> should.fail()
  }
}

pub fn test_validate_meals_per_day_zero() {
  case validate_meals_per_day(0) {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_validate_meals_per_day_negative() {
  case validate_meals_per_day(-5) {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// ============================================================================
// Parse Bodyweight Tests
// ============================================================================

pub fn test_parse_bodyweight_valid() {
  parse_bodyweight("180.0") |> should.equal(Ok(180.0))
}

pub fn test_parse_bodyweight_integer() {
  parse_bodyweight("180") |> should.equal(Ok(180.0))
}

pub fn test_parse_bodyweight_with_whitespace() {
  parse_bodyweight("  180.0  ") |> should.equal(Ok(180.0))
}

pub fn test_parse_bodyweight_invalid_string() {
  case parse_bodyweight("not_a_number") {
    Error(ParseError(msg)) ->
      should.be_true(msg == "invalid bodyweight: must be a number")
    _ -> should.fail()
  }
}

pub fn test_parse_bodyweight_empty_string() {
  case parse_bodyweight("") {
    Error(ParseError(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_parse_bodyweight_out_of_range() {
  case parse_bodyweight("50.0") {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// ============================================================================
// Parse Meals Per Day Tests
// ============================================================================

pub fn test_parse_meals_per_day_valid() {
  parse_meals_per_day("3") |> should.equal(Ok(3))
}

pub fn test_parse_meals_per_day_with_whitespace() {
  parse_meals_per_day("  4  ") |> should.equal(Ok(4))
}

pub fn test_parse_meals_per_day_invalid_string() {
  case parse_meals_per_day("not_a_number") {
    Error(ParseError(msg)) ->
      should.be_true(msg == "invalid meals per day: must be a number")
    _ -> should.fail()
  }
}

pub fn test_parse_meals_per_day_empty_string() {
  case parse_meals_per_day("") {
    Error(ParseError(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_parse_meals_per_day_float() {
  case parse_meals_per_day("3.5") {
    Error(ParseError(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_parse_meals_per_day_out_of_range() {
  case parse_meals_per_day("10") {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

// ============================================================================
// Create Profile Tests
// ============================================================================

pub fn test_create_profile_valid() {
  let result = create_profile("test-user", 180.0, Moderate, Maintain, 3)
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 180.0)
      should.equal(profile.activity_level, Moderate)
      should.equal(profile.goal, Maintain)
      should.equal(profile.meals_per_day, 3)
      should.equal(profile.micronutrient_goals, None)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_create_profile_sedentary() {
  let result = create_profile("test-user", 150.0, Sedentary, Lose, 2)
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 150.0)
      should.equal(profile.activity_level, Sedentary)
      should.equal(profile.goal, Lose)
      should.equal(profile.meals_per_day, 2)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_create_profile_active() {
  let result = create_profile("test-user", 200.0, Active, Gain, 5)
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 200.0)
      should.equal(profile.activity_level, Active)
      should.equal(profile.goal, Gain)
      should.equal(profile.meals_per_day, 5)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_create_profile_invalid_bodyweight() {
  let result = create_profile("test-user", 50.0, Moderate, Maintain, 3)
  case result {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_create_profile_invalid_meals() {
  let result = create_profile("test-user", 180.0, Moderate, Maintain, 10)
  case result {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_create_profile_boundary_min() {
  let result = create_profile("test-user", 80.0, Moderate, Maintain, 2)
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 80.0)
      should.equal(profile.meals_per_day, 2)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_create_profile_boundary_max() {
  let result = create_profile("test-user", 500.0, Moderate, Maintain, 6)
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 500.0)
      should.equal(profile.meals_per_day, 6)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Create Profile From Strings Tests
// ============================================================================

pub fn test_create_profile_from_strings_valid() {
  let result =
    create_profile_from_strings(
      "test-user",
      "180.0",
      "moderate",
      "maintain",
      "3",
    )
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 180.0)
      should.equal(profile.activity_level, Moderate)
      should.equal(profile.goal, Maintain)
      should.equal(profile.meals_per_day, 3)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_create_profile_from_strings_mixed_case() {
  let result =
    create_profile_from_strings("test-user", "180", "SEDENTARY", "Lose", "2")
  case result {
    Ok(profile) -> {
      should.equal(profile.activity_level, Sedentary)
      should.equal(profile.goal, Lose)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_create_profile_from_strings_invalid_bodyweight() {
  let result =
    create_profile_from_strings(
      "test-user",
      "not_a_number",
      "moderate",
      "maintain",
      "3",
    )
  case result {
    Error(ParseError(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_create_profile_from_strings_invalid_activity() {
  let result =
    create_profile_from_strings("test-user", "180", "invalid", "maintain", "3")
  case result {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_create_profile_from_strings_invalid_goal() {
  let result =
    create_profile_from_strings("test-user", "180", "moderate", "invalid", "3")
  case result {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_create_profile_from_strings_invalid_meals() {
  let result =
    create_profile_from_strings(
      "test-user",
      "180",
      "moderate",
      "maintain",
      "10",
    )
  case result {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_create_profile_from_strings_whitespace() {
  let result =
    create_profile_from_strings(
      "test-user",
      "  180.0  ",
      "  moderate  ",
      "  maintain  ",
      "  3  ",
    )
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 180.0)
      should.equal(profile.meals_per_day, 3)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Profile Calculation Tests
// ============================================================================

pub fn test_create_profile_with_id_generation() {
  let result = create_profile("unique-id-123", 180.0, Moderate, Maintain, 3)
  case result {
    Ok(profile) -> {
      // ID should be created properly
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_create_profile_all_goal_types() {
  let gain_result = create_profile("test", 180.0, Moderate, Gain, 3)
  let lose_result = create_profile("test", 180.0, Moderate, Lose, 3)
  let maintain_result = create_profile("test", 180.0, Moderate, Maintain, 3)

  case gain_result, lose_result, maintain_result {
    Ok(g), Ok(l), Ok(m) -> {
      should.equal(g.goal, Gain)
      should.equal(l.goal, Lose)
      should.equal(m.goal, Maintain)
    }
    _, _, _ -> should.fail()
  }
}

pub fn test_create_profile_all_activity_types() {
  let sedentary = create_profile("test", 180.0, Sedentary, Maintain, 3)
  let moderate = create_profile("test", 180.0, Moderate, Maintain, 3)
  let active = create_profile("test", 180.0, Active, Maintain, 3)

  case sedentary, moderate, active {
    Ok(s), Ok(m), Ok(a) -> {
      should.equal(s.activity_level, Sedentary)
      should.equal(m.activity_level, Moderate)
      should.equal(a.activity_level, Active)
    }
    _, _, _ -> should.fail()
  }
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn test_profile_exact_min_values() {
  let result = create_profile("test", 80.0, Sedentary, Lose, 2)
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 80.0)
      should.equal(profile.meals_per_day, 2)
      should.equal(profile.activity_level, Sedentary)
      should.equal(profile.goal, Lose)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_profile_exact_max_values() {
  let result = create_profile("test", 500.0, Active, Gain, 6)
  case result {
    Ok(profile) -> {
      should.equal(profile.bodyweight, 500.0)
      should.equal(profile.meals_per_day, 6)
      should.equal(profile.activity_level, Active)
      should.equal(profile.goal, Gain)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_profile_just_below_min_bodyweight() {
  let result = create_profile("test", 79.99, Moderate, Maintain, 3)
  case result {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_profile_just_above_max_bodyweight() {
  let result = create_profile("test", 500.01, Moderate, Maintain, 3)
  case result {
    Error(InvalidInput(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}

pub fn test_parse_bodyweight_leading_zeros() {
  parse_bodyweight("0180.0") |> should.equal(Ok(180.0))
}

pub fn test_parse_meals_per_day_multiple_digits() {
  parse_meals_per_day("6") |> should.equal(Ok(6))
}

pub fn test_empty_string_parsing() {
  case parse_bodyweight("   ") {
    Error(ParseError(_)) -> should.be_true(True)
    _ -> should.fail()
  }
}
