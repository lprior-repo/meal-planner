/// Tandoor User Module
///
/// Provides user-related types (User, UserPreference, UserFileView) along with
/// JSON encoding/decoding and user preference API operations.
///
/// Users in Tandoor are readonly accounts managed by the authentication system.
/// User preferences are customizable settings that control UI theme, units,
/// meal planning, shopping list behavior, and more.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_get, execute_patch, parse_json_list, parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{
  type UserId, user_id_decoder, user_id_to_int,
}

// ============================================================================
// Types
// ============================================================================

/// Tandoor user account
///
/// Represents a user in the Tandoor system. This is a readonly type - user
/// data is managed by Tandoor's authentication system.
pub type User {
  User(
    /// Unique user ID
    id: UserId,
    /// Username (readonly, required, max 150 chars)
    /// Letters, digits and @/./+/-/_ only
    username: String,
    /// User's first name (max 150 chars)
    first_name: String,
    /// User's last name (max 150 chars)
    last_name: String,
    /// Display name (readonly, computed from first/last or username)
    display_name: String,
    /// Whether user can access admin site (readonly)
    is_staff: Bool,
    /// Whether user has all permissions (readonly)
    is_superuser: Bool,
    /// Whether user account is active (readonly)
    is_active: Bool,
  )
}

/// View of a user-uploaded file (readonly)
///
/// Used for displaying uploaded files like profile avatars in user preferences.
/// All fields are readonly - file management happens through separate upload APIs.
pub type UserFileView {
  UserFileView(
    /// Unique file ID
    id: Int,
    /// File name (max 128 chars)
    name: String,
    /// Download URL for the file
    file_download: String,
    /// Preview/thumbnail URL
    preview: String,
    /// File size in kilobytes
    file_size_kb: Int,
    /// User who created/uploaded the file
    created_by: User,
    /// ISO 8601 timestamp when file was created
    created_at: String,
  )
}

/// User preferences and settings
///
/// Controls various aspects of the Tandoor UI and behavior for a specific user.
/// Most fields have defaults and can be updated by the user.
pub type UserPreference {
  UserPreference(
    /// The user these preferences belong to (readonly)
    user: User,
    /// Optional profile image (nullable)
    image: Option(UserFileView),
    /// UI theme (e.g., "BOOTSTRAP", "FLATLY")
    theme: String,
    /// Navigation bar background color (hex, max 8 chars including #)
    nav_bg_color: String,
    /// Navigation bar text color ("LIGHT" or "DARK")
    nav_text_color: String,
    /// Whether to show logo in navigation bar
    nav_show_logo: Bool,
    /// Default unit for ingredients (max 32 chars, e.g., "g", "ml")
    default_unit: String,
    /// Default page to show on login (e.g., "SEARCH", "PLAN")
    default_page: String,
    /// Whether to use fractions for measurements (e.g., 1/2 cup)
    use_fractions: Bool,
    /// Whether to use kilojoules instead of calories
    use_kj: Bool,
    /// Users to share meal plans with (nullable)
    plan_share: Option(List(User)),
    /// Whether navigation bar should stick to top when scrolling
    nav_sticky: Bool,
    /// Number of decimal places for ingredient amounts
    ingredient_decimals: Int,
    /// Whether to enable comments
    comments: Bool,
    /// Auto-sync interval for shopping list (seconds)
    shopping_auto_sync: Int,
    /// Whether to automatically add meal plan items to shopping list
    mealplan_autoadd_shopping: Bool,
    /// Default food inheritance behavior (readonly, e.g., "ENABLED", "DISABLED")
    food_inherit_default: String,
    /// Default delay for recipe steps (minutes, -10000 to 10000 exclusive)
    default_delay: Float,
    /// Whether to auto-include related recipes in meal plan
    mealplan_autoinclude_related: Bool,
    /// Whether to auto-exclude items marked as "on hand" from meal plan
    mealplan_autoexclude_onhand: Bool,
    /// Users to share shopping lists with (nullable)
    shopping_share: Option(List(User)),
    /// How many days of recent shopping history to show
    shopping_recent_days: Int,
    /// CSV delimiter character (max 2 chars, e.g., ",", ";")
    csv_delim: String,
    /// CSV prefix string (max 10 chars)
    csv_prefix: String,
    /// Whether to filter shopping list items to selected supermarket
    filter_to_supermarket: Bool,
    /// Whether to add "on hand" items to shopping list
    shopping_add_onhand: Bool,
    /// Whether UI should be optimized for left-handed use
    left_handed: Bool,
    /// Whether to show ingredients in each recipe step
    show_step_ingredients: Bool,
    /// Whether any foods have children (readonly, for optimization)
    food_children_exist: Bool,
  )
}

