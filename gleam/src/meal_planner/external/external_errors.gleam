//// External API Error Types
////
//// This module defines common error types for external recipe API fetchers.

pub type FetchError {
  NetworkError(String)
  ParseError(String)
  RateLimitError
  ApiKeyMissing
  RecipeNotFound(String)
  InvalidQuery(String)
}
