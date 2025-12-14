/// Recipe List API
///
/// This module provides functions to list recipes from the Tandoor API
/// with pagination support.
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/types.{type TandoorRecipe}

/// List recipes from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (limit parameter)
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated recipe list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_recipes(config, limit: Some(20), offset: Some(0))
/// ```
pub fn list_recipes(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(TandoorRecipe), TandoorError) {
  // Build query parameters list
  let query_params =
    []
    |> fn(params) {
      case limit {
        option.Some(l) -> [#("limit", int.to_string(l)), ..params]
        option.None -> params
      }
    }
    |> fn(params) {
      case offset {
        option.Some(o) -> [#("offset", int.to_string(o)), ..params]
        option.None -> params
      }
    }
    |> list.reverse

  // Execute GET request using CRUD helper
  use resp <- result.try(crud_helpers.execute_get(
    config,
    "/api/recipe/",
    query_params,
  ))

  // Parse JSON response using paginated helper
  crud_helpers.parse_json_paginated(resp, recipe_decoder.recipe_decoder())
}