/// Request to update user preferences
///
/// Contains only the writable fields that can be updated via PATCH.
/// Readonly fields (user, food_inherit_default, food_children_exist) are excluded.
/// All fields are optional to support partial updates.
pub type UserPreferenceUpdateRequest {
  UserPreferenceUpdateRequest(
    theme: Option(String),
    nav_bg_color: Option(String),
    nav_text_color: Option(String),
    nav_show_logo: Option(Bool),
    default_unit: Option(String),
    default_page: Option(String),
    use_fractions: Option(Bool),
    use_kj: Option(Bool),
    plan_share: Option(List(Int)),
    nav_sticky: Option(Bool),
    ingredient_decimals: Option(Int),
    comments: Option(Bool),
    shopping_auto_sync: Option(Int),
    mealplan_autoadd_shopping: Option(Bool),
    default_delay: Option(Float),
    mealplan_autoinclude_related: Option(Bool),
    mealplan_autoexclude_onhand: Option(Bool),
    shopping_share: Option(List(Int)),
    shopping_recent_days: Option(Int),
    csv_delim: Option(String),
    csv_prefix: Option(String),
    filter_to_supermarket: Option(Bool),
    shopping_add_onhand: Option(Bool),
    left_handed: Option(Bool),
    show_step_ingredients: Option(Bool),
  )
}

// ============================================================================
// Decoders
// ============================================================================

/// User decoder - returns a Decoder for use with decode.field, decode.run, etc.
///
/// This is the core decoder that can be composed with other decoders.
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "username": "admin",
///   "first_name": "Admin",
///   "last_name": "User",
///   "display_name": "Admin User",
///   "is_staff": true,
///   "is_superuser": true,
///   "is_active": true
/// }
/// ```
pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", user_id_decoder())
  use username <- decode.field("username", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.string)
  use display_name <- decode.field("display_name", decode.string)
  use is_staff <- decode.field("is_staff", decode.bool)
  use is_superuser <- decode.field("is_superuser", decode.bool)
  use is_active <- decode.field("is_active", decode.bool)

  decode.success(User(
    id: id,
    username: username,
    first_name: first_name,
    last_name: last_name,
    display_name: display_name,
    is_staff: is_staff,
    is_superuser: is_superuser,
    is_active: is_active,
  ))
}

/// Decode a User from JSON - convenience wrapper
///
/// Decodes the complete User object with all fields from Tandoor API.
/// All fields are required in the API response.
pub fn decode_user(
  json: dynamic.Dynamic,
) -> Result(User, List(decode.DecodeError)) {
  decode.run(json, user_decoder())
}

/// UserFileView decoder - returns a Decoder for use with decode.field, decode.run, etc.
///
/// Example JSON:
/// ```json
/// {
///   "id": 10,
///   "name": "avatar.jpg",
///   "file_download": "https://example.com/avatar.jpg",
///   "preview": "https://example.com/avatar_preview.jpg",
///   "file_size_kb": 150,
///   "created_by": { ...user object... },
///   "created_at": "2025-12-01T10:30:00Z"
/// }
/// ```
pub fn user_file_view_decoder() -> decode.Decoder(UserFileView) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use file_download <- decode.field("file_download", decode.string)
  use preview <- decode.field("preview", decode.string)
  use file_size_kb <- decode.field("file_size_kb", decode.int)
  use created_by <- decode.field("created_by", user_decoder())
  use created_at <- decode.field("created_at", decode.string)

  decode.success(UserFileView(
    id: id,
    name: name,
    file_download: file_download,
    preview: preview,
    file_size_kb: file_size_kb,
    created_by: created_by,
    created_at: created_at,
  ))
}

/// Decode a UserFileView from JSON - convenience wrapper
///
/// Decodes a readonly view of a user-uploaded file.
/// All fields are required as they come from the API.
pub fn decode_user_file_view(
  json: dynamic.Dynamic,
) -> Result(UserFileView, List(decode.DecodeError)) {
  decode.run(json, user_file_view_decoder())
}

