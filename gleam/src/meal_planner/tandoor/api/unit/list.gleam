/// Unit List API
///
/// This module provides functions to list units from the Tandoor API
/// with pagination support.
import gleam/int
import gleam/list
import gleam/option.{type Option}
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/unit/unit_decoder
import meal_planner/tandoor/types/unit/unit.{type Unit}

/// List units from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `page` - Optional page number for pagination
///
/// # Returns
/// Result with paginated unit list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_units(config, limit: Some(25), page: Some(1))
/// ```
pub fn list_units(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Unit), TandoorError) {
  // Build query parameters list
  let query_params = build_query_params(limit, page)

  // Use generic_crud.list_paginated for paginated unit listing
  generic_crud.list_paginated(
    config,
    "/api/unit/",
    query_params,
    unit_decoder.decode_unit(),
  )
}

/// Build query parameters from limit and page options
fn build_query_params(
  limit: Option(Int),
  page: Option(Int),
) -> List(#(String, String)) {
  let limit_params = case limit {
    option.Some(l) -> [#("page_size", int.to_string(l))]
    option.None -> []
  }

  let page_params = case page {
    option.Some(p) -> [#("page", int.to_string(p))]
    option.None -> []
  }

  list.append(limit_params, page_params)
}
