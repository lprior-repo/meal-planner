/// Recipe scoring handler for the Meal Planner API
///
/// This module provides the recipe scoring endpoint that evaluates recipes
/// based on macro targets and compliance criteria. Scores recipes based on:
/// - Macro target alignment (protein/fat/carb percentages)
/// - Diet compliance (vertical diet, FODMAP level)
/// - Variety factors
///
/// Scoring Algorithm:
/// 1. Calculate macro match score (0-100): How well macros align with targets
/// 2. Calculate diet compliance score (0-100): Based on vertical diet/FODMAP
/// 3. Calculate variety score (0-100): Based on ingredient diversity
/// 4. Weighted final score: Applies user-specified weights to subscores
///
/// Example: A recipe with perfect macro match (100), good vertical compliance (80),
/// and average variety (60) with weights {macro: 0.4, compliance: 0.4, variety: 0.2}
/// yields: 100*0.4 + 80*0.4 + 60*0.2 = 84.0 final score
import gleam/float
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import meal_planner/types
import wisp

/// Scoring weights configuration from request
type ScoringWeights {
  ScoringWeights(diet_compliance: Float, macro_match: Float, variety: Float)
}

/// Complete scored recipe result
type ScoredRecipe {
  ScoredRecipe(
    id: String,
    name: String,
    final_score: Float,
    macro_score: Float,
    compliance_score: Float,
    variety_score: Float,
    macro_breakdown: MacroBreakdown,
    compliance_details: ComplianceDetails,
  )
}

/// Macro alignment details
type MacroBreakdown {
  MacroBreakdown(
    target_protein_pct: Float,
    actual_protein_pct: Float,
    protein_match: Float,
    target_fat_pct: Float,
    actual_fat_pct: Float,
    fat_match: Float,
    target_carb_pct: Float,
    actual_carb_pct: Float,
    carb_match: Float,
  )
}

/// Diet compliance scoring details
type ComplianceDetails {
  ComplianceDetails(
    is_vertical_compliant: Bool,
    fodmap_level: String,
    fodmap_score: Float,
  )
}

/// Recipe scoring request
type ScoringRequest {
  ScoringRequest(
    recipes: List(ScoringRecipeInput),
    macro_targets: MacroTargets,
    weights: ScoringWeights,
  )
}

/// Simplified recipe input for scoring
type ScoringRecipeInput {
  ScoringRecipeInput(
    id: String,
    name: String,
    macros: types.Macros,
    vertical_compliant: Bool,
    fodmap_level: String,
  )
}

/// Macro targets for scoring
type MacroTargets {
  MacroTargets(protein: Float, fat: Float, carbs: Float)
}

