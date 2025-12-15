/// Recipe detail decoder for full RecipeDetail type from client.gleam
///
/// This module provides JSON decoders for the RecipeDetail type used in Tandoor
/// API detail endpoints. RecipeDetail includes steps, ingredients, nutrition,
/// and keywords.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type Food, type Ingredient, type Keyword, type NutritionInfo,
  type RecipeDetail, type Step, type SupermarketCategory, type Unit, Food,
  Ingredient, Keyword, NutritionInfo, RecipeDetail, Step, SupermarketCategory,
  Unit,
}

// ============================================================================
// Component Decoders
// ============================================================================

/// Decoder for SupermarketCategory
fn supermarket_category_decoder() -> decode.Decoder(SupermarketCategory) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field("description", "", decode.string)

  decode.success(SupermarketCategory(
    id: id,
    name: name,
    description: description,
  ))
}

/// Decoder for Unit
fn unit_decoder() -> decode.Decoder(Unit) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.optional_field(
    "plural_name",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field("description", "", decode.string)

  decode.success(Unit(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
  ))
}

/// Decoder for Food
fn food_decoder() -> decode.Decoder(Food) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.optional_field(
    "plural_name",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field("description", "", decode.string)
  use supermarket_category <- decode.optional_field(
    "supermarket_category",
    None,
    decode.optional(supermarket_category_decoder()),
  )

  decode.success(Food(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
    supermarket_category: supermarket_category,
  ))
}

/// Decoder for Ingredient
fn ingredient_decoder() -> decode.Decoder(Ingredient) {
  use id <- decode.field("id", decode.int)
  use food <- decode.optional_field(
    "food",
    None,
    decode.optional(food_decoder()),
  )
  use unit <- decode.optional_field(
    "unit",
    None,
    decode.optional(unit_decoder()),
  )
  use amount <- decode.optional_field("amount", 0.0, decode.float)
  use note <- decode.optional_field("note", "", decode.string)
  use is_header <- decode.optional_field("is_header", False, decode.bool)
  use no_amount <- decode.optional_field("no_amount", False, decode.bool)
  use original_text <- decode.optional_field(
    "original_text",
    None,
    decode.optional(decode.string),
  )

  decode.success(Ingredient(
    id: id,
    food: food,
    unit: unit,
    amount: amount,
    note: note,
    is_header: is_header,
    no_amount: no_amount,
    original_text: original_text,
  ))
}

/// Decoder for Keyword
fn keyword_decoder() -> decode.Decoder(Keyword) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field("description", "", decode.string)

  decode.success(Keyword(id: id, name: name, description: description))
}

/// Decoder for Step
fn step_decoder() -> decode.Decoder(Step) {
  use id <- decode.field("id", decode.int)
  use name <- decode.optional_field("name", "", decode.string)
  use instruction <- decode.optional_field("instruction", "", decode.string)
  use ingredients <- decode.optional_field(
    "ingredients",
    [],
    decode.list(ingredient_decoder()),
  )
  use time <- decode.optional_field("time", 0, decode.int)
  use order <- decode.optional_field("order", 0, decode.int)
  use show_as_header <- decode.optional_field(
    "show_as_header",
    False,
    decode.bool,
  )
  use show_ingredients_table <- decode.optional_field(
    "show_ingredients_table",
    True,
    decode.bool,
  )

  decode.success(Step(
    id: id,
    name: name,
    instruction: instruction,
    ingredients: ingredients,
    time: time,
    order: order,
    show_as_header: show_as_header,
    show_ingredients_table: show_ingredients_table,
  ))
}

/// Decoder for NutritionInfo
fn nutrition_decoder() -> decode.Decoder(NutritionInfo) {
  use id <- decode.field("id", decode.int)
  use carbohydrates <- decode.optional_field("carbohydrates", 0.0, decode.float)
  use fats <- decode.optional_field("fats", 0.0, decode.float)
  use proteins <- decode.optional_field("proteins", 0.0, decode.float)
  use calories <- decode.optional_field("calories", 0.0, decode.float)
  use source <- decode.optional_field("source", "", decode.string)

  decode.success(NutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  ))
}

// ============================================================================
// RecipeDetail Decoder
// ============================================================================

/// Decoder for RecipeDetail (full recipe with steps, ingredients, nutrition)
fn recipe_detail_decoder_internal() -> decode.Decoder(RecipeDetail) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use slug <- decode.optional_field(
    "slug",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.optional_field(
    "servings_text",
    None,
    decode.optional(decode.string),
  )
  use working_time <- decode.optional_field(
    "working_time",
    None,
    decode.optional(decode.int),
  )
  use waiting_time <- decode.optional_field(
    "waiting_time",
    None,
    decode.optional(decode.int),
  )
  use created_at <- decode.optional_field(
    "created_at",
    None,
    decode.optional(decode.string),
  )
  use updated_at <- decode.optional_field(
    "updated_at",
    None,
    decode.optional(decode.string),
  )
  use steps <- decode.optional_field("steps", [], decode.list(step_decoder()))
  use nutrition <- decode.optional_field(
    "nutrition",
    None,
    decode.optional(nutrition_decoder()),
  )
  use keywords <- decode.optional_field(
    "keywords",
    [],
    decode.list(keyword_decoder()),
  )
  use source_url <- decode.optional_field(
    "source_url",
    None,
    decode.optional(decode.string),
  )

  decode.success(RecipeDetail(
    id: id,
    name: name,
    slug: slug,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
    created_at: created_at,
    updated_at: updated_at,
    steps: steps,
    nutrition: nutrition,
    keywords: keywords,
    source_url: source_url,
  ))
}

/// Decode a RecipeDetail from JSON
///
/// This function takes raw JSON dynamic data and decodes it into a RecipeDetail
/// type with all nested structures (steps, ingredients, nutrition, keywords).
/// It provides detailed error messages on failure.
///
/// # Example
/// ```gleam
/// import gleam/json
/// import gleam/dynamic/decode
/// import meal_planner/tandoor/decoders/recipe/recipe_detail_decoder
///
/// let json_str = "{\"id\": 1, \"name\": \"Pasta\", \"steps\": [...], ...}"
/// case json.parse(json_str, using: decode.dynamic) {
///   Ok(json_data) -> {
///     case recipe_detail_decoder.decoder(json_data) {
///       Ok(recipe_detail) -> // Use recipe_detail
///       Error(msg) -> // Handle error
///     }
///   }
///   Error(_) -> // Handle JSON parse error
/// }
/// ```
pub fn decoder(json_value: dynamic.Dynamic) -> Result(RecipeDetail, String) {
  decode.run(json_value, recipe_detail_decoder_internal())
  |> result.map_error(fn(errors) {
    "Failed to decode recipe detail: "
    <> string.join(
      list.map(errors, fn(e) {
        case e {
          decode.DecodeError(expected, _found, path) ->
            expected <> " at " <> string.join(path, ".")
        }
      }),
      ", ",
    )
  })
}
