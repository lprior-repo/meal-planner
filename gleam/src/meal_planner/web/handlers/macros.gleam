/// Macro calculation handler for the Meal Planner API
///
/// This module provides the macro calculation endpoint that aggregates
/// nutritional information across recipes.
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/string
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

// JSON Decoders for type-safe request parsing

fn macros_decoder() -> decode.Decoder(types.Macros) {
  decode.into(types.Macros)
  |> decode.field("protein", decode.float)
  |> decode.field("fat", decode.float)
  |> decode.field("carbs", decode.float)
  |> decode.build
}

fn recipe_serving_decoder() -> decode.Decoder(RecipeServing) {
  decode.into(RecipeServing)
  |> decode.field("servings", decode.float)
  |> decode.field("macros", macros_decoder())
  |> decode.build
}

fn macros_request_decoder() -> decode.Decoder(MacrosRequest) {
  decode.into(MacrosRequest)
  |> decode.field("recipes", decode.list(recipe_serving_decoder()))
  |> decode.build
}

/// Parse macro calculation request from HTTP body
fn parse_macros_request(req: wisp.Request) -> Result(MacrosRequest, String) {
  use body <- result.try(wisp.require_json(req))
  
  // Parse the JSON body using the macros request decoder
  decode.run(body, macros_request_decoder())
  |> result.map_error(fn(errs) {
    "Failed to parse macros request: " <> string.inspect(errs)
  })
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
