/// Migration helpers for transitioning from old client.gleam to new SDK
///
/// This module provides utilities to help migrate code from the legacy
/// monolithic client.gleam to the new modular SDK structure.
///
/// ## Migration Path
///
/// ### Before (Old Client)
/// ```gleam
/// import meal_planner/fatsecret/client
///
/// let config = client.FatSecretConfig(...)
/// case client.search_foods(config, "apple", None, None) {
///   Ok(results) -> process_results(results)
///   Error(e) -> handle_error(e)
/// }
/// ```
///
/// ### After (New SDK)
/// ```gleam
/// import meal_planner/fatsecret/fatsecret
///
/// // Configuration is loaded automatically from environment
/// case fatsecret.search_foods("apple", None, None) {
///   Ok(results) -> process_results(results)
///   Error(fatsecret.NotConfigured) -> handle_not_configured()
///   Error(fatsecret.ApiError(e)) -> handle_api_error(e)
/// }
/// ```
///
/// ## Key Changes
///
/// 1. **Configuration**: Automatically loaded from environment via `config.from_env()`
/// 2. **Module Organization**: Domain-specific modules (foods, recipes, diary, etc.)
/// 3. **Service Layer**: High-level functions in `*/service.gleam` modules
/// 4. **Error Types**: More specific error types per domain
/// 5. **Opaque Types**: Type-safe IDs (FoodId, RecipeId, etc.)
import gleam/option.{type Option}
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/fatsecret
import meal_planner/fatsecret/foods/service as foods_service
import meal_planner/fatsecret/recipes/service as recipes_service

// ============================================================================
// Configuration Migration
// ============================================================================

/// OLD: Manual configuration construction
/// ```gleam
/// let config = client.FatSecretConfig(
///   consumer_key: "...",
///   consumer_secret: "...",
///   api_host: None,
///   auth_host: None,
/// )
/// ```
///
/// NEW: Automatic environment loading (recommended)
/// ```gleam
/// // Configuration loaded automatically by service functions
/// case fatsecret.search_foods("apple", None, None) {
///   Ok(results) -> ...
///   Error(fatsecret.NotConfigured) -> ...
/// }
/// ```
///
/// NEW: Explicit configuration (if needed)
/// ```gleam
/// case config.from_env() {
///   Some(config) -> use_config(config)
///   None -> handle_missing_config()
/// }
/// ```
pub fn load_config() -> Option(config.FatSecretConfig) {
  config.from_env()
}

// ============================================================================
// Foods API Migration
// ============================================================================

/// OLD: Direct client call with config
/// ```gleam
/// case client.search_foods(config, "apple", Some(0), Some(20)) {
///   Ok(response) -> process(response)
///   Error(e) -> handle_error(e)
/// }
/// ```
///
/// NEW: Service layer automatically handles config
/// ```gleam
/// case fatsecret.search_foods("apple", Some(0), Some(20)) {
///   Ok(response) -> process(response)
///   Error(e) -> handle_error(e)
/// }
/// ```
///
/// Migration helper: Use this if you have existing client code
pub fn search_foods_legacy(
  query: String,
  page: Option(Int),
  max_results: Option(Int),
) -> Result(fatsecret.FoodSearchResponse, String) {
  case foods_service.search_foods(query, page, max_results) {
    Ok(response) -> Ok(response)
    Error(e) -> Error(legacy_error_message(e))
  }
}

/// OLD: Get food by string ID
/// ```gleam
/// case client.get_food(config, "12345") {
///   Ok(food) -> process(food)
///   Error(e) -> handle_error(e)
/// }
/// ```
///
/// NEW: Type-safe FoodId
/// ```gleam
/// let food_id = fatsecret.food_id("12345")
/// case fatsecret.get_food(food_id) {
///   Ok(food) -> process(food)
///   Error(e) -> handle_error(e)
/// }
/// ```
pub fn get_food_legacy(food_id_str: String) -> Result(fatsecret.Food, String) {
  let food_id = fatsecret.food_id(food_id_str)
  case foods_service.get_food(food_id) {
    Ok(food) -> Ok(food)
    Error(e) -> Error(legacy_error_message(e))
  }
}

// ============================================================================
// Recipes API Migration
// ============================================================================

/// OLD: Recipe search with string ID
/// ```gleam
/// case client.search_recipes(config, "chicken", None, None) {
///   Ok(results) -> process(results)
///   Error(e) -> handle_error(e)
/// }
/// ```
///
/// NEW: Service layer with better typing
/// ```gleam
/// case fatsecret.search_recipes("chicken", None, None) {
///   Ok(results) -> process(results)
///   Error(e) -> handle_error(e)
/// }
/// ```
pub fn search_recipes_legacy(
  query: String,
  page: Option(Int),
  max_results: Option(Int),
) -> Result(fatsecret.RecipeSearchResponse, String) {
  case recipes_service.search_recipes(query, page, max_results) {
    Ok(response) -> Ok(response)
    Error(e) -> Error(legacy_error_message_recipe(e))
  }
}

