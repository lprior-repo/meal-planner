/// FatSecret SDK Profile domain types
///
/// This module defines the core types for the FatSecret Profile API.
/// These types are independent from the Tandoor domain and represent
/// FatSecret's profile and user data structures.
///
/// The Profile API uses 3-legged OAuth authentication and allows
/// creating and managing user profiles in FatSecret.
import gleam/option.{type Option}

// ============================================================================
// Profile Data Types
// ============================================================================

/// User profile information from profile.get API
///
/// Contains user's goals and current metrics. All fields are optional
/// as the API returns null for unset values.
pub type Profile {
  Profile(
    /// Goal weight in kilograms
    goal_weight_kg: Option(Float),
    /// Last recorded weight in kilograms
    last_weight_kg: Option(Float),
    /// Last weight date as integer (Unix timestamp or YYYYMMDD format)
    last_weight_date_int: Option(Int),
    /// Comment on last weight entry
    last_weight_comment: Option(String),
    /// Height in centimeters
    height_cm: Option(Float),
    /// Daily calorie goal
    calorie_goal: Option(Int),
    /// Weight measurement unit (e.g., "Kg")
    weight_measure: Option(String),
    /// Height measurement unit (e.g., "Cm")
    height_measure: Option(String),
  )
}

// ============================================================================
// Profile Authentication Types
// ============================================================================

/// Profile authentication tokens from profile.create and profile.get_auth APIs
///
/// After creating a profile or retrieving auth credentials, FatSecret returns
/// OAuth credentials that can be used for all subsequent authenticated API calls.
/// These should be stored securely in your application.
///
/// IMPORTANT: The API returns these as "auth_token" and "auth_secret" in JSON,
/// but they serve the same purpose as OAuth tokens.
pub type ProfileAuth {
  ProfileAuth(
    /// OAuth access token for the profile (returned as "auth_token" in API)
    auth_token: String,
    /// OAuth token secret for signing requests (returned as "auth_secret" in API)
    auth_secret: String,
  )
}

/// Input for creating a new profile
///
/// The user_id should be a unique identifier from your application
/// that you can use to retrieve the profile credentials later.
pub type ProfileCreateInput {
  ProfileCreateInput(
    /// Your application's unique user identifier
    user_id: String,
  )
}

/// Response from profile.get_auth API
///
/// Returns the OAuth credentials for an existing profile.
/// This is an alias of ProfileAuth but kept separate for
/// API clarity.
pub type ProfileAuthResponse =
  ProfileAuth
