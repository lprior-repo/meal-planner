//! FatSecret SDK Profile domain types
//!
//! This module defines the core types for the FatSecret Profile API.
//! These types are independent from the Tandoor domain and represent
//! FatSecret's profile and user data structures.
//!
//! The Profile API uses 3-legged OAuth authentication and allows
//! creating and managing user profiles in FatSecret.

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
    pub goal_weight_kg: Option<f64>,
    /// Last recorded weight in kilograms
    pub last_weight_kg: Option<f64>,
    /// Last weight date as integer (Unix timestamp or YYYYMMDD format)
    pub last_weight_date_int: Option<i64>,
    /// Comment on last weight entry
    pub last_weight_comment: Option<String>,
    /// Height in centimeters
    pub height_cm: Option<f64>,
    /// Daily calorie goal
    pub calorie_goal: Option<i64>,
    /// Weight measurement unit (e.g., "Kg")
    pub weight_measure: Option<String>,
    /// Height measurement unit (e.g., "Cm")
    pub height_measure: Option<String>,
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
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileAuth {
    /// OAuth access token for the profile (returned as "auth_token" in API)
    pub auth_token: String,
    /// OAuth token secret for signing requests (returned as "auth_secret" in API)
    pub auth_secret: String,
}

/// Input for creating a new profile
///
/// The user_id should be a unique identifier from your application
/// that you can use to retrieve the profile credentials later.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileCreateInput {
    /// Your application's unique user identifier
    pub user_id: String,
}

/// Response from profile.get_auth API
///
/// Returns the OAuth credentials for an existing profile.
/// This is an alias of ProfileAuth but kept separate for API clarity.
pub type ProfileAuthResponse = ProfileAuth;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_profile_serialization() {
        let profile = Profile {
            goal_weight_kg: Some(70.0),
            last_weight_kg: Some(75.5),
            last_weight_date_int: Some(19723),
            last_weight_comment: Some("Morning weight".to_string()),
            height_cm: Some(175.0),
            calorie_goal: Some(2000),
            weight_measure: Some("Kg".to_string()),
            height_measure: Some("Cm".to_string()),
        };

        let json = serde_json::to_string(&profile).unwrap();
        let deserialized: Profile = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.goal_weight_kg, Some(70.0));
    }

    #[test]
    fn test_profile_auth_serialization() {
        let auth = ProfileAuth {
            auth_token: "token123".to_string(),
            auth_secret: "secret456".to_string(),
        };

        let json = serde_json::to_string(&auth).unwrap();
        let deserialized: ProfileAuth = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.auth_token, "token123");
    }
}
