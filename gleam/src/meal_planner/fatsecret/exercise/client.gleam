/// FatSecret Exercise API client
/// Provides type-safe wrappers around the base FatSecret client
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/client as base_client
import meal_planner/fatsecret/exercise/decoders
import meal_planner/fatsecret/exercise/types.{
  type Exercise, type ExerciseEntry, type ExerciseEntryId,
  type ExerciseEntryInput, type ExerciseEntryUpdate, type ExerciseId,
  type ExerciseMonthSummary,
}

// Re-export error types and AccessToken from base client
pub type FatSecretError =
  base_client.FatSecretError

pub type AccessToken =
  base_client.AccessToken

// ============================================================================
// Exercise Get API (exercises.get.v2 - 2-legged)
// ============================================================================

/// Get exercise details by ID using exercises.get.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns exercise information from the FatSecret public database.
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// let exercise_id = types.exercise_id("1")
/// case get_exercise(config, exercise_id) {
///   Ok(exercise) -> io.println("Exercise: " <> exercise.exercise_name)
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn get_exercise(
  config: FatSecretConfig,
  exercise_id: ExerciseId,
) -> Result(Exercise, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("exercise_id", types.exercise_id_to_string(exercise_id))

  // Use base client's make_api_request function
  use response_json <- result.try(base_client.make_api_request(
    config,
    "exercises.get.v2",
    params,
  ))

  // Parse JSON response with type-safe decoders
  case json.parse(response_json, decoders.exercise_decoder()) {
    Ok(exercise) -> Ok(exercise)
    Error(_) ->
      Error(base_client.ParseError(
        "Failed to decode exercise response: " <> response_json,
      ))
  }
}

// ============================================================================
// Exercise Entries API (3-legged - Requires user authentication)
// ============================================================================

/// Get user's exercise entries for a specific date
///
/// This is a 3-legged OAuth request (requires user access token).
/// Returns all exercises logged on the specified date.
///
/// ## Parameters
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token
/// - date_int: Date as days since epoch (use types.date_to_int)
///
/// ## Example
/// ```gleam
/// let date_int = types.date_to_int("2025-12-14") |> result.unwrap(0)
/// case get_exercise_entries(config, access_token, date_int) {
///   Ok(entries) -> {
///     io.println("Found " <> int.to_string(list.length(entries)) <> " exercises")
///     list.each(entries, fn(entry) {
///       io.println("- " <> entry.exercise_name <> " for " <> int.to_string(entry.duration_min) <> " min")
///     })
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn get_exercise_entries(
  config: FatSecretConfig,
  access_token: AccessToken,
  date_int: Int,
) -> Result(List(ExerciseEntry), FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date", int.to_string(date_int))

  // Use base client's make_authenticated_request function
  use response_json <- result.try(base_client.make_authenticated_request(
    config,
    access_token,
    "exercise_entries.get.v2",
    params,
  ))

  // Parse JSON response with type-safe decoders
  case json.parse(response_json, decoders.decode_exercise_entries_response()) {
    Ok(entries) -> Ok(entries)
    Error(_) ->
      Error(base_client.ParseError(
        "Failed to decode exercise entries response: " <> response_json,
      ))
  }
}

/// Edit an existing exercise entry
///
/// This is a 3-legged OAuth request (requires user access token).
/// Allows updating exercise type and/or duration.
///
/// ## Parameters
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token
/// - entry_id: Exercise entry ID to edit
/// - update: Updates to apply
///
/// ## Example
/// ```gleam
/// let update = types.ExerciseEntryUpdate(
///   exercise_id: Some(types.exercise_id("2")),
///   duration_min: Some(45)
/// )
/// case edit_exercise_entry(config, access_token, entry_id, update) {
///   Ok(_) -> io.println("Exercise entry updated")
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn edit_exercise_entry(
  config: FatSecretConfig,
  access_token: AccessToken,
  entry_id: ExerciseEntryId,
  update: ExerciseEntryUpdate,
) -> Result(Nil, FatSecretError) {
  let mut_params =
    dict.new()
    |> dict.insert(
      "exercise_entry_id",
      types.exercise_entry_id_to_string(entry_id),
    )

  // Add optional exercise_id if provided
  let mut_params = case update.exercise_id {
    Some(id) ->
      dict.insert(mut_params, "exercise_id", types.exercise_id_to_string(id))
    None -> mut_params
  }

  // Add optional duration_min if provided
  let mut_params = case update.duration_min {
    Some(duration) ->
      dict.insert(mut_params, "duration_min", int.to_string(duration))
    None -> mut_params
  }

  // Use base client's make_authenticated_request function
  use _response_json <- result.try(base_client.make_authenticated_request(
    config,
    access_token,
    "exercise_entry.edit",
    mut_params,
  ))

  Ok(Nil)
}

