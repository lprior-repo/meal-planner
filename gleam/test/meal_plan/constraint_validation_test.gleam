import birl
import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/meal_plan/constraints.{type Constraint, Constraint}
import meal_planner/meal_plan/constraints_decoder
import meal_planner/meal_plan/constraints_encoder
import simplifile

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Constraint Validation Tests
// ============================================================================

/// Test that constraint validation rejects non-consecutive travel dates
///
/// Requirement: Travel dates must be consecutive and in future.
/// This test creates a constraint with travel dates that are NOT consecutive:
/// - 2020-01-01 (past date, not consecutive with 2025-12-22)
/// - 2025-12-22 (week start date)
///
/// Expected: Validation should return Error("Travel dates must be consecutive")
pub fn constraint_validation_rejects_invalid_travel_dates_test() {
  // Load base fixture
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  // Parse the JSON
  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  // Decode to Constraint type
  let assert Ok(constraint) =
    constraints_decoder.decode_constraint(fixture_json)

  // Test data: Non-consecutive travel dates
  // - "2020-01-01" is in the past and NOT consecutive with "2025-12-22"
  let invalid_dates = [
    birl.from_naive("2020-01-01 00:00:00"),
    birl.from_naive("2025-12-22 00:00:00"),
  ]

  // Create constraint with invalid travel dates
  let invalid_constraint =
    Constraint(
      week_of: constraint.week_of,
      travel_dates: invalid_dates,
      locked_meals: constraint.locked_meals,
      macro_adjustment: constraint.macro_adjustment,
      preferences: constraint.preferences,
      meal_skips: constraint.meal_skips,
    )

  // Validate constraint (this function doesn't exist yet - will be implemented in GREEN phase)
  let result = validate_travel_dates(invalid_constraint)

  // This should fail with an error message about consecutive dates
  result
  |> should.be_error()

  // Verify error message contains "consecutive"
  let assert Error(error_msg) = result
  error_msg
  |> should.equal("Travel dates must be consecutive")
}

// ============================================================================
// JSON Round-Trip Tests (Encode/Decode)
// ============================================================================

/// Test that a constraint can be encoded to JSON and decoded back
pub fn constraint_json_round_trip_full_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let assert Ok(constraint) =
    constraints_decoder.decode_constraint(fixture_json)

  // Encode the constraint back to JSON
  let encoded = constraints_encoder.encode_constraint(constraint)

  // Decode the encoded JSON back to a constraint
  let result = constraints_decoder.decode_constraint(encoded)

  // Round-trip should succeed and produce equivalent data
  result
  |> should.be_ok()
}

/// Test that minimal constraint round-trips correctly
pub fn constraint_json_round_trip_minimal_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_minimal.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let assert Ok(constraint) =
    constraints_decoder.decode_constraint(fixture_json)

  let encoded = constraints_encoder.encode_constraint(constraint)
  let result = constraints_decoder.decode_constraint(encoded)

  result
  |> should.be_ok()
}

/// Test that complex constraint round-trips correctly
pub fn constraint_json_round_trip_complex_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_complex.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let assert Ok(constraint) =
    constraints_decoder.decode_constraint(fixture_json)

  let encoded = constraints_encoder.encode_constraint(constraint)
  let result = constraints_decoder.decode_constraint(encoded)

  result
  |> should.be_ok()
}

// ============================================================================
// Date Validation Tests
// ============================================================================

/// Test that week_of date must be a valid ISO 8601 date
pub fn constraint_week_of_date_validation_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  // Decode should succeed and produce a Time value for week_of
  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_ok()
}

/// Test that travel_dates must be valid ISO 8601 dates
pub fn constraint_travel_dates_date_validation_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_ok()

  // Verify that travel_dates are actually Time values
  let assert Ok(constraint) = result
  constraint.travel_dates
  |> list.length()
  |> should.equal(3)
}

/// Test that invalid ISO 8601 date in week_of fails to decode
pub fn constraint_invalid_week_of_date_test() {
  let json_str =
    "{\"week_of\": \"not-a-date\", \"travel_dates\": [], \"locked_meals\": [], \"macro_adjustment\": \"balanced\", \"preferences\": [], \"meal_skips\": []}"

  let assert Ok(fixture_json) = json.decode(from: json_str, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_error()
}

// ============================================================================
// Enum Validation Tests (MealType, DayOfWeek, MacroAdjustment)
// ============================================================================

/// Test that MealType enum values are correctly decoded
pub fn constraint_meal_type_enum_parsing_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_ok()
}

/// Test that DayOfWeek enum values are correctly decoded
pub fn constraint_day_of_week_enum_parsing_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_ok()

  let assert Ok(constraint) = result
  constraint.locked_meals
  |> list.length()
  |> should.be_ok()
}

/// Test that MacroAdjustment enum values are correctly decoded
pub fn constraint_macro_adjustment_enum_parsing_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_ok()
}

// ============================================================================
// Recipe ID Validation Tests
// ============================================================================

/// Test that locked meal recipe_id is parsed as integer
pub fn locked_meal_recipe_id_validation_test() {
  let assert Ok(fixture_content) =
    simplifile.read(from: "test/fixtures/meal_plan/constraint_full.json")

  let assert Ok(fixture_json) =
    json.decode(from: fixture_content, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_ok()

  let assert Ok(constraint) = result
  constraint.locked_meals
  |> list.length()
  |> should.equal(1)

  let assert [locked_meal, ..] = constraint.locked_meals
  locked_meal.recipe_id
  |> should.equal(42)
}

/// Test that locked meal with missing recipe_id fails validation
pub fn locked_meal_missing_recipe_id_test() {
  let json_str =
    "{\"week_of\": \"2025-12-22T00:00:00Z\", \"travel_dates\": [], \"locked_meals\": [{\"day\": \"Friday\", \"meal_type\": \"dinner\"}], \"macro_adjustment\": \"balanced\", \"preferences\": [], \"meal_skips\": []}"

  let assert Ok(fixture_json) = json.decode(from: json_str, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_error()
}

/// Test that locked meal with non-integer recipe_id fails validation
pub fn locked_meal_invalid_recipe_id_type_test() {
  let json_str =
    "{\"week_of\": \"2025-12-22T00:00:00Z\", \"travel_dates\": [], \"locked_meals\": [{\"day\": \"Friday\", \"meal_type\": \"dinner\", \"recipe_id\": \"not-an-int\"}], \"macro_adjustment\": \"balanced\", \"preferences\": [], \"meal_skips\": []}"

  let assert Ok(fixture_json) = json.decode(from: json_str, using: json.dynamic)

  let result = constraints_decoder.decode_constraint(fixture_json)

  result
  |> should.be_error()
}

// ============================================================================
// Helper Functions (Placeholders - will be implemented in GREEN phase)
// ============================================================================

/// Validate that travel dates are consecutive
///
/// This is a placeholder function that will be implemented in the GREEN phase.
/// For RED phase, it always returns Ok to make the test fail.
fn validate_travel_dates(constraint: Constraint) -> Result(Nil, String) {
  // RED phase: Always return Ok to make test fail
  Ok(Nil)
}
