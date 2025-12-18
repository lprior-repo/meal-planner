/// Ingredient Update API
///
/// This module provides functions to update existing ingredient items in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/ingredient/ingredient_decoder
import meal_planner/tandoor/encoders/ingredient/ingredient_encoder.{
  type IngredientCreateRequest,
}
import meal_planner/tandoor/types/recipe/ingredient.{type Ingredient}

/// Update an existing ingredient item in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `ingredient_id` - The ID of the ingredient item to update
/// * `ingredient_data` - Updated ingredient data
///
/// # Returns
/// Result with updated ingredient item or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let ingredient_data = IngredientCreateRequest(
///   food: Some(5),
///   unit: Some(2),
///   amount: 300.0,
///   note: Some("finely diced"),
///   order: 1,
///   is_header: False,
///   no_amount: False,
///   original_text: Some("300g tomatoes, finely diced")
/// )
/// let result = update_ingredient(config, ingredient_id: 42, ingredient_data: ingredient_data)
/// ```
pub fn update_ingredient(
  config: ClientConfig,
  ingredient_id ingredient_id: Int,
  ingredient_data ingredient_data: IngredientCreateRequest,
) -> Result(Ingredient, TandoorError) {
  let body =
    ingredient_encoder.encode_ingredient_create(ingredient_data)
    |> json.to_string

  generic_crud.update(
    config,
    "/api/ingredient/",
    ingredient_id,
    body,
    ingredient_decoder.ingredient_decoder(),
  )
}
