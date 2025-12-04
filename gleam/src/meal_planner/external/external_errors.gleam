//// External API Error Types
////
//// This module defines common error types for external recipe API fetchers.
//// Separated into its own module to avoid circular dependencies.

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
