/// Decoder for MealPlanCreate from JSON
///
/// This module provides a JSON decoder for meal plan creation requests
/// following the gleam/dynamic/decode pattern.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to MealPlanCreate fields
/// 
/// Expected JSON structure:
/// ```json
/// {
///   "recipe": 42,
///   "recipe_name": "Pasta Carbonara",
///   "servings": 4.0,
///   "note": "Extra parmesan",
///   "from_date": "2024-01-15",
///   "to_date": "2024-01-15",
///   "meal_type": "lunch"
/// }
/// ```
pub fn meal_plan_create_request_decoder() -> decode.Decoder(
  #(
    option.Option(Int),
    String,
    Float,
    String,
    String,
    String,
    String,
  ),
) {
  use recipe <- decode.optional_field("recipe", option.None, decode.optional(decode.int))
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use note <- decode.field("note", decode.string)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type <- decode.field("meal_type", decode.string)
  decode.success(#(recipe, recipe_name, servings, note, from_date, to_date, meal_type))
}
