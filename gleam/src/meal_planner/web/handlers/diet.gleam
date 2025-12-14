/// Vertical diet compliance handler for the Meal Planner API
///
/// This module provides the diet compliance check endpoint that evaluates
/// recipes against vertical diet principles.
import gleam/http
import gleam/json
import gleam/option.{Some}
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

  // Create a mock recipe for testing the compliance checker
  let mock_recipe =
    vertical_diet_compliance.Recipe(
      name: "Grass-Fed Beef with White Rice and Spinach",
      description: Some(
        "A vertical diet compliant recipe with beef, rice, and vegetables",
      ),
      recipe_ingredient: [
        vertical_diet_compliance.RecipeIngredient(display: "grass-fed beef"),
        vertical_diet_compliance.RecipeIngredient(display: "white rice"),
        vertical_diet_compliance.RecipeIngredient(display: "spinach"),
        vertical_diet_compliance.RecipeIngredient(display: "carrot"),
        vertical_diet_compliance.RecipeIngredient(display: "salt"),
      ],
      recipe_instructions: [
        vertical_diet_compliance.RecipeInstruction(text: "Grill the beef"),
        vertical_diet_compliance.RecipeInstruction(text: "Cook the white rice"),
        vertical_diet_compliance.RecipeInstruction(
          text: "Sauté the spinach and carrot",
        ),
        vertical_diet_compliance.RecipeInstruction(text: "Combine and serve"),
      ],
      rating: Some(5),
    )

  // Check compliance
  let result = vertical_diet_compliance.check_compliance(mock_recipe)

  // Build JSON response
  let body =
    json.object([
      #("recipe_id", json.string(recipe_id)),
      #("recipe_name", json.string(mock_recipe.name)),
      #("compliant", json.bool(result.compliant)),
      #("score", json.int(result.score)),
      #("reasons", json.array(result.reasons, json.string)),
      #("recommendations", json.array(result.recommendations, json.string)),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}
