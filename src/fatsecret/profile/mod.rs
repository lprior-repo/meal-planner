//! `FatSecret` Profile API domain
//!
//! This module provides access to `FatSecret`'s Profile API, which manages user profiles
//! and their authentication credentials. The Profile API is essential for multi-user
//! applications as it creates isolated profiles for each user and provides OAuth
//! credentials for authenticated API access.
//!
//! # Key Concepts
//!
//! ## Profile Creation Flow
//!
//! 1. **Create Profile**: Call `profile.create` with your app's unique user ID
//! 2. **Receive Credentials**: Get OAuth token/secret for that user
//! 3. **Use Credentials**: Make authenticated API calls on behalf of the user
//!
//! ## Profile Data
//!
//! After creating a profile, users can set:
//! - Weight goals and current weight
//! - Height measurements
//! - Daily calorie goals
//! - Preferred measurement units
//!
//! # Key Types
//!
//! - [`Profile`] - User's profile data (goals, metrics, preferences)
//! - [`ProfileAuth`] - OAuth credentials for a user profile
//! - [`ProfileCreateInput`] - Input for creating a new profile
//!
//! # Functions
//!
//! - `create_profile()` - Create a new user profile and get OAuth credentials
//! - `get_profile()` - Retrieve user's profile data (goals, weight, height, etc.)
//! - `get_profile_auth()` - Retrieve OAuth credentials for an existing user
//!
//! # Usage Example
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::core::config::FatSecretConfig;
//! use meal_planner::fatsecret::core::oauth::AccessToken;
//! use meal_planner::fatsecret::profile::{create_profile, get_profile};
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//! let app_token = AccessToken::from_client_credentials(&config).await?;
//!
//! // Create a new user profile
//! let profile_auth = create_profile(
//!     &config,
//!     &app_token,
//!     "my-app-user-123"
//! ).await?;
//!
//! println!("Profile created! OAuth token: {}", profile_auth.auth_token);
//!
//! // Convert ProfileAuth to AccessToken for user-specific API calls
//! let user_token = AccessToken {
//!     token: profile_auth.auth_token.clone(),
//!     secret: profile_auth.auth_secret.clone(),
//! };
//!
//! // Get user's profile data
//! let profile = get_profile(&config, &user_token).await?;
//!
//! if let Some(weight) = profile.last_weight_kg {
//!     println!("User's weight: {} kg", weight);
//! }
//! if let Some(goal) = profile.goal_weight_kg {
//!     println!("Goal weight: {} kg", goal);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Multi-User Pattern
//!
//! For multi-user applications, store `ProfileAuth` credentials in your database
//! keyed by your application's user ID:
//!
//! ```rust,no_run
//! # use meal_planner::fatsecret::core::config::FatSecretConfig;
//! # use meal_planner::fatsecret::core::oauth::AccessToken;
//! # use meal_planner::fatsecret::profile::create_profile;
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! # let config = FatSecretConfig::from_env()?;
//! # let app_token = AccessToken::from_client_credentials(&config).await?;
//! // On user signup
//! let profile_auth = create_profile(&config, &app_token, "user-456").await?;
//! // Store profile_auth.auth_token and profile_auth.auth_secret in your DB
//! // associated with your user ID "user-456"
//!
//! // On subsequent requests
//! // let stored_auth = db.get_profile_auth("user-456");
//! // let user_token = AccessToken {
//! //     token: stored_auth.auth_token,
//! //     secret: stored_auth.auth_secret,
//! // };
//! // Now use user_token for all API calls on behalf of this user
//! # Ok(())
//! # }
//! ```
//!
//! # API Methods
//!
//! This module wraps these `FatSecret` API methods:
//! - `profile.create` - Create a new user profile
//! - `profile.get` - Get user's profile data
//! - `profile.get_auth` - Get OAuth credentials for existing user

pub mod client;
pub mod types;

pub use client::*;
pub use types::*;
