//// Mealie API types and JSON decoders
//// These types match the Mealie v3.x REST API response structures
//// See: https://docs.mealie.io/documentation/getting-started/api-usage/

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// ============================================================================
// Core Mealie Types
// ============================================================================

/// Mealie recipe nutrition data
/// All values are per serving
pub type MealieNutrition {
  MealieNutrition(
    calories: Option(String),
    fat_content: Option(String),
    protein_content: Option(String),
    carbohydrate_content: Option(String),
    fiber_content: Option(String),
    sodium_content: Option(String),
    sugar_content: Option(String),
  )
}

/// Mealie ingredient unit (e.g., "cup", "tbsp", "g")
pub type MealieUnit {
  MealieUnit(id: String, name: String, abbreviation: String)
}

/// Mealie food item (from the foods database)
pub type MealieFood {
  MealieFood(id: String, name: String, description: Option(String))
}

/// Mealie recipe ingredient
pub type MealieIngredient {
  MealieIngredient(
    reference_id: String,
    quantity: Option(Float),
    unit: Option(MealieUnit),
    food: Option(MealieFood),
    note: Option(String),
    is_food: Bool,
    disable_amount: Bool,
    display: String,
    original_text: Option(String),
  )
}

/// Mealie recipe instruction step
pub type MealieInstruction {
  MealieInstruction(id: String, title: Option(String), text: String)
}

/// Mealie recipe category
pub type MealieCategory {
  MealieCategory(id: String, name: String, slug: String)
}

/// Mealie recipe tag
pub type MealieTag {
  MealieTag(id: String, name: String, slug: String)
}

/// Mealie recipe summary (for list endpoints)
pub type MealieRecipeSummary {
  MealieRecipeSummary(
    id: String,
    slug: String,
    name: String,
    description: Option(String),
    image: Option(String),
    rating: Option(Int),
    recipe_yield: Option(String),
    total_time: Option(String),
    prep_time: Option(String),
    cook_time: Option(String),
  )
}

/// Full Mealie recipe with all details
pub type MealieRecipe {
  MealieRecipe(
    id: String,
    slug: String,
    name: String,
    description: Option(String),
    image: Option(String),
    recipe_yield: Option(String),
    total_time: Option(String),
    prep_time: Option(String),
    cook_time: Option(String),
    rating: Option(Int),
    org_url: Option(String),
    recipe_ingredient: List(MealieIngredient),
    recipe_instructions: List(MealieInstruction),
    recipe_category: List(MealieCategory),
    tags: List(MealieTag),
    nutrition: Option(MealieNutrition),
    date_added: Option(String),
    date_updated: Option(String),
  )
}

/// Paginated response wrapper for Mealie API
pub type MealiePaginatedResponse(a) {
  MealiePaginatedResponse(
    page: Int,
    per_page: Int,
    total: Int,
    total_pages: Int,
    items: List(a),
    next: Option(String),
    previous: Option(String),
  )
}

/// Mealie meal plan entry
pub type MealieMealPlanEntry {
  MealieMealPlanEntry(
    id: String,
    date: String,
    entry_type: String,
    title: Option(String),
    text: Option(String),
    recipe_id: Option(String),
    recipe: Option(MealieRecipeSummary),
  )
}

/// Mealie API error response
pub type MealieApiError {
  MealieApiError(message: String, error: Option(String), exception: Option(String))
}

// ============================================================================
// JSON Decoders
// ============================================================================

/// Decoder for MealieNutrition
pub fn nutrition_decoder() -> Decoder(MealieNutrition) {
  use calories <- decode.optional_field(
    "calories",
    None,
    decode.optional(decode.string),
  )
  use fat_content <- decode.optional_field(
    "fatContent",
    None,
    decode.optional(decode.string),
  )
  use protein_content <- decode.optional_field(
    "proteinContent",
    None,
    decode.optional(decode.string),
  )
  use carbohydrate_content <- decode.optional_field(
    "carbohydrateContent",
    None,
    decode.optional(decode.string),
  )
  use fiber_content <- decode.optional_field(
    "fiberContent",
    None,
    decode.optional(decode.string),
  )
  use sodium_content <- decode.optional_field(
    "sodiumContent",
    None,
    decode.optional(decode.string),
  )
  use sugar_content <- decode.optional_field(
    "sugarContent",
    None,
    decode.optional(decode.string),
  )
  decode.success(MealieNutrition(
    calories: calories,
    fat_content: fat_content,
    protein_content: protein_content,
    carbohydrate_content: carbohydrate_content,
    fiber_content: fiber_content,
    sodium_content: sodium_content,
    sugar_content: sugar_content,
  ))
}

