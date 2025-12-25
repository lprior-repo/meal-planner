/// Tandoor Foods API Client
///
/// This module provides food/ingredient operations for the Tandoor API.
/// It includes searching, retrieving, creating, and updating food items.
///
/// Foods represent ingredients and food items in Tandoor that can be used
/// in recipes and meal planning.
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, ParseError, build_delete_request,
  build_get_request, build_patch_request, build_post_request, execute_and_parse,
}
import meal_planner/tandoor/food.{
  type Food, type FoodCreateRequest, type FoodUpdateRequest,
  encode_food_create_request, encode_food_update_request, food_decoder,
}

// ============================================================================
// Food Search and List Operations
// ============================================================================

/// Search for foods in Tandoor by name/query
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `query` - Search query string to filter foods
/// * `limit` - Optional result limit
/// * `offset` - Optional result offset for pagination
///
/// # Returns
/// Result with paginated food list or error
///
/// # Example
/// ```gleam
/// let config = client.session_config("http://localhost:8000", "session_id")
/// search_foods(config, "tomato", Some(10), None)
/// ```
pub fn search_foods(
  config: ClientConfig,
  query: String,
  limit: Option(Int),
  offset: Option(Int),
) -> Result(List(Food), TandoorError) {
  let query_params =
    [#("query", query)]
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

  use req <- result.try(build_get_request(config, "/api/food/", query_params))
  logger.debug("Tandoor GET /api/food/ with query: " <> query)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, decode.list(food_decoder())) {
        Ok(foods) -> Ok(foods)
        Error(errors) -> {
          let error_msg =
            "Failed to decode foods list: "
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
    Error(_) -> Error(ParseError("Invalid JSON response from food search"))
  }
}

// ============================================================================
// Food Retrieval Operations
// ============================================================================

/// Get a single food item by ID
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `food_id` - The ID of the food to retrieve
///
/// # Returns
/// Result with the food details or error
///
/// # Example
/// ```gleam
/// let config = client.session_config("http://localhost:8000", "session_id")
/// get_food(config, 42)
/// ```
pub fn get_food(
  config: ClientConfig,
  food_id: Int,
) -> Result(Food, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"

  use req <- result.try(build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, food_decoder()) {
        Ok(food) -> Ok(food)
        Error(errors) -> {
          let error_msg =
            "Failed to decode food: "
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
    Error(_) -> Error(ParseError("Invalid JSON response from food get"))
  }
}

// ============================================================================
// Food Creation Operations
// ============================================================================

/// Create a new food item in Tandoor
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `food_data` - Food creation request with required fields
///
/// # Returns
/// Result with the created food or error
///
/// # Example
/// ```gleam
/// let config = client.session_config("http://localhost:8000", "session_id")
/// let create_req = FoodCreateRequest(name: "Tomato")
/// create_food(config, create_req)
/// ```
pub fn create_food(
  config: ClientConfig,
  food_data: FoodCreateRequest,
) -> Result(Food, TandoorError) {
  let body = encode_food_create_request(food_data) |> json.to_string

  use req <- result.try(build_post_request(config, "/api/food/", body))
  logger.debug("Tandoor POST /api/food/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, food_decoder()) {
        Ok(food) -> Ok(food)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created food: "
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
    Error(_) -> Error(ParseError("Invalid JSON response from food create"))
  }
}

// ============================================================================
// Food Update Operations
// ============================================================================

/// Update an existing food item (supports partial updates)
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `food_id` - The ID of the food to update
/// * `food_data` - Food update request with fields to modify
///
/// # Returns
/// Result with the updated food or error
///
/// # Example
/// ```gleam
/// let config = client.session_config("http://localhost:8000", "session_id")
/// let update_req = FoodUpdateRequest(
///   name: Some("Cherry Tomato"),
///   description: Some("Small sweet tomatoes"),
///   plural_name: Some(Some("Cherry Tomatoes")),
///   recipe: None,
///   food_onhand: None,
///   supermarket_category: None,
///   ignore_shopping: None,
///   shopping: None,
///   url: None,
///   properties_food_amount: None,
///   properties_food_unit: None,
///   fdc_id: None,
///   parent: None,
/// )
/// update_food(config, 42, update_req)
/// ```
pub fn update_food(
  config: ClientConfig,
  food_id: Int,
  food_data: FoodUpdateRequest,
) -> Result(Food, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"
  let body = encode_food_update_request(food_data) |> json.to_string

  use req <- result.try(build_patch_request(config, path, body))
  logger.debug("Tandoor PATCH " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, food_decoder()) {
        Ok(food) -> Ok(food)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated food: "
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
    Error(_) -> Error(ParseError("Invalid JSON response from food update"))
  }
}
