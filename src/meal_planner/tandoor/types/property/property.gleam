/// Tandoor Property type definition
///
/// This module defines the Property type - an instance/value of a PropertyType applied to an entity.
/// Properties allow users to add custom metadata fields beyond the standard attributes.
///
/// Note: Property is the VALUE (instance with an amount).
/// PropertyType is the TEMPLATE (schema/definition).
///
/// Examples of Property values:
/// - Recipe has allergen "Peanuts" (property_amount = "Yes")
/// - Food has prep time 15 minutes (property_amount = "15")
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}
import meal_planner/tandoor/types/property/property_type.{type PropertyType}

/// Custom property instance/value for recipes or foods
///
/// Property represents a specific VALUE of a PropertyType applied to a recipe or food.
/// It connects a PropertyType (the schema) with an amount (the value).
///
/// Fields:
/// - id: Unique identifier for this property instance
/// - property_amount: The value/amount for this property (nullable, depends on type)
/// - property_type: Reference to the PropertyType template (schema)
pub type Property {
  Property(id: Int, property_amount: Option(Float), property_type: PropertyType)
}
