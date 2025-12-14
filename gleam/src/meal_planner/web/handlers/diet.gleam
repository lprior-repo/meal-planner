/// Vertical diet compliance handler for the Meal Planner API
///
/// This module provides the diet compliance check endpoint that evaluates
/// recipes against vertical diet principles.
import gleam/http
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import meal_planner/storage/recipes as recipe_storage
import meal_planner/vertical_diet_compliance
import wisp

/// Vertical diet compliance check endpoint
/// GET /api/diet/vertical/compliance/{recipe_id}
///
/// Returns vertical diet compliance score and recommendations for a recipe.
pub fn handle_compliance(req: wisp.Request, recipe_id: String) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  // Fetch the recipe from database
  case fetch_and_check_recipe(recipe_id) {
    Ok(result) -> {
      let body =
        json.object([
          #("recipe_id", json.string(recipe_id)),
          #("recipe_name", json.string(result.recipe_name)),
          #("compliant", json.bool(result.compliant)),
          #("score", json.int(result.score)),
          #("reasons", json.array(result.reasons, json.string)),
          #("recommendations", json.array(result.recommendations, json.string)),
        ])
        |> json.to_string

      wisp.json_response(body, 200)
    }
    Error(#("not_found", _)) -> {
      let response =
        json.object([
          #("status", json.string("error")),
          #("error", json.string("Recipe not found")),
          #("recipe_id", json.string(recipe_id)),
        ])
        |> json.to_string

      wisp.json_response(response, 404)
    }
    Error(#("invalid_id", _)) -> {
      let response =
        json.object([
          #("status", json.string("error")),
          #("error", json.string("Invalid recipe ID format")),
        ])
        |> json.to_string

      wisp.json_response(response, 400)
    }
    Error(#("db_error", msg)) -> {
      let response =
        json.object([
          #("status", json.string("error")),
          #("error", json.string("Database error: " <> msg)),
        ])
        |> json.to_string

      wisp.json_response(response, 500)
    }
  }
}

/// Fetch recipe from database and check compliance
/// Returns error tuple with (#error_type, error_message)
fn fetch_and_check_recipe(
  recipe_id: String,
) -> Result(
  #(String, Int, Bool, List(String), List(String)),
  #(String, String),
) {
  use recipe <- result.try(
    recipe_storage.get_recipe(recipe_id)
    |> result.map_error(fn(err) { #("db_error", "Failed to fetch recipe") }),
  )

  // Convert database recipe to vertical_diet_compliance.Recipe type
  let compliance_recipe =
    vertical_diet_compliance.Recipe(
      name: recipe.name,
      description: recipe.description,
      recipe_ingredient: recipe.ingredients
        |> Nil,  // TODO: Map recipe ingredients to RecipeIngredient list
      recipe_instructions: recipe.instructions
        |> Nil,  // TODO: Map recipe instructions to RecipeInstruction list
      rating: recipe.rating,
    )

  // Check compliance
  let result = vertical_diet_compliance.check_compliance(compliance_recipe)

  Ok(#(
    recipe.name,
    result.score,
    result.compliant,
    result.reasons,
    result.recommendations,
  ))
}
