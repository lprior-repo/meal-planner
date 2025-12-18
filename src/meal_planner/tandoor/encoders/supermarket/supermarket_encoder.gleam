/// Supermarket encoder for Tandoor SDK
///
/// This module provides JSON encoders for SupermarketCreateRequest type for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
import gleam/json.{type Json}
import gleam/option
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest,
}

// ============================================================================
// Supermarket Create Encoder
// ============================================================================

/// Encode a SupermarketCreateRequest to JSON
///
/// This encoder creates JSON for supermarket creation requests.
/// It includes the required 'name' field and optional 'description' field.
///
/// # Example
/// ```gleam
/// let request = SupermarketCreateRequest(
///   name: "Whole Foods",
///   description: Some("Natural and organic grocery store")
/// )
/// let encoded = encode_supermarket_create(request)
/// json.to_string(encoded) // "{\"name\":\"Whole Foods\",\"description\":\"Natural and organic grocery store\"}"
/// ```
///
/// # Arguments
/// * `request` - The supermarket create request to encode
///
/// # Returns
/// JSON representation of the supermarket create request
pub fn encode_supermarket_create(request: SupermarketCreateRequest) -> Json {
  let base_fields = [#("name", json.string(request.name))]

  let fields = case request.description {
    option.Some(desc) -> [#("description", json.string(desc)), ..base_fields]
    option.None -> base_fields
  }

  json.object(fields)
}
