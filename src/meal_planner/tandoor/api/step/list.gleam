/// Step List API
///
/// This module provides functions to list steps from the Tandoor API
/// with pagination support.
import gleam/int
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/recipe/step_decoder
import meal_planner/tandoor/types/recipe/step.{type Step}

/// List steps from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `page` - Optional page number for pagination
///
/// # Returns
/// Result with paginated step list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_steps(config, limit: Some(20), page: Some(1))
/// ```
pub fn list_steps(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Step), TandoorError) {
  // Build query parameters
  let params = case limit, page {
    option.Some(l), option.Some(p) -> [
      #("page_size", int.to_string(l)),
      #("page", int.to_string(p)),
    ]
    option.Some(l), option.None -> [#("page_size", int.to_string(l))]
    option.None, option.Some(p) -> [#("page", int.to_string(p))]
    option.None, option.None -> []
  }

  // Execute GET request using CRUD helper
  use resp <- result.try(crud_helpers.execute_get(config, "/api/step/", params))

  // Parse JSON response using paginated helper
  crud_helpers.parse_json_paginated(resp, step_decoder.step_decoder())
}
