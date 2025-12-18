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
pub type FoodInheritField {
  FoodInheritField(id: Int, name: String, field: String)
}
