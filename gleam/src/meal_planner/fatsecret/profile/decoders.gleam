/// FatSecret SDK Profile decoders
///
/// JSON decoders for Profile API responses.
/// All decoders handle the FatSecret API response format.
import gleam/dynamic/decode
import gleam/option.{type Option}
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

/// Decode optional string from JSON
///
/// FatSecret returns null for unset string values.
fn optional_string() -> decode.Decoder(Option(String)) {
  decode.optional(decode.string)
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
///     "last_weight_comment": "Woohoo!",
///     "height_cm": 175.0,
///     "calorie_goal": 2000,
///     "weight_measure": "Kg",
///     "height_measure": "Cm"
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
  use last_weight_comment <- decode.field(
    "last_weight_comment",
    optional_string(),
  )
  use height_cm <- decode.field("height_cm", optional_float())
  use calorie_goal <- decode.field("calorie_goal", optional_int())
  use weight_measure <- decode.field("weight_measure", optional_string())
  use height_measure <- decode.field("height_measure", optional_string())

  decode.success(types.Profile(
    goal_weight_kg: goal_weight_kg,
    last_weight_kg: last_weight_kg,
    last_weight_date_int: last_weight_date_int,
    last_weight_comment: last_weight_comment,
    height_cm: height_cm,
    calorie_goal: calorie_goal,
    weight_measure: weight_measure,
    height_measure: height_measure,
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
/// Example response from profile.create and profile.get_auth:
/// ```json
/// {
///   "profile": {
///     "auth_token": "639aa3c886b849d2811c09bb640ec2b3",
///     "auth_secret": "cadff7ef247744b4bff48fb2489451fc"
///   }
/// }
/// ```
///
/// CRITICAL: FatSecret returns "auth_token" and "auth_secret", NOT
/// "oauth_token" and "oauth_token_secret" as the field names.
pub fn profile_auth_decoder() -> decode.Decoder(types.ProfileAuth) {
  use auth_token <- decode.field("auth_token", decode.string)
  use auth_secret <- decode.field("auth_secret", decode.string)

  decode.success(types.ProfileAuth(
    auth_token: auth_token,
    auth_secret: auth_secret,
  ))
}

/// Decode ProfileAuth from API response wrapper
///
/// FatSecret wraps the auth in a "profile" field (NOT "profile_auth")
pub fn profile_auth_response_decoder() -> decode.Decoder(types.ProfileAuth) {
  use profile_auth <- decode.field("profile", profile_auth_decoder())
  decode.success(profile_auth)
}
