/// MealPlan decoder for Tandoor SDK
///
/// Provides JSON decoders for MealPlan types from the Tandoor API.
/// Handles complex nested structures including recipes, meal types, and shared users.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/result
import gleam/string
import meal_planner/tandoor/decoders/decoder_combinators
import meal_planner/tandoor/decoders/mealplan/meal_type_decoder
import meal_planner/tandoor/decoders/mealplan/user_decoder
import meal_planner/tandoor/decoders/recipe/recipe_overview_decoder
import meal_planner/tandoor/types/mealplan/meal_plan.{
  type MealPlan, type MealPlanListResponse, MealPlan, MealPlanListResponse,
}
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{
  type MealPlanEntry, MealPlanEntry,
}

/// Decode a complete MealPlan from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "title": "Pasta Night",
///   "recipe": { "id": 42, "name": "Carbonara", ... },
///   "servings": 4.0,
///   "note": "Don't forget the parmesan",
///   "note_markdown": "Don't forget the parmesan",
///   "from_date": "2024-01-15T18:00:00Z",
///   "to_date": "2024-01-15T19:00:00Z",
///   "meal_type": { "id": 2, "name": "Dinner", ... },
///   "created_by": 1,
///   "shared": [{ "id": 2, "username": "alice", ... }],
///   "recipe_name": "Carbonara",
///   "meal_type_name": "Dinner",
///   "shopping": true
/// }
/// ```
pub fn meal_plan_decoder_internal() -> decode.Decoder(MealPlan) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use recipe <- decode.field(
    "recipe",
    decode.optional(recipe_overview_decoder.recipe_overview_decoder()),
  )
  use servings <- decode.field("servings", decode.float)
  use note <- decode.field("note", decode.string)
  use note_markdown <- decode.field("note_markdown", decode.string)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type <- decode.field(
    "meal_type",
    meal_type_decoder.meal_type_decoder(),
  )
  use created_by <- decode.field("created_by", decode.int)
  use shared <- decode.field(
    "shared",
    decode.optional(decode.list(user_decoder.user_decoder())),
  )
  use recipe_name <- decode.field("recipe_name", decode.string)
  use meal_type_name <- decode.field("meal_type_name", decode.string)
  use shopping <- decode.field("shopping", decode.bool)

  decode.success(MealPlan(
    id: id,
    title: title,
    recipe: recipe,
    servings: servings,
    note: note,
    note_markdown: note_markdown,
    from_date: from_date,
    to_date: to_date,
    meal_type: meal_type,
    created_by: created_by,
    shared: shared,
    recipe_name: recipe_name,
    meal_type_name: meal_type_name,
    shopping: shopping,
  ))
}

pub fn meal_plan_list_decoder_internal() -> decode.Decoder(MealPlanListResponse) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field(
    "results",
    decode.list(meal_plan_decoder_internal()),
  )

  decode.success(MealPlanListResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

pub fn meal_plan_decoder(
  json_value: dynamic.Dynamic,
) -> Result(MealPlan, String) {
  decoder_combinators.run_decoder(
    json_value,
    meal_plan_decoder_internal(),
    "Failed to decode meal plan",
  )
}

/// Decode a simplified MealPlanEntry from JSON
///
/// Used for list operations where full details aren't needed.
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "title": "Quick Breakfast",
///   "recipe_id": 10,
///   "recipe_name": "Scrambled Eggs",
///   "servings": 2.0,
///   "from_date": "2024-01-15T08:00:00Z",
///   "to_date": "2024-01-15T08:30:00Z",
///   "meal_type_id": 1,
///   "meal_type_name": "Breakfast",
///   "shopping": false
/// }
/// ```
pub fn meal_plan_entry_decoder() -> decode.Decoder(MealPlanEntry) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use recipe_id <- decode.field("recipe_id", decode.optional(decode.int))
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type_id <- decode.field("meal_type_id", decode.int)
  use meal_type_name <- decode.field("meal_type_name", decode.string)
  use shopping <- decode.field("shopping", decode.bool)

  decode.success(MealPlanEntry(
    id: id,
    title: title,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    from_date: from_date,
    to_date: to_date,
    meal_type_id: meal_type_id,
    meal_type_name: meal_type_name,
    shopping: shopping,
  ))
}
