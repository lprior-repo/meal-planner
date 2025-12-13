/// Instrumented wrappers for storage operations with metrics collection
///
/// These functions wrap storage operations and automatically collect timing metrics.
/// They maintain compatibility with existing code while adding performance visibility.

import meal_planner/id
import meal_planner/metrics/mod.{type MetricsRegistry, StorageQuery}
import meal_planner/metrics/storage.{
  end_query_timing, record_query, start_query_timing,
}
import meal_planner/storage/foods.{
  type UsdaFood, type UsdaFoodWithNutrients, type FoodNutrientValue,
}
import meal_planner/storage/profile.{type StorageError}
import meal_planner/types
import pog

// ============================================================================
// Food Search Operations
// ============================================================================

/// Search foods with performance monitoring
pub fn search_foods(
  registry: MetricsRegistry,
  conn: pog.Connection,
  query: String,
  limit: Int,
) -> #(Result(List(UsdaFood), StorageError), MetricsRegistry) {
  let context = start_query_timing("search_foods")
  let result = foods.search_foods(conn, query, limit)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Search foods with filters - with performance monitoring
pub fn search_foods_filtered(
  registry: MetricsRegistry,
  conn: pog.Connection,
  query: String,
  filters: types.SearchFilters,
  limit: Int,
) -> #(Result(List(UsdaFood), StorageError), MetricsRegistry) {
  let context = start_query_timing("search_foods_filtered")
  let result = foods.search_foods_filtered(conn, query, filters, limit)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Search foods with filters and pagination - with performance monitoring
pub fn search_foods_filtered_with_offset(
  registry: MetricsRegistry,
  conn: pog.Connection,
  query: String,
  filters: types.SearchFilters,
  limit: Int,
  offset: Int,
) -> #(Result(List(UsdaFood), StorageError), MetricsRegistry) {
  let context = start_query_timing("search_foods_paginated")
  let result =
    foods.search_foods_filtered_with_offset(conn, query, filters, limit, offset)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Get food by ID - with performance monitoring
pub fn get_food_by_id(
  registry: MetricsRegistry,
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> #(Result(UsdaFood, StorageError), MetricsRegistry) {
  let context = start_query_timing("get_food_by_id")
  let result = foods.get_food_by_id(conn, fdc_id)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Load USDA food with macros - with performance monitoring
pub fn load_usda_food_with_macros(
  registry: MetricsRegistry,
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> #(Result(UsdaFoodWithNutrients, StorageError), MetricsRegistry) {
  let context = start_query_timing("load_usda_food_with_macros")
  let result = foods.load_usda_food_with_macros(conn, fdc_id)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Get foods count - with performance monitoring
pub fn get_foods_count(
  registry: MetricsRegistry,
  conn: pog.Connection,
) -> #(Result(Int, StorageError), MetricsRegistry) {
  let context = start_query_timing("get_foods_count")
  let result = foods.get_foods_count(conn)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Get food categories - with performance monitoring
pub fn get_food_categories(
  registry: MetricsRegistry,
  conn: pog.Connection,
) -> #(Result(List(String), StorageError), MetricsRegistry) {
  let context = start_query_timing("get_food_categories")
  let result = foods.get_food_categories(conn)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

// ============================================================================
// Custom Foods Operations
// ============================================================================

/// Create custom food - with performance monitoring
pub fn create_custom_food(
  registry: MetricsRegistry,
  conn: pog.Connection,
  user_id: id.UserId,
  food: types.CustomFood,
) -> #(Result(types.CustomFood, StorageError), MetricsRegistry) {
  let context = start_query_timing("create_custom_food")
  let result = foods.create_custom_food(conn, user_id, food)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Get custom food by ID - with performance monitoring
pub fn get_custom_food_by_id(
  registry: MetricsRegistry,
  conn: pog.Connection,
  user_id: id.UserId,
  food_id: id.CustomFoodId,
) -> #(Result(types.CustomFood, StorageError), MetricsRegistry) {
  let context = start_query_timing("get_custom_food_by_id")
  let result = foods.get_custom_food_by_id(conn, user_id, food_id)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Search custom foods - with performance monitoring
pub fn search_custom_foods(
  registry: MetricsRegistry,
  conn: pog.Connection,
  user_id: id.UserId,
  query: String,
  limit: Int,
) -> #(Result(List(types.CustomFood), StorageError), MetricsRegistry) {
  let context = start_query_timing("search_custom_foods")
  let result = foods.search_custom_foods(conn, user_id, query, limit)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Get custom foods for user - with performance monitoring
pub fn get_custom_foods_for_user(
  registry: MetricsRegistry,
  conn: pog.Connection,
  user_id: id.UserId,
) -> #(Result(List(types.CustomFood), StorageError), MetricsRegistry) {
  let context = start_query_timing("get_custom_foods_for_user")
  let result = foods.get_custom_foods_for_user(conn, user_id)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Delete custom food - with performance monitoring
pub fn delete_custom_food(
  registry: MetricsRegistry,
  conn: pog.Connection,
  user_id: id.UserId,
  food_id: id.CustomFoodId,
) -> #(Result(Nil, StorageError), MetricsRegistry) {
  let context = start_query_timing("delete_custom_food")
  let result = foods.delete_custom_food(conn, user_id, food_id)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

/// Update custom food - with performance monitoring
pub fn update_custom_food(
  registry: MetricsRegistry,
  conn: pog.Connection,
  user_id: id.UserId,
  food: types.CustomFood,
) -> #(Result(types.CustomFood, StorageError), MetricsRegistry) {
  let context = start_query_timing("update_custom_food")
  let result = foods.update_custom_food(conn, user_id, food)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}

// ============================================================================
// Nutrient Operations
// ============================================================================

/// Get food nutrients - with performance monitoring
pub fn get_food_nutrients(
  registry: MetricsRegistry,
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> #(Result(List(FoodNutrientValue), StorageError), MetricsRegistry) {
  let context = start_query_timing("get_food_nutrients")
  let result = foods.get_food_nutrients(conn, fdc_id)
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)
  #(result, updated_registry)
}
