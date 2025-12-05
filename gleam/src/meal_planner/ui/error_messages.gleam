/// User-Friendly Error Messages Module
///
/// This module provides user-friendly, actionable error messages that replace
/// technical errors with clear explanations and helpful suggestions.
///
/// Features:
/// - Error categorization and severity levels
/// - Context-aware message generation
/// - Actionable recovery suggestions
/// - Consistent user experience
///
/// Usage:
/// ```gleam
/// case storage.get_recipe(id) {
///   Ok(recipe) -> // Handle success
///   Error(storage.DatabaseError(msg)) -> {
///     let friendly = from_storage_error(storage.DatabaseError(msg))
///     render_error(friendly)
///   }
/// }
/// ```
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/nutrition_constants
import meal_planner/storage.{type StorageError}
import meal_planner/storage/profile.{
  DatabaseError, InvalidInput, NotFound, Unauthorized,
}
import meal_planner/types.{type FoodSearchError}

// ============================================================================
// ERROR MESSAGE TYPES
// ============================================================================

/// Severity level for error categorization and UI styling
pub type Severity {
  /// Informational messages (blue)
  Info
  /// Warnings that don't prevent operation (yellow)
  Warning
  /// Errors that prevent operation (red)
  Error
  /// Critical system failures (dark red)
  Critical
}

/// User-friendly error message with actionable suggestions
pub type ErrorMessage {
  ErrorMessage(
    /// Short, user-facing error title
    title: String,
    /// Detailed explanation of what went wrong
    message: String,
    /// List of actionable suggestions for the user
    suggestions: List(String),
    /// Severity level for UI styling
    severity: Severity,
    /// Whether a retry operation is available
    retry_available: Bool,
    /// Optional retry URL/action
    retry_url: Option(String),
    /// Optional technical details (for debugging, hidden by default)
    technical_details: Option(String),
  )
}

/// Action button for error recovery
pub type ErrorAction {
  ErrorAction(label: String, url: String)
}

// ============================================================================
// ERROR CONVERSION FUNCTIONS
// ============================================================================

/// Convert StorageError to user-friendly ErrorMessage
pub fn from_storage_error(error: StorageError) -> ErrorMessage {
  case error {
    DatabaseError(msg) -> database_error(msg)
    NotFound -> not_found_error()
    InvalidInput(msg) -> invalid_input_error(msg)
    Unauthorized(msg) -> unauthorized_error(msg)
  }
}

/// Convert FoodSearchError to user-friendly ErrorMessage
pub fn from_search_error(error: FoodSearchError) -> ErrorMessage {
  case error {
    types.DatabaseError(msg) -> database_error(msg)
    types.InvalidQuery(msg) -> invalid_query_error(msg)
  }
}

// ============================================================================
// SPECIFIC ERROR MESSAGES
// ============================================================================

/// Database connection or query error
fn database_error(technical_msg: String) -> ErrorMessage {
  ErrorMessage(
    title: "Connection Problem",
    message: "We're having trouble connecting to the database. This is usually temporary.",
    suggestions: [
      "Wait a moment and try again",
      "Check your internet connection",
      "If this continues, please contact support",
    ],
    severity: Error,
    retry_available: True,
    retry_url: None,
    technical_details: Some(technical_msg),
  )
}

/// Resource not found error
fn not_found_error() -> ErrorMessage {
  ErrorMessage(
    title: "Not Found",
    message: "We couldn't find what you're looking for. It may have been deleted or moved.",
    suggestions: [
      "Check that the link is correct",
      "Try searching for it again",
      "Go back to the previous page",
    ],
    severity: Warning,
    retry_available: False,
    retry_url: None,
    technical_details: None,
  )
}

/// Invalid input validation error
fn invalid_input_error(msg: String) -> ErrorMessage {
  let friendly_msg = make_validation_message_friendly(msg)

  ErrorMessage(
    title: "Invalid Input",
    message: friendly_msg,
    suggestions: ["Please correct the highlighted fields and try again"],
    severity: Warning,
    retry_available: False,
    retry_url: None,
    technical_details: Some(msg),
  )
}

