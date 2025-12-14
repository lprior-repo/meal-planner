/// Macro calculation handler for the Meal Planner API
///
/// This module provides the macro calculation endpoint that aggregates
/// nutritional information across recipes.
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import meal_planner/types
import wisp

/// Request format for macro calculation
type MacrosRequest {
  MacrosRequest(recipes: List(RecipeServing))
}

/// Individual recipe with servings
type RecipeServing {
  RecipeServing(servings: Float, macros: types.Macros)
}

/// Macro calculation endpoint
/// POST /api/macros/calculate
///
/// Calculates total macros from recipe servings and individual macros.
pub fn handle_calculate(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)

  case parse_macros_request(req) {
    Ok(request) -> {
      // Calculate totals
      let total_macros = calculate_total_macros(request.recipes)
      let total_calories = types.macros_calories(total_macros)

      // Build response
      let response =
        json.object([
          #("status", json.string("success")),
          #(
            "total_macros",
            json.object([
              #("protein", json.float(total_macros.protein)),
              #("fat", json.float(total_macros.fat)),
              #("carbs", json.float(total_macros.carbs)),
            ]),
          ),
          #("total_calories", json.float(total_calories)),
          #("recipe_count", json.int(list.length(request.recipes))),
        ])
        |> json.to_string

      wisp.json_response(response, 200)
    }
    Error(error_msg) -> {
      let response =
        json.object([
          #("status", json.string("error")),
          #("error", json.string(error_msg)),
        ])
        |> json.to_string

      wisp.json_response(response, 400)
    }
  }
}

/// Parse macro calculation request from HTTP body
fn parse_macros_request(req: wisp.Request) -> Result(MacrosRequest, String) {
  use _body <- result.try(wisp.require_json(req))
  
  // TODO: Implement full JSON decoding to extract recipes array
  // For now, return a sample valid request
  Ok(MacrosRequest(recipes: [
    RecipeServing(servings: 1.5, macros: types.Macros(protein: 50.0, fat: 20.0, carbs: 70.0)),
    RecipeServing(servings: 1.0, macros: types.Macros(protein: 35.0, fat: 12.0, carbs: 45.0)),
  ]))
}

/// Calculate total macros across all recipes with servings
fn calculate_total_macros(recipes: List(RecipeServing)) -> types.Macros {
  list.fold(recipes, types.Macros(0.0, 0.0, 0.0), fn(acc, recipe) {
    types.Macros(
      protein: acc.protein +. recipe.macros.protein *. recipe.servings,
      fat: acc.fat +. recipe.macros.fat *. recipe.servings,
      carbs: acc.carbs +. recipe.macros.carbs *. recipe.servings,
    )
  })
}
