/// Property decoder for Tandoor SDK
///
/// This module provides JSON decoders for Property types.
/// Handles both RECIPE and FOOD property types.
import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/types/property/property.{
  type Property, type PropertyType, FoodProperty, Property, RecipeProperty,
}

/// Decode PropertyType from JSON string
fn property_type_decoder() -> decode.Decoder(PropertyType) {
  use type_string <- decode.then(decode.string)
  case type_string {
    "RECIPE" -> decode.success(RecipeProperty)
    "FOOD" -> decode.success(FoodProperty)
    _ -> decode.failure(RecipeProperty, "Unknown property type: " <> type_string)
  }
}

/// Decode Property from JSON
///
/// # Returns
/// Decoder for Property type
pub fn property_decoder() -> decode.Decoder(Property) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use description <- decode.parameter
    use property_type <- decode.parameter
    use unit <- decode.parameter
    use order <- decode.parameter
    use created_at <- decode.parameter
    use updated_at <- decode.parameter

    Property(
      id:,
      name:,
      description:,
      property_type:,
      unit:,
      order:,
      created_at:,
      updated_at:,
    )
  })
  |> decode.field("id", decode.int)
  |> decode.field("name", decode.string)
  |> decode.field("description", decode.string)
  |> decode.field("property_type", property_type_decoder())
  |> decode.field("unit", decode.optional(decode.string))
  |> decode.field("order", decode.int)
  |> decode.field("created_at", decode.string)
  |> decode.field("updated_at", decode.string)
}