/// Unauthorized access error
fn unauthorized_error(msg: String) -> ErrorMessage {
  ErrorMessage(
    title: "Access Denied",
    message: "You don't have permission to access this resource.",
    suggestions: [
      "Make sure you're logged in",
      "Check that you have the necessary permissions",
      "Contact your administrator if you think this is a mistake",
    ],
    severity: Error,
    retry_available: False,
    retry_url: Some("/login"),
    technical_details: Some(msg),
  )
}

/// Invalid search query error
fn invalid_query_error(msg: String) -> ErrorMessage {
  let friendly_msg = case string.contains(msg, "at least 2 characters") {
    True -> "Please enter at least 2 characters to search."
    False ->
      case string.contains(msg, "between 1 and 100") {
        True -> "Please request between 1 and 100 results."
        False -> "Your search query isn't quite right. " <> msg
      }
  }

  ErrorMessage(
    title: "Search Error",
    message: friendly_msg,
    suggestions: ["Try a different search term", "Use at least 2 characters"],
    severity: Info,
    retry_available: False,
    retry_url: None,
    technical_details: Some(msg),
  )
}

// ============================================================================
// NETWORK ERROR MESSAGES
// ============================================================================

/// Network connection lost
pub fn network_offline() -> ErrorMessage {
  ErrorMessage(
    title: "You're Offline",
    message: "It looks like you've lost your internet connection.",
    suggestions: [
      "Check your Wi-Fi or mobile data",
      "Try moving to a location with better signal",
      "We'll automatically reconnect when you're back online",
    ],
    severity: Warning,
    retry_available: True,
    retry_url: None,
    technical_details: None,
  )
}

/// Network request timeout
pub fn network_timeout() -> ErrorMessage {
  ErrorMessage(
    title: "Request Timeout",
    message: "The server is taking too long to respond.",
    suggestions: [
      "Check your internet connection",
      "Try again in a moment",
      "The server might be experiencing high traffic",
    ],
    severity: Warning,
    retry_available: True,
    retry_url: None,
    technical_details: None,
  )
}

/// Server error (500)
pub fn server_error() -> ErrorMessage {
  ErrorMessage(
    title: "Server Error",
    message: "Something went wrong on our end. We're working on it!",
    suggestions: [
      "Try again in a few moments",
      "Your data has been saved",
      "Contact support if this continues",
    ],
    severity: Error,
    retry_available: True,
    retry_url: None,
    technical_details: None,
  )
}

// ============================================================================
// VALIDATION ERROR MESSAGES
// ============================================================================

/// Make validation message more user-friendly
fn make_validation_message_friendly(msg: String) -> String {
  case string.contains(msg, "is required") {
    True -> {
      let field = extract_field_name(msg)
      "Please enter a " <> field <> "."
    }
    False ->
      case string.contains(msg, "must be a positive number") {
        True -> {
          let field = extract_field_name(msg)
          field <> " must be greater than zero."
        }
        False ->
          case string.contains(msg, "must be a non-negative number") {
            True -> {
              let field = extract_field_name(msg)
              field <> " cannot be negative."
            }
            False ->
              case string.contains(msg, "at least") {
                True -> msg
                False ->
                  case string.contains(msg, "too long") {
                    True -> msg
                    False -> msg
                  }
              }
          }
      }
  }
}

/// Extract field name from error message
fn extract_field_name(msg: String) -> String {
  case string.split(msg, " ") {
    [field, ..] -> string.lowercase(field)
    [] -> "value"
  }
}

// ============================================================================
// SPECIFIC DOMAIN ERRORS
// ============================================================================

/// Recipe-specific errors
pub fn recipe_not_found(recipe_id: String) -> ErrorMessage {
  ErrorMessage(
    title: "Recipe Not Found",
    message: "We couldn't find that recipe. It may have been deleted.",
    suggestions: [
      "Try searching for a different recipe",
      "Browse all recipes",
      "Create a new recipe",
    ],
    severity: Warning,
    retry_available: False,
    retry_url: Some("/recipes"),
    technical_details: Some("Recipe ID: " <> recipe_id),
  )
}

/// Food search no results
pub fn no_search_results(query: String) -> ErrorMessage {
  ErrorMessage(
    title: "No Results Found",
    message: "We couldn't find any foods matching \"" <> query <> "\".",
    suggestions: [
      "Try a different search term",
      "Check your spelling",
      "Search for a broader term",
      "Add this as a custom food",
    ],
    severity: Info,
    retry_available: False,
    retry_url: Some("/foods/new"),
    technical_details: None,
  )
}

