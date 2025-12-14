/// FatSecret Foods API client
/// Provides type-safe wrappers around the base FatSecret client
import gleam/dict
import gleam/int
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/client as base_client
import meal_planner/fatsecret/foods/decoders
import meal_planner/fatsecret/foods/types.{
  type Food, type FoodId, type FoodSearchResponse,
}

// Re-export error types from base client
pub type FatSecretError =
  base_client.FatSecretError

// ============================================================================
// Food Get API (food.get.v5)
// ============================================================================

/// Get complete food details by ID using food.get.v5 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns complete nutrition information for all servings.
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// let food_id = types.food_id("12345")
/// case get_food(config, food_id) {
///   Ok(food) -> io.println("Food: " <> food.food_name)
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn get_food(
  config: FatSecretConfig,
  food_id: FoodId,
) -> Result(Food, FatSecretError) {
  // Use base client's get_food function
  use response_json <- result.try(base_client.get_food(
    config,
    types.food_id_to_string(food_id),
  ))

  // Parse JSON response with type-safe decoders
  case json.parse(response_json, decoders.food_decoder()) {
    Ok(food) -> Ok(food)
    Error(_) ->
      Error(base_client.ParseError(
        "Failed to decode food response: " <> response_json,
      ))
  }
}

// ============================================================================
// Food Search API (foods.search)
// ============================================================================

/// Search for foods using the foods.search endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns paginated search results with basic food information.
///
/// ## Parameters
/// - query: Search term (e.g., "apple", "chicken breast")
/// - page: Page number (0-indexed), None for first page
/// - max_results: Results per page (1-50), None for default (20)
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case search_foods(config, "banana", Some(0), Some(20)) {
///   Ok(response) -> {
///     io.println("Found " <> int.to_string(response.total_results) <> " results")
///     list.each(response.foods, fn(food) {
///       io.println("- " <> food.food_name)
///     })
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn search_foods(
  config: FatSecretConfig,
  query: String,
  page: Option(Int),
  max_results: Option(Int),
) -> Result(FoodSearchResponse, FatSecretError) {
  let page_str = page |> option.map(int.to_string) |> option.unwrap("0")
  let max_results_str =
    max_results |> option.map(int.to_string) |> option.unwrap("20")

  // Build search parameters
  let params =
    dict.new()
    |> dict.insert("search_expression", query)
    |> dict.insert("page_number", page_str)
    |> dict.insert("max_results", max_results_str)

  // Use base client's make_api_request function
  use response_json <- result.try(base_client.make_api_request(
    config,
    "foods.search",
    params,
  ))

  // Parse JSON response with type-safe decoders
  case json.parse(response_json, decoders.food_search_response_decoder()) {
    Ok(search_response) -> Ok(search_response)
    Error(_) ->
      Error(base_client.ParseError(
        "Failed to decode search response: " <> response_json,
      ))
  }
}

/// Simplified search with defaults (page 0, max 20 results)
///
/// ## Example
/// ```gleam
/// case search_foods_simple(config, "banana") {
///   Ok(response) -> list.each(response.foods, fn(food) {
///     io.println(food.food_name)
///   })
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn search_foods_simple(
  config: FatSecretConfig,
  query: String,
) -> Result(FoodSearchResponse, FatSecretError) {
  search_foods(config, query, None, None)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert error to user-friendly string
pub fn error_to_string(error: FatSecretError) -> String {
  case error {
    base_client.ConfigMissing -> "FatSecret API not configured"
    base_client.RequestFailed(status, body) ->
      "HTTP " <> int.to_string(status) <> ": " <> body
    base_client.InvalidResponse(msg) -> "Invalid response: " <> msg
    base_client.OAuthError(msg) -> "OAuth error: " <> msg
    base_client.NetworkError(msg) -> "Network error: " <> msg
    base_client.ApiError(code, msg) -> "API error " <> code <> ": " <> msg
    base_client.ParseError(msg) -> "Parse error: " <> msg
  }
}
