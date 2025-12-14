/// FatSecret Foods service layer
/// Automatic configuration loading and error handling
import gleam/int
import gleam/option.{type Option, None, Some}
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

/// Search for foods with pagination
///
/// Automatically loads FatSecret configuration from environment.
/// Returns ServiceError if not configured.
///
/// ## Parameters
/// - query: Search term (e.g., "apple", "chicken breast")
/// - page: Page number (0-indexed)
/// - max_results: Results per page (1-50, default 20)
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
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.search_foods(config, query, Some(page), Some(max_results)) {
        Ok(response) -> Ok(response)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Simplified search with default page 0 and 20 results
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
  search_foods(query, 0, 20)
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
