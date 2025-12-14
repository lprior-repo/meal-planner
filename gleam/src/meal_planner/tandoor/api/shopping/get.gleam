/// Shopping List Entry Get API
///
/// This module provides functions to get a single shopping list entry by ID from the
/// Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry,
}

/// Get a single shopping list entry by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - The ID of the shopping list entry to fetch
///
/// # Returns
/// Result with shopping list entry details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_shopping_list_entry(config, id: 42)
/// ```
pub fn get_shopping_list_entry(
  config: ClientConfig,
  id id: Int,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(id) <> "/"

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, shopping_list_entry_decoder.decoder()) {
        Ok(entry) -> Ok(entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode shopping list entry: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}