/// UserPreference decoder - returns a Decoder for use with decode.field, decode.run, etc.
pub fn user_preference_decoder() -> decode.Decoder(UserPreference) {
  use user <- decode.field("user", user_decoder())
  use image <- decode.optional_field(
    "image",
    None,
    decode.optional(user_file_view_decoder()),
  )
  use theme <- decode.field("theme", decode.string)
  use nav_bg_color <- decode.field("nav_bg_color", decode.string)
  use nav_text_color <- decode.field("nav_text_color", decode.string)
  use nav_show_logo <- decode.field("nav_show_logo", decode.bool)
  use default_unit <- decode.field("default_unit", decode.string)
  use default_page <- decode.field("default_page", decode.string)
  use use_fractions <- decode.field("use_fractions", decode.bool)
  use use_kj <- decode.field("use_kj", decode.bool)
  use plan_share <- decode.optional_field(
    "plan_share",
    None,
    decode.optional(decode.list(user_decoder())),
  )
  use nav_sticky <- decode.field("nav_sticky", decode.bool)
  use ingredient_decimals <- decode.field("ingredient_decimals", decode.int)
  use comments <- decode.field("comments", decode.bool)
  use shopping_auto_sync <- decode.field("shopping_auto_sync", decode.int)
  use mealplan_autoadd_shopping <- decode.field(
    "mealplan_autoadd_shopping",
    decode.bool,
  )
  use food_inherit_default <- decode.field(
    "food_inherit_default",
    decode.string,
  )
  use default_delay <- decode.field("default_delay", decode.float)
  use mealplan_autoinclude_related <- decode.field(
    "mealplan_autoinclude_related",
    decode.bool,
  )
  use mealplan_autoexclude_onhand <- decode.field(
    "mealplan_autoexclude_onhand",
    decode.bool,
  )
  use shopping_share <- decode.optional_field(
    "shopping_share",
    None,
    decode.optional(decode.list(user_decoder())),
  )
  use shopping_recent_days <- decode.field("shopping_recent_days", decode.int)
  use csv_delim <- decode.field("csv_delim", decode.string)
  use csv_prefix <- decode.field("csv_prefix", decode.string)
  use filter_to_supermarket <- decode.field(
    "filter_to_supermarket",
    decode.bool,
  )
  use shopping_add_onhand <- decode.field("shopping_add_onhand", decode.bool)
  use left_handed <- decode.field("left_handed", decode.bool)
  use show_step_ingredients <- decode.field(
    "show_step_ingredients",
    decode.bool,
  )
  use food_children_exist <- decode.field("food_children_exist", decode.bool)

  decode.success(UserPreference(
    user: user,
    image: image,
    theme: theme,
    nav_bg_color: nav_bg_color,
    nav_text_color: nav_text_color,
    nav_show_logo: nav_show_logo,
    default_unit: default_unit,
    default_page: default_page,
    use_fractions: use_fractions,
    use_kj: use_kj,
    plan_share: plan_share,
    nav_sticky: nav_sticky,
    ingredient_decimals: ingredient_decimals,
    comments: comments,
    shopping_auto_sync: shopping_auto_sync,
    mealplan_autoadd_shopping: mealplan_autoadd_shopping,
    food_inherit_default: food_inherit_default,
    default_delay: default_delay,
    mealplan_autoinclude_related: mealplan_autoinclude_related,
    mealplan_autoexclude_onhand: mealplan_autoexclude_onhand,
    shopping_share: shopping_share,
    shopping_recent_days: shopping_recent_days,
    csv_delim: csv_delim,
    csv_prefix: csv_prefix,
    filter_to_supermarket: filter_to_supermarket,
    shopping_add_onhand: shopping_add_onhand,
    left_handed: left_handed,
    show_step_ingredients: show_step_ingredients,
    food_children_exist: food_children_exist,
  ))
}

