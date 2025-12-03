/// Unified food search across USDA and custom foods
///
/// This module provides a unified search interface that queries both:
/// - Custom foods (user-scoped, from custom_foods table)
/// - USDA foods (global, from food_nutrients table)
///
/// Results are ordered with custom foods first, then USDA foods.

import pog
// TODO: Will be used in GREEN phase implementation:
// import gleam/list
// import gleam/result
// import gleam/string
// import meal_planner/custom_food_storage
// import meal_planner/storage
import shared/types.{
  type FoodSearchError, type FoodSearchResponse, DatabaseError,
  FoodSearchResponse, InvalidQuery,
}

/// Search both custom foods and USDA database
/// Returns custom foods first (user-scoped), then USDA foods (global)
///
/// ## Parameters
/// - `db`: PostgreSQL connection
/// - `user_id`: User ID for custom food scoping
/// - `query`: Search term (min 2 characters)
/// - `limit`: Total result limit (split 50/50 between sources, max 100)
///
/// ## Returns
/// - `Ok(FoodSearchResponse)`: Search results with metadata
/// - `Err(FoodSearchError)`: Validation or database error
///
/// ## Examples
/// ```gleam
/// let result = unified_food_search(db, "user-123", "chicken", 50)
/// ```
pub fn unified_food_search(
  db: pog.Connection,
  user_id: String,
  query: String,
  limit: Int,
) -> Result(FoodSearchResponse, FoodSearchError) {
  // TODO: Implement unified search
  // This is a placeholder for TDD - will fail tests
  Error(DatabaseError("Not implemented"))
}