/// Food log entry error
pub fn food_log_error(msg: String) -> ErrorMessage {
  ErrorMessage(
    title: "Couldn't Log Food",
    message: "We had trouble saving your food log entry.",
    suggestions: [
      "Check that all fields are filled in correctly",
      "Try again in a moment",
      "Make sure the food still exists",
    ],
    severity: Error,
    retry_available: True,
    retry_url: None,
    technical_details: Some(msg),
  )
}

/// Custom food creation error
pub fn custom_food_error(msg: String) -> ErrorMessage {
  let friendly_msg = case string.contains(msg, "name") {
    True -> "Please enter a food name."
    False ->
      case string.contains(msg, "serving") {
        True -> "Please specify a serving size."
        False ->
          case string.contains(msg, "macros") {
            True ->
              "Please enter nutritional information (protein, fat, carbs)."
            False -> "Please check your input and try again."
          }
      }
  }

  ErrorMessage(
    title: "Couldn't Create Food",
    message: friendly_msg,
    suggestions: [
      "Make sure all required fields are filled in",
      "Check that numbers are valid",
      "Serving size must be greater than zero",
    ],
    severity: Warning,
    retry_available: False,
    retry_url: None,
    technical_details: Some(msg),
  )
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Get icon for severity level
pub fn severity_icon(severity: Severity) -> String {
  case severity {
    Info -> "ℹ"
    Warning -> "⚠"
    Error -> "✕"
    Critical -> "🔥"
  }
}

/// Get CSS class for severity level
pub fn severity_class(severity: Severity) -> String {
  case severity {
    Info -> "alert-info"
    Warning -> "alert-warning"
    Error -> "alert-danger"
    Critical -> "alert-critical"
  }
}

/// Get color for severity level
pub fn severity_color(severity: Severity) -> String {
  case severity {
    Info -> "#0ea5e9"
    // Sky blue
    Warning -> "#f59e0b"
    // Amber
    Error -> "#ef4444"
    // Red
    Critical -> "#991b1b"
  }
}

/// Format suggestions as HTML list
pub fn format_suggestions(suggestions: List(String)) -> String {
  case suggestions {
    [] -> ""
    _ -> {
      let items =
        suggestions
        |> list.map(fn(s) { "<li>" <> s <> "</li>" })
        |> string.join("")
      "<ul class=\"error-suggestions\">" <> items <> "</ul>"
    }
  }
}

/// Create a generic error message
pub fn generic_error(title: String, message: String) -> ErrorMessage {
  ErrorMessage(
    title: title,
    message: message,
    suggestions: ["Try again", "Contact support if this continues"],
    severity: Error,
    retry_available: True,
    retry_url: None,
    technical_details: None,
  )
}

/// Create an info message (not really an error)
pub fn info_message(title: String, message: String) -> ErrorMessage {
  ErrorMessage(
    title: title,
    message: message,
    suggestions: [],
    severity: Info,
    retry_available: False,
    retry_url: None,
    technical_details: None,
  )
}

// ============================================================================
// FORM VALIDATION ERRORS
// ============================================================================

/// Collect multiple validation errors into a single message
pub fn validation_errors(errors: List(String)) -> ErrorMessage {
  let error_count = list.fold(errors, 0, fn(acc, _) { acc + 1 })
  let message = case error_count {
    1 -> "Please correct the following issue:"
    n -> "Please correct " <> int_to_string(n) <> " issues:"
  }

  ErrorMessage(
    title: "Validation Failed",
    message: message,
    suggestions: errors,
    severity: Warning,
    retry_available: False,
    retry_url: None,
    technical_details: None,
  )
}

@external(erlang, "erlang", "integer_to_list")
fn int_to_list(n: Int) -> List(Int)

fn int_to_string(n: Int) -> String {
  n
  |> int_to_list
  |> list.map(fn(c) {
    case c {
      48 -> "0"
      49 -> "1"
      50 -> "2"
      51 -> "3"
      52 -> "4"
      53 -> "5"
      54 -> "6"
      55 -> "7"
      56 -> "8"
      57 -> "9"
      _ -> ""
    }
  })
  |> string.join("")
}
