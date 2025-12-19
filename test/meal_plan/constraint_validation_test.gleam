/// RED Phase Tests: Constraint Validation
/// Tests for JSON deserialization, date validation, enum parsing, and recipe ID validation
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/result
import gleeunit
import gleeunit/should
import simplifile
import meal_planner/meal_plan/constraints
import meal_planner/meal_plan/constraints_decoder
import meal_planner/meal_plan/constraints_encoder

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// JSON Round-Trip Tests (Serialize/Deserialize)
// ============================================================================

/// Test: Full constraint with all fields round-trips through JSON
pub fn constraint_json_full_roundtrip_test() {
  let assert Ok(json_string) = simplifile.read("test/fixtures/meal_plan/constraint_full.json")
  let assert Ok(json_value) = json.parse(json_string, using: decode.dynamic)
  let assert Ok(constraint) = decode.run(json_value, constraints_decoder.constraint_decoder())
  let encoded = constraints_encoder.encode_constraint(constraint)
  let assert Ok(json_value2) = json.parse(encoded, using: decode.dynamic)
  let assert Ok(decoded) = decode.run(json_value2, constraints_decoder.constraint_decoder())

  constraint |> should.equal(decoded)
}

/// Test: Minimal constraint (only required fields) round-trips through JSON
pub fn constraint_json_minimal_roundtrip_test() {
  let assert Ok(json_string) = simplifile.read("test/fixtures/meal_plan/constraint_minimal.json")
  let assert Ok(json_value) = json.parse(json_string, using: decode.dynamic)
  let assert Ok(constraint) = decode.run(json_value, constraints_decoder.constraint_decoder())
  let encoded = constraints_encoder.encode_constraint(constraint)
  let assert Ok(json_value2) = json.parse(encoded, using: decode.dynamic)
  let assert Ok(decoded) = decode.run(json_value2, constraints_decoder.constraint_decoder())

  constraint |> should.equal(decoded)
}

/// Test: Complex constraint with multiple locked meals and travel dates
pub fn constraint_json_complex_roundtrip_test() {
  let assert Ok(json_string) = simplifile.read("test/fixtures/meal_plan/constraint_complex.json")
  let assert Ok(json_value) = json.parse(json_string, using: decode.dynamic)
  let assert Ok(constraint) = decode.run(json_value, constraints_decoder.constraint_decoder())
  let encoded = constraints_encoder.encode_constraint(constraint)
  let assert Ok(json_value2) = json.parse(encoded, using: decode.dynamic)
  let assert Ok(decoded) = decode.run(json_value2, constraints_decoder.constraint_decoder())

  constraint |> should.equal(decoded)
}

// ============================================================================
// Date Validation Tests
// ============================================================================

/// Test: Valid ISO 8601 date string parses correctly
pub fn date_validation_valid_iso8601_test() {
  let result = constraints.validate_date("2025-12-22")
  result |> should.be_ok()
}

/// Test: Invalid date format (YYYY/MM/DD) should fail
pub fn date_validation_invalid_format_test() {
  let result = constraints.validate_date("2025/12/22")
  result |> should.be_error()
}

/// Test: Invalid date value (Feb 30) should fail
pub fn date_validation_invalid_day_test() {
  let result = constraints.validate_date("2025-02-30")
  result |> should.be_error()
}

// ============================================================================
// Enum Parsing Tests
// ============================================================================

/// Test: MealType enum parses all valid values
pub fn enum_meal_type_parsing_test() {
  let breakfast = constraints.meal_type_from_string("breakfast")
  let lunch = constraints.meal_type_from_string("lunch")
  let dinner = constraints.meal_type_from_string("dinner")
  let snack = constraints.meal_type_from_string("snack")

  breakfast |> should.be_ok()
  lunch |> should.be_ok()
  dinner |> should.be_ok()
  snack |> should.be_ok()
}

/// Test: DayOfWeek enum parses all valid values
pub fn enum_day_of_week_parsing_test() {
  let monday = constraints.day_of_week_from_string("Monday")
  let tuesday = constraints.day_of_week_from_string("Tuesday")
  let friday = constraints.day_of_week_from_string("Friday")
  let sunday = constraints.day_of_week_from_string("Sunday")

  monday |> should.be_ok()
  tuesday |> should.be_ok()
  friday |> should.be_ok()
  sunday |> should.be_ok()
}

/// Test: MacroAdjustment enum parses all valid values
pub fn enum_macro_adjustment_parsing_test() {
  let high_protein = constraints.macro_adjustment_from_string("high_protein")
  let low_carb = constraints.macro_adjustment_from_string("low_carb")
  let balanced = constraints.macro_adjustment_from_string("balanced")

  high_protein |> should.be_ok()
  low_carb |> should.be_ok()
  balanced |> should.be_ok()
}

// ============================================================================
// Recipe ID Validation Tests
// ============================================================================

/// Test: Valid positive integer recipe_id passes validation
pub fn recipe_id_valid_positive_test() {
  let result = constraints.validate_recipe_id_positive(42)
  result |> should.be_ok()
}

/// Test: Zero recipe_id fails validation
pub fn recipe_id_zero_fails_test() {
  let result = constraints.validate_recipe_id_positive(0)
  result |> should.be_error()
}

/// Test: Negative recipe_id fails validation
pub fn recipe_id_negative_fails_test() {
  let result = constraints.validate_recipe_id_positive(-5)
  result |> should.be_error()
}

/// Test: Large valid recipe_id passes validation
pub fn recipe_id_large_valid_test() {
  let result = constraints.validate_recipe_id_positive(999_999)
  result |> should.be_ok()
}

// ============================================================================
// Travel Dates Validation Tests
// ============================================================================

/// Test: Valid consecutive travel dates pass validation
pub fn travel_dates_consecutive_valid_test() {
  let dates = ["2025-12-23", "2025-12-24", "2025-12-25"]
  let result = constraints.validate_travel_dates(dates)
  result |> should.be_ok()
}

/// Test: Single travel date passes validation
pub fn travel_dates_single_valid_test() {
  let dates = ["2025-12-23"]
  let result = constraints.validate_travel_dates(dates)
  result |> should.be_ok()
}

/// Test: Non-consecutive dates fail validation
pub fn travel_dates_non_consecutive_fails_test() {
  let dates = ["2025-12-23", "2025-12-25"]
  let result = constraints.validate_travel_dates(dates)
  result |> should.be_error()
}
