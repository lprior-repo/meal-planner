//// Generate meal plan handler for API endpoints

import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import lustre/element
import meal_planner/generator
import meal_planner/meal_plan.{type DailyPlan, type Meal, Meal}
import meal_planner/storage
import meal_planner/types.{type Recipe}
import meal_planner/ui/components/meal_card
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

// ============================================================================
// Type Definitions
// ============================================================================

/// Generate request structure
type GenerateRequest {
  GenerateRequest(target: Int, locked_id: option.Option(Int))
}

// ============================================================================
// Request Handlers
// ============================================================================

/// POST /api/generate - Generate a meal plan
///
/// Request body JSON:
/// {
///   "target": 2000,
///   "locked_id": 123  // optional - recipe ID to lock in the plan
/// }
///
/// Returns HTML fragment with meal cards for HTMX insertion
pub fn api_generate(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Post -> handle_generate_request(req, ctx)
    _ -> wisp.method_not_allowed([http.Post])
  }
}

/// Internal handler for generate request
fn handle_generate_request(req: wisp.Request, ctx: Context) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  // Decode the request JSON
  case decode.run(json_body, generate_request_decoder()) {
    Error(_) -> {
      let error_response =
        json.object([#("error", json.string("Invalid request format"))])
      wisp.json_response(json.to_string(error_response), 400)
    }
    Ok(gen_req) -> {
      process_generate_request(gen_req, ctx)
    }
  }
}

/// Process a valid generate request
fn process_generate_request(
  gen_req: GenerateRequest,
  ctx: Context,
) -> wisp.Response {
  // Validate target
  case gen_req.target <= 0 {
    True -> {
      let error_response =
        json.object([
          #("error", json.string("Invalid calorie target: must be positive")),
        ])
      wisp.json_response(json.to_string(error_response), 400)
    }
    False -> {
      // Load all recipes from database
      case load_all_recipes(ctx) {
        Error(_) -> {
          let error_response =
            json.object([#("error", json.string("Failed to load recipes"))])
          wisp.json_response(json.to_string(error_response), 500)
        }
        Ok(available_recipes) -> {
          // Check if locked_id is provided
          case gen_req.locked_id {
            None -> {
              // Generate without locked food - use first 3 recipes
              render_meal_cards_from_recipes(list.take(available_recipes, 3))
            }
            Some(locked_id) -> {
              // Find the locked recipe
              case find_recipe_by_id(ctx, locked_id) {
                Error(_) -> {
                  let error_response =
                    json.object([
                      #("error", json.string("Locked recipe not found")),
                    ])
                  wisp.json_response(json.to_string(error_response), 404)
                }
                Ok(locked_recipe) -> {
                  // Call generator with locked food
                  case
                    generator.generate_with_locked(
                      gen_req.target,
                      locked_recipe,
                      available_recipes,
                    )
                  {
                    Error(gen_error) -> {
                      let error_msg = generator_error_to_string(gen_error)
                      let error_response =
                        json.object([#("error", json.string(error_msg))])
                      wisp.json_response(json.to_string(error_response), 400)
                    }
                    Ok(daily_plan) -> {
                      // Render meal cards for all meals
                      render_daily_plan_meals(daily_plan)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// Decoders
// ============================================================================

/// Decoder for generate request - simple version that ignores optional locked_id
fn generate_request_decoder() -> decode.Decoder(GenerateRequest) {
  use target <- decode.field("target", decode.int)
  decode.success(GenerateRequest(target: target, locked_id: None))
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Render meal cards from a list of recipes
fn render_meal_cards_from_recipes(recipes: List(Recipe)) -> wisp.Response {
  case list.length(recipes) {
    0 -> {
      let error_response =
        json.object([#("error", json.string("No recipes available"))])
      wisp.json_response(json.to_string(error_response), 400)
    }
    _ -> {
      let meal_types = ["breakfast", "lunch", "dinner"]
      let meal_html =
        list.zip(recipes, meal_types)
        |> list.map(fn(pair) {
          let meal = Meal(recipe: pair.0, portion_size: 1.0)
          meal_card.render_meal_card(meal, pair.1)
          |> element.to_string
        })
        |> list.fold("", fn(acc, card) { acc <> card })

      wisp.response(200)
      |> wisp.set_header("content-type", "text/html")
      |> wisp.set_body(wisp.Text(meal_html))
    }
  }
}

/// Render meal cards from a daily plan
fn render_daily_plan_meals(daily_plan: DailyPlan) -> wisp.Response {
  let meal_types = ["breakfast", "lunch", "dinner"]
  let meals = list.zip(daily_plan.meals, meal_types)

  let meal_html =
    meals
    |> list.map(fn(pair) {
      meal_card.render_meal_card(pair.0, pair.1)
      |> element.to_string
    })
    |> list.fold("", fn(acc, card) { acc <> card })

  wisp.response(200)
  |> wisp.set_header("content-type", "text/html")
  |> wisp.set_body(wisp.Text(meal_html))
}

/// Load all recipes from database
fn load_all_recipes(ctx: Context) -> Result(List(Recipe), Nil) {
  case storage.get_all_recipes(ctx.db) {
    Ok(recipes) -> Ok(recipes)
    Error(_) -> Error(Nil)
  }
}

/// Find a recipe by ID
fn find_recipe_by_id(ctx: Context, recipe_id: Int) -> Result(Recipe, Nil) {
  case storage.get_recipe_by_id(ctx.db, int.to_string(recipe_id)) {
    Ok(recipe) -> Ok(recipe)
    Error(_) -> Error(Nil)
  }
}

/// Convert generator error to user-friendly string
fn generator_error_to_string(error: generator.GeneratorError) -> String {
  case error {
    generator.InvalidSlot(slot) -> "Invalid meal slot: " <> slot
    generator.SlotNotFound(slot) -> "Slot not found: " <> slot
    generator.KnapsackError(_) -> "Failed to find suitable meal"
    generator.NoRecipesAvailable -> "No recipes available"
    generator.InvalidTarget -> "Invalid calorie target"
  }
}
