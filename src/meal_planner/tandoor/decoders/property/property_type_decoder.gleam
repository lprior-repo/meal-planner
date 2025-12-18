/// PropertyType decoder for Tandoor SDK
///
/// This module provides JSON decoders for PropertyType.
/// PropertyType is a template/schema for custom properties.
import gleam/dynamic/decode
import meal_planner/tandoor/types/property/property_type.{
  type PropertyType, PropertyType,
}

/// Decode PropertyType from JSON
///
/// PropertyType represents a template for custom properties with optional fields
/// for unit, description, open_data_slug, and fdc_id.
///
/// # Returns
/// Decoder for PropertyType
pub fn property_type_decoder() -> decode.Decoder(PropertyType) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use unit <- decode.field("unit", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use open_data_slug <- decode.field(
    "open_data_slug",
    decode.optional(decode.string),
  )
  use fdc_id <- decode.field("fdc_id", decode.optional(decode.int))

  decode.success(PropertyType(
    id: id,
    name: name,
    unit: unit,
    description: description,
    order: order,
    open_data_slug: open_data_slug,
    fdc_id: fdc_id,
  ))
}
