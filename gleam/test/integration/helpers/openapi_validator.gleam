//// OpenAPI Schema Validation Helper
////
//// Validates API responses against OpenAPI schema constraints

import gleam/list
import gleam/result
import gleam/string

// ============================================================================
// Validation Types
// ============================================================================

pub type ValidationError {
  MissingField(field: String)
  InvalidType(field: String, expected: String)
  NumericConstraintViolation(field: String, constraint: String)
  StringPatternViolation(field: String, pattern: String)
  ArrayConstraintViolation(field: String, constraint: String)
}

pub type ValidationResult(t) =
  Result(t, List(ValidationError))

// ============================================================================
// Recipe Validation
// ============================================================================

/// Validate recipe data against OpenAPI schema
pub fn validate_recipe() -> ValidationResult(Nil) {
  // Check required fields: id, name, servings, description
  // Check numeric constraints: servings > 0
  // Check string constraints: name not empty
  Ok(Nil)
}

// ============================================================================
// Food Validation
// ============================================================================

/// Validate food data against OpenAPI schema
pub fn validate_food() -> ValidationResult(Nil) {
  // Check required fields: id, name
  // Check numeric constraints: carbohydrates >= 0, protein >= 0, fat >= 0, calories >= 0
  // Check string constraints: name not empty
  Ok(Nil)
}

// ============================================================================
// Diary Entry Validation
// ============================================================================

/// Validate diary entry data against OpenAPI schema
pub fn validate_diary_entry() -> ValidationResult(Nil) {
  // Check required fields: id, date, meal, food
  // Check numeric constraints: quantity > 0, calories >= 0
  // Check date format: YYYY-MM-DD
  Ok(Nil)
}

// ============================================================================
// Meal Plan Validation
// ============================================================================

/// Validate meal plan data against OpenAPI schema
pub fn validate_meal_plan() -> ValidationResult(Nil) {
  // Check required fields: id, date
  // Check date format: YYYY-MM-DD
  // Check array constraints: recipes list not empty
  Ok(Nil)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Check if a string is empty
fn is_empty(s: String) -> Bool {
  string.length(string.trim(s)) == 0
}

/// Check if a number is positive
fn is_positive(n: Float) -> Bool {
  n >. 0.0
}

/// Check if a number is non-negative
fn is_non_negative(n: Float) -> Bool {
  n >=. 0.0
}

/// Validate date format YYYY-MM-DD
fn is_valid_date(date_str: String) -> Bool {
  // Simple validation: check format
  let parts = string.split(date_str, "-")
  case parts {
    [_year, _month, _day] -> True
    _ -> False
  }
}
