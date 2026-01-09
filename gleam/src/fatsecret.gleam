//  FatSecret API Client
//  Provides Gleam bindings for FatSecret nutrition tracking API
//  Supports both 2-legged (app-only) and 3-legged (user-specific) OAuth

import gleam/list
import gleam/option
import gleam/result

pub type OAuthConfig {
  OAuthConfig(
    consumer_key: String,
    consumer_secret: String,
    user_token: option.Option(String),
    user_secret: option.Option(String),
  )
}

pub type Food {
  Food(
    id: String,
    name: String,
    calories: Float,
    protein: Float,
    carbs: Float,
    fat: Float,
  )
}

pub type DiaryEntry {
  DiaryEntry(
    id: String,
    food_id: String,
    date_int: Int,
    meal_type: String,
    serving_id: String,
    number_of_servings: Float,
  )
}

pub type SearchResult {
  SearchResult(
    total: Int,
    results: list.List(Food),
  )
}

/// Create a new FatSecret OAuth configuration (2-legged flow)
pub fn new_oauth(consumer_key: String, consumer_secret: String) -> OAuthConfig {
  OAuthConfig(
    consumer_key: consumer_key,
    consumer_secret: consumer_secret,
    user_token: option.None,
    user_secret: option.None,
  )
}

/// Add user credentials for 3-legged OAuth
pub fn with_user_credentials(
  config: OAuthConfig,
  user_token: String,
  user_secret: String,
) -> OAuthConfig {
  OAuthConfig(
    ..config,
    user_token: option.Some(user_token),
    user_secret: option.Some(user_secret),
  )
}

/// Search for foods by name
pub fn search_foods(
  config: OAuthConfig,
  query: String,
) -> result.Result(SearchResult, String) {
  let _ = (config, query)
  // TODO: Implement FatSecret search_foods API call
  Ok(SearchResult(total: 0, results: []))
}

/// Get food details by ID
pub fn get_food(
  config: OAuthConfig,
  food_id: String,
) -> result.Result(Food, String) {
  let _ = (config, food_id)
  // TODO: Implement FatSecret get_food API call
  Error("Not yet implemented")
}

/// Log a food entry to diary
pub fn log_food(
  config: OAuthConfig,
  food_id: String,
  serving_id: String,
  date_int: Int,
  meal_type: String,
) -> result.Result(DiaryEntry, String) {
  let _ = (config, food_id, serving_id, date_int, meal_type)
  // TODO: Implement FatSecret food_entry.create API call
  Error("Not yet implemented")
}