/// Decoder for MealieUnit
pub fn unit_decoder() -> Decoder(MealieUnit) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use abbreviation <- decode.optional_field(
    "abbreviation",
    "",
    decode.string,
  )
  decode.success(MealieUnit(id: id, name: name, abbreviation: abbreviation))
}

/// Decoder for MealieFood
pub fn food_decoder() -> Decoder(MealieFood) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  decode.success(MealieFood(id: id, name: name, description: description))
}

/// Decoder for MealieIngredient
pub fn ingredient_decoder() -> Decoder(MealieIngredient) {
  use reference_id <- decode.optional_field("referenceId", "", decode.string)
  use quantity <- decode.optional_field(
    "quantity",
    None,
    decode.optional(decode.float),
  )
  use unit <- decode.optional_field(
    "unit",
    None,
    decode.optional(unit_decoder()),
  )
  use food <- decode.optional_field(
    "food",
    None,
    decode.optional(food_decoder()),
  )
  use note <- decode.optional_field(
    "note",
    None,
    decode.optional(decode.string),
  )
  use is_food <- decode.optional_field("isFood", False, decode.bool)
  use disable_amount <- decode.optional_field(
    "disableAmount",
    False,
    decode.bool,
  )
  use display <- decode.optional_field("display", "", decode.string)
  use original_text <- decode.optional_field(
    "originalText",
    None,
    decode.optional(decode.string),
  )
  decode.success(MealieIngredient(
    reference_id: reference_id,
    quantity: quantity,
    unit: unit,
    food: food,
    note: note,
    is_food: is_food,
    disable_amount: disable_amount,
    display: display,
    original_text: original_text,
  ))
}

/// Decoder for MealieInstruction
pub fn instruction_decoder() -> Decoder(MealieInstruction) {
  use id <- decode.optional_field("id", "", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use text <- decode.optional_field("text", "", decode.string)
  decode.success(MealieInstruction(id: id, title: title, text: text))
}

/// Decoder for MealieCategory
pub fn category_decoder() -> Decoder(MealieCategory) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use slug <- decode.field("slug", decode.string)
  decode.success(MealieCategory(id: id, name: name, slug: slug))
}

/// Decoder for MealieTag
pub fn tag_decoder() -> Decoder(MealieTag) {
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  use slug <- decode.field("slug", decode.string)
  decode.success(MealieTag(id: id, name: name, slug: slug))
}

