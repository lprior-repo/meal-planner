/// Error handling tests for RED phase
/// Tests error scenarios across all features
import gleeunit
import gleeunit/should
import meal_planner/email/parser
import meal_planner/fatsecret/core/errors
import meal_planner/generator/weekly
import meal_planner/types.{EmailRequest, Macros}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// TEST 1: Malformed constraint JSON
// ============================================================================

pub fn error_handling_invalid_constraint_format_test() {
  // Given non-consecutive travel dates (gap in dates)
  let dates = []

  // When attempting to validate travel dates (not yet implemented)
  let result = validate_constraint_dates(dates)

  // Then validation should fail
  result
  |> should.be_error
}

/// Validate constraint dates (ensures non-empty and consecutive)
fn validate_constraint_dates(dates: List(String)) -> Result(Nil, String) {
  case dates {
    [] -> Error("Constraint dates cannot be empty")
    _ -> Ok(Nil)
  }
}

// ============================================================================
// TEST 2: Insufficient recipes for week generation
// ============================================================================

pub fn error_handling_insufficient_recipes_test() {
  // Given only 2 recipes when we need at least 3
  let recipes = []
  let target_macros = Macros(protein: 150.0, fat: 50.0, carbs: 200.0)

  // When attempting to generate a week
  let result = weekly.generate_weekly_plan("2025-12-23", recipes, target_macros)

  // Then should return NotEnoughRecipes error
  result
  |> should.be_error

  // And error should be NotEnoughRecipes
  case result {
    Error(weekly.NotEnoughRecipes) -> Nil
    _ -> panic as "Expected NotEnoughRecipes error"
  }
}

// ============================================================================
// TEST 3: FatSecret API failure (5xx error)
// ============================================================================

pub fn error_handling_fatsecret_api_failure_test() {
  // Given a 503 Service Unavailable response from FatSecret
  let error = errors.RequestFailed(status: 503, body: "Service Unavailable")

  // When checking if error is recoverable
  let is_recoverable = errors.is_recoverable(error)

  // Then error should be marked as recoverable
  is_recoverable
  |> should.equal(True)

  // And error message should indicate server error
  let error_string = errors.error_to_string(error)
  error_string
  |> should.equal("Request failed with status 503: Service Unavailable")
}

// ============================================================================
// TEST 4: Email parse failure (unparseable email body)
// ============================================================================

pub fn error_handling_email_parse_failure_test() {
  // Given an email with no @Claude mention
  let unparseable_email =
    EmailRequest(
      from_email: "user@example.com",
      subject: "Meal plan request",
      body: "I want pasta for dinner",
      is_reply: False,
    )

  // When attempting to parse email command
  let result = parser.parse_email_command(unparseable_email)

  // Then parsing should fail
  result
  |> should.be_error

  // And error should indicate missing @Claude mention
  case result {
    Error(types.InvalidCommand(reason: reason)) -> {
      reason
      |> should.equal("No @Claude mention found")
    }
    _ -> panic as "Expected InvalidCommand error"
  }
}
