/// Recipe validation module for verifying recipe slugs exist in Mealie before logging
///
/// This module provides validation functions to ensure recipe slugs are valid
/// and exist in the Mealie database before they are logged to the meal planner.
/// This prevents orphaned log entries with non-existent recipes.

import gleam/list
import gleam/result
import meal_planner/config.{type Config}
import meal_planner/mealie/client
import meal_planner/mealie/retry

pub type ValidationError {
  /// Recipe slug was not found in Mealie
  RecipeNotFound(slug: String)
  /// Connection error while validating recipe
  ConnectionError(message: String)
  /// Mealie service is unavailable
  ServiceUnavailable(message: String)
  /// Configuration is missing or invalid
  ConfigurationError(message: String)
}

/// Convert ValidationError to a user-friendly message
pub fn error_to_message(error: ValidationError) -> String {
  case error {
    RecipeNotFound(slug) ->
      "Recipe '" <> slug <> "' was not found in your recipe database."
    ConnectionError(msg) ->
      "Unable to verify recipe: " <> msg <> ". Please try again."
    ServiceUnavailable(msg) ->
      "Recipe service is temporarily unavailable: " <> msg
    ConfigurationError(msg) ->
      "Recipe service is not properly configured: " <> msg
  }
}

/// Validate that a recipe slug exists in Mealie before logging
///
/// This function attempts to fetch the recipe from Mealie to verify it exists.
/// Returns Ok(slug) if the recipe exists, or an error if validation fails.
///
/// Example:
/// ```gleam
/// case validate_recipe_slug(config, "chicken-stir-fry") {
///   Ok(slug) -> io.println("Recipe validated: " <> slug)
///   Error(RecipeNotFound(slug)) -> io.println("Recipe not found: " <> slug)
///   Error(err) -> io.println("Validation error: " <> error_to_message(err))
/// }
/// ```
pub fn validate_recipe_slug(
  config: Config,
  slug: String,
) -> Result(String, ValidationError) {
  use resolved_slug <- result.try(
    case retry.with_backoff(fn() { client.resolve_recipe_slug(config, slug) }) {
      Ok(s) -> Ok(s)
      Error(client.RecipeNotFound(_)) -> Error(RecipeNotFound(slug))
      Error(client.ConfigError(msg)) -> Error(ConfigurationError(msg))
      Error(client.ConnectionRefused(msg)) -> Error(ConnectionError(msg))
      Error(client.DnsResolutionFailed(msg)) -> Error(ConnectionError(msg))
      Error(client.NetworkTimeout(msg, _)) -> Error(ConnectionError(msg))
      Error(client.MealieUnavailable(msg)) -> Error(ServiceUnavailable(msg))
      Error(client.HttpError(msg)) -> Error(ConnectionError(msg))
      Error(client.DecodeError(msg)) -> Error(ConnectionError(msg))
      Error(client.ApiError(api_err)) -> Error(ServiceUnavailable(api_err.message))
    }
  )

  Ok(resolved_slug)
}

/// Validate multiple recipe slugs in batch
///
/// Returns a tuple of (valid_slugs, invalid_slugs) for batch validation.
/// This is useful when logging multiple recipes to catch any issues upfront.
///
/// Example:
/// ```gleam
/// case validate_recipe_slugs_batch(config, ["recipe-1", "recipe-2", "invalid-recipe"]) {
///   Ok(#(valid, invalid)) -> {
///     io.println("Valid: " <> string.inspect(valid))
///     io.println("Invalid: " <> string.inspect(invalid))
///   }
///   Error(err) -> io.println("Batch validation failed: " <> error_to_message(err))
/// }
/// ```
pub fn validate_recipe_slugs_batch(
  config: Config,
  slugs: List(String),
) -> Result(#(List(String), List(String)), ValidationError) {
  let results =
    list.map(slugs, fn(slug) {
      case validate_recipe_slug(config, slug) {
        Ok(s) -> Ok(s)
        Error(RecipeNotFound(_)) -> Error(slug)
        Error(err) -> Error(error_to_message(err))
      }
    })

  let #(valid, invalid) =
    list.partition(results, fn(result) {
      case result {
        Ok(_) -> True
        Error(_) -> False
      }
    })

  let valid_slugs =
    list.filter_map(valid, fn(result) {
      case result {
        Ok(slug) -> Ok(slug)
        Error(_) -> Error(Nil)
      }
    })

  let invalid_slugs =
    list.filter_map(invalid, fn(result) {
      case result {
        Ok(_) -> Error(Nil)
        Error(slug) -> Ok(slug)
      }
    })

  Ok(#(valid_slugs, invalid_slugs))
}
