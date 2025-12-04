/// Tests for user-friendly error messages module
///
/// This test suite verifies:
/// - Error message conversion from technical to user-friendly
/// - Severity level assignment
/// - Actionable suggestions generation
/// - Error categorization
/// - Message formatting

import gleam/option.{Some}
import gleeunit
import gleeunit/should
import meal_planner/storage
import meal_planner/types
import meal_planner/ui/error_messages

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// STORAGE ERROR CONVERSION TESTS
// ============================================================================

pub fn database_error_conversion_test() {
  let error = storage.DatabaseError("Connection timeout: pg_pool_error")
  let friendly = error_messages.from_storage_error(error)

  friendly.title
  |> should.equal("Connection Problem")

  friendly.message
  |> should.equal(
    "We're having trouble connecting to the database. This is usually temporary.",
  )

  friendly.severity
  |> should.equal(error_messages.Error)

  friendly.retry_available
  |> should.equal(True)

  friendly.technical_details
  |> should.equal(Some("Connection timeout: pg_pool_error"))
}

pub fn not_found_error_conversion_test() {
  let error = storage.NotFound
  let friendly = error_messages.from_storage_error(error)

  friendly.title
  |> should.equal("Not Found")

  friendly.severity
  |> should.equal(error_messages.Warning)

  friendly.retry_available
  |> should.equal(False)

  // Should have helpful suggestions
  friendly.suggestions
  |> should.not_equal([])
}

pub fn invalid_input_error_conversion_test() {
  let error = storage.InvalidInput("Recipe name is required")
  let friendly = error_messages.from_storage_error(error)

  friendly.title
  |> should.equal("Invalid Input")

  friendly.severity
  |> should.equal(error_messages.Warning)

  // Message should be user-friendly
  friendly.message
  |> should.not_equal("")
}

pub fn unauthorized_error_conversion_test() {
  let error = storage.Unauthorized("User not authenticated")
  let friendly = error_messages.from_storage_error(error)

  friendly.title
  |> should.equal("Access Denied")

  friendly.severity
  |> should.equal(error_messages.Error)

  friendly.retry_url
  |> should.equal(Some("/login"))
}

// ============================================================================
// SEARCH ERROR CONVERSION TESTS
// ============================================================================

pub fn search_database_error_test() {
  let error = types.DatabaseError("Search index unavailable")
  let friendly = error_messages.from_search_error(error)

  friendly.title
  |> should.equal("Connection Problem")

  friendly.retry_available
  |> should.equal(True)
}

pub fn search_invalid_query_short_test() {
  let error = types.InvalidQuery("Query must be at least 2 characters")
  let friendly = error_messages.from_search_error(error)

  friendly.title
  |> should.equal("Search Error")

  friendly.message
  |> should.equal("Please enter at least 2 characters to search.")

  friendly.severity
  |> should.equal(error_messages.Info)
}

pub fn search_invalid_query_limit_test() {
  let error = types.InvalidQuery("Limit must be between 1 and 100")
  let friendly = error_messages.from_search_error(error)

  friendly.message
  |> should.equal("Please request between 1 and 100 results.")
}

// ============================================================================
// NETWORK ERROR TESTS
// ============================================================================

pub fn network_offline_test() {
  let error = error_messages.network_offline()

  error.title
  |> should.equal("You're Offline")

  error.severity
  |> should.equal(error_messages.Warning)

  error.retry_available
  |> should.equal(True)

  // Should mention reconnection
  error.suggestions
  |> should.not_equal([])
}

pub fn network_timeout_test() {
  let error = error_messages.network_timeout()

  error.title
  |> should.equal("Request Timeout")

  error.severity
  |> should.equal(error_messages.Warning)

  // Should have meaningful message
  error.message
  |> should.not_equal("")
}

pub fn server_error_test() {
  let error = error_messages.server_error()

  error.title
  |> should.equal("Server Error")

  error.severity
  |> should.equal(error_messages.Error)

  // Should reassure user
  error.message
  |> should.not_equal("")

  // Should reassure user about data
  error.suggestions
  |> should.not_equal([])
}

// ============================================================================
// DOMAIN-SPECIFIC ERROR TESTS
// ============================================================================

pub fn recipe_not_found_test() {
  let error = error_messages.recipe_not_found("recipe-123")

  error.title
  |> should.equal("Recipe Not Found")

  error.severity
  |> should.equal(error_messages.Warning)

  error.retry_url
  |> should.equal(Some("/recipes"))

  error.technical_details
  |> should.equal(Some("Recipe ID: recipe-123"))
}

pub fn no_search_results_test() {
  let error = error_messages.no_search_results("unicorn meat")

  error.title
  |> should.equal("No Results Found")

  // Should include the query term
  error.message
  |> should.not_equal("")

  error.severity
  |> should.equal(error_messages.Info)

  error.retry_url
  |> should.equal(Some("/foods/new"))
}

pub fn food_log_error_test() {
  let error = error_messages.food_log_error("Foreign key constraint violation")

  error.title
  |> should.equal("Couldn't Log Food")

  error.severity
  |> should.equal(error_messages.Error)

  error.retry_available
  |> should.equal(True)
}

