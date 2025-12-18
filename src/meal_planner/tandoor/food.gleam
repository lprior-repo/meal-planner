/// Tandoor Food Module
///
/// Provides the Food and FoodSimple types for managing food items in Tandoor,
/// along with JSON encoding/decoding and CRUD API operations.
///
/// Foods represent ingredients and food items in the Tandoor recipe manager.
/// They can be standalone items or linked to recipes, and include metadata
/// for shopping lists and inventory management.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_paginated,
  parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/core/ids.{type FoodId}
import meal_planner/tandoor/property.{type Property, property_decoder}
import meal_planner/tandoor/supermarket.{supermarket_category_decoder, type SupermarketCategory}
import meal_planner/tandoor/types/food/food_inherit_field.{food_inherit_field_decoder, type FoodInheritField}
import meal_planner/tandoor/unit.{decode_unit, type Unit}

// ============================================================================
// Types
// ============================================================================

/// Complete food type with full metadata
///
/// Used for detailed food views and full food data operations.
///
/// Fields:
/// - id: Unique Tandoor food identifier
/// - name: Food name (e.g., "Tomato")
/// - plural_name: Optional plural form (e.g., "Tomatoes")
/// - description: Detailed description of the food
/// - recipe: Optional reference to a recipe (for recipe-based foods)
/// - food_onhand: Whether the food is currently in inventory
/// - supermarket_category: Optional category ID for shopping organization
/// - ignore_shopping: Whether to exclude this food from shopping lists
///
/// Note: This is a simplified version focusing on core fields.
/// Additional Tandoor API fields (url, properties, fdc_id, etc.)
/// can be added as needed.
pub type Food {
  Food(
    id: FoodId,
    name: String,
    plural_name: Option(String),
    description: String,
    recipe: Option(FoodSimple),
    food_onhand: Option(Bool),
    supermarket_category: Option(SupermarketCategory),
    ignore_shopping: Bool,
    shopping: String,
    url: Option(String),
    properties: Option(List(Property)),
    properties_food_amount: Float,
    properties_food_unit: Option(Unit),
    fdc_id: Option(Int),
    parent: Option(Int),
    numchild: Int,
    inherit_fields: Option(List(FoodInheritField)),
    full_name: String,
  )
}

/// Minimal food type for embedded references
///
/// Used when a food is referenced from other entities (e.g., in ingredients).
///
/// Fields:
/// - id: Unique Tandoor food identifier
/// - name: Food name
/// - plural_name: Optional plural form
pub type FoodSimple {
  FoodSimple(id: FoodId, name: String, plural_name: Option(String))
}

/// Request to create a new food item in Tandoor
///
/// Only includes the required writable field (name).
pub type FoodCreateRequest {
  FoodCreateRequest(name: String)
}

/// Request to update an existing food item in Tandoor
///
/// All fields are optional to support partial updates.
/// Uses nested Option for fields that can be set to null.
pub type FoodUpdateRequest {
  FoodUpdateRequest(
    name: Option(String),
    description: Option(String),
    plural_name: Option(Option(String)),
    recipe: Option(Option(Int)),
    food_onhand: Option(Option(Bool)),
    supermarket_category: Option(Option(Int)),
    ignore_shopping: Option(Bool),
    shopping: Option(String),
    url: Option(Option(String)),
    properties_food_amount: Option(Float),
    properties_food_unit: Option(Option(Int)),
    fdc_id: Option(Option(Int)),
    parent: Option(Option(Int)),
  )
}

// ============================================================================
// Decoders
// ============================================================================

/// Decode a FoodSimple from JSON
///
/// Minimal food reference with ID, name, and optional plural name.
/// Used when a food is embedded as a reference (e.g., in recipe field).
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Tomato",
///   "plural_name": "Tomatoes"
/// }
/// ```
pub fn food_simple_decoder() -> decode.Decoder(FoodSimple) {
  use id <- decode.field("id", ids.food_id_decoder())
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.field("plural_name", decode.optional(decode.string))

  decode.success(FoodSimple(id: id, name: name, plural_name: plural_name))
}

