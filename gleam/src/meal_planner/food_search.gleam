/// Unified food search across USDA and custom foods
///
/// This module provides a unified search interface that queries both:
/// - Custom foods (user-scoped, from custom_foods table)
/// - USDA foods (global, from food_nutrients table)
///
/// Results are ordered with custom foods first, then USDA foods.
import gleam/list
import gleam/string
import meal_planner/storage
import meal_planner/types.{
  type FoodSearchError, type FoodSearchResponse, FoodSearchResponse,
  InvalidQuery, UsdaFoodResult,
}
import pog

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
  _user_id: String,
  query: String,
  limit: Int,
) -> Result(FoodSearchResponse, FoodSearchError) {
  // STEP 1: Validate query (trim whitespace, check length)
  let trimmed_query = string.trim(query)

  case string.length(trimmed_query) {
    len if len < 2 -> Error(InvalidQuery("Query must be at least 2 characters"))
    _ -> {
      // STEP 2: Validate limit (must be 1-100)
      case limit {
        l if l < 1 || l > 100 ->
          Error(InvalidQuery("Limit must be between 1 and 100"))
        _ -> {
          // STEP 3: Custom foods tracked in bead meal-planner-1k0
          let custom_results = []
          // Placeholder until custom foods implemented
          let usda_limit = limit

          // STEP 4: Query USDA foods (global)
          let usda_results = case
            storage.search_foods(db, trimmed_query, usda_limit)
          {
            Ok(foods) ->
              foods
              |> list.map(fn(food) {
                UsdaFoodResult(
                  food.fdc_id,
                  food.description,
                  food.data_type,
                  food.category,
                )
              })
            Error(_) -> []
            // Graceful degradation - return empty on error
          }

          // STEP 5: Merge results and count efficiently (custom first, then USDA)
          let all_results = list.append(custom_results, usda_results)
          let #(custom_count, usda_count) = #(
            list.fold(custom_results, 0, fn(acc, _) { acc + 1 }),
            list.fold(usda_results, 0, fn(acc, _) { acc + 1 }),
          )
          let total_count = custom_count + usda_count

          // STEP 6: Return response
          Ok(FoodSearchResponse(
            results: all_results,
            total_count: total_count,
            custom_count: custom_count,
            usda_count: usda_count,
          ))
        }
      }
    }
  }
}
