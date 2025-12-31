//! FatSecret Weight Management domain
//!
//! This module provides a type-safe interface for managing weight measurements
//! through the FatSecret Platform API. It supports recording weight entries,
//! retrieving historical data, and tracking progress over time.
//!
//! # Key Types
//!
//! - [`WeightEntry`] - A single weight measurement with date and optional comment
//! - [`WeightUpdate`] - Input structure for recording a new weight measurement
//! - [`WeightMonthSummary`] - Monthly summary of weight measurements
//! - [`WeightDaySummary`] - Daily weight data within a monthly summary
//!
//! # Key Functions
//!
//! - [`update_weight`] - Record a new weight measurement for a specific date
//! - [`get_weight_by_date`] - Retrieve weight measurement for a specific date
//! - [`get_weight_month_summary`] - Get all weight measurements for a month
//!
//! # Date Format
//!
//! All dates use the FatSecret `date_int` format: days since Unix epoch (0 = 1970-01-01).
//! Use the utility functions in `fatsecret::core::date_utils` to convert to/from standard dates.
//!
//! # Usage Example
//!
//! ```no_run
//! use meal_planner::fatsecret::weight::{update_weight, get_weight_month_summary, WeightUpdate};
//! use meal_planner::fatsecret::core::config::FatSecretConfig;
//! use meal_planner::fatsecret::core::oauth::AccessToken;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//! let token = AccessToken::new("access_token", "access_secret");
//!
//! // Record a weight measurement
//! let update = WeightUpdate {
//!     current_weight_kg: 75.5,
//!     date_int: 19723, // 2024-01-01
//!     goal_weight_kg: Some(70.0),
//!     height_cm: Some(175.0),
//!     comment: Some("Morning weight".to_string()),
//! };
//! update_weight(&config, &token, update).await?;
//!
//! // Retrieve monthly summary
//! let summary = get_weight_month_summary(&config, &token, 19723).await?;
//! for day in &summary.days {
//!     println!("Date: {}, Weight: {} kg", day.date_int, day.weight_kg);
//! }
//! # Ok(())
//! # }
//! ```

pub mod client;
pub mod types;

pub use client::*;
pub use types::*;