/// Recipe scoring endpoint
/// POST /api/ai/score-recipe
///
/// Request body JSON example:
/// {
///   "recipes": [
///     {
///       "id": "recipe-123",
///       "name": "Grilled Steak",
///       "macros": {"protein": 50, "fat": 30, "carbs": 5},
///       "vertical_compliant": true,
///       "fodmap_level": "low"
///     }
///   ],
///   "macro_targets": {"protein": 40, "fat": 25, "carbs": 35},
///   "weights": {"diet_compliance": 0.4, "macro_match": 0.5, "variety": 0.1}
/// }
///
/// Response: Array of scored recipes with breakdown
pub fn handle_score(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Post)

  // Attempt to read and parse request body
  case read_scoring_request(req) {
    Ok(scoring_request) -> {
      // Score each recipe
      let scored_recipes =
        list.map(scoring_request.recipes, fn(recipe) {
          score_recipe(
            recipe,
            scoring_request.macro_targets,
            scoring_request.weights,
          )
        })

      // Build response
      let response =
        json.object([
          #("status", json.string("success")),
          #("count", json.int(list.length(scored_recipes))),
          #(
            "scores",
            json.array(scored_recipes, fn(sr) { scored_recipe_to_json(sr) }),
          ),
          #("weights_applied", scoring_weights_to_json(scoring_request.weights)),
        ])
        |> json.to_string

      wisp.json_response(response, 200)
    }

    Error(error_msg) -> {
      // Return error response
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

/// Attempt to read and parse the scoring request from HTTP body
fn read_scoring_request(req: wisp.Request) -> Result(ScoringRequest, String) {
  // In a real implementation, we would use wisp.require_json or similar
  // For now, return a sample valid request to demonstrate the endpoint
  Ok(ScoringRequest(
    recipes: [
      ScoringRecipeInput(
        id: "sample-recipe-1",
        name: "High-Protein Steak",
        macros: types.Macros(protein: 60.0, fat: 35.0, carbs: 8.0),
        vertical_compliant: True,
        fodmap_level: "low",
      ),
      ScoringRecipeInput(
        id: "sample-recipe-2",
        name: "Balanced Chicken Bowl",
        macros: types.Macros(protein: 45.0, fat: 20.0, carbs: 50.0),
        vertical_compliant: False,
        fodmap_level: "low",
      ),
    ],
    macro_targets: MacroTargets(protein: 40.0, fat: 25.0, carbs: 35.0),
    weights: ScoringWeights(
      diet_compliance: 0.4,
      macro_match: 0.5,
      variety: 0.1,
    ),
  ))
}

/// Score a single recipe against targets with weights
fn score_recipe(
  recipe: ScoringRecipeInput,
  targets: MacroTargets,
  weights: ScoringWeights,
) -> ScoredRecipe {
  // Calculate macro percentages
  let total_cals = types.macros_calories(recipe.macros)
  let protein_pct = case total_cals >. 0.0 {
    True -> { recipe.macros.protein *. 4.0 } /. total_cals
    False -> 0.0
  }
  let fat_pct = case total_cals >. 0.0 {
    True -> { recipe.macros.fat *. 9.0 } /. total_cals
    False -> 0.0
  }
  let carb_pct = case total_cals >. 0.0 {
    True -> { recipe.macros.carbs *. 4.0 } /. total_cals
    False -> 0.0
  }

  // Calculate target percentages
  let target_total_cals =
    { targets.protein *. 4.0 }
    +. { targets.fat *. 9.0 }
    +. { targets.carbs *. 4.0 }
  let target_protein_pct = { targets.protein *. 4.0 } /. target_total_cals
  let target_fat_pct = { targets.fat *. 9.0 } /. target_total_cals
  let target_carb_pct = { targets.carbs *. 4.0 } /. target_total_cals

  // Calculate match scores (0-100) - how close to target percentage
  // Perfect match (within 5%) = 100, no match = 0
  let protein_match = calculate_macro_match(protein_pct, target_protein_pct)
  let fat_match = calculate_macro_match(fat_pct, target_fat_pct)
  let carb_match = calculate_macro_match(carb_pct, target_carb_pct)

  // Average macro match score
  let macro_score = { protein_match +. fat_match +. carb_match } /. 3.0

  // Calculate compliance score
  let compliance_score =
    calculate_compliance_score(recipe.vertical_compliant, recipe.fodmap_level)

  // Calculate variety score (simplified - would be based on ingredient count)
  let variety_score = 75.0

  // Calculate weighted final score
  let final_score =
    { macro_score *. weights.macro_match }
    +. { compliance_score *. weights.diet_compliance }
    +. { variety_score *. weights.variety }

  // Build macro breakdown
  let macro_breakdown =
    MacroBreakdown(
      target_protein_pct: target_protein_pct *. 100.0,
      actual_protein_pct: protein_pct *. 100.0,
      protein_match: protein_match,
      target_fat_pct: target_fat_pct *. 100.0,
      actual_fat_pct: fat_pct *. 100.0,
      fat_match: fat_match,
      target_carb_pct: target_carb_pct *. 100.0,
      actual_carb_pct: carb_pct *. 100.0,
      carb_match: carb_match,
    )

  // Build compliance details
  let compliance_details =
    ComplianceDetails(
      is_vertical_compliant: recipe.vertical_compliant,
      fodmap_level: recipe.fodmap_level,
      fodmap_score: case recipe.fodmap_level {
        "low" -> 100.0
        "medium" -> 50.0
        "high" -> 0.0
        _ -> 25.0
      },
    )

  ScoredRecipe(
    id: recipe.id,
    name: recipe.name,
    final_score: final_score,
    macro_score: macro_score,
    compliance_score: compliance_score,
    variety_score: variety_score,
    macro_breakdown: macro_breakdown,
    compliance_details: compliance_details,
  )
}

/// Calculate how well an actual percentage matches target
/// Returns 0-100 score where 100 is perfect match
/// This is exposed for testing purposes
pub fn calculate_macro_match(actual: Float, target: Float) -> Float {
  let difference = float_abs(actual -. target)
  // Allow 5% tolerance (0.05) for perfect score
  // At 10% difference, score is 50%
  // At 20% difference or more, score is 0%
  let tolerance = 0.05
  case difference {
    d if d <=. tolerance -> 100.0
    d if d <=. 0.1 -> 100.0 -. { { d -. tolerance } /. 0.05 *. 50.0 }
    d if d <=. 0.2 -> 50.0 -. { { d -. 0.1 } /. 0.1 *. 50.0 }
    _ -> 0.0
  }
}

/// Calculate compliance score based on diet requirements
/// This is exposed for testing purposes
pub fn calculate_compliance_score(
  vertical_compliant: Bool,
  fodmap_level: String,
) -> Float {
  let vertical_score = case vertical_compliant {
    True -> 100.0
    False -> 50.0
  }

  let fodmap_score = case fodmap_level {
    "low" -> 100.0
    "medium" -> 50.0
    "high" -> 0.0
    _ -> 25.0
  }

  // Average the two compliance factors
  { vertical_score +. fodmap_score } /. 2.0
}

/// Helper to get absolute value of a float
fn float_abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}

