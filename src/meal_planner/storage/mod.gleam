/// Main storage module - re-exports all storage functionality
/// Organized by domain:
/// - profile: User profiles, nutrition state, and goals
/// - recipes: Recipe storage and retrieval
/// - foods: USDA food database and custom foods
/// - logs: Food logging and daily/weekly summaries
/// - nutrients: Nutrient calculations and parsing
/// - migrations: Database migration utilities
///
/// Import this module with:
/// ```
/// import meal_planner/storage
/// ```
///
/// Then use via submodule imports:
/// ```
/// import meal_planner/storage/profile
/// import meal_planner/storage/recipes
/// import meal_planner/storage/foods
/// import meal_planner/storage/logs
/// import meal_planner/storage/nutrients
/// import meal_planner/storage/migrations
/// ```
// This file serves as documentation and organization hub
// All functionality is in submodules - see them for actual API
