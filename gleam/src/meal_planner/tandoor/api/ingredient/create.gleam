/// Ingredient Create API
///
/// This module provides functions to create new ingredient items in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/ingredient/ingredient_decoder
import meal_planner/tandoor/encoders/ingredient/ingredient_encoder.{
  type IngredientCreateRequest,
}
import meal_planner/tandoor/types/recipe/ingredient.{type Ingredient}

/// Create a new ingredient item in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `ingredient_data` - Ingredient data to create
///
/// # Returns
/// Result with created ingredient item or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let ingredient_data = IngredientCreateRequest(
///   food: Some(5),
///   unit: Some(2),
///   amount: 250.0,
///   note: Some("diced"),
///   order: 1,
///   is_header: False,
///   no_amount: False,
///   original_text: Some("250g tomatoes, diced")
/// )
/// let result = create_ingredient(config, ingredient_data)
/// ```
pub fn create_ingredient(
  config: ClientConfig,
  ingredient_data: IngredientCreateRequest,
) -> Result(Ingredient, TandoorError) {
  let body =
    ingredient_encoder.encode_ingredient_create(ingredient_data)
    |> json.to_string

  generic_crud.create(
    config,
    "/api/ingredient/",
    body,
    ingredient_decoder.ingredient_decoder(),
  )
}