/// Decode a complete Food from JSON
///
/// This decoder handles all fields of a food item including the optional
/// nested recipe reference.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Tomato",
///   "plural_name": "Tomatoes",
///   "description": "Fresh red tomatoes",
///   "recipe": null,
///   "food_onhand": true,
///   "supermarket_category": null,
///   "ignore_shopping": false
/// }
/// ```
pub fn food_decoder() -> decode.Decoder(Food) {
  use id <- decode.field("id", ids.food_id_decoder())
  use name <- decode.field("name", decode.string)
  use plural_name <- decode.field("plural_name", decode.optional(decode.string))
  use description <- decode.field("description", decode.string)
  use recipe <- decode.field("recipe", decode.optional(food_simple_decoder()))
  use food_onhand <- decode.field("food_onhand", decode.optional(decode.bool))
  use supermarket_category <- decode.field(
    "supermarket_category",
    decode.optional(supermarket_category_decoder()),
  )
  use ignore_shopping <- decode.field("ignore_shopping", decode.bool)
  use shopping <- decode.field("shopping", decode.string)
  use url <- decode.field("url", decode.optional(decode.string))
  use properties <- decode.field(
    "properties",
    decode.optional(decode.list(property_decoder())),
  )
  use properties_food_amount <- decode.field(
    "properties_food_amount",
    decode.float,
  )
  use properties_food_unit <- decode.field(
    "properties_food_unit",
    decode.optional(decode_unit()),
  )
  use fdc_id <- decode.field("fdc_id", decode.optional(decode.int))
  use parent <- decode.field("parent", decode.optional(decode.int))
  use numchild <- decode.field("numchild", decode.int)
  use inherit_fields <- decode.field(
    "inherit_fields",
    decode.optional(decode.list(food_inherit_field_decoder())),
  )
  use full_name <- decode.field("full_name", decode.string)

  decode.success(Food(
    id: id,
    name: name,
    plural_name: plural_name,
    description: description,
    recipe: recipe,
    food_onhand: food_onhand,
    supermarket_category: supermarket_category,
    ignore_shopping: ignore_shopping,
    shopping: shopping,
    url: url,
    properties: properties,
    properties_food_amount: properties_food_amount,
    properties_food_unit: properties_food_unit,
    fdc_id: fdc_id,
    parent: parent,
    numchild: numchild,
    inherit_fields: inherit_fields,
    full_name: full_name,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Encode a complete Food to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_food(food: Food) -> Json {
  json.object([
    #("id", json.int(ids.food_id_to_int(food.id))),
    #("name", json.string(food.name)),
    #("plural_name", case food.plural_name {
      Some(plural) -> json.string(plural)
      None -> json.null()
    }),
    #("description", json.string(food.description)),
    #("recipe", case food.recipe {
      Some(recipe) -> encode_food_simple(recipe)
      None -> json.null()
    }),
    #("food_onhand", case food.food_onhand {
      Some(onhand) -> json.bool(onhand)
      None -> json.null()
    }),
    #("supermarket_category", case food.supermarket_category {
      Some(cat) -> encode_supermarket_category(cat)
      None -> json.null()
    }),
    #("ignore_shopping", json.bool(food.ignore_shopping)),
    #("shopping", json.string(food.shopping)),
    #("url", case food.url {
      Some(url) -> json.string(url)
      None -> json.null()
    }),
    #("properties", case food.properties {
      Some(props) -> json.array(props, encode_property)
      None -> json.null()
    }),
    #("properties_food_amount", json.float(food.properties_food_amount)),
    #("properties_food_unit", case food.properties_food_unit {
      Some(unit) -> encode_unit(unit)
      None -> json.null()
    }),
    #("fdc_id", case food.fdc_id {
      Some(fdc) -> json.int(fdc)
      None -> json.null()
    }),
    #("parent", case food.parent {
      Some(parent) -> json.int(parent)
      None -> json.null()
    }),
    #("numchild", json.int(food.numchild)),
    #("inherit_fields", case food.inherit_fields {
      Some(fields) -> json.array(fields, encode_food_inherit_field)
      None -> json.null()
    }),
    #("full_name", json.string(food.full_name)),
  ])
}

/// Encode a FoodSimple to JSON
///
/// Minimal representation for embedded references.
pub fn encode_food_simple(food: FoodSimple) -> Json {
  json.object([
    #("id", json.int(ids.food_id_to_int(food.id))),
    #("name", json.string(food.name)),
    #("plural_name", case food.plural_name {
      Some(plural) -> json.string(plural)
      None -> json.null()
    }),
  ])
}

/// Encode a SupermarketCategory to JSON
fn encode_supermarket_category(cat: SupermarketCategory) -> Json {
  json.object([
    #("id", json.int(cat.id)),
    #("name", json.string(cat.name)),
    #("description", case cat.description {
      Some(desc) -> json.string(desc)
      None -> json.null()
    }),
    #("open_data_slug", case cat.open_data_slug {
      Some(slug) -> json.string(slug)
      None -> json.null()
    }),
  ])
}

/// Encode a Property to JSON
fn encode_property(prop: Property) -> Json {
  json.object([
    #("id", json.int(ids.property_id_to_int(prop.id))),
    #("name", json.string(prop.name)),
    #("description", json.string(prop.description)),
    #("property_type", json.string(case prop.property_type {
      property.RecipeProperty -> "RECIPE"
      property.FoodProperty -> "FOOD"
    })),
    #("unit", case prop.unit {
      Some(unit) -> json.string(unit)
      None -> json.null()
    }),
    #("order", json.int(prop.order)),
    #("created_at", json.string(prop.created_at)),
    #("updated_at", json.string(prop.updated_at)),
  ])
}

