/// Supermarket category encoder for Tandoor SDK
///
/// This module provides JSON encoders for SupermarketCategoryCreateRequest type for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
import gleam/json.{type Json}
import gleam/option
import meal_planner/tandoor/types/supermarket/supermarket_category_create.{
  type SupermarketCategoryCreateRequest,
}

// ============================================================================
// Supermarket Category Create Encoder
// ============================================================================

/// Encode a SupermarketCategoryCreateRequest to JSON
///
/// This encoder creates JSON for supermarket category creation requests.
/// It includes the required 'name' field and optional 'description' field.
///
/// # Example
/// ```gleam
/// let request = SupermarketCategoryCreateRequest(
///   name: "Produce",
///   description: Some("Fresh fruits and vegetables")
/// )
/// let encoded = encode_supermarket_category_create(request)
/// json.to_string(encoded) // "{\"name\":\"Produce\",\"description\":\"Fresh fruits and vegetables\"}"
/// ```
///
/// # Arguments
/// * `request` - The supermarket category create request to encode
///
/// # Returns
/// JSON representation of the supermarket category create request
pub fn encode_supermarket_category_create(
  request: SupermarketCategoryCreateRequest,
) -> Json {
  let base_fields = [#("name", json.string(request.name))]

  let fields = case request.description {
    option.Some(desc) -> [#("description", json.string(desc)), ..base_fields]
    option.None -> base_fields
  }

  json.object(fields)
}