/// OLD: Get recipe by string ID
/// ```gleam
/// case client.get_recipe(config, "67890") {
///   Ok(recipe) -> process(recipe)
///   Error(e) -> handle_error(e)
/// }
/// ```
///
/// NEW: Type-safe RecipeId
/// ```gleam
/// let recipe_id = fatsecret.recipe_id("67890")
/// case fatsecret.get_recipe(recipe_id) {
///   Ok(recipe) -> process(recipe)
///   Error(e) -> handle_error(e)
/// }
/// ```
pub fn get_recipe_legacy(
  recipe_id_str: String,
) -> Result(fatsecret.Recipe, String) {
  let recipe_id = fatsecret.recipe_id(recipe_id_str)
  case recipes_service.get_recipe(recipe_id) {
    Ok(recipe) -> Ok(recipe)
    Error(e) -> Error(legacy_error_message_recipe(e))
  }
}

// ============================================================================
// Error Handling Migration
// ============================================================================

/// Convert new service errors to legacy string format
///
/// OLD: Errors were typically strings
/// ```gleam
/// Error("Failed to connect to API")
/// ```
///
/// NEW: Structured error types
/// ```gleam
/// Error(foods_service.NotConfigured)
/// Error(foods_service.ApiError(errors.ApiError(...)))
/// ```
fn legacy_error_message(error: foods_service.ServiceError) -> String {
  case error {
    foods_service.NotConfigured ->
      "FatSecret not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET"
    foods_service.ApiError(api_error) -> errors.error_to_string(api_error)
  }
}

/// Convert recipe service errors to legacy string format
fn legacy_error_message_recipe(
  error: recipes_service.RecipeServiceError,
) -> String {
  case error {
    recipes_service.NotConfigured ->
      "FatSecret not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET"
    recipes_service.ApiError(api_error) -> errors.error_to_string(api_error)
  }
}
/// Migration helper for HTTP handlers
///
/// OLD: Handlers manually created config and called client
/// ```gleam
/// pub fn handle_search(req: Request) -> Response {
///   case env.load_fatsecret_config() {
///     None -> error_response("Not configured")
///     Some(config) -> {
///       case client.search_foods(config, query, None, None) {
///         Ok(results) -> json_response(results)
///         Error(e) -> error_response(e)
///       }
///     }
///   }
/// }
/// ```
///
/// NEW: Handlers use service layer directly
/// ```gleam
/// pub fn handle_search(req: Request) -> Response {
///   case fatsecret.search_foods(query, None, None) {
///     Ok(results) -> json_response(results)
///     Error(fatsecret.NotConfigured) ->
///       error_response(500, "FatSecret not configured")
///     Error(fatsecret.ApiError(e)) ->
///       error_response(500, errors.error_to_string(e))
///   }
/// }
/// ```
/// ## OLD Import Structure
/// ```gleam
/// import meal_planner/fatsecret/client
///
/// // All types and functions in one module
/// client.FatSecretConfig
/// client.Food
/// client.Recipe
/// client.search_foods()
/// client.get_recipe()
/// ```
///
/// ## NEW Import Structure
/// ```gleam
/// import meal_planner/fatsecret/fatsecret
///
/// // Organized by domain, all accessible via facade
/// fatsecret.FatSecretConfig
/// fatsecret.Food
/// fatsecret.Recipe
/// fatsecret.search_foods()
/// fatsecret.get_recipe()
/// ```
///
/// ## Or import domain-specific modules
/// ```gleam
/// import meal_planner/fatsecret/foods/types as foods
/// import meal_planner/fatsecret/foods/service as foods_service
/// import meal_planner/fatsecret/recipes/types as recipes
/// import meal_planner/fatsecret/recipes/service as recipes_service
///
/// foods.Food
/// foods_service.search_foods()
/// recipes.Recipe
/// recipes_service.get_recipe()
/// ```
/// | Old Client Function           | New SDK Function              |
/// |------------------------------|-------------------------------|
/// | client.search_foods()        | fatsecret.search_foods()      |
/// | client.get_food()            | fatsecret.get_food()          |
/// | client.search_recipes()      | fatsecret.search_recipes()    |
/// | client.get_recipe()          | fatsecret.get_recipe()        |
/// | client.get_recipe_types()    | fatsecret.get_recipe_types()  |
/// | client.add_favorite_food()   | fatsecret.add_favorite_food() |
/// | client.get_saved_meals()     | fatsecret.get_saved_meals()   |
/// | client.create_saved_meal()   | fatsecret.create_saved_meal() |
/// | client.get_weight()          | fatsecret.get_weight()        |
/// | client.update_weight()       | fatsecret.update_weight()     |
/// | Old Type                  | New Type                        |
/// |---------------------------|--------------------------------|
/// | String (food ID)          | fatsecret.FoodId               |
/// | String (recipe ID)        | fatsecret.RecipeId             |
/// | String (serving ID)       | fatsecret.ServingId            |
/// | String (meal type)        | fatsecret.DiaryMealType        |
/// | client.FatSecretError     | fatsecret.FatSecretError       |
/// | client.Food               | fatsecret.Food                 |
/// | client.Recipe             | fatsecret.Recipe               |
/// | client.FoodEntry          | fatsecret.FoodEntry            |
/// | client.SavedMeal          | fatsecret.SavedMeal            |
/// | client.WeightEntry        | fatsecret.WeightEntry          |
// ============================================================================
// Handler Migration Helpers
// ============================================================================

// ============================================================================
// Module Import Migration Guide
// ============================================================================

// ============================================================================
// Quick Reference: API Mapping
// ============================================================================

// ============================================================================
// Type Migration Guide
// ============================================================================