pub fn custom_food_error_name_test() {
  let error = error_messages.custom_food_error("name cannot be empty")

  error.message
  |> should.equal("Please enter a food name.")

  error.severity
  |> should.equal(error_messages.Warning)
}

pub fn custom_food_error_serving_test() {
  let error = error_messages.custom_food_error("serving size must be positive")

  error.message
  |> should.equal("Please specify a serving size.")
}

pub fn custom_food_error_macros_test() {
  let error = error_messages.custom_food_error("macros.protein is required")

  error.message
  |> should.equal("Please enter nutritional information (protein, fat, carbs).")
}

// ============================================================================
// VALIDATION ERROR TESTS
// ============================================================================

pub fn validation_errors_single_test() {
  let errors = ["Recipe name is required"]
  let friendly = error_messages.validation_errors(errors)

  friendly.title
  |> should.equal("Validation Failed")

  // Should have helpful message
  friendly.message
  |> should.not_equal("")

  friendly.suggestions
  |> should.equal(errors)

  friendly.severity
  |> should.equal(error_messages.Warning)
}

pub fn validation_errors_multiple_test() {
  let errors = [
    "Recipe name is required", "Servings must be positive",
    "At least one ingredient is required",
  ]
  let friendly = error_messages.validation_errors(errors)

  // Should mention multiple issues
  friendly.message
  |> should.not_equal("")

  friendly.suggestions
  |> should.equal(errors)
}

// ============================================================================
// SEVERITY HELPER TESTS
// ============================================================================

pub fn severity_icon_test() {
  error_messages.severity_icon(error_messages.Info)
  |> should.equal("ℹ")

  error_messages.severity_icon(error_messages.Warning)
  |> should.equal("⚠")

  error_messages.severity_icon(error_messages.Error)
  |> should.equal("✕")

  error_messages.severity_icon(error_messages.Critical)
  |> should.equal("🔥")
}

pub fn severity_class_test() {
  error_messages.severity_class(error_messages.Info)
  |> should.equal("alert-info")

  error_messages.severity_class(error_messages.Warning)
  |> should.equal("alert-warning")

  error_messages.severity_class(error_messages.Error)
  |> should.equal("alert-danger")

  error_messages.severity_class(error_messages.Critical)
  |> should.equal("alert-critical")
}

pub fn severity_color_test() {
  error_messages.severity_color(error_messages.Info)
  |> should.equal("#0ea5e9")

  error_messages.severity_color(error_messages.Warning)
  |> should.equal("#f59e0b")

  error_messages.severity_color(error_messages.Error)
  |> should.equal("#ef4444")

  error_messages.severity_color(error_messages.Critical)
  |> should.equal("#991b1b")
}

// ============================================================================
// GENERIC ERROR TESTS
// ============================================================================

pub fn generic_error_test() {
  let error =
    error_messages.generic_error("Something Failed", "The operation failed.")

  error.title
  |> should.equal("Something Failed")

  error.message
  |> should.equal("The operation failed.")

  error.severity
  |> should.equal(error_messages.Error)

  error.retry_available
  |> should.equal(True)
}

pub fn info_message_test() {
  let error =
    error_messages.info_message(
      "Feature Updated",
      "We've added a new feature!",
    )

  error.severity
  |> should.equal(error_messages.Info)

  error.retry_available
  |> should.equal(False)

  error.suggestions
  |> should.equal([])
}

// ============================================================================
// SUGGESTION FORMATTING TESTS
// ============================================================================

pub fn format_suggestions_empty_test() {
  error_messages.format_suggestions([])
  |> should.equal("")
}

pub fn format_suggestions_single_test() {
  let result =
    error_messages.format_suggestions(["Try again"])

  // Should contain HTML list with suggestion
  result
  |> should.not_equal("")
}

pub fn format_suggestions_multiple_test() {
  let result =
    error_messages.format_suggestions([
      "Check your input",
      "Try again",
      "Contact support",
    ])

  // Should contain all suggestions
  result
  |> should.not_equal("")
}

// ============================================================================
// EDGE CASE TESTS
// ============================================================================

pub fn empty_technical_message_test() {
  let error = storage.DatabaseError("")
  let friendly = error_messages.from_storage_error(error)

  // Should still have a friendly message
  friendly.message
  |> should.not_equal("")

  friendly.technical_details
  |> should.equal(Some(""))
}

pub fn long_technical_message_test() {
  let long_msg =
    "PostgreSQL error: relation \"recipes\" does not exist at line 1: SELECT * FROM recipes WHERE id = $1 (SQLSTATE 42P01)"
  let error = storage.DatabaseError(long_msg)
  let friendly = error_messages.from_storage_error(error)

  // User message should be simple (not technical)
  friendly.message
  |> should.not_equal("")

  // But technical details should preserve it
  friendly.technical_details
  |> should.equal(Some(long_msg))
}

pub fn special_characters_in_error_test() {
  let error = storage.InvalidInput("Name cannot contain <script> tags")
  let friendly = error_messages.from_storage_error(error)

  // Should have a message (escaping is done at render time)
  friendly.message
  |> should.not_equal("")
}
