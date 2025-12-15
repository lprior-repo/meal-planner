/// FatSecret Foods service layer
/// Automatic configuration loading and error handling
import gleam/option.{None, Some}
import meal_planner/env
import meal_planner/fatsecret/foods/client
import meal_planner/fatsecret/foods/types.{
  type Food, type FoodId, type FoodSearchResponse,
}

/// Service-level errors with clearer messaging
pub type ServiceError {
  /// FatSecret API credentials not configured
  NotConfigured
  /// API error from FatSecret
  ApiError(inner: client.FatSecretError)
}

// ============================================================================
// Public API - Configuration handled automatically
// ============================================================================

/// Get complete food details by ID
///
/// Automatically loads FatSecret configuration from environment.
/// Returns ServiceError if not configured.
///
/// ## Example
/// ```gleam
/// let food_id = types.food_id("12345")
/// case get_food(food_id) {
///   Ok(food) -> io.println("Food: " <> food.food_name)
///   Error(NotConfigured) -> io.println("FatSecret not configured")
///   Error(ApiError(e)) -> io.println("API error: " <> client.error_to_string(e))
/// }
/// ```
pub fn get_food(food_id: FoodId) -> Result(Food, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.get_food(config, food_id) {
        Ok(food) -> Ok(food)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Search for foods with optional pagination parameters
///
/// This is the core implementation that other search functions call.
/// Automatically loads FatSecret configuration from environment.
/// Returns ServiceError if not configured.
///
/// ## Parameters
/// - query: Search term (e.g., "apple", "chicken breast")
/// - page: Page number (0-indexed), None for first page (0)
/// - max_results: Results per page (1-50), None for default (20)
///
/// ## Example
/// ```gleam
/// case list_foods_with_options("banana", Some(0), Some(20)) {
///   Ok(response) -> {
///     io.println("Found " <> int.to_string(response.total_results))
///     list.each(response.foods, fn(food) {
///       io.println("- " <> food.food_name)
///     })
///   }
///   Error(NotConfigured) -> io.println("FatSecret not configured")
///   Error(ApiError(e)) -> io.println("API error")
/// }
/// ```
pub fn list_foods_with_options(
  query: String,
  page: option.Option(Int),
  max_results: option.Option(Int),
) -> Result(FoodSearchResponse, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.list_foods_with_options(config, query, page, max_results) {
        Ok(response) -> Ok(response)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Search for foods with pagination
///
/// This is a convenience wrapper around `list_foods_with_options` that takes
/// concrete Int values instead of Option(Int). Use this when you have specific
/// page and max_results values.
///
/// Automatically loads FatSecret configuration from environment.
/// Returns ServiceError if not configured.
///
/// ## Parameters
/// - query: Search term (e.g., "apple", "chicken breast")
/// - page: Page number (0-indexed)
/// - max_results: Results per page (1-50)
///
/// ## Example
/// ```gleam
/// case search_foods("banana", 0, 20) {
///   Ok(response) -> {
///     io.println("Found " <> int.to_string(response.total_results))
///     list.each(response.foods, fn(food) {
///       io.println("- " <> food.food_name)
///     })
///   }
///   Error(NotConfigured) -> io.println("FatSecret not configured")
///   Error(ApiError(e)) -> io.println("API error")
/// }
/// ```
pub fn search_foods(
  query: String,
  page: Int,
  max_results: Int,
) -> Result(FoodSearchResponse, ServiceError) {
  list_foods_with_options(query, Some(page), Some(max_results))
}

/// Simplified search with default page 0 and 20 results
///
/// This is a convenience wrapper that uses default pagination values.
/// Use this for simple searches where you don't need pagination control.
///
/// ## Example
/// ```gleam
/// case search_foods_simple("banana") {
///   Ok(response) -> list.each(response.foods, fn(food) {
///     io.println(food.food_name)
///   })
///   Error(e) -> io.println(error_to_string(e))
/// }
/// ```
pub fn search_foods_simple(
  query: String,
) -> Result(FoodSearchResponse, ServiceError) {
  list_foods_with_options(query, None, None)
}

// ============================================================================
// Error Handling
// ============================================================================

/// Convert ServiceError to user-friendly string
pub fn error_to_string(error: ServiceError) -> String {
  case error {
    NotConfigured ->
      "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET environment variables."
    ApiError(inner) -> client.error_to_string(inner)
  }
}
