/// Tandoor Recipe Module
///
/// Provides comprehensive recipe types for different use cases, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// Recipe Types:
/// - Recipe: Basic recipe type for list views (minimal fields)
/// - RecipeDetail: Full recipe with steps, ingredients, nutrition, keywords
/// - RecipeOverview: Optimized for pagination with rating/last_cooked
/// - RecipeSimple: Minimal recipe for embedded references (id, name, image)
/// - NutritionInfo: Detailed nutrition information with source tracking
/// - RecipeUpdate: Request type for partial recipe updates
///
/// Based on Tandoor API specification.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_list,
  parse_json_paginated, parse_json_single,
}
import meal_planner/tandoor/client.{
  type ClientConfig, type Food, type Ingredient, type Keyword,
  type NutritionInfo as ClientNutritionInfo, type Step, type SupermarketCategory,
  type TandoorError, type Unit, Food, Ingredient, Keyword,
  NutritionInfo as ClientNutritionInfo, Step, SupermarketCategory, Unit,
}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/decoder_combinators

// ============================================================================
// Types
// ============================================================================

/// Recipe type for API responses (basic fields for list view)
///
/// This is a lightweight representation suitable for recipe lists and
/// pagination. Contains only essential fields without nested structures.
///
/// Fields:
/// - id: Unique recipe identifier
/// - name: Recipe name
/// - slug: URL-friendly name (optional, readonly)
/// - description: Recipe description (optional)
/// - servings: Number of servings
/// - servings_text: Human-readable servings description (optional, e.g., "4 people")
/// - working_time: Active preparation time in minutes (optional)
/// - waiting_time: Passive waiting time in minutes (optional, e.g., baking, marinating)
/// - created_at: Creation timestamp (optional, readonly)
/// - updated_at: Last update timestamp (optional, readonly)
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
///
/// This is the complete recipe representation including all nested structures
/// like steps, ingredients, nutrition data, and keywords. Use this for
/// detailed recipe views and when you need access to all recipe information.
///
/// Fields (extends Recipe fields):
/// - steps: List of cooking steps with instructions and ingredients
/// - nutrition: Optional nutrition information per serving
/// - keywords: List of categorization tags
/// - source_url: Optional URL to external recipe source
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
    nutrition: Option(ClientNutritionInfo),
    keywords: List(Keyword),
    source_url: Option(String),
  )
}

/// Recipe overview type for list responses
///
/// Contains a subset of recipe data optimized for pagination and list views.
/// Lighter than full RecipeDetail, suitable for API list endpoints.
/// Includes display-friendly fields like rating and last_cooked.
///
/// Fields:
/// - id: Tandoor recipe ID
/// - name: Recipe name
/// - description: Recipe description
/// - image: Optional recipe image URL
/// - keywords: List of Keyword objects (id, name, description)
/// - rating: Optional user rating (0.0 - 5.0)
/// - last_cooked: Optional last cooked date (ISO 8601 format)
pub type RecipeOverview {
  RecipeOverview(
    id: Int,
    name: String,
    description: String,
    image: Option(String),
    keywords: List(Keyword),
    rating: Option(Float),
    last_cooked: Option(String),
  )
}

/// Minimal recipe type for embedded references
///
/// Used when a recipe is referenced from other entities (e.g., in meal plans).
/// Contains only the most essential fields needed for display and linking.
///
/// Fields:
/// - id: Tandoor recipe ID
/// - name: Recipe name
/// - image: Optional recipe image URL
pub type RecipeSimple {
  RecipeSimple(id: Int, name: String, image: Option(String))
}

/// Detailed nutrition information with source tracking
///
/// This type represents comprehensive nutrition data for a recipe,
/// including all macronutrients and the ability to track the data source.
///
/// All numeric fields are optional Float values to accommodate:
/// - Missing data from various sources
/// - Recipes where certain nutritional info isn't calculated
/// - Partial nutrition information
///
/// Fields:
/// - id: Unique identifier for this nutrition record
/// - carbohydrates: Total carbohydrates in grams
/// - fats: Total fats in grams
/// - proteins: Total proteins in grams
/// - calories: Total calories (kcal)
/// - source: Where this nutrition data came from (e.g., "USDA", "manual", "calculated")
pub type NutritionInfo {
  NutritionInfo(
    id: Int,
    carbohydrates: Option(Float),
    fats: Option(Float),
    proteins: Option(Float),
    calories: Option(Float),
    source: Option(String),
  )
}

