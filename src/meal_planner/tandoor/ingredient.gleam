/// Tandoor Ingredient Module
///
/// Provides the Ingredient type for recipe ingredients, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// Ingredients represent food items used in recipes with associated quantities,
/// units, and additional metadata like preparation notes.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_paginated,
  parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/food.{type Food}
import meal_planner/tandoor/unit.{type Unit}

// ============================================================================
// Types
// ============================================================================

/// An ingredient in a recipe with food, amount, and units
///
/// Represents a single ingredient entry with full details including
/// the food item, measurement unit, quantity, and additional notes.
///
/// Fields:
/// - id: Unique identifier for the ingredient
/// - food: The food item (nullable - can be null for custom/unknown foods)
/// - unit: The measurement unit (nullable - can be null for dimensionless amounts)
/// - amount: Quantity of the ingredient
/// - note: Additional notes or preparation instructions (max 256 chars)
/// - order: Display order in the recipe (lower = earlier)
/// - is_header: If true, display as section header (e.g., "For the sauce:")
/// - no_amount: If true, amount is not specified (e.g., "Salt to taste")
/// - original_text: Original text as parsed/entered (max 512 chars)
pub type Ingredient {
  Ingredient(
    id: Int,
    food: Option(Food),
    unit: Option(Unit),
    amount: Float,
    note: Option(String),
    order: Int,
    is_header: Bool,
    no_amount: Bool,
    original_text: Option(String),
  )
}

/// Request to create or update an ingredient
///
/// This matches the Tandoor API /api/ingredient/ endpoint expectations.
/// All fields are writable.
pub type IngredientCreateRequest {
  IngredientCreateRequest(
    food: Option(Int),
    unit: Option(Int),
    amount: Float,
    note: Option(String),
    order: Int,
    is_header: Bool,
    no_amount: Bool,
    original_text: Option(String),
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode an Ingredient from JSON
///
/// This decoder handles all fields of an ingredient including the optional
/// food and unit references.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "food": {"id": 5, "name": "Tomato", ...},
///   "unit": {"id": 2, "name": "gram", ...},
///   "amount": 250.0,
///   "note": "diced",
///   "order": 1,
///   "is_header": false,
///   "no_amount": false,
///   "original_text": "250g tomatoes, diced"
/// }
/// ```
pub fn ingredient_decoder() -> decode.Decoder(Ingredient) {
  use id <- decode.field("id", decode.int)
  use food <- decode.field("food", decode.optional(food.food_decoder()))
  use unit <- decode.field("unit", decode.optional(unit.decode_unit()))
  use amount <- decode.field("amount", decode.float)
  use note <- decode.field("note", decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use is_header <- decode.field("is_header", decode.bool)
  use no_amount <- decode.field("no_amount", decode.bool)
  use original_text <- decode.field(
    "original_text",
    decode.optional(decode.string),
  )

  decode.success(Ingredient(
    id: id,
    food: food,
    unit: unit,
    amount: amount,
    note: note,
    order: order,
    is_header: is_header,
    no_amount: no_amount,
    original_text: original_text,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode a complete Ingredient to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_ingredient(ingredient: Ingredient) -> Json {
  json.object([
    #("id", json.int(ingredient.id)),
    #("food", case ingredient.food {
      Some(f) -> food.encode_food(f)
      None -> json.null()
    }),
    #("unit", case ingredient.unit {
      Some(unit) -> unit.encode_unit(unit)
      None -> json.null()
    }),
    #("amount", json.float(ingredient.amount)),
    #("note", case ingredient.note {
      Some(note) -> json.string(note)
      None -> json.null()
    }),
    #("order", json.int(ingredient.order)),
    #("is_header", json.bool(ingredient.is_header)),
    #("no_amount", json.bool(ingredient.no_amount)),
    #("original_text", case ingredient.original_text {
      Some(text) -> json.string(text)
      None -> json.null()
    }),
  ])
}

