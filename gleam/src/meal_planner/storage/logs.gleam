/// PostgreSQL storage module for food logs - Facade Pattern
///
/// This module serves as the public API for food log operations. Internal
/// implementations have been split into focused submodules for maintainability:
///
/// - logs/entries.gleam: Individual log entry operations (save, delete, retrieve)
/// - logs/queries.gleam: Complex queries (recent meals, daily logs, foods)
/// - logs/summaries.gleam: Aggregation operations (weekly summaries, calculations)
///
/// This facade re-exports all public functions, allowing external code to
/// continue using the original import path: `meal_planner/storage/logs`.

import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/config
import meal_planner/id
import meal_planner/postgres
import meal_planner/storage/foods.{type UsdaFood, UsdaFood}
import meal_planner/storage/logs/entries
import meal_planner/storage/logs/queries
import meal_planner/storage/logs/summaries
import meal_planner/storage/profile.{type StorageError, DatabaseError}
import meal_planner/storage/utils
import meal_planner/types.{
  type DailyLog, type FoodLogEntry, type Macros, type UserProfile, Breakfast,
  DailyLog, Dinner, FoodLogEntry, Lunch, Macros, Maintain, Moderate, Snack,
  UserProfile,
}
import pog

// ============================================================================
// Database Configuration (re-exported from postgres module)
// ============================================================================

/// Database configuration (re-export from postgres module)
pub type DbConfig =
  postgres.Config

/// Default configuration for development (re-export from postgres module)
pub fn default_config() -> DbConfig {
  postgres.default_config()
}

/// Start the database connection pool (re-export from postgres module)
pub fn start_pool(config: DbConfig) -> Result(pog.Connection, String) {
  postgres.connect(config)
  |> result.map_error(postgres.format_error)
}

// ============================================================================
// Type Re-exports from Entry Module
// ============================================================================

/// Food log entry type (re-exported from entries module)
pub type FoodLog =
  entries.FoodLog

/// Log entry type for food consumption tracking (re-exported from queries module)
pub type Log =
  queries.Log

/// Input type for logging a meal with a Tandoor recipe slug (re-exported from entries module)
pub type FoodLogInput = entries.FoodLogInput

// ============================================================================
// Type Re-exports from Summaries Module
// ============================================================================

/// Food summary item for weekly aggregation (re-exported from summaries module)
pub type FoodSummaryItem =
  summaries.FoodSummaryItem

/// Weekly summary of nutrition data (re-exported from summaries module)
pub type WeeklySummary =
  summaries.WeeklySummary

// ============================================================================
// Entry Operations (from logs/entries.gleam)
// ============================================================================

/// Save a food log entry
pub fn save_food_log(
  conn: pog.Connection,
  log: FoodLog,
) -> Result(Nil, StorageError) {
  entries.save_food_log(conn, log)
}

/// Save a food log entry using shared types
pub fn save_food_log_entry(
  conn: pog.Connection,
  date: String,
  entry: FoodLogEntry,
) -> Result(Nil, StorageError) {
  entries.save_food_log_entry(conn, date, entry)
}

/// Enhanced save_food_log_entry with recipe slug validation
pub fn save_food_log_entry_with_validation(
  conn: pog.Connection,
  config: config.Config,
  date: String,
  entry: FoodLogEntry,
) -> Result(Nil, StorageError) {
  entries.save_food_log_entry_with_validation(conn, config, date, entry)
}

/// Delete a food log entry
pub fn delete_food_log(
  conn: pog.Connection,
  log_id: id.LogEntryId,
) -> Result(Nil, StorageError) {
  entries.delete_food_log(conn, log_id)
}

/// Save a food log entry from a Tandoor recipe slug
pub fn save_food_log_from_tandoor_recipe(
  conn: pog.Connection,
  input: FoodLogInput,
) -> Result(String, StorageError) {
  entries.save_food_log_from_tandoor_recipe(conn, input)
}

// ============================================================================
// Query Operations (from logs/queries.gleam)
// ============================================================================

/// Get food logs for a specific date
pub fn get_food_logs_by_date(
  conn: pog.Connection,
  date: String,
) -> Result(List(FoodLogEntry), StorageError) {
  queries.get_food_logs_by_date(conn, date)
}

/// Get logs for a specific user and date from the logs table
pub fn get_todays_logs(
  conn: pog.Connection,
  user_id: Int,
  date: String,
) -> Result(List(Log), StorageError) {
  queries.get_todays_logs(conn, user_id, date)
}

/// Get recent meals (distinct by recipe, most recent first)
pub fn get_recent_meals(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(FoodLogEntry), StorageError) {
  queries.get_recent_meals(conn, limit)
}

/// Get recent meals with Tandoor enrichment
pub fn get_recent_meals_enriched(
  conn: pog.Connection,
  cfg: config.Config,
  limit: Int,
) -> Result(List(FoodLogEntry), StorageError) {
  queries.get_recent_meals_enriched(conn, cfg, limit)
}

/// Get the 10 most recently logged USDA foods (distinct by fdc_id)
pub fn get_recently_logged_foods(
  conn: pog.Connection,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  queries.get_recently_logged_foods(conn, limit)
}

/// Get daily log for a specific date
pub fn get_daily_log(
  conn: pog.Connection,
  date: String,
) -> Result(DailyLog, StorageError) {
  queries.get_daily_log(conn, date)
}

// ============================================================================
// Summary Operations (from logs/summaries.gleam)
// ============================================================================

/// Get weekly summary of nutrition data aggregated by food
pub fn get_weekly_summary(
  conn: pog.Connection,
  user_id: Int,
  start_date: String,
) -> Result(WeeklySummary, StorageError) {
  summaries.get_weekly_summary(conn, user_id, start_date)
}


// ============================================================================
// User Profile Helpers
// ============================================================================

/// Get user profile or return default if not found
pub fn get_user_profile_or_default(conn: pog.Connection) -> UserProfile {
  case profile.get_user_profile(conn) {
    Ok(profile) -> profile
    Error(_) -> default_user_profile()
  }
}

fn default_user_profile() -> UserProfile {
  UserProfile(
    id: id.user_id("user-1"),
    bodyweight: 180.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
}

// ============================================================================
// Private Helper Imports
// ============================================================================