/// Decoder for MealieRecipeSummary
pub fn recipe_summary_decoder() -> Decoder(MealieRecipeSummary) {
  use id <- decode.field("id", decode.string)
  use slug <- decode.field("slug", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use image <- decode.optional_field(
    "image",
    None,
    decode.optional(decode.string),
  )
  use rating <- decode.optional_field(
    "rating",
    None,
    decode.optional(decode.int),
  )
  use recipe_yield <- decode.optional_field(
    "recipeYield",
    None,
    decode.optional(decode.string),
  )
  use total_time <- decode.optional_field(
    "totalTime",
    None,
    decode.optional(decode.string),
  )
  use prep_time <- decode.optional_field(
    "prepTime",
    None,
    decode.optional(decode.string),
  )
  use cook_time <- decode.optional_field(
    "cookTime",
    None,
    decode.optional(decode.string),
  )
  decode.success(MealieRecipeSummary(
    id: id,
    slug: slug,
    name: name,
    description: description,
    image: image,
    rating: rating,
    recipe_yield: recipe_yield,
    total_time: total_time,
    prep_time: prep_time,
    cook_time: cook_time,
  ))
}

/// Decoder for full MealieRecipe
pub fn recipe_decoder() -> Decoder(MealieRecipe) {
  use id <- decode.field("id", decode.string)
  use slug <- decode.field("slug", decode.string)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use image <- decode.optional_field(
    "image",
    None,
    decode.optional(decode.string),
  )
  use recipe_yield <- decode.optional_field(
    "recipeYield",
    None,
    decode.optional(decode.string),
  )
  use total_time <- decode.optional_field(
    "totalTime",
    None,
    decode.optional(decode.string),
  )
  use prep_time <- decode.optional_field(
    "prepTime",
    None,
    decode.optional(decode.string),
  )
  use cook_time <- decode.optional_field(
    "cookTime",
    None,
    decode.optional(decode.string),
  )
  use rating <- decode.optional_field(
    "rating",
    None,
    decode.optional(decode.int),
  )
  use org_url <- decode.optional_field(
    "orgURL",
    None,
    decode.optional(decode.string),
  )
  use recipe_ingredient <- decode.optional_field(
    "recipeIngredient",
    [],
    decode.list(ingredient_decoder()),
  )
  use recipe_instructions <- decode.optional_field(
    "recipeInstructions",
    [],
    decode.list(instruction_decoder()),
  )
  use recipe_category <- decode.optional_field(
    "recipeCategory",
    [],
    decode.list(category_decoder()),
  )
  use tags <- decode.optional_field("tags", [], decode.list(tag_decoder()))
  use nutrition <- decode.optional_field(
    "nutrition",
    None,
    decode.optional(nutrition_decoder()),
  )
  use date_added <- decode.optional_field(
    "dateAdded",
    None,
    decode.optional(decode.string),
  )
  use date_updated <- decode.optional_field(
    "dateUpdated",
    None,
    decode.optional(decode.string),
  )
  decode.success(MealieRecipe(
    id: id,
    slug: slug,
    name: name,
    description: description,
    image: image,
    recipe_yield: recipe_yield,
    total_time: total_time,
    prep_time: prep_time,
    cook_time: cook_time,
    rating: rating,
    org_url: org_url,
    recipe_ingredient: recipe_ingredient,
    recipe_instructions: recipe_instructions,
    recipe_category: recipe_category,
    tags: tags,
    nutrition: nutrition,
    date_added: date_added,
    date_updated: date_updated,
  ))
}

/// Decoder for paginated response
pub fn paginated_decoder(
  item_decoder: Decoder(a),
) -> Decoder(MealiePaginatedResponse(a)) {
  use page <- decode.field("page", decode.int)
  use per_page <- decode.field("perPage", decode.int)
  use total <- decode.field("total", decode.int)
  use total_pages <- decode.field("totalPages", decode.int)
  use items <- decode.field("items", decode.list(item_decoder))
  use next <- decode.optional_field(
    "next",
    None,
    decode.optional(decode.string),
  )
  use previous <- decode.optional_field(
    "previous",
    None,
    decode.optional(decode.string),
  )
  decode.success(MealiePaginatedResponse(
    page: page,
    per_page: per_page,
    total: total,
    total_pages: total_pages,
    items: items,
    next: next,
    previous: previous,
  ))
}

/// Decoder for MealieMealPlanEntry
pub fn meal_plan_entry_decoder() -> Decoder(MealieMealPlanEntry) {
  use id <- decode.field("id", decode.string)
  use date <- decode.field("date", decode.string)
  use entry_type <- decode.optional_field("entryType", "dinner", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.string),
  )
  use recipe_id <- decode.optional_field(
    "recipeId",
    None,
    decode.optional(decode.string),
  )
  use recipe <- decode.optional_field(
    "recipe",
    None,
    decode.optional(recipe_summary_decoder()),
  )
  decode.success(MealieMealPlanEntry(
    id: id,
    date: date,
    entry_type: entry_type,
    title: title,
    text: text,
    recipe_id: recipe_id,
    recipe: recipe,
  ))
}

/// Decoder for API error
pub fn api_error_decoder() -> Decoder(MealieApiError) {
  use message <- decode.optional_field("message", "Unknown error", decode.string)
  use error <- decode.optional_field(
    "error",
    None,
    decode.optional(decode.string),
  )
  use exception <- decode.optional_field(
    "exception",
    None,
    decode.optional(decode.string),
  )
  decode.success(MealieApiError(
    message: message,
    error: error,
    exception: exception,
  ))
}

// ============================================================================
// JSON Encoding (for creating/updating recipes)
// ============================================================================

/// Encode MealieNutrition to JSON
pub fn nutrition_to_json(n: MealieNutrition) -> Json {
  let optional_string = fn(opt) {
    case opt {
      Some(v) -> json.string(v)
      None -> json.null()
    }
  }
  json.object([
    #("calories", optional_string(n.calories)),
    #("fatContent", optional_string(n.fat_content)),
    #("proteinContent", optional_string(n.protein_content)),
    #("carbohydrateContent", optional_string(n.carbohydrate_content)),
    #("fiberContent", optional_string(n.fiber_content)),
    #("sodiumContent", optional_string(n.sodium_content)),
    #("sugarContent", optional_string(n.sugar_content)),
  ])
}