/// Encode a Unit to JSON
fn encode_unit(unit: Unit) -> Json {
  json.object([
    #("id", json.int(unit.id)),
    #("name", json.string(unit.name)),
    #("plural_name", case unit.plural_name {
      Some(plural) -> json.string(plural)
      None -> json.null()
    }),
    #("description", case unit.description {
      Some(desc) -> json.string(desc)
      None -> json.null()
    }),
    #("base_unit", case unit.base_unit {
      Some(base) -> json.string(base)
      None -> json.null()
    }),
    #("open_data_slug", case unit.open_data_slug {
      Some(slug) -> json.string(slug)
      None -> json.null()
    }),
  ])
}

/// Encode a FoodInheritField to JSON
fn encode_food_inherit_field(field: FoodInheritField) -> Json {
  json.object([
    #("id", json.int(field.id)),
    #("name", json.string(field.name)),
    #("field", json.string(field.field)),
  ])
}

/// Encode a FoodCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_food_create_request(request: FoodCreateRequest) -> Json {
  json.object([#("name", json.string(request.name))])
}

/// Encode a FoodUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_food_update_request(request: FoodUpdateRequest) -> Json {
  let name_field = case request.name {
    Some(name) -> [#("name", json.string(name))]
    None -> []
  }

  let description_field = case request.description {
    Some(desc) -> [#("description", json.string(desc))]
    None -> []
  }

  let plural_name_field = case request.plural_name {
    Some(Some(plural)) -> [#("plural_name", json.string(plural))]
    Some(None) -> [#("plural_name", json.null())]
    None -> []
  }

  let recipe_field = case request.recipe {
    Some(Some(recipe_id)) -> [#("recipe", json.int(recipe_id))]
    Some(None) -> [#("recipe", json.null())]
    None -> []
  }

  let food_onhand_field = case request.food_onhand {
    Some(Some(onhand)) -> [#("food_onhand", json.bool(onhand))]
    Some(None) -> [#("food_onhand", json.null())]
    None -> []
  }

  let supermarket_category_field = case request.supermarket_category {
    Some(Some(cat)) -> [#("supermarket_category", json.int(cat))]
    Some(None) -> [#("supermarket_category", json.null())]
    None -> []
  }

  let ignore_shopping_field = case request.ignore_shopping {
    Some(ignore) -> [#("ignore_shopping", json.bool(ignore))]
    None -> []
  }

  json.object(
    list.flatten([
      name_field,
      description_field,
      plural_name_field,
      recipe_field,
      food_onhand_field,
      supermarket_category_field,
      ignore_shopping_field,
    ]),
  )
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// List foods from Tandoor API with pagination
///
/// Uses page-based pagination (page_size and page parameters).
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `page` - Optional page number for pagination
///
/// # Returns
/// Result with paginated food list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_foods(config, limit: Some(20), page: Some(1))
/// ```
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError) {
  let params = case limit, page {
    Some(l), Some(p) -> [
      #("page_size", int.to_string(l)),
      #("page", int.to_string(p)),
    ]
    Some(l), None -> [#("page_size", int.to_string(l))]
    None, Some(p) -> [#("page", int.to_string(p))]
    None, None -> []
  }

  use resp <- result.try(execute_get(config, "/api/food/", params))
  parse_json_single(resp, http.paginated_decoder(food_decoder()))
}

/// List foods from Tandoor API with extended options
///
/// Provides flexible querying with support for limit, offset-based pagination,
/// and query string search.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results to return (limit parameter)
/// * `offset` - Optional number of results to skip (offset parameter)
/// * `query` - Optional search query string to filter foods by name
///
/// # Returns
/// Result with paginated food list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// // List first 10 foods
/// let result = list_foods_with_options(config, Some(10), None, None)
///
/// // Search for foods with query
/// let result = list_foods_with_options(config, Some(20), Some(0), Some("tomato"))
///
/// // Paginate with offset
/// let result = list_foods_with_options(config, Some(10), Some(20), None)
/// ```
pub fn list_foods_with_options(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
  query: Option(String),
) -> Result(PaginatedResponse(Food), TandoorError) {
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
    |> fn(params) {
      case query {
        Some(q) -> [#("query", q), ..params]
        None -> params
      }
    }
    |> list.reverse

  use resp <- result.try(execute_get(config, "/api/food/", query_params))
  parse_json_paginated(resp, food_decoder())
}

/// Get a single food item by ID
pub fn get_food(
  config: ClientConfig,
  food_id food_id: Int,
) -> Result(Food, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, food_decoder())
}

/// Create a new food item in Tandoor
pub fn create_food(
  config: ClientConfig,
  create_data: FoodCreateRequest,
) -> Result(Food, TandoorError) {
  let body = encode_food_create_request(create_data) |> json.to_string
  use resp <- result.try(execute_post(config, "/api/food/", body))
  parse_json_single(resp, food_decoder())
}

/// Update an existing food item (supports partial updates)
pub fn update_food(
  config: ClientConfig,
  food_id food_id: Int,
  data update_data: FoodUpdateRequest,
) -> Result(Food, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"
  let body = encode_food_update_request(update_data) |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, food_decoder())
}

/// Delete a food item from Tandoor
pub fn delete_food(
  config: ClientConfig,
  food_id food_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}
