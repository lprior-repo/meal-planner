/// Ingredient Get API
///
/// This module provides functions to get a single ingredient item by ID from the
/// Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/ingredient/ingredient_decoder
import meal_planner/tandoor/types/recipe/ingredient.{type Ingredient}

/// Get a single ingredient item by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `ingredient_id` - The ID of the ingredient item to fetch
///
/// # Returns
/// Result with ingredient details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_ingredient(config, ingredient_id: 42)
/// ```
pub fn get_ingredient(
  config: ClientConfig,
  ingredient_id ingredient_id: Int,
) -> Result(Ingredient, TandoorError) {
  generic_crud.get(
    config,
    "/api/ingredient/",
    ingredient_id,
    ingredient_decoder.ingredient_decoder(),
  )
}
