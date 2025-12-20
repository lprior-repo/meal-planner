/// Supermarket Categories HTTP handlers
///
/// Handles HTTP requests for Tandoor supermarket categories:
/// - GET /api/tandoor/supermarket-categories - List all categories
/// - POST /api/tandoor/supermarket-categories - Create a new category
/// - GET /api/tandoor/supermarket-categories/:id - Get category by ID
/// - PATCH /api/tandoor/supermarket-categories/:id - Update category
/// - DELETE /api/tandoor/supermarket-categories/:id - Delete category
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/option
import gleam/result
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/supermarket.{
  type SupermarketCategoryCreateRequest, SupermarketCategoryCreateRequest,
  create_category, delete_category, get_category, list_categories,
  update_category,
}
import wisp

// =============================================================================
// Supermarket Category Collection Handler
// =============================================================================

/// Handle requests to the categories collection endpoint
///
/// Routes:
/// - GET: List all categories
/// - POST: Create a new category
pub fn handle_categories_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_categories(req)
    http.Post -> handle_create_category(req)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn handle_list_categories(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case list_categories(config, limit: option.None, offset: option.None) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(category) {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
            })

          helpers.paginated_response(
            results_json,
            response.count,
            response.next,
            response.previous,
          )
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_create_category(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_category_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case create_category(config, request) {
            Ok(category) -> {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(201)
            }
            Error(_) -> helpers.error_response(500, "Failed to create category")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

// =============================================================================
// Supermarket Category Item Handler
// =============================================================================

/// Handle requests to individual category endpoints
///
/// Routes:
/// - GET: Get category by ID
/// - PATCH: Update category
/// - DELETE: Delete category
pub fn handle_category_by_id(
  req: wisp.Request,
  category_id: String,
) -> wisp.Response {
  case int.parse(category_id) {
    Ok(id) -> {
      case req.method {
        http.Get -> handle_get_category(req, id)
        http.Patch -> handle_update_category(req, id)
        http.Delete -> handle_delete_category(req, id)
        _ -> wisp.method_not_allowed([http.Get, http.Patch, http.Delete])
      }
    }
    Error(_) -> helpers.error_response(400, "Invalid category ID")
  }
}

fn handle_get_category(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case get_category(config, category_id: id) {
        Ok(category) -> {
          json.object([
            #("id", json.int(category.id)),
            #("name", json.string(category.name)),
            #(
              "description",
              helpers.encode_optional_string(category.description),
            ),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

fn handle_update_category(req: wisp.Request, id: Int) -> wisp.Response {
  use body <- wisp.require_json(req)

  case parse_supermarket_category_create_request(body) {
    Ok(request) -> {
      case helpers.get_authenticated_client() {
        Ok(config) -> {
          case
            update_category(config, category_id: id, category_data: request)
          {
            Ok(category) -> {
              json.object([
                #("id", json.int(category.id)),
                #("name", json.string(category.name)),
                #(
                  "description",
                  helpers.encode_optional_string(category.description),
                ),
              ])
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(_) -> helpers.error_response(500, "Failed to update category")
          }
        }
        Error(resp) -> resp
      }
    }
    Error(msg) -> helpers.error_response(400, msg)
  }
}

fn handle_delete_category(_req: wisp.Request, id: Int) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case delete_category(config, category_id: id) {
        Ok(Nil) -> wisp.response(204)
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Request Parsing and Validation
// =============================================================================

fn parse_supermarket_category_create_request(
  json_data: dynamic.Dynamic,
) -> Result(SupermarketCategoryCreateRequest, String) {
  decode.run(json_data, supermarket_category_create_decoder())
  |> result.map_error(fn(_) { "Invalid category create request" })
}

fn supermarket_category_create_decoder() -> decode.Decoder(
  SupermarketCategoryCreateRequest,
) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(SupermarketCategoryCreateRequest(
    name: name,
    description: description,
  ))
}
