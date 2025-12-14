/// Tandoor Property type definition
///
/// This module defines the Property type used for custom properties on recipes and foods in Tandoor.
/// Properties allow users to add custom metadata fields beyond the standard attributes.
///
/// Examples:
/// - Allergen information
/// - Dietary restrictions
/// - Meal prep time categories
/// - Custom nutrition facts
/// - Source/origin tracking
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}

/// Property type (recipe or food)
pub type PropertyType {
  RecipeProperty
  FoodProperty
}

/// Custom property for recipes or foods
///
/// Properties extend Tandoor's data model with user-defined fields.
/// They can be used for filtering, searching, and custom workflows.
///
/// Fields:
/// - id: Unique identifier
/// - name: Property name (required)
/// - description: Optional detailed description
/// - property_type: Whether this applies to recipes or foods
/// - unit: Optional unit of measurement
/// - order: Display order (lower numbers first)
/// - created_at: Creation timestamp (readonly)
/// - updated_at: Last update timestamp (readonly)
pub type Property {
  Property(
    id: Int,
    name: String,
    description: String,
    property_type: PropertyType,
    unit: Option(String),
    order: Int,
    created_at: String,
    updated_at: String,
  )
}
