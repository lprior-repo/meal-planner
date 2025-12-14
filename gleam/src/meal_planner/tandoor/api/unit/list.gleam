/// Unit List API
///
/// This module provides functions to list units from the Tandoor API
/// with pagination support.
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/tandoor/api/crud_helpers
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

  // Execute GET request
  use resp <- result.try(crud_helpers.execute_get(
    config,
    "/api/unit/",
    query_params,
  ))

  // Parse JSON response using the paginated decoder
  parse_paginated_response(resp)
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

/// Parse paginated response from JSON
fn parse_paginated_response(
  response: client.ApiResponse,
) -> Result(PaginatedResponse(Unit), TandoorError) {
  case json.parse(response.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(
          json_data,
          http.paginated_decoder(unit_decoder.decode_unit()),
        )
      {
        Ok(paginated) -> Ok(paginated)
        Error(errors) -> {
          let error_msg =
            "Failed to decode unit list: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(client.ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(client.ParseError("Invalid JSON response"))
  }
}
