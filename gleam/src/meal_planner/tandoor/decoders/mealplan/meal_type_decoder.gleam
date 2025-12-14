/// MealType decoder for Tandoor SDK
///
/// Provides JSON decoders for MealType from the Tandoor API.
/// Handles meal type categorization (breakfast, lunch, dinner, etc)
import gleam/dynamic/decode
import meal_planner/tandoor/types/mealplan/meal_type.{type MealType, MealType}

/// Decode a MealType from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "Breakfast",
///   "order": 0,
///   "time": "08:00",
///   "color": "#FF5733",
///   "default": true,
///   "created_by": 1
/// }
/// ```
pub fn meal_type_decoder() -> decode.Decoder(MealType) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use order <- decode.field("order", decode.int)
  use time <- decode.field("time", decode.optional(decode.string))
  use color <- decode.field("color", decode.optional(decode.string))
  use default <- decode.field("default", decode.bool)
  use created_by <- decode.field("created_by", decode.int)

  decode.success(MealType(
    id: id,
    name: name,
    order: order,
    time: time,
    color: color,
    default: default,
    created_by: created_by,
  ))
}
