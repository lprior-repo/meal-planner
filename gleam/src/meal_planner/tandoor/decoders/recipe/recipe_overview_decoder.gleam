/// RecipeOverview decoder for Tandoor SDK
///
/// Provides JSON decoder for RecipeOverview type used in list responses.
import gleam/dynamic/decode
import meal_planner/tandoor/types/recipe/recipe_overview.{
  type RecipeOverview, RecipeOverview,
}

/// Decode a RecipeOverview from JSON
///
/// Example JSON (from Tandoor API schema):
/// ```json
/// {
///   "id": 42,
///   "name": "Pasta Carbonara",
///   "description": "Classic Italian pasta dish",
///   "image": "https://example.com/image.jpg",
///   "keywords": ["Italian", "Pasta", "Quick"],
///   "rating": 4.5,
///   "last_cooked": "2024-01-10T18:30:00Z"
/// }
/// ```
pub fn recipe_overview_decoder() -> decode.Decoder(RecipeOverview) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use image <- decode.field("image", decode.optional(decode.string))
  use keywords <- decode.field("keywords", decode.list(decode.string))
  use rating <- decode.field("rating", decode.optional(decode.float))
  use last_cooked <- decode.field("last_cooked", decode.optional(decode.string))

  decode.success(RecipeOverview(
    id: id,
    name: name,
    description: description,
    image: image,
    keywords: keywords,
    rating: rating,
    last_cooked: last_cooked,
  ))
}