/// Decode a UserPreference from JSON - convenience wrapper
pub fn decode_user_preference(
  json: dynamic.Dynamic,
) -> Result(UserPreference, List(decode.DecodeError)) {
  decode.run(json, user_preference_decoder())
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode UserPreferenceUpdateRequest to JSON for API updates
///
/// Converts only the provided (Some) fields to JSON for partial updates.
/// None values are omitted from the request.
pub fn encode_user_preference_update(req: UserPreferenceUpdateRequest) -> Json {
  let fields =
    []
    |> add_optional_string_field("theme", req.theme)
    |> add_optional_string_field("nav_bg_color", req.nav_bg_color)
    |> add_optional_string_field("nav_text_color", req.nav_text_color)
    |> add_optional_bool_field("nav_show_logo", req.nav_show_logo)
    |> add_optional_string_field("default_unit", req.default_unit)
    |> add_optional_string_field("default_page", req.default_page)
    |> add_optional_bool_field("use_fractions", req.use_fractions)
    |> add_optional_bool_field("use_kj", req.use_kj)
    |> add_optional_int_list_field("plan_share", req.plan_share)
    |> add_optional_bool_field("nav_sticky", req.nav_sticky)
    |> add_optional_int_field("ingredient_decimals", req.ingredient_decimals)
    |> add_optional_bool_field("comments", req.comments)
    |> add_optional_int_field("shopping_auto_sync", req.shopping_auto_sync)
    |> add_optional_bool_field(
      "mealplan_autoadd_shopping",
      req.mealplan_autoadd_shopping,
    )
    |> add_optional_float_field("default_delay", req.default_delay)
    |> add_optional_bool_field(
      "mealplan_autoinclude_related",
      req.mealplan_autoinclude_related,
    )
    |> add_optional_bool_field(
      "mealplan_autoexclude_onhand",
      req.mealplan_autoexclude_onhand,
    )
    |> add_optional_int_list_field("shopping_share", req.shopping_share)
    |> add_optional_int_field("shopping_recent_days", req.shopping_recent_days)
    |> add_optional_string_field("csv_delim", req.csv_delim)
    |> add_optional_string_field("csv_prefix", req.csv_prefix)
    |> add_optional_bool_field(
      "filter_to_supermarket",
      req.filter_to_supermarket,
    )
    |> add_optional_bool_field("shopping_add_onhand", req.shopping_add_onhand)
    |> add_optional_bool_field("left_handed", req.left_handed)
    |> add_optional_bool_field(
      "show_step_ingredients",
      req.show_step_ingredients,
    )

  json.object(fields)
}

// Helper functions for building optional fields

fn add_optional_string_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(String),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.string(v)), ..fields]
    None -> fields
  }
}

fn add_optional_bool_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(Bool),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.bool(v)), ..fields]
    None -> fields
  }
}

fn add_optional_int_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(Int),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.int(v)), ..fields]
    None -> fields
  }
}

fn add_optional_float_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(Float),
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(name, json.float(v)), ..fields]
    None -> fields
  }
}

fn add_optional_int_list_field(
  fields: List(#(String, Json)),
  name: String,
  value: Option(List(Int)),
) -> List(#(String, Json)) {
  case value {
    Some(ids) -> [#(name, json.array(ids, json.int)), ..fields]
    None -> fields
  }
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

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
  use resp <- result.try(execute_get(config, "/api/user-preference/", []))

  use prefs_list <- result.try(parse_json_list(
    resp,
    user_preference_decoder(),
  ))

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
/// let user_id = ids.user_id_from_int(1)
/// let result = get_user_preferences(config, user_id: user_id)
/// ```
pub fn get_user_preferences(
  config: ClientConfig,
  user_id user_id: UserId,
) -> Result(UserPreference, TandoorError) {
  let user_id_int = user_id_to_int(user_id)
  let path = "/api/user-preference/" <> int.to_string(user_id_int) <> "/"

  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, user_preference_decoder())
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
/// let user_id = ids.user_id_from_int(1)
/// let update = UserPreferenceUpdateRequest(
///   theme: Some("FLATLY"),
///   use_fractions: Some(True),
///   ..default_update()
/// )
/// let result = update_user_preferences(config, user_id: user_id, update: update)
/// ```
pub fn update_user_preferences(
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
  parse_json_single(resp, user_preference_decoder())
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
/// // Then update
/// let update = UserPreferenceUpdateRequest(theme: Some("FLATLY"), ..default_update())
/// update_preferences(config, user_id: current.user.id, update: update)
/// ```
pub fn update_preferences(
  config: ClientConfig,
  user_id user_id: UserId,
  update update: UserPreferenceUpdateRequest,
) -> Result(UserPreference, TandoorError) {
  update_user_preferences(config, user_id: user_id, update: update)
}
