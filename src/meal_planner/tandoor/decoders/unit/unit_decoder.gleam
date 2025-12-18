/// Unit decoder for Tandoor SDK
///
/// Provides JSON decoders for Unit type (measurement units like gram, liter, piece).
import gleam/dynamic/decode
import meal_planner/tandoor/types/unit/unit.{type Unit, Unit}

/// Decode a Unit from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "gram",
///   "plural_name": "grams",
///   "description": "Metric unit of mass",
///   "base_unit": "kilogram",
///   "open_data_slug": "g"
/// }
/// ```
///
/// Required fields:
/// - id: Int
/// - name: String
///
/// Optional fields (nullable):
/// - plural_name: String
/// - description: String
/// - base_unit: String
/// - open_data_slug: String
pub fn decode_unit() -> decode.Decoder(Unit) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.field("plural_name", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use base_unit <- decode.field("base_unit", decode.optional(decode.string))
  use open_data_slug <- decode.field(
    "open_data_slug",
    decode.optional(decode.string),
  )

  decode.success(Unit(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
    base_unit: base_unit,
    open_data_slug: open_data_slug,
  ))
}
