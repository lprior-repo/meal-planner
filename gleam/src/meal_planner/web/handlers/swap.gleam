//// Meal swap handler for regenerating individual meal slots

import gleam/dynamic/decode
import gleam/http
import gleam/json
import meal_planner/generator
import meal_planner/meal_plan.{type DailyPlan, type Meal, Meal}
import meal_planner/storage
import meal_planner/types
import meal_planner/ui/components/meal_card
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

// ============================================================================
// Decoders
// ============================================================================

/// Decoder for a Meal from JSON
fn meal_decoder() -> decode.Decoder(Meal) {
  use recipe <- decode.field("recipe", types.recipe_decoder())
  use portion_size <- decode.field("portion_size", decode.float)
  decode.success(Meal(recipe: recipe, portion_size: portion_size))
}

/// Decoder for DailyPlan from JSON
fn daily_plan_decoder() -> decode.Decoder(DailyPlan) {
  use day_name <- decode.field("day_name", decode.string)
  use meals <- decode.field("meals", decode.list(meal_decoder()))
  decode.success(meal_plan.DailyPlan(day_name: day_name, meals: meals))
}

// ============================================================================
// Request Handlers
// ============================================================================

/// POST /api/swap/:meal_type - Regenerate a meal slot
///
/// Request body JSON:
/// {
///   "day_plan": {
///     "day_name": "Monday",
///     "meals": [
///       {"recipe": {...}, "portion_size": 1.0},
///       ...
///     ]
///   },
///   "calorie_target": 2000
/// }
///
/// Returns HTML fragment of the updated meal card (for HTMX outerHTML replacement)
pub fn api_swap_meal(
  req: wisp.Request,
  meal_type: String,
  ctx: Context,
) -> wisp.Response {
  // Check HTTP method
  case check_method(req) {
    Ok(Nil) -> handle_swap_request(req, meal_type, ctx)
    Error(response) -> response
  }
}

/// Internal handler for swap request
fn handle_swap_request(
  req: wisp.Request,
  meal_type: String,
  ctx: Context,
) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  // Decode the request JSON
  case decode.run(json_body, swap_request_decoder()) {
    Error(_) -> {
      let error_response =
        json.object([#("error", json.string("Invalid request format"))])
      wisp.json_response(json.to_string(error_response), 400)
    }
    Ok(swap_req) -> {
      // Validate meal_type
      case is_valid_meal_type(meal_type) {
        False -> {
          let error_response =
            json.object([
              #("error", json.string("Invalid meal type: " <> meal_type)),
            ])
          wisp.json_response(json.to_string(error_response), 400)
        }
        True -> {
          // Load all recipes from database
          case load_all_recipes(ctx) {
            Error(_) -> {
              let error_response =
                json.object([#("error", json.string("Failed to load recipes"))])
              wisp.json_response(json.to_string(error_response), 500)
            }
            Ok(available_recipes) -> {
              // Call generator to regenerate the slot
              case
                generator.regenerate_slot(
                  swap_req.day_plan,
                  meal_type,
                  swap_req.calorie_target,
                  available_recipes,
                )
              {
                Error(gen_error) -> {
                  let error_msg = generator_error_to_string(gen_error)
                  let error_response =
                    json.object([#("error", json.string(error_msg))])
                  wisp.json_response(json.to_string(error_response), 400)
                }
                Ok(new_recipe) -> {
                  // Create the new meal with default portion size
                  let new_meal = Meal(recipe: new_recipe, portion_size: 1.0)

                  // Render the meal card as HTML
                  let html = meal_card.render_meal_card(new_meal, meal_type)

                  // Return HTML (not JSON) for HTMX outerHTML replacement
                  wisp.response(200)
                  |> wisp.set_header("content-type", "text/html")
                  |> wisp.set_body(wisp.Text(html))
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Check HTTP method is POST
fn check_method(req: wisp.Request) -> Result(Nil, wisp.Response) {
  case req.method {
    http.Post -> Ok(Nil)
    _ -> Error(wisp.method_not_allowed([http.Post]))
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Decoder for swap request
fn swap_request_decoder() -> decode.Decoder(SwapRequest) {
  use day_plan <- decode.field("day_plan", daily_plan_decoder())
  use calorie_target <- decode.field("calorie_target", decode.int)
  decode.success(SwapRequest(day_plan: day_plan, calorie_target: calorie_target))
}

/// Swap request type
type SwapRequest {
  SwapRequest(day_plan: DailyPlan, calorie_target: Int)
}

/// Check if meal_type is valid
fn is_valid_meal_type(meal_type: String) -> Bool {
  case meal_type {
    "breakfast" | "lunch" | "dinner" -> True
    _ -> False
  }
}

/// Load all recipes from database
fn load_all_recipes(ctx: Context) -> Result(List(types.Recipe), Nil) {
  case storage.get_all_recipes(ctx.db) {
    Ok(recipes) -> Ok(recipes)
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
