/// Supermarket List API
///
/// This module provides functions to list supermarkets from the Tandoor API
/// with pagination support.
///
/// Note: This is a stub implementation. Full client integration pending.
import gleam/option.{type Option}

/// List supermarkets from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated supermarket list or error
///
/// # Example
/// ```gleam
/// let config = ClientConfig(...)
/// let result = list_supermarkets(config, limit: Some(10), offset: None)
/// ```
///
/// TODO: Implement once client has supermarket methods
pub fn list_supermarkets(
  config _config: a,
  limit _limit: Option(Int),
  offset _offset: Option(Int),
) -> Result(b, c) {
  // Placeholder - awaiting client implementation
  // Will delegate to: client.get_supermarkets(config, limit, offset)
  todo as "Supermarket list not yet implemented"
}
