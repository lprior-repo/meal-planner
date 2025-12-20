/// Foods/Ingredients web handlers for Tandoor Recipe Manager
///
/// This module handles HTTP requests for food items endpoints:
/// - GET /api/tandoor/foods - List foods with search/filtering
/// - GET /api/tandoor/foods/:id - Get single food with nutrition data
/// - POST /api/tandoor/foods - Create new food
/// - PATCH /api/tandoor/foods/:id - Update food
/// - DELETE /api/tandoor/foods/:id - Delete food
///
/// Supports:
/// - Search by query string
/// - Pagination (limit/offset)
/// - Nutrition data extraction via properties
/// - Food hierarchy (parent/child relationships)
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{
  type Food, type FoodCreateRequest, type FoodSimple, type FoodUpdateRequest,
  FoodCreateRequest, FoodUpdateRequest, create_food, delete_food, get_food,
  list_foods_with_options, update_food,
}
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/property.{type Property}
import meal_planner/tandoor/supermarket.{type SupermarketCategory}
import meal_planner/tandoor/types/food/food_inherit_field.{type FoodInheritField}
import meal_planner/tandoor/unit.{type Unit}
import wisp

// =============================================================================
// Foods Collection Handler
// =============================================================================

/// Handle requests to the foods collection endpoint
///
/// Supports:
/// - GET: List foods with optional query, limit, offset parameters
/// - POST: Create new food
pub fn handle_foods_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_foods(req)
    http.Post -> handle_create_food(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

/// Handle requests to a specific food by ID
///
/// Supports:
/// - GET: Get food details including nutrition
/// - PATCH: Update food
/// - DELETE: Delete food
pub fn handle_food_by_id(req: wisp.Request, food_id: String) -> wisp.Response {
  case int.parse(food_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_food(req, id)
        http.Patch -> handle_update_food(req, id)
        http.Delete -> handle_delete_food(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid food ID")
  }
}

// =============================================================================
// Private Handler Functions
// =============================================================================

fn handle_list_foods(req: wisp.Request) -> wisp.Response {
  let query_params = wisp.get_query(req)

  // Parse query parameters
  let limit = helpers.parse_int_param(query_params, "limit")
  let offset = helpers.parse_int_param(query_params, "offset")
  let query = helpers.get_query_param(query_params, "query")

  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case list_foods_with_options(config, limit, offset, query) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(food) { encode_food_detail(food) })

          helpers.paginated_response(
            results_json,
            response.count,
            response.next,
            response.previous,
          )
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> helpers.error_response(500, "Failed to list foods")
      }
    }
    Error(resp) -> resp
  }
}

fn handle_get_food(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case get_food(config, food_id: id) {
        Ok(food) -> {
          encode_food_detail(food)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_food(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_food_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case create_food(config, request) {
            Ok(food) -> {
              encode_food_detail(food)
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) -> helpers.error_response(500, "Failed to create food")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_update_food(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_food_update_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case update_food(config, food_id: id, data: request) {
            Ok(food) -> {
              encode_food_detail(food)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> helpers.error_response(500, "Failed to update food")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_food(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case delete_food(config, food_id: id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Food JSON Encoding
// =============================================================================

/// Encode a Food with complete details including nutrition properties
///
/// This is the main encoder used for GET responses. It includes all fields:
/// - Basic info (id, name, description)
/// - Optional fields (plural_name, url, fdc_id)
/// - Relationships (supermarket_category, recipe)
/// - Nutrition data (properties, properties_food_amount, properties_food_unit)
/// - Hierarchy (parent, numchild, inherit_fields)
pub fn encode_food_detail(food: Food) -> json.Json {
  json.object([
    #("id", json.int(ids.food_id_to_int(food.id))),
    #("name", json.string(food.name)),
    #("plural_name", helpers.encode_optional_string(food.plural_name)),
    #("description", json.string(food.description)),
    #("recipe", case food.recipe {
      option.Some(recipe) -> encode_food_simple(recipe)
      option.None -> json.null()
    }),
    #("food_onhand", case food.food_onhand {
      option.Some(onhand) -> json.bool(onhand)
      option.None -> json.null()
    }),
    #("supermarket_category", case food.supermarket_category {
      option.Some(cat) -> encode_supermarket_category(cat)
      option.None -> json.null()
    }),
    #("ignore_shopping", json.bool(food.ignore_shopping)),
    #("shopping", json.string(food.shopping)),
    #("url", helpers.encode_optional_string(food.url)),
    #("properties", case food.properties {
      option.Some(props) -> json.array(props, encode_property)
      option.None -> json.null()
    }),
    #("properties_food_amount", json.float(food.properties_food_amount)),
    #("properties_food_unit", case food.properties_food_unit {
      option.Some(unit) -> encode_unit(unit)
      option.None -> json.null()
    }),
    #("fdc_id", helpers.encode_optional_int(food.fdc_id)),
    #("parent", helpers.encode_optional_int(food.parent)),
    #("numchild", json.int(food.numchild)),
    #("inherit_fields", case food.inherit_fields {
      option.Some(fields) -> json.array(fields, encode_food_inherit_field)
      option.None -> json.null()
    }),
    #("full_name", json.string(food.full_name)),
  ])
}