/// Encode an IngredientCreateRequest to JSON
///
/// This encoder creates JSON for ingredient creation/update requests.
/// It includes all fields, encoding None as null for optional fields.
///
/// Example:
/// ```gleam
/// let ingredient = IngredientCreateRequest(
///   food: Some(5),
///   unit: Some(2),
///   amount: 250.0,
///   note: Some("diced"),
///   order: 1,
///   is_header: False,
///   no_amount: False,
///   original_text: Some("250g tomatoes, diced")
/// )
/// let encoded = encode_ingredient_create_request(ingredient)
/// json.to_string(encoded)
/// ```
pub fn encode_ingredient_create_request(
  request: IngredientCreateRequest,
) -> Json {
  json.object([
    #("food", case request.food {
      Some(id) -> json.int(id)
      None -> json.null()
    }),
    #("unit", case request.unit {
      Some(id) -> json.int(id)
      None -> json.null()
    }),
    #("amount", json.float(request.amount)),
    #("note", case request.note {
      Some(note) -> json.string(note)
      None -> json.null()
    }),
    #("order", json.int(request.order)),
    #("is_header", json.bool(request.is_header)),
    #("no_amount", json.bool(request.no_amount)),
    #("original_text", case request.original_text {
      Some(text) -> json.string(text)
      None -> json.null()
    }),
  ])
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// List ingredients from Tandoor API with pagination
///
/// Arguments:
/// - config: Client configuration with authentication
/// - limit: Optional number of results per page (page_size parameter)
/// - page: Optional page number for pagination
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_ingredients(config, limit: Some(20), page: Some(1))
/// ```
pub fn list_ingredients(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Ingredient), TandoorError) {
  let params = case limit, page {
    Some(l), Some(p) -> [
      #("page_size", int.to_string(l)),
      #("page", int.to_string(p)),
    ]
    Some(l), None -> [#("page_size", int.to_string(l))]
    None, Some(p) -> [#("page", int.to_string(p))]
    None, None -> []
  }

  use resp <- result.try(execute_get(config, "/api/ingredient/", params))
  parse_json_paginated(resp, ingredient_decoder())
}

/// Get a single ingredient by ID
///
/// Arguments:
/// - config: Client configuration with authentication
/// - ingredient_id: The ID of the ingredient to fetch
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_ingredient(config, ingredient_id: 42)
/// ```
pub fn get_ingredient(
  config: ClientConfig,
  ingredient_id ingredient_id: Int,
) -> Result(Ingredient, TandoorError) {
  let path = "/api/ingredient/" <> int.to_string(ingredient_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, ingredient_decoder())
}

/// Create a new ingredient in Tandoor
///
/// Arguments:
/// - config: Client configuration with authentication
/// - create_data: Ingredient data to create
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let ingredient_data = IngredientCreateRequest(
///   food: Some(5),
///   unit: Some(2),
///   amount: 250.0,
///   note: Some("diced"),
///   order: 1,
///   is_header: False,
///   no_amount: False,
///   original_text: Some("250g tomatoes, diced")
/// )
/// let result = create_ingredient(config, create_data: ingredient_data)
/// ```
pub fn create_ingredient(
  config: ClientConfig,
  create_data create_data: IngredientCreateRequest,
) -> Result(Ingredient, TandoorError) {
  let body =
    encode_ingredient_create_request(create_data)
    |> json.to_string

  use resp <- result.try(execute_post(config, "/api/ingredient/", body))
  parse_json_single(resp, ingredient_decoder())
}

/// Update an existing ingredient (full replacement)
///
/// Arguments:
/// - config: Client configuration with authentication
/// - ingredient_id: The ID of the ingredient to update
/// - update_data: Updated ingredient data
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let ingredient_data = IngredientCreateRequest(
///   food: Some(5),
///   unit: Some(2),
///   amount: 300.0,
///   note: Some("finely diced"),
///   order: 1,
///   is_header: False,
///   no_amount: False,
///   original_text: Some("300g tomatoes, finely diced")
/// )
/// let result = update_ingredient(
///   config,
///   ingredient_id: 42,
///   update_data: ingredient_data,
/// )
/// ```
pub fn update_ingredient(
  config: ClientConfig,
  ingredient_id ingredient_id: Int,
  update_data update_data: IngredientCreateRequest,
) -> Result(Ingredient, TandoorError) {
  let path = "/api/ingredient/" <> int.to_string(ingredient_id) <> "/"
  let body =
    encode_ingredient_create_request(update_data)
    |> json.to_string

  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, ingredient_decoder())
}

/// Delete an ingredient from Tandoor
///
/// Arguments:
/// - config: Client configuration with authentication
/// - ingredient_id: The ID of the ingredient to delete
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_ingredient(config, ingredient_id: 42)
/// ```
pub fn delete_ingredient(
  config: ClientConfig,
  ingredient_id ingredient_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/ingredient/" <> int.to_string(ingredient_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
