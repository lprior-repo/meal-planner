/// PostgreSQL storage module - Domain-driven organization
/// 
/// This module re-exports all storage functionality from domain-specific submodules:
/// - storage/profile: User profiles, nutrition state, and goals
/// - storage/recipes: Recipe storage and retrieval
/// - storage/foods: USDA food database and custom foods
/// - storage/logs: Food logging and daily/weekly summaries
/// - storage/nutrients: Nutrient calculations and parsing
/// - storage/migrations: Database migration utilities
import meal_planner/storage/profile.{
  type DbConfig, type StorageError, default_config, get_goals,
  get_nutrition_history, get_nutrition_state, get_user_profile,
  get_user_profile_or_default, save_goals, save_nutrition_state,
  save_user_profile, start_pool,
}

import meal_planner/storage/recipes.{
  delete_recipe, filter_recipes, get_all_recipes, get_recipe_by_id,
  get_recipes_by_category, save_recipe,
}

import meal_planner/storage/foods.{
  type FoodNutrientValue, type UsdaFood, type UsdaFoodWithNutrients,
  create_custom_food, delete_custom_food, get_custom_food_by_id,
  get_custom_foods_for_user, get_food_by_id, get_food_categories,
  get_foods_count, load_usda_food_with_macros, search_custom_foods, search_foods,
  search_foods_filtered, update_custom_food,
}

import meal_planner/storage/logs.{
  type FoodLog, type FoodSummaryItem, type Log, type WeeklySummary,
  delete_food_log, get_daily_log, get_food_logs_by_date, get_recent_meals,
  get_recently_logged_foods, get_todays_logs, get_weekly_summary, save_food_log,
  save_food_log_entry, save_food_to_log,
}

import meal_planner/storage/nutrients.{
  calculate_total_macros, calculate_total_micronutrients, get_food_nutrients,
  parse_usda_macros, parse_usda_micronutrients,
}

import meal_planner/storage/migrations.{init_migrations}

// Re-export everything
pub fn default_config() {
  profile.default_config()
}

pub fn start_pool(config) {
  profile.start_pool(config)
}

pub fn save_nutrition_state(conn, state) {
  profile.save_nutrition_state(conn, state)
}

pub fn get_nutrition_state(conn, date) {
  profile.get_nutrition_state(conn, date)
}

pub fn get_nutrition_history(conn, days) {
  profile.get_nutrition_history(conn, days)
}

pub fn save_goals(conn, goals) {
  profile.save_goals(conn, goals)
}

pub fn get_goals(conn) {
  profile.get_goals(conn)
}

pub fn save_user_profile(conn, user_profile) {
  profile.save_user_profile(conn, user_profile)
}

pub fn get_user_profile(conn, user_id) {
  profile.get_user_profile(conn, user_id)
}

pub fn get_user_profile_or_default(conn) {
  profile.get_user_profile_or_default(conn)
}

pub fn save_recipe(conn, recipe) {
  recipes.save_recipe(conn, recipe)
}

pub fn get_all_recipes(conn) {
  recipes.get_all_recipes(conn)
}

pub fn get_recipe_by_id(conn, id) {
  recipes.get_recipe_by_id(conn, id)
}

pub fn delete_recipe(conn, id) {
  recipes.delete_recipe(conn, id)
}

pub fn get_recipes_by_category(conn, category) {
  recipes.get_recipes_by_category(conn, category)
}

pub fn filter_recipes(conn, constraints) {
  recipes.filter_recipes(conn, constraints)
}

pub fn search_foods(conn, query) {
  foods.search_foods(conn, query)
}

pub fn search_foods_filtered(conn, query, category) {
  foods.search_foods_filtered(conn, query, category)
}

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

pub fn create_custom_food(conn, user_id, custom_food) {
  foods.create_custom_food(conn, user_id, custom_food)
}

pub fn get_custom_food_by_id(conn, user_id, id) {
  foods.get_custom_food_by_id(conn, user_id, id)
}

pub fn search_custom_foods(conn, user_id, query) {
  foods.search_custom_foods(conn, user_id, query)
}

pub fn get_custom_foods_for_user(conn, user_id) {
  foods.get_custom_foods_for_user(conn, user_id)
}

pub fn delete_custom_food(conn, user_id, food_id) {
  foods.delete_custom_food(conn, user_id, food_id)
}

pub fn update_custom_food(conn, user_id, food) {
  foods.update_custom_food(conn, user_id, food)
}

pub fn save_food_log(conn, log) {
  logs.save_food_log(conn, log)
}

pub fn get_food_logs_by_date(conn, date) {
  logs.get_food_logs_by_date(conn, date)
}

pub fn get_todays_logs(conn) {
  logs.get_todays_logs(conn)
}

pub fn delete_food_log(conn, id) {
  logs.delete_food_log(conn, id)
}

pub fn get_recent_meals(conn, limit) {
  logs.get_recent_meals(conn, limit)
}

pub fn save_food_log_entry(conn, user_id, entry) {
  logs.save_food_log_entry(conn, user_id, entry)
}

pub fn get_daily_log(conn, date) {
  logs.get_daily_log(conn, date)
}

pub fn get_weekly_summary(conn, start_date) {
  logs.get_weekly_summary(conn, start_date)
}

pub fn save_food_to_log(conn, user_id, meal_type, food) {
  logs.save_food_to_log(conn, user_id, meal_type, food)
}

pub fn get_recently_logged_foods(conn, user_id, limit) {
  logs.get_recently_logged_foods(conn, user_id, limit)
}

pub fn get_food_nutrients(conn, id) {
  nutrients.get_food_nutrients(conn, id)
}

pub fn parse_usda_macros(nutrients_list) {
  nutrients.parse_usda_macros(nutrients_list)
}

pub fn parse_usda_micronutrients(nutrients_list) {
  nutrients.parse_usda_micronutrients(nutrients_list)
}

pub fn calculate_total_macros(entries) {
  nutrients.calculate_total_macros(entries)
}

pub fn calculate_total_micronutrients(entries) {
  nutrients.calculate_total_micronutrients(entries)
}

pub fn init_migrations() {
  migrations.init_migrations()
}

// Re-export types for type annotations
pub type StorageError =
  profile.StorageError

pub type DbConfig =
  profile.DbConfig

pub type UsdaFood =
  foods.UsdaFood

pub type FoodNutrientValue =
  foods.FoodNutrientValue

pub type UsdaFoodWithNutrients =
  foods.UsdaFoodWithNutrients

pub type FoodLog =
  logs.FoodLog

pub type Log =
  logs.Log

pub type FoodSummaryItem =
  logs.FoodSummaryItem

pub type WeeklySummary =
  logs.WeeklySummary