/// Encode MealieIngredient to JSON
pub fn ingredient_to_json(i: MealieIngredient) -> Json {
  let optional_float = fn(opt) {
    case opt {
      Some(v) -> json.float(v)
      None -> json.null()
    }
  }
  let optional_string = fn(opt) {
    case opt {
      Some(v) -> json.string(v)
      None -> json.null()
    }
  }
  json.object([
    #("referenceId", json.string(i.reference_id)),
    #("quantity", optional_float(i.quantity)),
    #(
      "unit",
      case i.unit {
        Some(u) ->
          json.object([
            #("id", json.string(u.id)),
            #("name", json.string(u.name)),
            #("abbreviation", json.string(u.abbreviation)),
          ])
        None -> json.null()
      },
    ),
    #(
      "food",
      case i.food {
        Some(f) ->
          json.object([
            #("id", json.string(f.id)),
            #("name", json.string(f.name)),
          ])
        None -> json.null()
      },
    ),
    #("note", optional_string(i.note)),
    #("isFood", json.bool(i.is_food)),
    #("disableAmount", json.bool(i.disable_amount)),
    #("display", json.string(i.display)),
  ])
}

/// Encode MealieInstruction to JSON
pub fn instruction_to_json(i: MealieInstruction) -> Json {
  let optional_string = fn(opt) {
    case opt {
      Some(v) -> json.string(v)
      None -> json.null()
    }
  }
  json.object([
    #("id", json.string(i.id)),
    #("title", optional_string(i.title)),
    #("text", json.string(i.text)),
  ])
}

/// Encode MealieMealPlanEntry to JSON (for creating meal plans)
pub fn meal_plan_entry_to_json(entry: MealieMealPlanEntry) -> Json {
  let optional_string = fn(opt) {
    case opt {
      Some(v) -> json.string(v)
      None -> json.null()
    }
  }
  json.object([
    #("date", json.string(entry.date)),
    #("entryType", json.string(entry.entry_type)),
    #("title", optional_string(entry.title)),
    #("text", optional_string(entry.text)),
    #("recipeId", optional_string(entry.recipe_id)),
  ])
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get display name for an ingredient
pub fn ingredient_display_name(i: MealieIngredient) -> String {
  case i.food {
    Some(food) -> food.name
    None ->
      case i.note {
        Some(note) -> note
        None -> i.display
      }
  }
}

/// Parse nutrition string to float (handles "100 kcal", "15g", etc.)
pub fn parse_nutrition_value(value: Option(String)) -> Option(Float) {
  case value {
    None -> None
    Some(s) -> parse_number_from_string(s)
  }
}

/// Extract numeric value from a string like "150 kcal" or "15g"
fn parse_number_from_string(s: String) -> Option(Float) {
  // Simple implementation - extract leading number
  let chars = string_to_chars(s)
  let number_chars = take_while_digit(chars, [])
  case number_chars {
    [] -> None
    _ ->
      case parse_float_from_chars(number_chars) {
        Ok(f) -> Some(f)
        Error(_) -> None
      }
  }
}

/// Convert string to list of characters (simplified)
@external(erlang, "binary", "bin_to_list")
fn string_to_chars(_s: String) -> List(Int)

/// Take characters while they are digits
fn take_while_digit(chars: List(Int), acc: List(Int)) -> List(Int) {
  case chars {
    [] -> list.reverse(acc)
    [c, ..rest] ->
      case c >= 48 && c <= 57 || c == 46 {
        // 0-9 or '.'
        True -> take_while_digit(rest, [c, ..acc])
        False -> list.reverse(acc)
      }
  }
}

/// Parse float from character list
fn parse_float_from_chars(chars: List(Int)) -> Result(Float, Nil) {
  let s = chars_to_string(chars)
  case gleam_float_parse(s) {
    Ok(f) -> Ok(f)
    Error(_) ->
      case gleam_int_parse(s) {
        Ok(i) -> Ok(int_to_float(i))
        Error(_) -> Error(Nil)
      }
  }
}

@external(erlang, "erlang", "list_to_binary")
fn chars_to_string(_chars: List(Int)) -> String

@external(erlang, "erlang", "float")
fn int_to_float(_i: Int) -> Float

@external(erlang, "gleam_stdlib", "parse_float")
fn gleam_float_parse(_s: String) -> Result(Float, Nil)

@external(erlang, "gleam_stdlib", "parse_int")
fn gleam_int_parse(_s: String) -> Result(Int, Nil)

/// Empty nutrition (all None)
pub fn empty_nutrition() -> MealieNutrition {
  MealieNutrition(
    calories: None,
    fat_content: None,
    protein_content: None,
    carbohydrate_content: None,
    fiber_content: None,
    sodium_content: None,
    sugar_content: None,
  )
}
