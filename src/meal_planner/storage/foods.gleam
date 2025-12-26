/// Food storage module - USDA foods and custom foods
///
/// This module has been decomposed into focused submodules:
/// - foods/types.gleam: Type definitions
/// - foods/decoders.gleam: Database result decoders
/// - foods/queries.gleam: Database query operations
///
/// This file serves as a facade maintaining backward compatibility.
import meal_planner/id
import meal_planner/storage/foods/queries
import meal_planner/storage/foods/types
import meal_planner/storage/profile.{type StorageError}
import meal_planner/types/custom_food.{type CustomFood}
import meal_planner/types/food.{type FoodSearchResponse, type SearchFilters}
import pog

// Re-export types
pub type UsdaFood =
  types.UsdaFood

pub type FoodNutrientValue =
  types.FoodNutrientValue

pub type UsdaFoodWithNutrients =
  types.UsdaFoodWithNutrients

// USDA Foods - re-export functions

pub fn search_foods(
  conn: pog.Connection,
  query: String,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  queries.search_foods(conn, query, limit)
}

pub fn search_foods_filtered(
  conn: pog.Connection,
  query: String,
  filters: SearchFilters,
  limit: Int,
) -> Result(List(UsdaFood), StorageError) {
  queries.search_foods_filtered(conn, query, filters, limit)
}

pub fn search_foods_filtered_with_offset(
  conn: pog.Connection,
  query: String,
  filters: SearchFilters,
  limit: Int,
  offset: Int,
) -> Result(List(UsdaFood), StorageError) {
  queries.search_foods_filtered_with_offset(conn, query, filters, limit, offset)
}

pub fn get_food_by_id(
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> Result(UsdaFood, StorageError) {
  queries.get_food_by_id(conn, fdc_id)
}

pub fn load_usda_food_with_macros(
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> Result(UsdaFoodWithNutrients, StorageError) {
  queries.load_usda_food_with_macros(conn, fdc_id)
}

pub fn get_foods_count(conn: pog.Connection) -> Result(Int, StorageError) {
  queries.get_foods_count(conn)
}

pub fn get_food_categories(
  conn: pog.Connection,
) -> Result(List(String), StorageError) {
  queries.get_food_categories(conn)
}

// Custom Foods - re-export functions

pub fn create_custom_food(
  conn: pog.Connection,
  user_id: id.UserId,
  food: CustomFood,
) -> Result(CustomFood, StorageError) {
  queries.create_custom_food(conn, user_id, food)
}

pub fn get_custom_food_by_id(
  conn: pog.Connection,
  user_id: id.UserId,
  food_id: id.CustomFoodId,
) -> Result(CustomFood, StorageError) {
  queries.get_custom_food_by_id(conn, user_id, food_id)
}

pub fn search_custom_foods(
  conn: pog.Connection,
  user_id: id.UserId,
  query: String,
  limit: Int,
) -> Result(List(CustomFood), StorageError) {
  queries.search_custom_foods(conn, user_id, query, limit)
}

pub fn get_custom_foods_for_user(
  conn: pog.Connection,
  user_id: id.UserId,
) -> Result(List(CustomFood), StorageError) {
  queries.get_custom_foods_for_user(conn, user_id)
}

pub fn delete_custom_food(
  conn: pog.Connection,
  user_id: id.UserId,
  food_id: id.CustomFoodId,
) -> Result(Nil, StorageError) {
  queries.delete_custom_food(conn, user_id, food_id)
}

pub fn update_custom_food(
  conn: pog.Connection,
  user_id: id.UserId,
  food: CustomFood,
) -> Result(CustomFood, StorageError) {
  queries.update_custom_food(conn, user_id, food)
}

// Unified Search - re-export

pub fn unified_search_foods(
  conn: pog.Connection,
  user_id: id.UserId,
  query: String,
  limit: Int,
) -> Result(FoodSearchResponse, StorageError) {
  queries.unified_search_foods(conn, user_id, query, limit)
}

// Nutrients - re-export

pub fn get_food_nutrients(
  conn: pog.Connection,
  fdc_id: id.FdcId,
) -> Result(List(FoodNutrientValue), StorageError) {
  queries.get_food_nutrients(conn, fdc_id)
}