/// Encode a FoodSimple (minimal food reference)
fn encode_food_simple(food: FoodSimple) -> json.Json {
  json.object([
    #("id", json.int(ids.food_id_to_int(food.id))),
    #("name", json.string(food.name)),
    #("plural_name", helpers.encode_optional_string(food.plural_name)),
  ])
}

/// Encode a SupermarketCategory
fn encode_supermarket_category(cat: SupermarketCategory) -> json.Json {
  json.object([
    #("id", json.int(cat.id)),
    #("name", json.string(cat.name)),
    #("description", helpers.encode_optional_string(cat.description)),
    #("open_data_slug", helpers.encode_optional_string(cat.open_data_slug)),
  ])
}

/// Encode a Property (nutrition/allergen data)
fn encode_property(prop: Property) -> json.Json {
  json.object([
    #("id", json.int(ids.property_id_to_int(prop.id))),
    #("name", json.string(prop.name)),
    #("description", json.string(prop.description)),
    #(
      "property_type",
      json.string(case prop.property_type {
        property.RecipeProperty -> "RECIPE"
        property.FoodProperty -> "FOOD"
      }),
    ),
    #("unit", helpers.encode_optional_string(prop.unit)),
    #("order", json.int(prop.order)),
    #("created_at", json.string(prop.created_at)),
    #("updated_at", json.string(prop.updated_at)),
  ])
}

/// Encode a Unit
fn encode_unit(unit: Unit) -> json.Json {
  json.object([
    #("id", json.int(unit.id)),
    #("name", json.string(unit.name)),
    #("plural_name", helpers.encode_optional_string(unit.plural_name)),
    #("description", helpers.encode_optional_string(unit.description)),
    #("base_unit", helpers.encode_optional_string(unit.base_unit)),
    #("open_data_slug", helpers.encode_optional_string(unit.open_data_slug)),
  ])
}

/// Encode a FoodInheritField
fn encode_food_inherit_field(field: FoodInheritField) -> json.Json {
  json.object([
    #("id", json.int(field.id)),
    #("name", json.string(field.name)),
    #("field", json.string(field.field)),
  ])
}

// =============================================================================
// JSON Decoding for Request Bodies
// =============================================================================

fn parse_food_create_request(
  json_data: dynamic.Dynamic,
) -> Result(FoodCreateRequest, String) {
  decode.run(json_data, food_create_decoder())
  |> result.map_error(fn(_) { "Invalid food create request" })
}

fn food_create_decoder() -> decode.Decoder(FoodCreateRequest) {
  use name <- decode.field("name", decode.string)
  decode.success(FoodCreateRequest(name: name))
}

fn parse_food_update_request(
  json_data: dynamic.Dynamic,
) -> Result(FoodUpdateRequest, String) {
  decode.run(json_data, food_update_decoder())
  |> result.map_error(fn(_) { "Invalid food update request" })
}

fn food_update_decoder() -> decode.Decoder(FoodUpdateRequest) {
  // Minimal decoder - all fields optional for update operations
  decode.success(FoodUpdateRequest(
    name: None,
    description: None,
    plural_name: None,
    recipe: None,
    food_onhand: None,
    supermarket_category: None,
    ignore_shopping: None,
    shopping: None,
    url: None,
    properties_food_amount: None,
    properties_food_unit: None,
    fdc_id: None,
    parent: None,
  ))
}
