/// RecipeOverview decoder for Tandoor SDK
///
/// Provides JSON decoder for RecipeOverview type used in list responses.
import gleam/dynamic/decode
import meal_planner/tandoor/decoders/keyword/keyword_label_decoder
import meal_planner/tandoor/decoders/mealplan/user_decoder
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
///   "keywords": [{"id": 1, "name": "pasta", "label": "Pasta"}],
///   "rating": 4.5,
///   "last_cooked": "2024-01-10T18:30:00Z",
///   "working_time": 20,
///   "waiting_time": 5,
///   "created_by": {"id": 1, "username": "admin", ...},
///   "created_at": "2024-01-01T10:00:00Z",
///   "updated_at": "2024-01-10T15:30:00Z",
///   "internal": false,
///   "private": false,
///   "servings": 2,
///   "servings_text": "2 servings"
/// }
/// ```
pub fn recipe_overview_decoder() -> decode.Decoder(RecipeOverview) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use image <- decode.field("image", decode.optional(decode.string))
  use keywords <- decode.field(
    "keywords",
    decode.list(keyword_label_decoder.keyword_label_decoder()),
  )
  use rating <- decode.field("rating", decode.optional(decode.float))
  use last_cooked <- decode.field("last_cooked", decode.optional(decode.string))
  use working_time <- decode.field("working_time", decode.int)
  use waiting_time <- decode.field("waiting_time", decode.int)
  use created_by <- decode.field("created_by", user_decoder.user_decoder())
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  use internal <- decode.field("internal", decode.bool)
  use private <- decode.field("private", decode.bool)
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.field("servings_text", decode.string)

  decode.success(RecipeOverview(
    id: id,
    name: name,
    description: description,
    image: image,
    keywords: keywords,
    rating: rating,
    last_cooked: last_cooked,
    working_time: working_time,
    waiting_time: waiting_time,
    created_by: created_by,
    created_at: created_at,
    updated_at: updated_at,
    internal: internal,
    private: private,
    servings: servings,
    servings_text: servings_text,
  ))
}
