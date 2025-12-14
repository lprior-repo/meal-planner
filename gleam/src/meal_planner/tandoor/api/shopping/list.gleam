/// Shopping List Entry List API
///
/// This module provides functions to list shopping list entries from the Tandoor API
/// with filtering and pagination support.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder.{
  type ShoppingListEntryResponse,
}

/// List shopping list entries from Tandoor API with filtering and pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `checked` - Optional filter by checked status (true/false)
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated shopping list entry list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// // Get unchecked items
/// let result = list_shopping_entries(config, checked: Some(False), limit: Some(20), offset: Some(0))
/// // Get all items
/// let all = list_shopping_entries(config, checked: None, limit: None, offset: None)
/// ```
pub fn list_shopping_entries(
  config: ClientConfig,
  checked checked: Option(Bool),
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(ShoppingListEntryResponse), TandoorError) {
  // Build query parameters
  let path = build_query_path(checked, limit, offset)

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      // Decode paginated response with shopping list entry items
      case
        decode.run(
          json_data,
          http.paginated_decoder(shopping_list_entry_decoder.decode_entry()),
        )
      {
        Ok(paginated) -> Ok(paginated)
        Error(errors) -> {
          let error_msg =
            "Failed to decode shopping list entry list: "
            <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

/// Build query path with all optional parameters
fn build_query_path(
  checked: Option(Bool),
  limit: Option(Int),
  offset: Option(Int),
) -> String {
  let base = "/api/shopping-list-entry/"

  // Convert boolean to string for query param
  let bool_to_string = fn(b: Bool) -> String {
    case b {
      True -> "true"
      False -> "false"
    }
  }

  case checked, limit, offset {
    option.Some(c), option.Some(l), option.Some(o) ->
      base
      <> "?checked="
      <> bool_to_string(c)
      <> "&page_size="
      <> int.to_string(l)
      <> "&offset="
      <> int.to_string(o)
    option.Some(c), option.Some(l), option.None ->
      base
      <> "?checked="
      <> bool_to_string(c)
      <> "&page_size="
      <> int.to_string(l)
    option.Some(c), option.None, option.Some(o) ->
      base <> "?checked=" <> bool_to_string(c) <> "&offset=" <> int.to_string(o)
    option.None, option.Some(l), option.Some(o) ->
      base
      <> "?page_size="
      <> int.to_string(l)
      <> "&offset="
      <> int.to_string(o)
    option.Some(c), option.None, option.None ->
      base <> "?checked=" <> bool_to_string(c)
    option.None, option.Some(l), option.None ->
      base <> "?page_size=" <> int.to_string(l)
    option.None, option.None, option.Some(o) ->
      base <> "?offset=" <> int.to_string(o)
    option.None, option.None, option.None -> base
  }
}