/// Request to update an existing recipe (partial update)
///
/// All fields are optional to support partial updates.
/// Only provided fields will be sent in the PATCH request.
///
/// Fields:
/// - name: New recipe name
/// - description: New recipe description
/// - servings: New serving count
/// - servings_text: New servings description
/// - working_time: New active preparation time in minutes
/// - waiting_time: New passive waiting time in minutes
pub type RecipeUpdate {
  RecipeUpdate(
    name: Option(String),
    description: Option(String),
    servings: Option(Int),
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

/// Request structure for creating a new recipe
///
/// Only includes writable fields. Tandoor API requires a steps array
/// with at least one step (which can be empty).
///
/// Fields:
/// - name: Recipe name (required)
/// - description: Recipe description (optional)
/// - servings: Number of servings (required)
/// - servings_text: Human-readable servings description (optional)
/// - working_time: Active preparation time in minutes (optional)
/// - waiting_time: Passive waiting time in minutes (optional)
pub type RecipeCreateRequest {
  RecipeCreateRequest(
    name: String,
    description: Option(String),
    servings: Int,
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

// ============================================================================
// Decoders
// ============================================================================

/// Decode a Recipe from JSON (basic recipe for list views)
///
/// This decoder handles all optional fields and provides detailed error
/// messages on failure. Used for recipe list endpoints.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Pasta Carbonara",
///   "slug": "pasta-carbonara",
///   "description": "Classic Italian pasta",
///   "servings": 4,
///   "servings_text": "4 people",
///   "working_time": 30,
///   "waiting_time": 0,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn recipe_decoder() -> decode.Decoder(Recipe) {
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

/// Decode a RecipeDetail from JSON (full recipe with all nested structures)
///
/// This decoder handles the complete recipe representation including steps,
/// ingredients, nutrition, and keywords. Used for recipe detail endpoints.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Pasta",
///   "steps": [...],
///   "nutrition": {...},
///   "keywords": [...],
///   ...
/// }
/// ```
pub fn recipe_detail_decoder() -> decode.Decoder(RecipeDetail) {
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
    decode.optional(client_nutrition_decoder()),
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

/// Decode a RecipeOverview from JSON
///
/// Used for list responses with display-optimized fields.
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
  use keywords <- decode.field("keywords", decode.list(keyword_decoder()))
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

/// Decode NutritionInfo from JSON
///
/// This decoder handles nutrition information with optional fields
/// for all macronutrients. It's designed to work with partial data
/// where some nutritional values may be missing.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "carbohydrates": 45.0,
///   "fats": 12.0,
///   "proteins": 25.0,
///   "calories": 380.0,
///   "source": "USDA"
/// }
/// ```
///
/// All nutritional fields (carbohydrates, fats, proteins, calories, source)
/// are optional and will be decoded as Option(Float) or Option(String).
pub fn nutrition_info_decoder() -> decode.Decoder(NutritionInfo) {
  use id <- decode.field("id", decode.int)
  use carbohydrates <- decode.field(
    "carbohydrates",
    decode.optional(decode_flexible_float()),
  )
  use fats <- decode.field("fats", decode.optional(decode_flexible_float()))
  use proteins <- decode.field(
    "proteins",
    decode.optional(decode_flexible_float()),
  )
  use calories <- decode.field(
    "calories",
    decode.optional(decode_flexible_float()),
  )
  use source <- decode.field("source", decode.optional(decode.string))

  decode.success(NutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  ))
}

// Helper decoder for client.gleam NutritionInfo type
fn client_nutrition_decoder() -> decode.Decoder(ClientNutritionInfo) {
  use id <- decode.field("id", decode.int)
  use carbohydrates <- decode.optional_field("carbohydrates", 0.0, decode.float)
  use fats <- decode.optional_field("fats", 0.0, decode.float)
  use proteins <- decode.optional_field("proteins", 0.0, decode.float)
  use calories <- decode.optional_field("calories", 0.0, decode.float)
  use source <- decode.optional_field("source", "", decode.string)

  decode.success(ClientNutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  ))
}

// Helper decoders for nested component types
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

fn keyword_decoder() -> decode.Decoder(Keyword) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field("description", "", decode.string)

  decode.success(Keyword(id: id, name: name, description: description))
}

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

/// Decoder that accepts both int and float values, converting int to float
fn decode_flexible_float() -> decode.Decoder(Float) {
  decode.one_of(decode.float, or: [
    decode.int |> decode.map(fn(n) { int.to_float(n) }),
  ])
}

// ============================================================================
// Encoders
// ============================================================================

/// Helper to encode Keyword to JSON
fn encode_keyword(keyword: Keyword) -> Json {
  json.object([
    #("id", json.int(keyword.id)),
    #("name", json.string(keyword.name)),
    #("description", json.string(keyword.description)),
  ])
}

/// Encode a RecipeCreateRequest to JSON
///
/// Tandoor API requires steps array with at least one empty step.
/// This encoder creates the minimal valid JSON for recipe creation.
///
/// Example output:
/// ```json
/// {
///   "name": "New Recipe",
///   "description": "A delicious recipe",
///   "servings": 4,
///   "servings_text": "4 people",
///   "working_time": 30,
///   "waiting_time": 0,
///   "steps": [{"instruction": "", "ingredients": []}]
/// }
/// ```
pub fn encode_recipe_create_request(request: RecipeCreateRequest) -> Json {
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

  json.object([
    #("name", json.string(request.name)),
    #("description", description_json),
    #("servings", json.int(request.servings)),
    #("servings_text", servings_text_json),
    #("working_time", working_time_json),
    #("waiting_time", waiting_time_json),
    #("steps", json.array([empty_step], fn(x) { x })),
  ])
}

/// Encode a RecipeUpdate to JSON (only include provided fields)
///
/// This encoder creates minimal JSON for recipe update requests.
/// It only includes fields that are Some, allowing partial updates.
///
/// Example:
/// ```gleam
/// let update = RecipeUpdate(
///   name: Some("Updated Recipe"),
///   description: None,
///   servings: Some(6),
///   servings_text: None,
///   working_time: None,
///   waiting_time: None,
/// )
/// let encoded = encode_recipe_update(update)
/// json.to_string(encoded) // "{\"name\":\"Updated Recipe\",\"servings\":6}"
/// ```
pub fn encode_recipe_update(update: RecipeUpdate) -> Json {
  let fields =
    []
    |> add_optional_field("name", update.name, json.string)
    |> add_optional_field("description", update.description, json.string)
    |> add_optional_field("servings", update.servings, json.int)
    |> add_optional_field("servings_text", update.servings_text, json.string)
    |> add_optional_field("working_time", update.working_time, json.int)
    |> add_optional_field("waiting_time", update.waiting_time, json.int)

  json.object(fields)
}

/// Helper to add optional field to JSON object
///
/// Only adds the field if the value is Some.
fn add_optional_field(
  fields: List(#(String, Json)),
  key: String,
  value: Option(a),
  encoder: fn(a) -> Json,
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(key, encoder(v)), ..fields]
    None -> fields
  }
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// List recipes from Tandoor API with pagination
///
/// Returns a paginated response containing Recipe objects (basic recipe type).
/// Use this for listing recipes with pagination support.
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_recipes(config, limit: Some(20), offset: Some(0))
/// ```
pub fn list_recipes(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(Recipe), TandoorError) {
  // Build query parameters list
  let query_params =
    []
    |> fn(params) {
      case limit {
        Some(l) -> [#("limit", int.to_string(l)), ..params]
        None -> params
      }
    }
    |> fn(params) {
      case offset {
        Some(o) -> [#("offset", int.to_string(o)), ..params]
        None -> params
      }
    }
    |> list.reverse

  // Execute GET request using CRUD helper
  use resp <- result.try(execute_get(config, "/api/recipe/", query_params))

  // Parse JSON response using paginated helper
  parse_json_paginated(resp, recipe_decoder())
}

/// Get a single recipe by ID from Tandoor API
///
/// Returns a RecipeDetail with full recipe information including steps,
/// ingredients, nutrition, and keywords.
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_recipe(config, recipe_id: 42)
/// ```
pub fn get_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
) -> Result(RecipeDetail, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, recipe_detail_decoder())
}

/// Create a new recipe in Tandoor API
///
/// Creates a new recipe with the provided data. Returns the created recipe
/// as a RecipeDetail with all fields populated by the server.
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = RecipeCreateRequest(
///   name: "New Recipe",
///   description: Some("A delicious recipe"),
///   servings: 4,
///   servings_text: Some("4 people"),
///   working_time: Some(30),
///   waiting_time: Some(60),
/// )
/// let result = create_recipe(config, request)
/// ```
pub fn create_recipe(
  config: ClientConfig,
  create_data: RecipeCreateRequest,
) -> Result(RecipeDetail, TandoorError) {
  let body =
    encode_recipe_create_request(create_data)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/recipe/", body))
  parse_json_single(resp, recipe_detail_decoder())
}

/// Update an existing recipe (supports partial updates)
///
/// Updates a recipe with the provided data. Only fields present in the
/// RecipeUpdate will be modified. Returns the updated RecipeDetail.
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let update_data = RecipeUpdate(
///   name: Some("Updated Recipe"),
///   description: None,
///   servings: Some(6),
///   servings_text: None,
///   working_time: None,
///   waiting_time: None,
/// )
/// let result = update_recipe(config, recipe_id: 42, update_data: update_data)
/// ```
pub fn update_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
  data update_data: RecipeUpdate,
) -> Result(RecipeDetail, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"
  let body =
    encode_recipe_update(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, recipe_detail_decoder())
}

/// Delete a recipe from Tandoor
///
/// Permanently deletes the recipe with the given ID.
///
/// Example:
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_recipe(config, recipe_id: 42)
/// ```
pub fn delete_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
