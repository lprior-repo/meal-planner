/// Recipe scoring handler for the Meal Planner API
///
/// This module provides the recipe scoring endpoint using Wisp's idiomatic patterns:
/// - wisp.require_method() for HTTP method validation
/// - wisp.require_string_body() for request body handling
/// - Centralized response builders from web/responses
import gleam/dynamic/decode
import gleam/http
import gleam/json
import meal_planner/web/responses
import wisp

/// Scoring request from client
type ScoringRequest {
  ScoringRequest(
    recipes: List(ScoringRecipeInput),
    targets: MacroTargets,
    weights: ScoringWeights,
  )
}

/// Individual recipe input for scoring
type ScoringRecipeInput {
  ScoringRecipeInput(recipe_id: String, servings: Float)
}

/// Macro targets for the day
type MacroTargets {
  MacroTargets(protein: Float, fat: Float, carbs: Float)
}

/// Weighting for scoring
type ScoringWeights {
  ScoringWeights(protein_weight: Float, fat_weight: Float, carbs_weight: Float)
}

/// Recipe scoring endpoint
/// POST /api/ai/score-recipe
///
/// Uses Wisp's idiomatic patterns:
/// - wisp.log_request() for request logging
/// - wisp.rescue_crashes() for error recovery
/// - wisp.handle_head() for HEAD method support
/// - wisp.require_method() to enforce POST-only
/// - wisp.require_string_body() to get request body
/// - Centralized response builders for consistent error responses
pub fn handle_score(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_string_body(req)

  case parse_scoring_request(body) {
    Error(msg) -> responses.bad_request(msg)
    Ok(_scoring_request) -> {
      // TODO: Implement actual scoring logic
      responses.not_implemented(
        "Recipe scoring algorithm needs to be implemented",
      )
    }
  }
}

// ============================================================================
// JSON Parsing
// ============================================================================

fn parse_scoring_request(body: String) -> Result(ScoringRequest, String) {
  let decoder = scoring_request_decoder()
  case json.parse(body, decoder) {
    Ok(request) -> Ok(request)
    Error(_) ->
      Error(
        "Invalid request: expected JSON with recipes, targets, and weights fields",
      )
  }
}

fn scoring_request_decoder() -> decode.Decoder(ScoringRequest) {
  use recipes <- decode.field("recipes", decode.list(scoring_recipe_decoder()))
  use targets <- decode.field("targets", macro_targets_decoder())
  use weights <- decode.field("weights", scoring_weights_decoder())
  decode.success(ScoringRequest(
    recipes: recipes,
    targets: targets,
    weights: weights,
  ))
}

fn scoring_recipe_decoder() -> decode.Decoder(ScoringRecipeInput) {
  use recipe_id <- decode.field("recipe_id", decode.string)
  use servings <- decode.field("servings", decode.float)
  decode.success(ScoringRecipeInput(recipe_id: recipe_id, servings: servings))
}

fn macro_targets_decoder() -> decode.Decoder(MacroTargets) {
  use protein <- decode.field("protein", decode.float)
  use fat <- decode.field("fat", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  decode.success(MacroTargets(protein: protein, fat: fat, carbs: carbs))
}

fn scoring_weights_decoder() -> decode.Decoder(ScoringWeights) {
  use protein_weight <- decode.optional_field(
    "protein_weight",
    1.0,
    decode.float,
  )
  use fat_weight <- decode.optional_field("fat_weight", 1.0, decode.float)
  use carbs_weight <- decode.optional_field("carbs_weight", 1.0, decode.float)
  decode.success(ScoringWeights(
    protein_weight: protein_weight,
    fat_weight: fat_weight,
    carbs_weight: carbs_weight,
  ))
}
