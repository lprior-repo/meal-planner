/// Tandoor API client - Recipe operations
///
/// This module handles all recipe-related operations for the Tandoor API:
/// - Fetching recipes (list and detail)
/// - Creating new recipes  
/// - Deleting recipes
/// - Decoding recipe JSON responses
///
/// Types include Recipe, RecipeDetail, and all associated components like
/// Steps, Ingredients, Units, Foods, and Nutrition information.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client/http.{type TandoorError, ParseError}
import meal_planner/tandoor/client/mod.{type ClientConfig}

// ============================================================================
// Types
// ============================================================================

/// Unit of measurement for ingredients
pub type Unit {
  Unit(id: Int, name: String, plural_name: Option(String), description: String)
}

/// Food item (base ingredient)
pub type Food {
  Food(
    id: Int,
    name: String,
    plural_name: Option(String),
    description: String,
    supermarket_category: Option(SupermarketCategory),
  )
}

/// Supermarket category for shopping list organization
pub type SupermarketCategory {
  SupermarketCategory(id: Int, name: String, description: String)
}

/// Ingredient in a recipe step
pub type Ingredient {
  Ingredient(
    id: Int,
    food: Option(Food),
    unit: Option(Unit),
    amount: Float,
    note: String,
    is_header: Bool,
    no_amount: Bool,
    original_text: Option(String),
  )
}

/// Step in a recipe with instructions and ingredients
pub type Step {
  Step(
    id: Int,
    name: String,
    instruction: String,
    ingredients: List(Ingredient),
    time: Int,
    order: Int,
    show_as_header: Bool,
    show_ingredients_table: Bool,
  )
}

/// Nutrition information per serving
pub type NutritionInfo {
  NutritionInfo(
    id: Int,
    carbohydrates: Float,
    fats: Float,
    proteins: Float,
    calories: Float,
    source: String,
  )
}

/// Recipe type for API responses (basic fields for list view)
pub type Recipe {
  Recipe(
    id: Int,
    name: String,
    slug: Option(String),
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
    created_at: Option(String),
    updated_at: Option(String),
  )
}

/// Full recipe with ingredients, steps, and nutrition (for detail view)
pub type RecipeDetail {
  RecipeDetail(
    id: Int,
    name: String,
    slug: Option(String),
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
    created_at: Option(String),
    updated_at: Option(String),
    steps: List(Step),
    nutrition: Option(NutritionInfo),
    keywords: List(Keyword),
    source_url: Option(String),
  )
}

/// Keyword/tag for recipes
pub type Keyword {
  Keyword(id: Int, name: String, description: String)
}

/// Paginated recipe list response
pub type RecipeListResponse {
  RecipeListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(Recipe),
  )
}

/// Request to create a new recipe
pub type CreateRecipeRequest {
  CreateRecipeRequest(
    name: String,
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

// ============================================================================
// Decoders for Recipe Components
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
pub fn recipe_detail_decoder(
  json_value: dynamic.Dynamic,
) -> Result(RecipeDetail, String) {
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

/// Decoder for Recipe from JSON (internal)
fn recipe_decoder_internal() -> decode.Decoder(Recipe) {
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

  decode.success(Recipe(
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
  ))
}

/// Decode a Recipe from JSON
pub fn recipe_decoder(json_value: dynamic.Dynamic) -> Result(Recipe, String) {
  decode.run(json_value, recipe_decoder_internal())
  |> result.map_error(fn(errors) {
    "Failed to decode recipe: "
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

/// Decode a paginated recipe list response
fn recipe_list_decoder_internal() -> decode.Decoder(RecipeListResponse) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", decode.list(recipe_decoder_internal()))

  decode.success(RecipeListResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

// ============================================================================
// API Operations
// ============================================================================

/// Get all recipes from Tandoor API
///
/// # Arguments
/// * config - Client configuration with API token
/// * limit - Optional limit for number of results (default: 100)
/// * offset - Optional offset for pagination (default: 0)
///
/// # Returns
/// Result with paginated recipe list or error
pub fn get_recipes(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
) -> Result(RecipeListResponse, TandoorError) {
  let limit_val = option.unwrap(limit, 100)
  let offset_val = option.unwrap(offset, 0)

  let query_params = [
    #("limit", int.to_string(limit_val)),
    #("offset", int.to_string(offset_val)),
  ]

  use req <- result.try(http.build_get_request(
    config.base_url,
    config.auth,
    "/api/recipe/",
    query_params,
  ))
  logger.debug("Tandoor GET /api/recipe/")

  use resp <- result.try(http.execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_list_decoder_internal()) {
        Ok(recipe_list) -> Ok(recipe_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe list: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Get a single recipe by ID from Tandoor API
///
/// # Arguments
/// * config - Client configuration with API token
/// * recipe_id - The ID of the recipe to fetch
///
/// # Returns
/// Result with recipe details or error
pub fn get_recipe_by_id(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Recipe, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(
    http.build_get_request(config.base_url, config.auth, path, []),
  )
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(http.execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_decoder_internal()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Get a single recipe with full details (steps, ingredients, nutrition) by ID
///
/// # Arguments
/// * config - Client configuration with API token
/// * recipe_id - The ID of the recipe to fetch
///
/// # Returns
/// Result with full recipe details including steps, ingredients, and nutrition
pub fn get_recipe_detail(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(RecipeDetail, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(
    http.build_get_request(config.base_url, config.auth, path, []),
  )
  logger.debug("Tandoor GET (detail) " <> path)

  use resp <- result.try(http.execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_detail_decoder_internal()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
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
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Create a new recipe in Tandoor API
///
/// # Arguments
/// * config - Client configuration with API token
/// * recipe_request - Recipe data to create
///
/// # Returns
/// Result with created recipe details or error
pub fn create_recipe(
  config: ClientConfig,
  recipe_request: CreateRecipeRequest,
) -> Result(Recipe, TandoorError) {
  let body = encode_create_recipe(recipe_request)

  use req <- result.try(http.build_post_request(
    config.base_url,
    config.auth,
    "/api/recipe/",
    body,
  ))
  logger.debug("Tandoor POST /api/recipe/")

  use resp <- result.try(http.execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_decoder_internal()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created recipe: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Delete a recipe from Tandoor API
///
/// # Arguments
/// * config - Client configuration with API token
/// * recipe_id - The ID of the recipe to delete
///
/// # Returns
/// Result with unit or error
pub fn delete_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(http.build_delete_request(
    config.base_url,
    config.auth,
    path,
  ))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(http.execute_and_parse(req))
  Ok(Nil)
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode a CreateRecipeRequest to JSON string
fn encode_create_recipe(request: CreateRecipeRequest) -> String {
  let working_time_json = case request.working_time {
    Some(val) -> json.int(val)
    None -> json.int(0)
  }

  let waiting_time_json = case request.waiting_time {
    Some(val) -> json.int(val)
    None -> json.int(0)
  }

  let description_json = case request.description {
    Some(val) -> json.string(val)
    None -> json.null()
  }

  let servings_text_json = case request.servings_text {
    Some(val) -> json.string(val)
    None -> json.null()
  }

  // Tandoor requires steps with ingredients array
  let empty_step =
    json.object([
      #("instruction", json.string("")),
      #("ingredients", json.array([], json.object)),
    ])

  let body =
    json.object([
      #("name", json.string(request.name)),
      #("description", description_json),
      #("servings", json.int(request.servings)),
      #("servings_text", servings_text_json),
      #("working_time", working_time_json),
      #("waiting_time", waiting_time_json),
      #("steps", json.array([empty_step], fn(x) { x })),
    ])

  json.to_string(body)
}
