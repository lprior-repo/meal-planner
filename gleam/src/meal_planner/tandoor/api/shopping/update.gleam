/// Shopping List Entry Update API
///
/// This module provides functions to update existing shopping list entries in the Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/core/ids.{type ShoppingListEntryId}
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder
import meal_planner/tandoor/encoders/shopping/shopping_list_entry_encoder
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry, type ShoppingListEntryUpdate,
}

/// Update an existing shopping list entry in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - The ID of the shopping list entry to update
/// * `data` - Updated shopping list entry data
///
/// # Returns
/// Result with updated shopping list entry or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let update_data = ShoppingListEntryUpdate(
///   list_recipe: Some(shopping_list_id(1)),
///   food: Some(food_id(42)),
///   unit: None,
///   amount: 3.0,
///   order: 1,
///   checked: True,
///   ingredient: None,
///   completed_at: Some("2025-12-14T14:00:00Z"),
///   delay_until: None,
/// )
/// let result = update_shopping_list_entry(config, id: entry_id, data: update_data)
/// ```
pub fn update_shopping_list_entry(
  config: ClientConfig,
  id id: ShoppingListEntryId,
  data data: ShoppingListEntryUpdate,
) -> Result(ShoppingListEntry, TandoorError) {
  let path =
    "/api/shopping-list-entry/" <> int.to_string(ids.shopping_list_entry_id_to_int(id)) <> "/"

  // Encode shopping list entry data to JSON
  let request_body =
    shopping_list_entry_encoder.encode_shopping_list_entry_update(data)
    |> json.to_string

  // Build and execute PATCH request
  use req <- result.try(client.build_patch_request(config, path, request_body))

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
            "Failed to decode updated shopping list entry: "
            <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}
