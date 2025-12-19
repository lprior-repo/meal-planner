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
  type Food, type FoodAutocompleteResponse, type FoodId, type FoodSearchResponse,
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

/// Search for foods with optional pagination parameters
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns paginated search results with basic food information.
/// This is the core implementation that other search functions call.
///
/// ## Parameters
/// - query: Search term (e.g., "apple", "chicken breast")
/// - page: Page number (0-indexed), None for first page (0)
/// - max_results: Results per page (1-50), None for default (20)
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case list_foods_with_options(config, "banana", Some(0), Some(20)) {
///   Ok(response) -> {
///     io.println("Found " <> int.to_string(response.total_results) <> " results")
///     list.each(response.foods, fn(food) {
///       io.println("- " <> food.food_name)
///     })
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn list_foods_with_options(
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

/// Search for foods using the foods.search endpoint
///
/// This is a convenience wrapper around `list_foods_with_options` that takes
/// concrete Int values instead of Option(Int). Use this when you have specific
/// page and max_results values.
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns paginated search results with basic food information.
///
/// ## Parameters
/// - query: Search term (e.g., "apple", "chicken breast")
/// - page: Page number (0-indexed)
/// - max_results: Results per page (1-50)
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case search_foods(config, "banana", 0, 20) {
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
  page: Int,
  max_results: Int,
) -> Result(FoodSearchResponse, FatSecretError) {
  list_foods_with_options(
    config,
    query,
    option.Some(page),
    option.Some(max_results),
  )
}

/// Simplified search with defaults (page 0, max 20 results)
///
/// This is a convenience wrapper that uses default pagination values.
/// Use this for simple searches where you don't need pagination control.
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
  list_foods_with_options(config, query, None, None)
}

// ============================================================================
// Food Barcode Lookup API (food.find_id_for_barcode.v2)
// ============================================================================

/// Find food ID by barcode using food.find_id_for_barcode.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns the food ID associated with the barcode, which can then be used
/// with get_food() to retrieve full nutrition details.
///
/// ## Parameters
/// - config: FatSecret API configuration
/// - barcode: Barcode string (UPC, EAN13, EAN8, etc.)
/// - barcode_type: Optional barcode type ("upc", "ean13", "ean8")
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case find_food_by_barcode(config, "012000161551", option.Some("upc")) {
///   Ok(food) -> io.println("Food: " <> food.food_name)
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn find_food_by_barcode(
  config: FatSecretConfig,
  barcode: String,
  barcode_type: Option(String),
) -> Result(Food, FatSecretError) {
  // Build parameters for barcode lookup
  let params = case barcode_type {
    option.Some(btype) ->
      dict.new()
      |> dict.insert("barcode", barcode)
      |> dict.insert("barcode_type", btype)
    option.None ->
      dict.new()
      |> dict.insert("barcode", barcode)
  }

  // Use base client's make_api_request function
  use response_json <- result.try(base_client.make_api_request(
    config,
    "food.find_id_for_barcode.v2",
    params,
  ))

  // Parse JSON response to extract food_id
  use food_id_value <- result.try(
    json.parse(response_json, decoders.barcode_lookup_decoder())
    |> result.map_error(fn(_) {
      base_client.ParseError(
        "Failed to decode barcode lookup response: " <> response_json,
      )
    }),
  )

  // Now fetch the complete food details using the found food_id
  get_food(config, food_id_value)
}

// ============================================================================
// Food Autocomplete API (foods.autocomplete.v2)
// ============================================================================

/// Get food suggestions with optional max results using foods.autocomplete.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns a list of food suggestions matching the search expression.
///
/// ## Parameters
/// - expression: Search term for autocomplete (required)
/// - max_results: Maximum suggestions to return (optional, default varies by API)
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case autocomplete_foods_with_options(config, "banan", Some(10)) {
///   Ok(response) -> {
///     list.each(response.suggestions, fn(suggestion) {
///       io.println("- " <> suggestion.food_name)
///     })
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn autocomplete_foods_with_options(
  config: FatSecretConfig,
  expression: String,
  max_results: option.Option(Int),
) -> Result(FoodAutocompleteResponse, FatSecretError) {
  // Build autocomplete parameters
  let params = dict.new() |> dict.insert("expression", expression)

  let params = case max_results {
    option.Some(max) -> dict.insert(params, "max_results", int.to_string(max))
    option.None -> params
  }

  // Use base client's make_api_request function
  use response_json <- result.try(base_client.make_api_request(
    config,
    "foods.autocomplete.v2",
    params,
  ))

  // Parse JSON response with type-safe decoders
  json.parse(response_json, decoders.food_autocomplete_response_decoder())
  |> result.map_error(fn(_) {
    base_client.ParseError(
      "Failed to decode autocomplete response: " <> response_json,
    )
  })
}

/// Get food suggestions using foods.autocomplete.v2 endpoint
///
/// This is a convenience wrapper around `autocomplete_foods_with_options` that
/// uses no max_results limit. Use this for simple autocomplete suggestions.
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns a list of food suggestions matching the search expression.
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case autocomplete_foods(config, "apple") {
///   Ok(response) -> {
///     list.each(response.suggestions, fn(suggestion) {
///       io.println("- " <> suggestion.food_name)
///     })
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn autocomplete_foods(
  config: FatSecretConfig,
  expression: String,
) -> Result(FoodAutocompleteResponse, FatSecretError) {
  autocomplete_foods_with_options(config, expression, option.None)
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
