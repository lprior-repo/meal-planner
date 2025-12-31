//! FatSecret Exercise domain - manage exercise tracking and diary entries.
//!
//! This module provides a complete interface to FatSecret's exercise APIs, supporting
//! both public exercise database lookups (2-legged OAuth) and user diary operations
//! (3-legged OAuth with user consent).
//!
//! # Overview
//!
//! The exercise domain is organized into two main areas:
//!
//! - **Public Exercise Database**: Look up exercises by ID, get calorie burn rates
//! - **User Exercise Diary**: Log exercises, track duration/calories, view summaries
//!
//! # Key Types
//!
//! - [`Exercise`] - Exercise details from the public database (name, calories/hour)
//! - [`ExerciseEntry`] - User's logged exercise session (duration, calories burned, date)
//! - [`ExerciseId`] / [`ExerciseEntryId`] - Opaque, type-safe IDs
//! - [`ExerciseMonthSummary`] - Daily breakdown of exercise for a month
//!
//! # Authentication
//!
//! - **2-legged OAuth** (public database): Only requires [`FatSecretConfig`]
//! - **3-legged OAuth** (user diary): Requires [`FatSecretConfig`] + [`AccessToken`]
//!
//! # Usage Example
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::exercise::{
//!     get_exercise, create_exercise_entry, get_exercise_entries,
//!     ExerciseId, ExerciseEntryInput,
//! };
//! use meal_planner::fatsecret::core::config::FatSecretConfig;
//! use meal_planner::fatsecret::core::oauth::AccessToken;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//! let access_token = AccessToken::new("user_token", "user_secret");
//!
//! // Look up exercise details (2-legged - public database)
//! let exercise_id = ExerciseId::new("12345");
//! let exercise = get_exercise(&config, &exercise_id).await?;
//! println!("Exercise: {} burns {} cal/hour",
//!          exercise.exercise_name, exercise.calories_per_hour);
//!
//! // Log an exercise session (3-legged - user diary)
//! let input = ExerciseEntryInput {
//!     exercise_id,
//!     duration_min: 30,
//!     date_int: 19723, // Days since Unix epoch (2024-01-01)
//! };
//! let entry_id = create_exercise_entry(&config, &access_token, input).await?;
//!
//! // Retrieve today's exercise entries
//! let entries = get_exercise_entries(&config, &access_token, 19723).await?;
//! for entry in entries {
//!     println!("{}: {} min, {} cal",
//!              entry.exercise_name, entry.duration_min, entry.calories);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Date Format
//!
//! FatSecret uses `date_int` - days since Unix epoch (1970-01-01). Helper functions
//! are provided in [`types`] module:
//!
//! - [`date_to_int`] - Convert "YYYY-MM-DD" → date_int
//! - [`int_to_date`] - Convert date_int → "YYYY-MM-DD"
//!
//! # See Also
//!
//! - [`client`] - HTTP client functions for exercise APIs
//! - [`types`] - Type definitions and serialization logic
//! - [FatSecret Exercise API docs](https://platform.fatsecret.com/api/Default.aspx?screen=rapiref2&method=exercise_entries.get.v2)

pub mod client;
pub mod types;

#[cfg(test)]
mod tests;

pub use client::*;
pub use types::*;
