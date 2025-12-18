/// Property decoder for Tandoor SDK
///
/// This module provides JSON decoders for Property types.
/// Property represents an instance/value of a PropertyType applied to a recipe or food.
import gleam/dynamic/decode
import meal_planner/tandoor/decoders/property/property_type_decoder
import meal_planner/tandoor/types/property/property.{type Property, Property}

/// Decode Property from JSON
///
/// Property is an instance with an amount and a reference to a PropertyType template.
///
/// # Returns
/// Decoder for Property type
pub fn property_decoder() -> decode.Decoder(Property) {
  use id <- decode.field("id", decode.int)
  use property_amount <- decode.field(
    "property_amount",
    decode.optional(decode.float),
  )
  use property_type <- decode.field(
    "property_type",
    property_type_decoder.property_type_decoder(),
  )

  decode.success(Property(
    id: id,
    property_amount: property_amount,
    property_type: property_type,
  ))
}
