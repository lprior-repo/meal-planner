/// Tandoor PropertyType type definition
///
/// This module defines the PropertyType type - a template for custom properties
/// that can be applied to recipes and foods in Tandoor.
///
/// PropertyType defines WHAT a property is (the schema/template),
/// while Property represents a specific VALUE of that property.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}

/// Template/schema for custom properties
///
/// PropertyType defines a reusable property template that can be applied to
/// multiple recipes or foods. It specifies the property's name, unit, and metadata.
///
/// Fields:
/// - id: Unique identifier
/// - name: Human-readable property name (required)
/// - unit: Optional unit of measurement (e.g., "degrees C", "minutes")
/// - description: Optional detailed explanation of this property
/// - order: Display order (lower numbers first)
/// - open_data_slug: Reference to Open Food Facts property (optional)
/// - fdc_id: Reference to USDA Food Data Central ID (optional)
pub type PropertyType {
  PropertyType(
    id: Int,
    name: String,
    unit: Option(String),
    description: Option(String),
    order: Int,
    open_data_slug: Option(String),
    fdc_id: Option(Int),
  )
}
