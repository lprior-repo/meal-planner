/// FatSecret Recipes HTTP handlers
/// Endpoints for browsing and searching recipes
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import meal_planner/fatsecret/recipes/service
import meal_planner/fatsecret/recipes/types
import meal_planner/fatsecret/handlers_helpers as helpers
import wisp

/// GET /api/fatsecret/recipes/:id
/// Get recipe details by ID
pub fn handle_get_recipe(req: wisp.Request, recipe_id: String) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  case service.get_recipe(types.recipe_id(recipe_id)) {
    Ok(recipe) ->
      helpers.encode_recipe(recipe)
      |> json.to_string
      |> wisp.json_response(200)
    Error(service.NotConfigured) ->
      helpers.error_response(500, "FatSecret API not configured")
    Error(service.ApiError(e)) ->
      helpers.error_response(
        500,
        "Failed to get recipe: " <> service.error_to_string(service.ApiError(e)),
      )
  }
}

/// GET /api/fatsecret/recipes/search?q=query&page=1&max_results=20
/// Search for recipes
pub fn handle_search_recipes(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)

  let query = helpers.get_query_param(query_params, "q")

  case helpers.validate_required_string(query, "q") {
    Error(#(status, msg)) -> helpers.error_response(status, msg)
    Ok(q) -> {
      let page_number = helpers.parse_int_param(query_params, "page")
      let max_results = helpers.parse_int_param(query_params, "max_results")

      case service.search_recipes(q, page_number, max_results) {
        Ok(search_response) ->
          encode_search_response(search_response)
          |> json.to_string
          |> wisp.json_response(200)
        Error(service.NotConfigured) ->
          helpers.error_response(500, "FatSecret API not configured")
        Error(service.ApiError(e)) ->
          helpers.error_response(
            500,
            "Failed to search recipes: "
              <> service.error_to_string(service.ApiError(e)),
          )
      }
  }
}

/// GET /api/fatsecret/recipes/types
/// Get all recipe types/categories
pub fn handle_get_recipe_types(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  case service.get_recipe_types() {
    Ok(types_response) ->
      encode_recipe_types_response(types_response)
      |> json.to_string
      |> wisp.json_response(200)
    Error(service.NotConfigured) ->
      helpers.error_response(500, "FatSecret API not configured")
    Error(service.ApiError(e)) ->
      helpers.error_response(
        500,
        "Failed to get recipe types: "
          <> service.error_to_string(service.ApiError(e)),
      )
  }
}

/// GET /api/fatsecret/recipes/search/type/:type_id?page=1&max_results=20
/// Search recipes by type/category
pub fn handle_search_recipes_by_type(
  req: wisp.Request,
  type_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)

  let page_number = helpers.parse_int_param(query_params, "page")
  let max_results = helpers.parse_int_param(query_params, "max_results")

  case service.search_recipes_by_type(type_id, page_number, max_results) {
    Ok(search_response) ->
      encode_search_response(search_response)
      |> json.to_string
      |> wisp.json_response(200)
    Error(service.NotConfigured) ->
      helpers.error_response(500, "FatSecret API not configured")
    Error(service.ApiError(e)) ->
      helpers.error_response(
        500,
        "Failed to search recipes by type: "
          <> service.error_to_string(service.ApiError(e)),
      )
  }
}

// =============================================================================
// JSON Encoders
// =============================================================================

fn encode_search_response(response: types.RecipeSearchResponse) -> json.Json {
  json.object([
    #("recipes", json.array(response.recipes, helpers.encode_recipe_search_result)),
    #("max_results", json.int(response.max_results)),
    #("total_results", json.int(response.total_results)),
    #("page_number", json.int(response.page_number)),
  ])
}

fn encode_recipe_types_response(
  response: types.RecipeTypesResponse,
) -> json.Json {
  json.object([
    #("recipe_types", json.array(response.recipe_types, helpers.encode_recipe_type)),
  ])
}
