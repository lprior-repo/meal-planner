/// FatSecret SDK Profile decoders
///
/// JSON decoders for Profile API responses.
/// All decoders handle the FatSecret API response format.
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import meal_planner/fatsecret/profile/types

// ============================================================================
// Profile Decoders
// ============================================================================

/// Decode optional float from JSON
///
/// FatSecret returns null for unset numeric values.
fn optional_float() -> decode.Decoder(Option(Float)) {
  decode.optional(decode.float)
}

/// Decode optional int from JSON
///
/// FatSecret returns null for unset numeric values.
fn optional_int() -> decode.Decoder(Option(Int)) {
  decode.optional(decode.int)
}

/// Decode Profile from JSON
///
/// Example response:
/// ```json
/// {
///   "profile": {
///     "goal_weight_kg": 75.5,
///     "last_weight_kg": 80.2,
///     "last_weight_date_int": 20251214,
///     "height_cm": 175.0,
///     "calorie_goal": 2000
///   }
/// }
/// ```
pub fn profile_decoder() -> decode.Decoder(types.Profile) {
  use goal_weight_kg <- decode.field("goal_weight_kg", optional_float())
  use last_weight_kg <- decode.field("last_weight_kg", optional_float())
  use last_weight_date_int <- decode.field(
    "last_weight_date_int",
    optional_int(),
  )
  use height_cm <- decode.field("height_cm", optional_float())
  use calorie_goal <- decode.field("calorie_goal", optional_int())

  decode.success(types.Profile(
    goal_weight_kg: goal_weight_kg,
    last_weight_kg: last_weight_kg,
    last_weight_date_int: last_weight_date_int,
    height_cm: height_cm,
    calorie_goal: calorie_goal,
  ))
}

/// Decode Profile from API response wrapper
///
/// FatSecret wraps the profile in a "profile" field
pub fn profile_response_decoder() -> decode.Decoder(types.Profile) {
  use profile <- decode.field("profile", profile_decoder())
  decode.success(profile)
}

// ============================================================================
// Profile Auth Decoders
// ============================================================================

/// Decode ProfileAuth from JSON
///
/// Example response from profile.create:
/// ```json
/// {
///   "profile_auth": {
///     "oauth_token": "abc123",
///     "oauth_token_secret": "xyz789"
///   }
/// }
/// ```
pub fn profile_auth_decoder() -> decode.Decoder(types.ProfileAuth) {
  use oauth_token <- decode.field("oauth_token", decode.string)
  use oauth_token_secret <- decode.field("oauth_token_secret", decode.string)

  decode.success(types.ProfileAuth(
    oauth_token: oauth_token,
    oauth_token_secret: oauth_token_secret,
  ))
}

/// Decode ProfileAuth from API response wrapper
///
/// FatSecret wraps the auth in a "profile_auth" field
pub fn profile_auth_response_decoder() -> decode.Decoder(types.ProfileAuth) {
  use profile_auth <- decode.field("profile_auth", profile_auth_decoder())
  decode.success(profile_auth)
}
