/// Cuisine API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing cuisines via Tandoor API.
/// Cuisines represent the cultural or regional origin of recipes (e.g., Italian, Mexican).
///
/// **REFACTORED WITH CRUD HELPERS - 87% LINE REDUCTION**
///
/// ## Architecture
///
/// This module demonstrates the CRUD helper pattern that reduces boilerplate by 87%:
///
/// ### Traditional Pattern (Before):
/// ```gleam
/// // ~40 lines per operation
/// pub fn get_cuisine(config, id) {
///   let path = "/api/cuisine/" <> int.to_string(id) <> "/"
///   use req <- result.try(client.build_get_request(config, path, []))
///   use resp <- result.try(execute_request(req))
///   use api_resp <- result.try(client.parse_response(resp))
///   case json.parse(api_resp.body, using: decode.dynamic) {
///     Ok(json_data) -> {
///       case decode.run(json_data, cuisine_decoder.cuisine_decoder()) {
///         Ok(cuisine) -> Ok(cuisine)
///         Error(errors) -> Error(ParseError("Failed to decode: " <> ...))
///       }
///     }
///     Error(_) -> Error(ParseError("Invalid JSON"))
///   }
/// }
/// ```
///
/// ### CRUD Helper Pattern (After):
/// ```gleam
/// // ~5 lines per operation
/// pub fn get_cuisine(config, id) {
///   let path = "/api/cuisine/" <> int.to_string(id) <> "/"
///   use resp <- result.try(crud_helpers.execute_get(config, path, []))
///   crud_helpers.parse_json_single(resp, cuisine_decoder.cuisine_decoder())
/// }
/// ```
///
/// ## Operations
///
/// - **list_cuisines**: Get all cuisines
/// - **list_cuisines_by_parent**: Get cuisines filtered by parent ID
/// - **get_cuisine**: Get a single cuisine by ID
/// - **create_cuisine**: Create a new cuisine
/// - **update_cuisine**: Update an existing cuisine (partial updates)
/// - **delete_cuisine**: Delete a cuisine
///
/// ## Example Usage
///
/// ```gleam
/// import meal_planner/tandoor/api/cuisine
/// import meal_planner/tandoor/client
/// import gleam/option.{Some, None}
///
/// pub fn main() {
///   let config = client.bearer_config("http://localhost:8000", "my-token")
///
///   // List all cuisines
///   let assert Ok(cuisines) = cuisine.list_cuisines(config)
///
///   // Get specific cuisine
///   let assert Ok(italian) = cuisine.get_cuisine(config, cuisine_id: 1)
/// }
/// ```
// Re-export types

pub type Cuisine =
  cuisine.Cuisine

pub type CuisineCreateRequest =
  cuisine.CuisineCreateRequest

pub type CuisineUpdateRequest =
  cuisine.CuisineUpdateRequest

// Re-export functions
import meal_planner/tandoor/api/cuisine/create
import meal_planner/tandoor/api/cuisine/delete
import meal_planner/tandoor/api/cuisine/get
import meal_planner/tandoor/api/cuisine/list
import meal_planner/tandoor/api/cuisine/update
import meal_planner/tandoor/types/cuisine/cuisine

pub const create_cuisine = create.create_cuisine

pub const delete_cuisine = delete.delete_cuisine

pub const get_cuisine = get.get_cuisine

pub const list_cuisines = list.list_cuisines

pub const list_cuisines_by_parent = list.list_cuisines_by_parent

pub const update_cuisine = update.update_cuisine
