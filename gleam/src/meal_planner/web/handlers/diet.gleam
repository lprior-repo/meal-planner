/// Vertical diet compliance handler for the Meal Planner API
///
/// This module provides the diet compliance check endpoint that evaluates
/// recipes against vertical diet principles.
import gleam/float
import gleam/http
import gleam/json
import gleam/list
import gleam/option
import meal_planner/fatsecret/recipes/service as recipe_service
import meal_planner/fatsecret/recipes/types as fatsecret_types
import meal_planner/vertical_diet_compliance as vdc
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

  case validate_recipe_id(recipe_id) {
    Error(msg) -> {
      let response =
        json.object([
          #("status", json.string("error")),
          #("error", json.string("Invalid recipe ID")),
          #("message", json.string(msg)),
          #("recipe_id", json.string(recipe_id)),
        ])
        |> json.to_string
      wisp.json_response(response, 400)
    }
    Ok(valid_id) -> {
      // Fetch recipe from FatSecret API
      case recipe_service.get_recipe(fatsecret_types.recipe_id(valid_id)) {
        Error(recipe_service.NotConfigured) -> {
          let response =
            json.object([
              #("status", json.string("error")),
              #("error", json.string("FatSecret API not configured")),
              #(
                "message",
                json.string(
                  "FatSecret API credentials are missing. Please configure FATSECRET_CLIENT_ID and FATSECRET_CLIENT_SECRET",
                ),
              ),
              #("recipe_id", json.string(recipe_id)),
            ])
            |> json.to_string
          wisp.json_response(response, 500)
        }
        Error(recipe_service.ApiError(error)) -> {
          let response =
            json.object([
              #("status", json.string("error")),
              #("error", json.string("Failed to fetch recipe")),
              #(
                "message",
                json.string(
                  "Error fetching recipe from FatSecret: "
                  <> recipe_service.error_to_string(recipe_service.ApiError(
                    error,
                  )),
                ),
              ),
              #("recipe_id", json.string(recipe_id)),
            ])
            |> json.to_string
          wisp.json_response(response, 500)
        }
        Ok(fatsecret_recipe) -> {
          // Convert FatSecret recipe to vertical diet compliance format
          let compliance_recipe = convert_to_compliance_recipe(fatsecret_recipe)

          // Check compliance
          let compliance = vdc.check_compliance(compliance_recipe)

          // Return compliance results
          let response =
            json.object([
              #("status", json.string("success")),
              #("recipe_id", json.string(recipe_id)),
              #("recipe_name", json.string(fatsecret_recipe.recipe_name)),
              #("compliance", encode_compliance(compliance)),
            ])
            |> json.to_string
          wisp.json_response(response, 200)
        }
      }
    }
  }
}

// ============================================================================
// Conversion Helpers
// ============================================================================

/// Convert FatSecret recipe to vertical diet compliance recipe format
fn convert_to_compliance_recipe(
  fatsecret_recipe: fatsecret_types.Recipe,
) -> vdc.Recipe {
  // Convert ingredients
  let ingredients =
    list.map(fatsecret_recipe.ingredients, fn(ingredient) {
      vdc.RecipeIngredient(display: ingredient.ingredient_description)
    })

  // Convert directions/instructions
  let instructions =
    list.map(fatsecret_recipe.directions, fn(direction) {
      vdc.RecipeInstruction(text: direction.direction_description)
    })

  // Convert rating from optional float to optional int
  let rating = case fatsecret_recipe.rating {
    option.Some(r) -> {
      let rounded = float.round(r)
      option.Some(rounded)
    }
    option.None -> option.None
  }

  vdc.Recipe(
    name: fatsecret_recipe.recipe_name,
    description: option.Some(fatsecret_recipe.recipe_description),
    recipe_ingredient: ingredients,
    recipe_instructions: instructions,
    rating: rating,
  )
}

// ============================================================================
// JSON Encoding Helpers
// ============================================================================

/// Encode vertical diet compliance result to JSON
fn encode_compliance(compliance: vdc.VerticalDietCompliance) -> json.Json {
  json.object([
    #("compliant", json.bool(compliance.compliant)),
    #("score", json.int(compliance.score)),
    #("reasons", json.array(compliance.reasons, json.string)),
    #("recommendations", json.array(compliance.recommendations, json.string)),
  ])
}

// ============================================================================
// Validation Helpers
// ============================================================================

fn validate_recipe_id(recipe_id: String) -> Result(String, String) {
  // Basic validation: recipe_id should be a non-empty string
  case recipe_id {
    "" -> Error("Recipe ID cannot be empty")
    id -> Ok(id)
  }
}
