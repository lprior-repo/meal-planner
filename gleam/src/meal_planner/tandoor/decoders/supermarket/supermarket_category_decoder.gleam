/// Decoder for SupermarketCategory type
///
/// Handles JSON decoding from Tandoor API responses
import gleam/dynamic/decode
import gleam/option.{type Option, None}
import meal_planner/tandoor/types/supermarket/supermarket_category.{
  type SupermarketCategory, SupermarketCategory,
}

/// Decoder for SupermarketCategory
/// Decodes JSON from Tandoor API into SupermarketCategory type
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "Produce",
///   "description": "Fresh fruits and vegetables",
///   "open_data_slug": "produce"
/// }
/// ```
pub fn decoder() -> decode.Decoder(SupermarketCategory) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use open_data_slug <- decode.optional_field(
    "open_data_slug",
    None,
    decode.optional(decode.string),
  )

  decode.success(SupermarketCategory(
    id: id,
    name: name,
    description: description,
    open_data_slug: open_data_slug,
  ))
}
