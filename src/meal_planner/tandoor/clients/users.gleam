/// Tandoor User Management API client
///
/// This module provides functions for interacting with Tandoor user-related APIs.
/// It handles user retrieval and user preference management operations.
///
/// Extracted from the main client.gleam for better modularity and single responsibility.
///
/// User operations in Tandoor:
/// - Get current authenticated user
/// - Get user preferences and settings
/// - Update user preferences
///
/// All user management operations require authentication via ClientConfig.
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/api/crud_helpers.{
  execute_get, execute_patch, parse_json_list, parse_json_single,
}
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, ParseError,
}
import meal_planner/tandoor/core/ids.{type UserId, user_id_to_int}
import meal_planner/tandoor/user.{
  type User, type UserPreference, type UserPreferenceUpdateRequest, decode_user,
  encode_user_preference_update, user_preference_decoder,
}

// ============================================================================
// User API Methods
// ============================================================================

/// Get the current authenticated user
///
/// Calls GET /api/user/ which returns the authenticated user's profile.
/// The API returns an array with a single element containing the current user's data.
///
/// # Arguments
/// * `config` - Client configuration with authentication
///
/// # Returns
/// Result with current user or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_current_user(config)
/// ```
pub fn get_current_user(config: ClientConfig) -> Result(User, TandoorError) {
  use resp <- result.try(execute_get(config, "/api/user/", []))
  logger.debug("Tandoor GET /api/user/")

  use users <- result.try(parse_json_list(resp, user_decoder()))

  case users {
    [first, ..] -> Ok(first)
    [] -> Error(ParseError("No current user returned from API"))
  }
}

/// Get user preferences for the current authenticated user
///
/// Calls GET /api/user-preference/ which returns the authenticated user's preferences.
/// The API returns an array with a single element containing the current user's preferences.
///
/// User preferences control various UI and behavioral settings:
/// - Theme (UI theme selection)
/// - Navigation settings (colors, logo visibility)
/// - Measurement units (default ingredient unit, fractions vs decimals)
/// - Meal planning preferences (auto-add to shopping, sharing settings)
/// - Shopping list behavior (auto-sync, recent history)
/// - CSV export settings
/// - And many more customization options
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
/// let result = get_user_preferences(config)
/// ```
pub fn get_user_preferences(
  config: ClientConfig,
) -> Result(UserPreference, TandoorError) {
  use resp <- result.try(execute_get(config, "/api/user-preference/", []))
  logger.debug("Tandoor GET /api/user-preference/")

  use prefs_list <- result.try(parse_json_list(resp, user_preference_decoder()))

  case prefs_list {
    [first, ..] -> Ok(first)
    [] -> Error(ParseError("No preferences returned for current user"))
  }
}

/// Get user preferences for a specific user by user ID
///
/// Calls GET /api/user-preference/{user_id}/ to retrieve preferences for a specific user.
/// Only accessible to authenticated users with appropriate permissions.
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
/// let user_id = ids.user_id_from_int(1)
/// let result = get_user_preferences_by_id(config, user_id: user_id)
/// ```
pub fn get_user_preferences_by_id(
  config: ClientConfig,
  user_id user_id: UserId,
) -> Result(UserPreference, TandoorError) {
  let user_id_int = user_id_to_int(user_id)
  let path = "/api/user-preference/" <> int.to_string(user_id_int) <> "/"

  use resp <- result.try(execute_get(config, path, []))
  logger.debug("Tandoor GET " <> path)

  parse_json_single(resp, user_preference_decoder())
}

/// Update user preferences for a specific user
///
/// Calls PATCH /api/user-preference/{user_id}/ with partial update data.
/// Only provided fields (Some values) will be updated; None values are ignored.
/// This allows partial updates without overwriting unmodified fields.
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
/// let user_id = ids.user_id_from_int(1)
/// let update = UserPreferenceUpdateRequest(
///   theme: Some("FLATLY"),
///   use_fractions: Some(True),
///   ..default_update()
/// )
/// let result = update_user_preferences_by_id(
///   config,
///   user_id: user_id,
///   update: update,
/// )
/// ```
pub fn update_user_preferences_by_id(
  config: ClientConfig,
  user_id user_id: UserId,
  update update: UserPreferenceUpdateRequest,
) -> Result(UserPreference, TandoorError) {
  let user_id_int = user_id_to_int(user_id)
  let path = "/api/user-preference/" <> int.to_string(user_id_int) <> "/"

  let request_body =
    encode_user_preference_update(update)
    |> json.to_string

  use resp <- result.try(execute_patch(config, path, request_body))
  logger.debug("Tandoor PATCH " <> path)

  parse_json_single(resp, user_preference_decoder())
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Create a default empty UserPreferenceUpdateRequest for use as a base
///
/// Useful when you want to update just a few preference fields.
/// All fields are None, so you can use record update syntax to set only
/// the fields you want to change.
///
/// # Example
/// ```gleam
/// let update = default_update()
///   |> fn(u) { UserPreferenceUpdateRequest(..u, theme: Some("FLATLY")) }
/// ```
pub fn default_update() -> UserPreferenceUpdateRequest {
  UserPreferenceUpdateRequest(
    theme: Nil,
    nav_bg_color: Nil,
    nav_text_color: Nil,
    nav_show_logo: Nil,
    default_unit: Nil,
    default_page: Nil,
    use_fractions: Nil,
    use_kj: Nil,
    plan_share: Nil,
    nav_sticky: Nil,
    ingredient_decimals: Nil,
    comments: Nil,
    shopping_auto_sync: Nil,
    mealplan_autoadd_shopping: Nil,
    default_delay: Nil,
    mealplan_autoinclude_related: Nil,
    mealplan_autoexclude_onhand: Nil,
    shopping_share: Nil,
    shopping_recent_days: Nil,
    csv_delim: Nil,
    csv_prefix: Nil,
    filter_to_supermarket: Nil,
    shopping_add_onhand: Nil,
    left_handed: Nil,
    show_step_ingredients: Nil,
  )
}
