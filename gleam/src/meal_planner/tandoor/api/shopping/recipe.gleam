/// Shopping List Recipe API
///
/// This module provides functions to add recipes to shopping lists in the Tandoor API.
/// When you add a recipe to a shopping list, all of its ingredients are added as shopping list entries.
import gleam/dynamic/decode
import gleam/httpc
import gleam/json
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError,
}
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntry,
}

/// Add a recipe to the shopping list
///
/// This creates shopping list entries for all ingredients in the specified recipe.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - ID of the recipe to add
/// * `servings` - Number of servings to add to shopping list
///
/// # Returns
/// Result with list of created shopping list entries or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = add_recipe_to_shopping_list(config, recipe_id: 123, servings: 4)
/// ```
pub fn add_recipe_to_shopping_list(
  config: ClientConfig,
  recipe_id recipe_id: Int,
  servings servings: Int,
) -> Result(List(ShoppingListEntry), TandoorError) {
  let path = "/api/shopping-list-recipe/"

  // Encode request body - simple inline encoder for recipe and servings
  let body =
    json.object([
      #("recipe", json.int(recipe_id)),
      #("servings", json.int(servings)),
    ])
    |> json.to_string

  // Build and execute POST request
  use req <- result.try(client.build_post_request(config, path, body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Convert to ApiResponse and parse JSON response
  let api_resp = client.ApiResponse(resp.status, resp.headers, resp.body)
  client.parse_json_body(api_resp, fn(dyn) {
    decode.run(dyn, decode.list(shopping_list_entry_decoder.decoder()))
    |> result.map_error(fn(_) { "Failed to decode shopping list entries" })
  })
}
