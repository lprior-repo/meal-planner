/// Unified food search across USDA and custom foods
///
/// This module provides a unified search interface that queries both:
/// - Custom foods (user-scoped, from custom_foods table)
/// - USDA foods (global, from food_nutrients table)
///
/// Results are ordered with custom foods first, then USDA foods.
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import meal_planner/nutrition_constants as constants
import meal_planner/storage
import meal_planner/types.{
  type FoodSearchError, type FoodSearchResponse, CustomFoodResult,
  FoodSearchResponse, InvalidQuery, SearchFilters, UsdaFoodResult,
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
  user_id: String,
  query: String,
  limit: Int,
) -> Result(FoodSearchResponse, FoodSearchError) {
  // STEP 1: Validate query (trim whitespace, check length)
  let trimmed_query = string.trim(query)

  case string.length(trimmed_query) {
    len if len < constants.min_query_length ->
      Error(InvalidQuery(
        "Query must be at least "
        <> int.to_string(constants.min_query_length)
        <> " characters",
      ))
    _ -> {
      // STEP 2: Validate limit (must be 1-100)
      case limit {
        l if l < 1 || l > constants.max_search_limit ->
          Error(InvalidQuery(
            "Limit must be between 1 and "
            <> int.to_string(constants.max_search_limit),
          ))
        _ -> {
          // STEP 3: Split limit between custom and USDA foods
          let custom_limit = int.min(limit / 2, 50)
          let usda_limit = int.min(limit - custom_limit, 50)

          // STEP 4: Query custom foods (user-scoped, prioritized)
          let custom_results = case
            storage.search_custom_foods(
              db,
              user_id,
              trimmed_query,
              custom_limit,
            )
          {
            Ok(foods) ->
              foods
              |> list.map(fn(food) { types.CustomFoodResult(food) })
            Error(_) -> []
            // Graceful degradation - return empty on error
          }

          // STEP 5: Query USDA foods (global)
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

          // STEP 6: Merge results and count efficiently (custom first, then USDA)
          let all_results = list.append(custom_results, usda_results)
          let #(custom_count, usda_count) = #(
            list.fold(custom_results, 0, fn(acc, _) { acc + 1 }),
            list.fold(usda_results, 0, fn(acc, _) { acc + 1 }),
          )
          let total_count = custom_count + usda_count

          // STEP 7: Return response
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

/// Search foods with category filter applied
/// Integrates category filtering with unified search
///
/// ## Parameters
/// - `db`: PostgreSQL connection
/// - `user_id`: User ID for custom food scoping
/// - `query`: Search term (min 2 characters, or empty for browse mode)
/// - `category`: Optional category filter (None = all categories)
/// - `limit`: Total result limit (max 100)
///
/// ## Returns
/// - `Ok(FoodSearchResponse)`: Filtered search results with metadata
/// - `Err(FoodSearchError)`: Validation or database error
///
/// ## Examples
/// ```gleam
/// // Search with category filter
/// let result = unified_food_search_with_category(
///   db, "user-123", "chicken", option.Some("Poultry Products"), 50
/// )
/// // Browse all items in category (empty query)
/// let result = unified_food_search_with_category(
///   db, "user-123", "", option.Some("Dairy and Egg Products"), 50
/// )
/// ```
pub fn unified_food_search_with_category(
  db: pog.Connection,
  _user_id: String,
  query: String,
  category: option.Option(String),
  limit: Int,
) -> Result(FoodSearchResponse, FoodSearchError) {
  // STEP 1: Validate limit (must be 1-100)
  case limit {
    l if l < 1 || l > constants.max_search_limit ->
      Error(InvalidQuery(
        "Limit must be between 1 and "
        <> int.to_string(constants.max_search_limit),
      ))
    _ -> {
      let trimmed_query = string.trim(query)

      // STEP 2: Build search filters with category
      let filters =
        SearchFilters(
          verified_only: False,
          branded_only: False,
          category: category,
        )

      // STEP 3: Query USDA foods with filters
      let usda_results = case string.length(trimmed_query) {
        len if len < 2 -> {
          // Browse mode: return foods in category without text search
          case category {
            option.Some(_) ->
              case storage.search_foods_filtered(db, "", filters, limit) {
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
              }
            option.None -> []
          }
        }
        _ -> {
          // Search mode: text search with category filter
          case
            storage.search_foods_filtered(db, trimmed_query, filters, limit)
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
          }
        }
      }

      // STEP 4: Count results
      let total_count = list.length(usda_results)

      // STEP 5: Return response
      Ok(FoodSearchResponse(
        results: usda_results,
        total_count: total_count,
        custom_count: 0,
        usda_count: total_count,
      ))
    }
  }
}
