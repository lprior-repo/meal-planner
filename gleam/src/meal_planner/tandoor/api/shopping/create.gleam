/// Shopping List Entry Create API
///
/// This module provides functions to create new shopping list entries in the Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/json
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError,
}
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder
import meal_planner/tandoor/encoders/shopping/shopping_list_entry_encoder
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry, type ShoppingListEntryCreate,
}

/// Create a new shopping list entry in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `data` - Shopping list entry data to create
///
/// # Returns
/// Result with created shopping list entry or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let entry_data = ShoppingListEntryCreate(
///   list_recipe: Some(shopping_list_id(1)),
///   food: Some(food_id(42)),
///   unit: None,
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: Some(10),
/// )
/// let result = create_shopping_list_entry(config, entry_data)
/// ```
pub fn create_shopping_list_entry(
  config: ClientConfig,
  data: ShoppingListEntryCreate,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/"

  // Encode shopping list entry data to JSON
  let body =
    shopping_list_entry_encoder.encode_shopping_list_entry_create(data)
    |> json.to_string

  // Build and execute request
  use req <- result.try(client.build_post_request(config, path, body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Convert to ApiResponse and parse JSON
  let api_resp = client.ApiResponse(resp.status, resp.headers, resp.body)
  client.parse_json_body(api_resp, fn(dyn) {
    decode.run(dyn, shopping_list_entry_decoder.decoder())
    |> result.map_error(fn(_) { "Failed to decode created shopping list entry" })
  })
}
