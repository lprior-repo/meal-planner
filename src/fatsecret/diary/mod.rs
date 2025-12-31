//! FatSecret Food Diary API
//!
//! This module provides a complete interface to the FatSecret Food Diary API,
//! allowing authenticated users to create, retrieve, update, and delete food
//! entries in their daily nutrition diary.
//!
//! # Overview
//!
//! The diary module enables:
//! - Creating food entries from the FatSecret database or custom nutrition values
//! - Retrieving individual entries or full day summaries
//! - Editing portion sizes and meal assignments
//! - Deleting entries
//! - Getting monthly nutrition summaries
//! - Copying entries between dates
//! - Managing meal templates
//!
//! # Authentication
//!
//! All operations require **3-legged OAuth** authentication. Users must have
//! authorized your application via OAuth 1.0a to access their diary data.
//!
//! # Key Types
//!
//! - [`FoodEntry`] - A complete food diary entry with nutrition data
//! - [`FoodEntryInput`] - Input for creating new entries (from database or custom)
//! - [`FoodEntryUpdate`] - Updates for existing entries (portions, meal type)
//! - [`FoodEntryId`] - Type-safe wrapper for entry identifiers
//! - [`MealType`] - Breakfast, Lunch, Dinner, or Snack
//! - [`MonthSummary`] - Aggregated nutrition totals for a month
//! - [`DaySummary`] - Aggregated nutrition totals for a single day
//!
//! # Date Handling
//!
//! The FatSecret API uses `date_int` (days since Unix epoch: 1970-01-01) for all
//! date operations. Use the provided conversion functions:
//! - [`date_to_int`] - Convert "YYYY-MM-DD" to date_int
//! - [`int_to_date`] - Convert date_int back to "YYYY-MM-DD"
//!
//! # Usage Example
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::{FatSecretConfig, AccessToken};
//! use meal_planner::fatsecret::diary::{
//!     create_food_entry, get_food_entries, get_month_summary,
//!     FoodEntryInput, MealType, date_to_int,
//! };
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! // Setup (config and token obtained via OAuth flow)
//! let config = FatSecretConfig::from_env()?;
//! let token = AccessToken::new("user_token", "user_secret");
//!
//! // Convert today's date to FatSecret format
//! let today = date_to_int("2024-01-15")?;
//!
//! // Create a food entry from the FatSecret database
//! let entry = FoodEntryInput::FromFood {
//!     food_id: "12345".to_string(),
//!     food_entry_name: "Banana".to_string(),
//!     serving_id: "67890".to_string(),
//!     number_of_units: 1.0,
//!     meal: MealType::Breakfast,
//!     date_int: today,
//! };
//!
//! let entry_id = create_food_entry(&config, &token, entry).await?;
//! println!("Created entry: {}", entry_id);
//!
//! // Get all entries for the day
//! let entries = get_food_entries(&config, &token, today).await?;
//! for entry in entries {
//!     println!("{}: {} calories", entry.food_entry_name, entry.calories);
//! }
//!
//! // Get monthly summary
//! let summary = get_month_summary(&config, &token, today).await?;
//! println!("Month: {}/{}", summary.month, summary.year);
//! for day in summary.days {
//!     println!("  Day {}: {} calories", day.date_int, day.calories);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Creating Custom Entries
//!
//! For foods not in the FatSecret database, create custom entries:
//!
//! ```rust,no_run
//! # use meal_planner::fatsecret::{FatSecretConfig, AccessToken};
//! # use meal_planner::fatsecret::diary::{create_food_entry, FoodEntryInput, MealType, date_to_int};
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! # let config = FatSecretConfig::from_env()?;
//! # let token = AccessToken::new("user_token", "user_secret");
//! # let today = date_to_int("2024-01-15")?;
//! let custom_entry = FoodEntryInput::Custom {
//!     food_entry_name: "Homemade Protein Shake".to_string(),
//!     serving_description: "1 scoop + 300ml milk".to_string(),
//!     number_of_units: 1.0,
//!     meal: MealType::Snack,
//!     date_int: today,
//!     calories: 250.0,
//!     carbohydrate: 15.0,  // grams
//!     protein: 30.0,       // grams
//!     fat: 5.0,            // grams
//! };
//!
//! create_food_entry(&config, &token, custom_entry).await?;
//! # Ok(())
//! # }
//! ```
//!
//! # Error Handling
//!
//! All functions return `Result<T, FatSecretError>` which includes:
//! - Network errors (timeout, connection failed)
//! - Authentication errors (invalid/revoked token)
//! - API errors (invalid parameters, rate limits)
//! - Parse errors (malformed API responses)
//!
//! Use [`map_auth_error`] to handle specific OAuth error scenarios.

mod client;
mod types;

pub use client::{
    commit_day, copy_entries, copy_meal, create_food_entry, delete_food_entry, edit_food_entry,
    get_food_entries, get_food_entry, get_month_summary, save_template,
};
pub use types::{
    date_to_int, int_to_date, map_auth_error, validate_custom_entry, validate_date_int_string,
    validate_number_of_units, AuthError, DaySummary, FoodEntry, FoodEntryId, FoodEntryInput,
    FoodEntryUpdate, MealType, MonthSummary, ValidationError,
};
