/// Property decoder for Tandoor SDK
///
/// This module provides JSON decoders for Property types.
/// Handles both RECIPE and FOOD property types.
import gleam/dynamic/decode
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/property/property.{
  type Property, type PropertyType, FoodProperty, Property, RecipeProperty,
}

/// Decode PropertyType from JSON string
fn property_type_decoder() -> decode.Decoder(PropertyType) {
  use type_string <- decode.then(decode.string)
  case type_string {
    "RECIPE" -> decode.success(RecipeProperty)
    "FOOD" -> decode.success(FoodProperty)
    _ ->
      decode.failure(RecipeProperty, "Unknown property type: " <> type_string)
  }
}

/// Decode Property from JSON
///
/// # Returns
/// Decoder for Property type
pub fn property_decoder() -> decode.Decoder(Property) {
  use id <- decode.field("id", ids.property_id_decoder())
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use property_type <- decode.field("property_type", property_type_decoder())
  use unit <- decode.field("unit", decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(Property(
    id: id,
    name: name,
    description: description,
    property_type: property_type,
    unit: unit,
    order: order,
    created_at: created_at,
    updated_at: updated_at,
  ))
}
