/// Recipe Create API
///
/// This module provides functions to create new recipes in the Tandoor API.
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/encoders/recipe/recipe_create_encoder.{
  type CreateRecipeRequest,
}
import meal_planner/tandoor/types.{type TandoorRecipe}

/// Create a new recipe in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Recipe data to create
///
/// # Returns
/// Result with created recipe or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = CreateRecipeRequest(
///   name: "New Recipe",
///   description: Some("A delicious recipe"),
///   servings: 4,
///   servings_text: Some("4 people"),
///   working_time: Some(30),
///   waiting_time: Some(60),
/// )
/// let result = create_recipe(config, request)
/// ```
pub fn create_recipe(
  config: ClientConfig,
  request: CreateRecipeRequest,
) -> Result(TandoorRecipe, TandoorError) {
  // Encode recipe data to JSON
  let request_body =
    recipe_create_encoder.encode_create_recipe(request)
    |> json.to_string

  // Execute POST request using CRUD helper
  use resp <- result.try(crud_helpers.execute_post(
    config,
    "/api/recipe/",
    request_body,
  ))

  // Parse JSON response using generic helper and standard recipe decoder
  crud_helpers.parse_json_single(resp, recipe_decoder.recipe_decoder())
}
