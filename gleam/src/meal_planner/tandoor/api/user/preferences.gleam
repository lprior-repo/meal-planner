/// User Preferences API for Tandoor SDK
///
/// This module provides functions to get and update user preferences.
///
/// API Endpoints:
/// - GET /api/user-preference/ - List all preferences (returns current user's)
/// - GET /api/user-preference/{user_id}/ - Get specific user's preferences
/// - PATCH /api/user-preference/{user_id}/ - Update preferences
///
/// Refactored to use CRUD helpers for reduced boilerplate.
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/decoders/user/user_preference_decoder
import meal_planner/tandoor/encoders/user/user_preference_encoder.{
  type UserPreferenceUpdateRequest,
}
import meal_planner/tandoor/types/user/user_preference.{type UserPreference}

/// Get current user's preferences
///
/// Calls GET /api/user-preference/ which returns the authenticated user's preferences.
/// The API returns an array with a single element containing the current user's preferences.
///
/// # Arguments
/// * `config` - Client configuration with authentication
///
/// # Returns
/// Result with user preferences or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_current_user_preferences(config)
/// ```
pub fn get_current_user_preferences(
  config: ClientConfig,
) -> Result(UserPreference, TandoorError) {
  // Execute GET request
  use resp <- result.try(crud_helpers.execute_get(
    config,
    "/api/user-preference/",
    [],
  ))

  // Parse as list and extract first element
  use prefs_list <- result.try(crud_helpers.parse_json_list(
    resp,
    user_preference_decoder.user_preference_decoder(),
  ))

  // API returns array with single element
  case prefs_list {
    [first, ..] -> Ok(first)
    [] -> Error(client.ParseError("No preferences returned for current user"))
  }
}

/// Get user preferences by user ID
///
/// Calls GET /api/user-preference/{user_id}/
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `user_id` - The ID of the user whose preferences to fetch
///
/// # Returns
/// Result with user preferences or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let user_id = ids.user_id(1)
/// let result = get_user_preferences(config, user_id: user_id)
/// ```
pub fn get_user_preferences(
  config: ClientConfig,
  user_id user_id: ids.UserId,
) -> Result(UserPreference, TandoorError) {
  let user_id_int = ids.user_id_to_int(user_id)
  let path = "/api/user-preference/" <> int.to_string(user_id_int) <> "/"

  // Execute GET request and parse response
  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(
    resp,
    user_preference_decoder.user_preference_decoder(),
  )
}

/// Update user preferences
///
/// Calls PATCH /api/user-preference/{user_id}/ with partial update data.
/// Only provided fields (Some values) will be updated.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `user_id` - The ID of the user whose preferences to update
/// * `update` - Partial update with optional fields
///
/// # Returns
/// Result with updated preferences or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let user_id = ids.user_id(1)
/// let update = UserPreferenceUpdateRequest(
///   theme: Some("FLATLY"),
///   use_fractions: Some(True),
///   ..default_update()
/// )
/// let result = update_user_preferences(config, user_id: user_id, update: update)
/// ```
pub fn update_user_preferences(
  config: ClientConfig,
  user_id user_id: ids.UserId,
  update update: UserPreferenceUpdateRequest,
) -> Result(UserPreference, TandoorError) {
  let user_id_int = ids.user_id_to_int(user_id)
  let path = "/api/user-preference/" <> int.to_string(user_id_int) <> "/"

  // Encode update data to JSON
  let request_body =
    user_preference_encoder.encode_update(update)
    |> json.to_string

  // Execute PATCH request and parse response
  use resp <- result.try(crud_helpers.execute_patch(config, path, request_body))
  crud_helpers.parse_json_single(
    resp,
    user_preference_decoder.user_preference_decoder(),
  )
}

/// Get current user's preferences (convenience alias)
///
/// Same as `get_current_user_preferences` but with a shorter name.
pub fn get_preferences(
  config: ClientConfig,
) -> Result(UserPreference, TandoorError) {
  get_current_user_preferences(config)
}

/// Update current user's preferences (convenience function)
///
/// Updates the preferences for the current authenticated user.
/// This is typically what you want for most use cases.
///
/// Note: This function requires knowing the user_id. If you don't have it,
/// first call get_preferences() to retrieve the current user's data.
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// // First get current preferences to get user_id
/// use current <- result.try(get_preferences(config))
/// let user_id = ids.user_id(current.user.id)
/// // Then update
/// let update = UserPreferenceUpdateRequest(theme: Some("FLATLY"), ..default_update())
/// update_preferences(config, user_id: user_id, update: update)
/// ```
pub fn update_preferences(
  config: ClientConfig,
  user_id user_id: ids.UserId,
  update update: UserPreferenceUpdateRequest,
) -> Result(UserPreference, TandoorError) {
  update_user_preferences(config, user_id: user_id, update: update)
}
