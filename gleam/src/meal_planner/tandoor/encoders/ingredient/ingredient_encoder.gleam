/// Ingredient encoder for Tandoor SDK
///
/// This module provides JSON encoders for Ingredient create/update types for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoders handle:
/// - Required fields (always encoded)
/// - Optional fields (null for None values)
/// - Clean, minimal JSON output matching Tandoor API expectations
import gleam/json.{type Json}
import gleam/option.{type Option}

// ============================================================================
// Ingredient Create/Update Request Type
// ============================================================================

/// Request to create or update an ingredient
/// This matches the Tandoor API /api/ingredient/ endpoint expectations
pub type IngredientCreateRequest {
  IngredientCreateRequest(
    food: Option(Int),
    // Food ID (nullable)
    unit: Option(Int),
    // Unit ID (nullable)
    amount: Float,
    // Quantity
    note: Option(String),
    // Additional notes (nullable)
    order: Int,
    // Display order
    is_header: Bool,
    // Is section header
    no_amount: Bool,
    // No amount specified
    original_text: Option(String),
    // Original text (nullable)
  )
}

// ============================================================================
// Ingredient Create/Update Encoder
// ============================================================================

/// Encode an IngredientCreateRequest to JSON
///
/// This encoder creates JSON for ingredient creation/update requests.
/// It includes all fields, encoding None as null for optional fields.
///
/// # Example
/// ```gleam
/// let ingredient = IngredientCreateRequest(
///   food: Some(5),
///   unit: Some(2),
///   amount: 250.0,
///   note: Some("diced"),
///   order: 1,
///   is_header: False,
///   no_amount: False,
///   original_text: Some("250g tomatoes, diced")
/// )
/// let encoded = encode_ingredient_create(ingredient)
/// json.to_string(encoded)
/// ```
///
/// # Arguments
/// * `ingredient` - The ingredient create request to encode
///
/// # Returns
/// JSON representation of the ingredient create request
pub fn encode_ingredient_create(ingredient: IngredientCreateRequest) -> Json {
  json.object([
    #("food", encode_optional_int(ingredient.food)),
    #("unit", encode_optional_int(ingredient.unit)),
    #("amount", json.float(ingredient.amount)),
    #("note", encode_optional_string(ingredient.note)),
    #("order", json.int(ingredient.order)),
    #("is_header", json.bool(ingredient.is_header)),
    #("no_amount", json.bool(ingredient.no_amount)),
    #("original_text", encode_optional_string(ingredient.original_text)),
  ])
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Encode optional integer field (None becomes null)
fn encode_optional_int(value: Option(Int)) -> Json {
  case value {
    option.Some(v) -> json.int(v)
    option.None -> json.null()
  }
}

/// Encode optional string field (None becomes null)
fn encode_optional_string(value: Option(String)) -> Json {
  case value {
    option.Some(v) -> json.string(v)
    option.None -> json.null()
  }
}
