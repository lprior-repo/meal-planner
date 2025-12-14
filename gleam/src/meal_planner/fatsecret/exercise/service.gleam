/// FatSecret Exercise service layer
/// Automatic configuration loading and error handling
import gleam/option.{None, Some}
import meal_planner/env
import meal_planner/fatsecret/exercise/client
import meal_planner/fatsecret/exercise/types.{
  type Exercise, type ExerciseEntry, type ExerciseEntryId,
  type ExerciseEntryInput, type ExerciseEntryUpdate, type ExerciseId,
  type ExerciseMonthSummary,
}

/// Service-level errors with clearer messaging
pub type ServiceError {
  /// FatSecret API credentials not configured
  NotConfigured
  /// API error from FatSecret
  ApiError(inner: client.FatSecretError)
  /// User not authenticated (missing access token)
  NotAuthenticated
}

// ============================================================================
// Public API - 2-legged (No user authentication required)
// ============================================================================

/// Get exercise details by ID from public database
///
/// Automatically loads FatSecret configuration from environment.
/// Returns ServiceError if not configured.
///
/// ## Example
/// ```gleam
/// let exercise_id = types.exercise_id("1")
/// case get_exercise(exercise_id) {
///   Ok(exercise) -> io.println("Exercise: " <> exercise.exercise_name)
///   Error(NotConfigured) -> io.println("FatSecret not configured")
///   Error(ApiError(e)) -> io.println("API error: " <> client.error_to_string(e))
/// }
/// ```
pub fn get_exercise(exercise_id: ExerciseId) -> Result(Exercise, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.get_exercise(config, exercise_id) {
        Ok(exercise) -> Ok(exercise)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

// ============================================================================
// Public API - 3-legged (Requires user authentication)
// ============================================================================

/// Get user's exercise entries for a specific date
///
/// Automatically loads FatSecret configuration from environment.
/// Requires user's OAuth access token for authentication.
///
/// ## Parameters
/// - access_token: User's OAuth access token
/// - date_int: Date as days since epoch (use types.date_to_int)
///
/// ## Example
/// ```gleam
/// let date_int = types.date_to_int("2025-12-14") |> result.unwrap(0)
/// case get_exercise_entries(access_token, date_int) {
///   Ok(entries) -> list.each(entries, fn(e) { io.println(e.exercise_name) })
///   Error(NotConfigured) -> io.println("FatSecret not configured")
///   Error(NotAuthenticated) -> io.println("User not authenticated")
///   Error(ApiError(e)) -> io.println("API error")
/// }
/// ```
pub fn get_exercise_entries(
  access_token: client.AccessToken,
  date_int: Int,
) -> Result(List(ExerciseEntry), ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.get_exercise_entries(config, access_token, date_int) {
        Ok(entries) -> Ok(entries)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Edit an existing exercise entry
///
/// Automatically loads FatSecret configuration from environment.
/// Requires user's OAuth access token for authentication.
///
/// ## Example
/// ```gleam
/// let update = types.ExerciseEntryUpdate(
///   exercise_id: Some(types.exercise_id("2")),
///   duration_min: Some(45)
/// )
/// case edit_exercise_entry(access_token, entry_id, update) {
///   Ok(_) -> io.println("Updated")
///   Error(e) -> io.println(error_to_string(e))
/// }
/// ```
pub fn edit_exercise_entry(
  access_token: client.AccessToken,
  entry_id: ExerciseEntryId,
  update: ExerciseEntryUpdate,
) -> Result(Nil, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.edit_exercise_entry(config, access_token, entry_id, update) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Create a new exercise entry in user's diary
///
/// Automatically loads FatSecret configuration from environment.
/// Requires user's OAuth access token for authentication.
///
/// ## Example
/// ```gleam
/// let date_int = types.date_to_int("2025-12-14") |> result.unwrap(0)
/// let input = types.ExerciseEntryInput(
///   exercise_id: types.exercise_id("1"),
///   duration_min: 30,
///   date_int: date_int
/// )
/// case create_exercise_entry(access_token, input) {
///   Ok(entry_id) -> io.println("Created: " <> types.exercise_entry_id_to_string(entry_id))
///   Error(e) -> io.println(error_to_string(e))
/// }
/// ```
pub fn create_exercise_entry(
  access_token: client.AccessToken,
  input: ExerciseEntryInput,
) -> Result(ExerciseEntryId, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.create_exercise_entry(config, access_token, input) {
        Ok(entry_id) -> Ok(entry_id)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Get monthly exercise summary
///
/// Automatically loads FatSecret configuration from environment.
/// Requires user's OAuth access token for authentication.
///
/// ## Example
/// ```gleam
/// case get_exercise_month_summary(access_token, 2024, 12) {
///   Ok(summary) -> {
///     io.println("Month: " <> int.to_string(summary.month))
///     list.each(summary.days, fn(day) {
///       io.println(types.int_to_date(day.date_int) <> ": " <> float.to_string(day.exercise_calories))
///     })
///   }
///   Error(e) -> io.println(error_to_string(e))
/// }
/// ```
pub fn get_exercise_month_summary(
  access_token: client.AccessToken,
  year: Int,
  month: Int,
) -> Result(ExerciseMonthSummary, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case
        client.get_exercise_month_summary(config, access_token, year, month)
      {
        Ok(summary) -> Ok(summary)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Commit exercise entries for a specific date
///
/// Automatically loads FatSecret configuration from environment.
/// Requires user's OAuth access token for authentication.
///
/// ## Example
/// ```gleam
/// let date_int = types.date_to_int("2025-12-14") |> result.unwrap(0)
/// case commit_exercise_day(access_token, date_int) {
///   Ok(_) -> io.println("Committed")
///   Error(e) -> io.println(error_to_string(e))
/// }
/// ```
pub fn commit_exercise_day(
  access_token: client.AccessToken,
  date_int: Int,
) -> Result(Nil, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.commit_exercise_day(config, access_token, date_int) {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Save exercise entries as a template
///
/// Automatically loads FatSecret configuration from environment.
/// Requires user's OAuth access token for authentication.
///
/// ## Example
/// ```gleam
/// let entry_ids = [types.exercise_entry_id("123456")]
/// case save_exercise_template(access_token, "Morning Routine", entry_ids) {
///   Ok(_) -> io.println("Template saved")
///   Error(e) -> io.println(error_to_string(e))
/// }
/// ```
pub fn save_exercise_template(
  access_token: client.AccessToken,
  template_name: String,
  exercise_entry_ids: List(ExerciseEntryId),
) -> Result(Nil, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case
        client.save_exercise_template(
          config,
          access_token,
          template_name,
          exercise_entry_ids,
        )
      {
        Ok(_) -> Ok(Nil)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

// ============================================================================
// Error Handling
// ============================================================================

/// Convert ServiceError to user-friendly string
pub fn error_to_string(error: ServiceError) -> String {
  case error {
    NotConfigured ->
      "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET environment variables."
    NotAuthenticated -> "User not authenticated. OAuth access token required."
    ApiError(inner) -> client.error_to_string(inner)
  }
}