/// Convert scored recipe to JSON
fn scored_recipe_to_json(sr: ScoredRecipe) -> json.Json {
  json.object([
    #("id", json.string(sr.id)),
    #("name", json.string(sr.name)),
    #("final_score", json.float(sr.final_score)),
    #("macro_score", json.float(sr.macro_score)),
    #("compliance_score", json.float(sr.compliance_score)),
    #("variety_score", json.float(sr.variety_score)),
    #("macro_breakdown", macro_breakdown_to_json(sr.macro_breakdown)),
    #("compliance_details", compliance_details_to_json(sr.compliance_details)),
  ])
}

/// Convert macro breakdown to JSON
fn macro_breakdown_to_json(mb: MacroBreakdown) -> json.Json {
  json.object([
    #(
      "protein",
      json.object([
        #("target_pct", json.float(mb.target_protein_pct)),
        #("actual_pct", json.float(mb.actual_protein_pct)),
        #("match_score", json.float(mb.protein_match)),
      ]),
    ),
    #(
      "fat",
      json.object([
        #("target_pct", json.float(mb.target_fat_pct)),
        #("actual_pct", json.float(mb.actual_fat_pct)),
        #("match_score", json.float(mb.fat_match)),
      ]),
    ),
    #(
      "carbs",
      json.object([
        #("target_pct", json.float(mb.target_carb_pct)),
        #("actual_pct", json.float(mb.actual_carb_pct)),
        #("match_score", json.float(mb.carb_match)),
      ]),
    ),
  ])
}

/// Convert compliance details to JSON
fn compliance_details_to_json(cd: ComplianceDetails) -> json.Json {
  json.object([
    #("is_vertical_compliant", json.bool(cd.is_vertical_compliant)),
    #("fodmap_level", json.string(cd.fodmap_level)),
    #("fodmap_score", json.float(cd.fodmap_score)),
  ])
}

/// Convert scoring weights to JSON
fn scoring_weights_to_json(w: ScoringWeights) -> json.Json {
  json.object([
    #("diet_compliance", json.float(w.diet_compliance)),
    #("macro_match", json.float(w.macro_match)),
    #("variety", json.float(w.variety)),
  ])
}
