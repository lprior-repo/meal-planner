//! FatSecret Profile domain types

use crate::fatsecret::core::serde_utils::{
    deserialize_optional_flexible_float, deserialize_optional_flexible_i64,
};
use serde::{Deserialize, Serialize};

// ============================================================================
// Profile Data Types
// ============================================================================

/// User profile information from profile.get API
///
/// Contains user's goals and current metrics. All fields are optional
/// as the API returns null for unset values.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Profile {
    /// Goal weight in kilograms
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub goal_weight_kg: Option<f64>,
    /// Last recorded weight in kilograms
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub last_weight_kg: Option<f64>,
    /// Last weight date as integer (Unix timestamp or YYYYMMDD format)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_i64")]
    pub last_weight_date_int: Option<i64>,
    /// Comment on last weight entry
    pub last_weight_comment: Option<String>,
    /// Height in centimeters
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub height_cm: Option<f64>,
    /// Daily calorie goal
    #[serde(default, deserialize_with = "deserialize_optional_flexible_i64")]
    pub calorie_goal: Option<i64>,
    /// Weight measurement unit (e.g., "Kg")
    pub weight_measure: Option<String>,
    /// Height measurement unit (e.g., "Cm")
    pub height_measure: Option<String>,
}

/// Wrapper for Profile response
#[derive(Debug, Deserialize)]
pub struct ProfileResponse {
    /// The user's profile information
    pub profile: Profile,
}

// ============================================================================
// Profile Authentication Types
// ============================================================================

/// Profile authentication tokens from profile.create and profile.get_auth APIs
///
/// After creating a profile or retrieving auth credentials, FatSecret returns
/// OAuth credentials that can be used for all subsequent authenticated API calls.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileAuth {
    /// OAuth access token for the profile (returned as "auth_token" in API)
    pub auth_token: String,
    /// OAuth token secret for signing requests (returned as "auth_secret" in API)
    pub auth_secret: String,
}

/// Wrapper for ProfileAuth response
#[derive(Debug, Deserialize)]
pub struct ProfileAuthResponseWrapper {
    /// The user's profile authentication credentials
    pub profile: ProfileAuth,
}

/// Input for creating a new profile
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileCreateInput {
    /// Your application's unique user identifier
    pub user_id: String,
}

/// Response from profile.get_auth API
pub type ProfileAuthResponse = ProfileAuth;
