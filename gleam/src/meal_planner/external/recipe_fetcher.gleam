//// External Recipe API Fetcher
////
//// This module provides a unified interface for fetching recipes from external APIs.
//// It supports multiple recipe sources and handles error conditions gracefully.

import gleam/list
import meal_planner/types.{type Recipe}

// ============================================================================
// Types
// ============================================================================

/// Supported external recipe sources
pub type RecipeSource {
  /// TheMealDB - Free recipe API (no key required)
  TheMealDB
  /// Spoonacular - Commercial recipe API (requires API key)
  Spoonacular
}

/// Error types for recipe fetching operations
pub type FetchError {
  /// Network error (connection failed, timeout, etc.)
  NetworkError(String)
  /// JSON parsing error (invalid response format)
  ParseError(String)
  /// Rate limiting error (too many requests)
  RateLimitError
  /// Missing API key (for sources that require authentication)
  ApiKeyMissing
  /// Recipe not found
  RecipeNotFound(String)
  /// Invalid query parameters
  InvalidQuery(String)
}

// ============================================================================
// Public API
// ============================================================================

/// Fetch a single recipe by ID from the specified source
/// Note: Actual API implementation should be in source-specific modules
pub fn fetch_recipe(
  source: RecipeSource,
  recipe_id: String,
) -> Result(Recipe, FetchError) {
  case source {
    TheMealDB -> {
      // TODO: Implement actual TheMealDB API call
      // For now, return not found
      Error(RecipeNotFound(recipe_id))
    }
    Spoonacular -> Error(ApiKeyMissing)
  }
}

/// Search for recipes by query string
pub fn search_recipes(
  source: RecipeSource,
  query: String,
  limit: Int,
) -> Result(List(Recipe), FetchError) {
  // Validate limit
  let validated_limit = case limit {
    l if l < 1 -> 1
    l if l > 100 -> 100
    l -> l
  }

  case source {
    TheMealDB -> {
      // TODO: Implement actual TheMealDB API call
      // For now, return empty list
      Ok([])
    }
    Spoonacular -> Error(ApiKeyMissing)
  }
}

/// Get a descriptive name for a recipe source
pub fn source_name(source: RecipeSource) -> String {
  case source {
    TheMealDB -> "TheMealDB"
    Spoonacular -> "Spoonacular"
  }
}

/// Check if a source requires an API key
pub fn requires_api_key(source: RecipeSource) -> Bool {
  case source {
    TheMealDB -> False
    Spoonacular -> True
  }
}

/// Batch fetch multiple recipes by ID
pub fn fetch_recipes_batch(
  source: RecipeSource,
  recipe_ids: List(String),
) -> Result(List(Recipe), FetchError) {
  recipe_ids
  |> list.try_map(fn(id) { fetch_recipe(source, id) })
}

/// Map a FetchError to a user-friendly error message
pub fn error_message(error: FetchError) -> String {
  case error {
    NetworkError(msg) -> "Network error: " <> msg
    ParseError(msg) -> "Failed to parse response: " <> msg
    RateLimitError -> "Rate limit exceeded. Please try again later."
    ApiKeyMissing -> "API key required but not provided"
    RecipeNotFound(id) -> "Recipe not found: " <> id
    InvalidQuery(msg) -> "Invalid query: " <> msg
  }
}
