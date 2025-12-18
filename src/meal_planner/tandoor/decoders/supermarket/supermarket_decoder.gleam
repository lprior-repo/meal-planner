/// Decoder for Supermarket type
///
/// Handles JSON decoding from Tandoor API responses
import gleam/dynamic/decode
import gleam/option.{None}
import meal_planner/tandoor/types/supermarket/supermarket.{
  type Supermarket, type SupermarketCategoryRelation, Supermarket,
  SupermarketCategoryRelation,
}

/// Decoder for SupermarketCategoryRelation
/// Decodes the category-to-supermarket mapping
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "category": 10,
///   "supermarket": 2,
///   "order": 0
/// }
/// ```
fn category_relation_decoder() -> decode.Decoder(SupermarketCategoryRelation) {
  use id <- decode.field("id", decode.int)
  use category_id <- decode.field("category", decode.int)
  use supermarket_id <- decode.field("supermarket", decode.int)
  use order <- decode.field("order", decode.int)

  decode.success(SupermarketCategoryRelation(
    id: id,
    category_id: category_id,
    supermarket_id: supermarket_id,
    order: order,
  ))
}

/// Decoder for Supermarket
/// Decodes JSON from Tandoor API into Supermarket type
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "Whole Foods",
///   "description": "Natural and organic grocery store",
///   "category_to_supermarket": [...],
///   "open_data_slug": "whole-foods"
/// }
/// ```
pub fn decoder() -> decode.Decoder(Supermarket) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use category_to_supermarket <- decode.field(
    "category_to_supermarket",
    decode.list(category_relation_decoder()),
  )
  use open_data_slug <- decode.optional_field(
    "open_data_slug",
    None,
    decode.optional(decode.string),
  )

  decode.success(Supermarket(
    id: id,
    name: name,
    description: description,
    category_to_supermarket: category_to_supermarket,
    open_data_slug: open_data_slug,
  ))
}
