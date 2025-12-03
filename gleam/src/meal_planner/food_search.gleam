/// Unified food search across USDA and custom foods
///
/// This module provides a unified search interface that queries both:
/// - Custom foods (user-scoped, from custom_foods table)
/// - USDA foods (global, from food_nutrients table)
///
/// Results are ordered with custom foods first, then USDA foods.

import gleam/string
import pog
// TODO: Will be used in GREEN phase implementation:
// import gleam/list
// import gleam/result
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
  // STEP 1: Validate query (trim whitespace, check length)
  let trimmed_query = string.trim(query)

  case string.length(trimmed_query) {
    len if len < 2 ->
      Error(InvalidQuery("Query must be at least 2 characters"))
    _ -> {
      // STEP 2: Validate limit (must be 1-100)
      case limit {
        l if l < 1 || l > 100 ->
          Error(InvalidQuery("Limit must be between 1 and 100"))
        _ -> {
          // STEP 3: Return placeholder response for now
          // This will make validation tests pass, but structure tests will still fail
          Ok(FoodSearchResponse(
            results: [],
            total_count: 0,
            custom_count: 0,
            usda_count: 0,
          ))
        }
      }
    }
  }
}
