/// User profile management for meal planning
///
/// Handles collecting user data interactively and calculating nutritional targets

import gleam/float
import gleam/io
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import meal_planner/types.{type ActivityLevel, type Goal, type UserProfile, UserProfile, Active, Gain, Lose, Maintain, Moderate, Sedentary}

/// Error type for user profile operations
pub type ProfileError {
  InvalidInput(String)
  ParseError(String)
}

/// Validate bodyweight is within reasonable range (80-500 lbs)
pub fn validate_bodyweight(weight: Float) -> Result(Float, ProfileError) {
  case weight {
    w if w <. 80.0 -> Error(InvalidInput("bodyweight too low: minimum 80 lbs"))
    w if w >. 500.0 -> Error(InvalidInput("bodyweight too high: maximum 500 lbs"))
    _ -> Ok(weight)
  }
}

/// Validate activity level is one of allowed values
pub fn validate_activity_level(level: String) -> Result(ActivityLevel, ProfileError) {
  case string.lowercase(level) {
    "sedentary" -> Ok(Sedentary)
    "moderate" -> Ok(Moderate)
    "active" -> Ok(Active)
    _ -> Error(InvalidInput("invalid activity level: must be sedentary, moderate, or active"))
  }
}

/// Validate goal is one of allowed values
pub fn validate_goal(goal: String) -> Result(Goal, ProfileError) {
  case string.lowercase(goal) {
    "gain" -> Ok(Gain)
    "maintain" -> Ok(Maintain)
    "lose" -> Ok(Lose)
    _ -> Error(InvalidInput("invalid goal: must be gain, maintain, or lose"))
  }
}

/// Validate meals per day is within range (2-6)
pub fn validate_meals_per_day(meals: Int) -> Result(Int, ProfileError) {
  case meals {
    m if m < 2 -> Error(InvalidInput("meals per day too low: minimum 2"))
    m if m > 6 -> Error(InvalidInput("meals per day too high: maximum 6"))
    _ -> Ok(meals)
  }
}

/// Parse string to float with error handling
fn parse_float(s: String) -> Result(Float, ProfileError) {
  case float.parse(s) {
    Ok(f) -> Ok(f)
    Error(_) -> Error(ParseError("invalid number: " <> s))
  }
}

/// Parse string to int with error handling
fn parse_int(s: String) -> Result(Int, ProfileError) {
  case int.parse(s) {
    Ok(i) -> Ok(i)
    Error(_) -> Error(ParseError("invalid number: " <> s))
  }
}

/// Collect user profile interactively from stdin
/// Note: This is a simplified version - full implementation would need proper stdin reading
pub fn collect_interactive_profile() -> Result(UserProfile, ProfileError) {
  io.println("=== User Profile Setup ===")
  
  // For now, return a default profile
  // In a full implementation, this would collect data interactively
  Ok(UserProfile(
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
  ))
}

/// Load user profile from storage or collect interactively
pub fn load_or_collect_profile() -> Result(UserProfile, String) {
  // For now, just collect interactively
  case collect_interactive_profile() {
    Ok(profile) -> Ok(profile)
    Error(err) -> {
      let error_msg = case err {
        InvalidInput(msg) -> "Invalid input: " <> msg
        ParseError(msg) -> "Parse error: " <> msg
      }
      Error(error_msg)
    }
  }
}

/// Display user profile with calculated targets
pub fn print_profile(profile: UserProfile) -> Nil {
  io.println(format_user_profile(profile))
}

/// Format user profile for display
pub fn format_user_profile(profile: UserProfile) -> String {
  let activity_str = case profile.activity_level {
    Sedentary -> "Sedentary"
    Moderate -> "Moderate"
    Active -> "Active"
  }
  
  let goal_str = case profile.goal {
    Gain -> "Gain"
    Maintain -> "Maintain"
    Lose -> "Lose"
  }
  
  "==== YOUR VERTICAL DIET PROFILE ====\n"
  <> "Bodyweight: " <> float_to_string(profile.bodyweight) <> " lbs\n"
  <> "Activity Level: " <> activity_str <> "\n"
  <> "Goal: " <> goal_str <> "\n"
  <> "Meals per Day: " <> int.to_string(profile.meals_per_day) <> "\n"
  <> "===================================="
}

/// Convert float to string
fn float_to_string(f: Float) -> String {
  // Simple conversion - in real implementation would handle rounding
  float.to_string(f)
}

/// Import int.to_string for formatting
@external(erlang, "erlang", "integer_to_list")
fn int_to_string(i: Int) -> String
/// Convert ProfileError to string
pub fn profile_error_to_string(error: ProfileError) -> String {
  case error {
    InvalidInput(msg) -> "Invalid input: " <> msg
    ParseError(msg) -> "Parse error: " <> msg
  }
}
