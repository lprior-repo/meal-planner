/// Supermarket Create API
///
/// This module provides functions to create new supermarkets in Tandoor.
///
/// Note: This is a stub implementation. Full client integration pending.
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/types/supermarket/supermarket.{type Supermarket}
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest,
}

/// Create a new supermarket
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Supermarket creation request data
///
/// # Returns
/// Result with created supermarket or error
///
/// # Example
/// ```gleam
/// let config = ClientConfig(...)
/// let request = SupermarketCreateRequest(
///   name: "Whole Foods",
///   description: Some("Natural grocery store")
/// )
/// let result = create_supermarket(config, request)
/// ```
///
/// TODO: Implement once client has supermarket methods
pub fn create_supermarket(
  config _config: ClientConfig,
  request _request: SupermarketCreateRequest,
) -> Result(Supermarket, TandoorError) {
  // Placeholder - awaiting client implementation and encoder
  // Will delegate to: client.create_supermarket(config, data)
  todo as "Supermarket API not yet implemented"
}
