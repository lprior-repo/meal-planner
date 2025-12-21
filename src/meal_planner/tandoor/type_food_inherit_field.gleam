/// Tandoor FoodInheritField type definition
///
/// This module defines the FoodInheritField type for controlling field inheritance
/// in the food hierarchy/tree structure.
///
/// Based on Tandoor API 2.3.6 specification.
/// Specifies which fields are inherited from parent foods
///
/// FoodInheritField controls which properties are automatically inherited when
/// a food is linked to a parent food in the food tree hierarchy.
///
/// Fields:
/// - id: Unique identifier
/// - name: Human-readable field name (e.g., "Nutrition", "Price")
/// - field: Machine-friendly field identifier (e.g., "nutrition", "price")
import gleam/dynamic/decode

pub type FoodInheritField {
  FoodInheritField(id: Int, name: String, field: String)
}

/// Decode a FoodInheritField from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Nutrition",
///   "field": "nutrition"
/// }
/// ```
pub fn food_inherit_field_decoder() -> decode.Decoder(FoodInheritField) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use field <- decode.field("field", decode.string)

  decode.success(FoodInheritField(id: id, name: name, field: field))
}
