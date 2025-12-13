/// PostgreSQL storage module - Facade Pattern
///
/// This module provides a unified interface to all storage functionality through
/// the Facade Pattern. It re-exports public APIs from domain-specific submodules:
///
/// **Submodule Organization:**
/// - storage/profile: User profiles, nutrition state, and goal management
/// - storage/foods: USDA food database searching and custom food management
/// - storage/logs: Food log entry operations and nutritional summaries
/// - storage/migrations: Database schema initialization and updates
/// - storage/analytics: Search event tracking and analytics
///
/// **Design Philosophy:**
/// This facade keeps the public API simple and focused, while internal implementations
/// are split across focused submodules. Callers use `meal_planner/storage` for all
/// storage operations, ensuring a stable, well-organized interface.
import meal_planner/storage/profile as profile_module

import meal_planner/storage/foods

import meal_planner/storage/logs

import meal_planner/storage/migrations

import meal_planner/storage/analytics

// ============================================================================
// Database Configuration (from storage/profile)
// ============================================================================

/// Get default database configuration for development/testing
pub fn default_config() {
  profile_module.default_config()
}

/// Initialize connection pool with the given configuration
pub fn start_pool(config) {
  profile_module.start_pool(config)
}

// ============================================================================
// User Profile Management (from storage/profile)
// ============================================================================

/// Save user profile with bodyweight, activity level, and nutrition goals
pub fn save_user_profile(conn, user_profile) {
  profile_module.save_user_profile(conn, user_profile)
}

/// Retrieve user profile or error if not found
pub fn get_user_profile(conn) {
  profile_module.get_user_profile(conn)
}

// ============================================================================
// Nutrition State & Goals (from storage/profile)
// ============================================================================

/// Save daily nutrition state snapshot (calories, macros achieved)
pub fn save_nutrition_state(conn, state) {
  profile_module.save_nutrition_state(conn, state)
}

/// Get nutrition state for a specific date
pub fn get_nutrition_state(conn, date) {
  profile_module.get_nutrition_state(conn, date)
}

/// Get nutrition state history for last N days
pub fn get_nutrition_history(conn, days) {
  profile_module.get_nutrition_history(conn, days)
}

/// Save user nutrition goals (calorie targets, macro ratios)
pub fn save_goals(conn, goals) {
  profile_module.save_goals(conn, goals)
}

/// Retrieve current nutrition goals
pub fn get_goals(conn) {
  profile_module.get_goals(conn)
}

// Custom food functions
pub fn create_custom_food(conn, user_id, custom_food) {
  foods.create_custom_food(conn, user_id, custom_food)
}

pub fn get_custom_food_by_id(conn, user_id, food_id) {
  foods.get_custom_food_by_id(conn, user_id, food_id)
}

pub fn get_custom_foods_for_user(conn, user_id) {
  foods.get_custom_foods_for_user(conn, user_id)
}

pub fn update_custom_food(conn, user_id, custom_food) {
  foods.update_custom_food(conn, user_id, custom_food)
}

pub fn delete_custom_food(conn, user_id, food_id) {
  foods.delete_custom_food(conn, user_id, food_id)
}

pub fn search_custom_foods(conn, user_id, query, limit) {
  foods.search_custom_foods(conn, user_id, query, limit)
}

// Unified search (custom + USDA)
pub fn unified_search_foods(conn, user_id, query, limit) {
  foods.unified_search_foods(conn, user_id, query, limit)
}

// Food database functions
pub fn get_food_by_id(conn, id) {
  foods.get_food_by_id(conn, id)
}

pub fn load_usda_food_with_macros(conn, id) {
  foods.load_usda_food_with_macros(conn, id)
}

pub fn get_foods_count(conn) {
  foods.get_foods_count(conn)
}

pub fn get_food_categories(conn) {
  foods.get_food_categories(conn)
}

pub fn search_foods(conn, query, limit) {
  foods.search_foods(conn, query, limit)
}

pub fn search_foods_filtered(conn, query, filters, limit) {
  foods.search_foods_filtered(conn, query, filters, limit)
}

pub fn search_foods_filtered_with_offset(conn, query, filters, limit, offset) {
  foods.search_foods_filtered_with_offset(conn, query, filters, limit, offset)
}

pub fn get_food_nutrients(conn, fdc_id) {
  foods.get_food_nutrients(conn, fdc_id)
}

// Food log functions
pub fn save_food_log(conn, log) {
  logs.save_food_log(conn, log)
}

pub fn save_food_log_entry(conn, date, entry) {
  logs.save_food_log_entry(conn, date, entry)
}

pub fn get_food_logs_by_date(conn, date) {
  logs.get_food_logs_by_date(conn, date)
}

pub fn delete_food_log(conn, id) {
  logs.delete_food_log(conn, id)
}

pub fn get_recent_meals(conn, limit) {
  logs.get_recent_meals(conn, limit)
}

pub fn get_recent_meals_enriched(conn, cfg, limit) {
  logs.get_recent_meals_enriched(conn, cfg, limit)
}

pub fn get_daily_log(conn, date) {
  logs.get_daily_log(conn, date)
}

pub fn get_user_profile_or_default(conn) {
  logs.get_user_profile_or_default(conn)
}

pub fn get_weekly_summary(conn, user_id, start_date) {
  logs.get_weekly_summary(conn, user_id, start_date)
}

// Migrations
pub fn init_migrations() {
  migrations.init_migrations()
}

// Analytics
pub fn record_search_event(conn, event) {
  analytics.record_search_event(conn, event)
}

/// Get recently logged USDA foods for the user
pub fn get_recently_logged_foods(conn, limit) {
  logs.get_recently_logged_foods(conn, limit)
}

// init_migrations is re-exported directly from migrations import above

// Re-export types for type annotations
pub type StorageError =
  profile_module.StorageError

pub type DbConfig =
  profile_module.DbConfig

pub type UsdaFood =
  foods.UsdaFood

pub type FoodNutrientValue =
  foods.FoodNutrientValue

pub type UsdaFoodWithNutrients =
  foods.UsdaFoodWithNutrients

pub type Log =
  logs.Log

pub type FoodSummaryItem =
  logs.FoodSummaryItem

pub type WeeklySummary =
  logs.WeeklySummary
