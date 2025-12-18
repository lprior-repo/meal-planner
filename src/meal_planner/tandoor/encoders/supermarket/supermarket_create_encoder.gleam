/// Supermarket Create encoder for Tandoor SDK
///
/// This module provides JSON encoders for SupermarketCreateRequest for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
import gleam/json.{type Json}
import gleam/list
import gleam/option
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest,
}

// ============================================================================
// Supermarket Create Encoder
// ============================================================================

/// Encode a SupermarketCreateRequest to JSON
///
/// This encoder creates minimal JSON for supermarket creation requests.
/// It includes the required 'name' field and optional 'description' field.
///
/// # Example
/// ```gleam
/// let supermarket = SupermarketCreateRequest(
///   name: "Whole Foods",
///   description: Some("Natural grocery store")
/// )
/// let encoded = encode_supermarket_create(supermarket)
/// json.to_string(encoded) // "{\"name\":\"Whole Foods\",\"description\":\"Natural grocery store\"}"
/// ```
///
/// # Arguments
/// * `supermarket` - The supermarket create request to encode
///
/// # Returns
/// JSON representation of the supermarket create request
pub fn encode_supermarket_create(supermarket: SupermarketCreateRequest) -> Json {
  let base = [#("name", json.string(supermarket.name))]

  let with_description = case supermarket.description {
    option.Some(desc) ->
      list.append(base, [#("description", json.string(desc))])
    option.None -> base
  }

  json.object(with_description)
}
