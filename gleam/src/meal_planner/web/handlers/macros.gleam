/// Macro calculation handler for the Meal Planner API
///
/// This module provides the macro calculation endpoint using Wisp's idiomatic patterns:
/// - wisp.require_method() for HTTP method enforcement
/// - wisp.require_string_body() for request body parsing
/// - Centralized response builders from web/responses
///
/// The endpoint aggregates nutritional information across recipes
/// and returns total macros calculated from individual recipe servings.
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import meal_planner/web/responses
import wisp

/// Macro calculation request
type MacrosRequest {
  MacrosRequest(recipes: List(MacrosRecipeInput))
}

/// Individual recipe for macro calculation
type MacrosRecipeInput {
  MacrosRecipeInput(recipe_id: String, servings: Float, macros: MacrosData)
}

/// Macro data for a recipe
type MacrosData {
  MacrosData(protein: Float, fat: Float, carbs: Float)
}

/// Macro calculation endpoint
/// POST /api/macros/calculate
///
/// Calculates total macros from recipe servings and individual macros.
/// Uses Wisp's idiomatic patterns:
/// - wisp.log_request() for request logging
/// - wisp.rescue_crashes() for error recovery
/// - wisp.handle_head() for HEAD support
/// - wisp.require_method() to enforce POST-only
/// - wisp.require_string_body() to get request body
/// - Centralized response builders for consistent responses
pub fn handle_calculate(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_string_body(req)

  case parse_macros_request(body) {
    Error(msg) -> responses.bad_request(msg)
    Ok(request) -> {
      // Aggregate macros across all recipes
      let aggregated = aggregate_macros(request.recipes)
      let response_data =
        json.object([
          #("total_macros", aggregated_to_json(aggregated)),
          #("recipe_count", json.int(list.length(request.recipes))),
        ])

      responses.json_ok(response_data)
    }
  }
}

// ============================================================================
// JSON Parsing
// ============================================================================

fn parse_macros_request(body: String) -> Result(MacrosRequest, String) {
  let decoder = macros_request_decoder()
  case json.parse(body, decoder) {
    Ok(request) -> Ok(request)
    Error(_) -> Error("Invalid request: expected JSON with recipes array")
  }
}

fn macros_request_decoder() -> decode.Decoder(MacrosRequest) {
  use recipes <- decode.field("recipes", decode.list(macros_recipe_decoder()))
  decode.success(MacrosRequest(recipes: recipes))
}

fn macros_recipe_decoder() -> decode.Decoder(MacrosRecipeInput) {
  use recipe_id <- decode.field("recipe_id", decode.string)
  use servings <- decode.field("servings", decode.float)
  use macros_data <- decode.field("macros", macros_data_decoder())
  decode.success(MacrosRecipeInput(
    recipe_id: recipe_id,
    servings: servings,
    macros: macros_data,
  ))
}

fn macros_data_decoder() -> decode.Decoder(MacrosData) {
  use protein <- decode.field("protein", decode.float)
  use fat <- decode.field("fat", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  decode.success(MacrosData(protein: protein, fat: fat, carbs: carbs))
}

// ============================================================================
// Macro Aggregation
// ============================================================================

type AggregatedMacros {
  AggregatedMacros(
    total_protein: Float,
    total_fat: Float,
    total_carbs: Float,
    total_calories: Float,
  )
}

fn aggregate_macros(recipes: List(MacrosRecipeInput)) -> AggregatedMacros {
  let aggregate = fn(acc: AggregatedMacros, input: MacrosRecipeInput) -> AggregatedMacros {
    let recipe_total_protein = input.macros.protein *. input.servings
    let recipe_total_fat = input.macros.fat *. input.servings
    let recipe_total_carbs = input.macros.carbs *. input.servings
    AggregatedMacros(
      total_protein: acc.total_protein +. recipe_total_protein,
      total_fat: acc.total_fat +. recipe_total_fat,
      total_carbs: acc.total_carbs +. recipe_total_carbs,
      total_calories: 0.0,
    )
  }

  let result =
    list.fold(recipes, AggregatedMacros(0.0, 0.0, 0.0, 0.0), aggregate)

  // Calculate calories: 4 cal/g protein, 9 cal/g fat, 4 cal/g carbs
  let calories =
    result.total_protein
    *. 4.0
    +. result.total_fat
    *. 9.0
    +. result.total_carbs
    *. 4.0
  AggregatedMacros(
    total_protein: result.total_protein,
    total_fat: result.total_fat,
    total_carbs: result.total_carbs,
    total_calories: calories,
  )
}

fn aggregated_to_json(agg: AggregatedMacros) -> json.Json {
  json.object([
    #("protein", json.float(agg.total_protein)),
    #("fat", json.float(agg.total_fat)),
    #("carbs", json.float(agg.total_carbs)),
    #("calories", json.float(agg.total_calories)),
  ])
}