/// Create a new exercise entry
///
/// This is a 3-legged OAuth request (requires user access token).
/// Creates a new exercise entry in the user's diary.
///
/// ## Example
/// ```gleam
/// let date_int = types.date_to_int("2025-12-14") |> result.unwrap(0)
/// let input = types.ExerciseEntryInput(
///   exercise_id: types.exercise_id("1"),
///   duration_min: 30,
///   date_int: date_int
/// )
/// case create_exercise_entry(config, access_token, input) {
///   Ok(entry_id) -> io.println("Created entry: " <> types.exercise_entry_id_to_string(entry_id))
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn create_exercise_entry(
  config: FatSecretConfig,
  access_token: AccessToken,
  input: ExerciseEntryInput,
) -> Result(ExerciseEntryId, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert(
      "exercise_id",
      types.exercise_id_to_string(input.exercise_id),
    )
    |> dict.insert("duration_min", int.to_string(input.duration_min))
    |> dict.insert("date", int.to_string(input.date_int))

  // Use base client's make_authenticated_request function
  use response_json <- result.try(base_client.make_authenticated_request(
    config,
    access_token,
    "exercise_entry.create",
    params,
  ))

  // Parse response to get entry_id
  // FatSecret returns: {"exercise_entry": {"exercise_entry_id": "123456"}}
  case
    json.parse(
      response_json,
      decode.at(["exercise_entry", "exercise_entry_id"], decode.string),
    )
  {
    Ok(entry_id_str) -> Ok(types.exercise_entry_id(entry_id_str))
    Error(_) ->
      Error(base_client.ParseError(
        "Failed to decode exercise_entry_id from response: " <> response_json,
      ))
  }
}

/// Get monthly exercise summary
///
/// This is a 3-legged OAuth request (requires user access token).
/// Returns aggregated exercise data for each day in the specified month.
///
/// ## Parameters
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token
/// - year: Year (e.g., 2024)
/// - month: Month (1-12)
///
/// ## Example
/// ```gleam
/// case get_exercise_month_summary(config, access_token, 2024, 12) {
///   Ok(summary) -> {
///     io.println("Exercise for " <> int.to_string(summary.month) <> "/" <> int.to_string(summary.year))
///     list.each(summary.days, fn(day) {
///       io.println("- " <> types.int_to_date(day.date_int) <> ": " <> float.to_string(day.exercise_calories) <> " cal")
///     })
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn get_exercise_month_summary(
  config: FatSecretConfig,
  access_token: AccessToken,
  year: Int,
  month: Int,
) -> Result(ExerciseMonthSummary, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date", int.to_string(year) <> "-" <> int.to_string(month))

  // Use base client's make_authenticated_request function
  use response_json <- result.try(base_client.make_authenticated_request(
    config,
    access_token,
    "exercise_entries.get_month.v2",
    params,
  ))

  // Parse JSON response with type-safe decoders
  case json.parse(response_json, decoders.decode_exercise_month_summary()) {
    Ok(summary) -> Ok(summary)
    Error(_) ->
      Error(base_client.ParseError(
        "Failed to decode exercise month summary: " <> response_json,
      ))
  }
}

/// Commit exercise entries for a specific date
///
/// This is a 3-legged OAuth request (requires user access token).
/// Marks all exercise entries for the date as committed.
///
/// ## Example
/// ```gleam
/// let date_int = types.date_to_int("2025-12-14") |> result.unwrap(0)
/// case commit_exercise_day(config, access_token, date_int) {
///   Ok(_) -> io.println("Exercise entries committed")
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn commit_exercise_day(
  config: FatSecretConfig,
  access_token: AccessToken,
  date_int: Int,
) -> Result(Nil, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date", int.to_string(date_int))

  // Use base client's make_authenticated_request function
  use _response_json <- result.try(base_client.make_authenticated_request(
    config,
    access_token,
    "exercise_entries.commit_day",
    params,
  ))

  Ok(Nil)
}

/// Save exercise entries as a template
///
/// This is a 3-legged OAuth request (requires user access token).
/// Saves a set of exercise entries as a reusable template.
///
/// ## Parameters
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token
/// - template_name: Name for the template
/// - exercise_entry_ids: List of entry IDs to include in template
///
/// ## Example
/// ```gleam
/// let entry_ids = [
///   types.exercise_entry_id("123456"),
///   types.exercise_entry_id("123457")
/// ]
/// case save_exercise_template(config, access_token, "Morning Routine", entry_ids) {
///   Ok(_) -> io.println("Template saved")
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn save_exercise_template(
  config: FatSecretConfig,
  access_token: AccessToken,
  template_name: String,
  exercise_entry_ids: List(ExerciseEntryId),
) -> Result(Nil, FatSecretError) {
  let entry_ids_str =
    exercise_entry_ids
    |> list.map(types.exercise_entry_id_to_string)
    |> string.join(",")

  let params =
    dict.new()
    |> dict.insert("template_name", template_name)
    |> dict.insert("exercise_entry_ids", entry_ids_str)

  // Use base client's make_authenticated_request function
  use _response_json <- result.try(base_client.make_authenticated_request(
    config,
    access_token,
    "exercise_entries.save_template",
    params,
  ))

  Ok(Nil)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert error to user-friendly string
pub fn error_to_string(error: FatSecretError) -> String {
  case error {
    base_client.ConfigMissing -> "FatSecret API not configured"
    base_client.RequestFailed(status, body) ->
      "HTTP " <> int.to_string(status) <> ": " <> body
    base_client.InvalidResponse(msg) -> "Invalid response: " <> msg
    base_client.OAuthError(msg) -> "OAuth error: " <> msg
    base_client.NetworkError(msg) -> "Network error: " <> msg
    base_client.ApiError(code, msg) -> "API error " <> code <> ": " <> msg
    base_client.ParseError(msg) -> "Parse error: " <> msg
  }
}
