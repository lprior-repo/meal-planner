//! `FatSecret` Profile API data types
//!
//! This module defines the data structures for `FatSecret`'s Profile API.
//! These types represent user profiles, authentication credentials, and API responses.
//!
//! # Key Types
//!
//! ## Core Types
//!
//! - [`Profile`] - User's profile data including goals, metrics, and preferences
//! - [`ProfileAuth`] - OAuth credentials for a user profile
//! - [`ProfileCreateInput`] - Input for creating a new profile
//!
//! ## Response Wrappers
//!
//! - [`ProfileResponse`] - Wrapper for `profile.get` API response
//! - [`ProfileAuthResponseWrapper`] - Wrapper for `profile.create` and `profile.get_auth` responses
//!
//! # Profile Data
//!
//! The [`Profile`] struct contains user goals and metrics:
//!
//! - **Weight tracking**: `last_weight_kg`, `last_weight_date_int`, `last_weight_comment`
//! - **Goals**: `goal_weight_kg`, `calorie_goal`
//! - **Measurements**: `height_cm`, `weight_measure`, `height_measure`
//!
//! All fields are `Option<T>` because the API returns `null` for unset values.
//!
//! # Authentication Flow
//!
//! When you create a profile or retrieve auth credentials, `FatSecret` returns a [`ProfileAuth`]
//! containing OAuth credentials:
//!
//! ```json
//! {
//!   "profile": {
//!     "auth_token": "abc123...",
//!     "auth_secret": "def456..."
//!   }
//! }
//! ```
//!
//! These credentials are used for all subsequent authenticated API calls on behalf of that user.
//!
//! # Usage Examples
//!
//! ## Creating a Profile
//!
//! ```rust
//! use meal_planner::fatsecret::profile::types::ProfileCreateInput;
//!
//! let input = ProfileCreateInput {
//!     user_id: "my-app-user-123".to_string(),
//! };
//!
//! // Pass to create_profile function
//! // let auth = create_profile(&config, &token, &input.user_id).await?;
//! ```
//!
//! ## Working with Profile Data
//!
//! ```rust
//! use meal_planner::fatsecret::profile::types::Profile;
//!
//! # fn example(profile: Profile) {
//! // Check if user has set weight goals
//! if let Some(goal_kg) = profile.goal_weight_kg {
//!     if let Some(current_kg) = profile.last_weight_kg {
//!         let remaining = goal_kg - current_kg;
//!         println!("Progress: {:.1} kg to goal", remaining.abs());
//!     }
//! }
//!
//! // Check calorie goal
//! if let Some(calories) = profile.calorie_goal {
//!     println!("Daily calorie target: {} kcal", calories);
//! }
//!
//! // Display height in preferred units
//! if let Some(height_cm) = profile.height_cm {
//!     let unit = profile.height_measure.as_deref().unwrap_or("cm");
//!     println!("Height: {} {}", height_cm, unit);
//! }
//! # }
//! ```
//!
//! ## Converting `ProfileAuth` to `AccessToken`
//!
//! ```rust
//! use meal_planner::fatsecret::core::oauth::`AccessToken`;
//! use meal_planner::fatsecret::profile::types::ProfileAuth;
//!
//! # fn example(profile_auth: ProfileAuth) {
//! // Convert ProfileAuth to `AccessToken` for API calls
//! let user_token = `AccessToken` {
//!     token: profile_auth.auth_token,
//!     secret: profile_auth.auth_secret,
//! };
//!
//! // Now use user_token for authenticated API calls
//! // let diary = get_food_entries(&config, &user_token, date).await?;
//! # }
//! ```
//!
//! # Serialization
//!
//! All types implement `Serialize` and `Deserialize` for easy storage and retrieval:
//!
//! ```rust
//! use meal_planner::fatsecret::profile::types::ProfileAuth;
//!
//! # fn example(profile_auth: ProfileAuth) -> Result<(), serde_json::Error> {
//! // Serialize for storage
//! let json = serde_json::to_string(&profile_auth)?;
//! // Store in database...
//!
//! // Deserialize when retrieving
//! let loaded: ProfileAuth = serde_json::from_str(&json)?;
//! # Ok(())
//! # }
//! ```
//!
//! # Field Parsing
//!
//! This module uses custom deserializers from `core::serde_utils` to handle
//! `FatSecret`'s flexible numeric formats (strings or numbers):
//!
//! - `deserialize_optional_flexible_float` - Handles `"1.5"` or `1.5` → `Option<f64>`
//! - `deserialize_optional_flexible_i64` - Handles `"123"` or `123` → `Option<i64>`

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

/// Profile authentication tokens from profile.create and `profile.get_auth` APIs
///
/// After creating a profile or retrieving auth credentials, `FatSecret` returns
/// OAuth credentials that can be used for all subsequent authenticated API calls.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileAuth {
    /// OAuth access token for the profile (returned as "`auth_token`" in API)
    pub auth_token: String,
    /// OAuth token secret for signing requests (returned as "`auth_secret`" in API)
    pub auth_secret: String,
}

/// Wrapper for `ProfileAuth` response
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

/// Response from `profile.get_auth` API
pub type ProfileAuthResponse = ProfileAuth;
