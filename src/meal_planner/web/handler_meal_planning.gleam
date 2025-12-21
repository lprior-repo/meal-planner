/// Meal Planning Orchestration Handler
///
/// This module provides the main meal planning endpoint that orchestrates:
/// 1. Recipe selection from MVP library
/// 2. Grocery list generation
/// 3. Meal prep plan generation (AI-powered)
/// 4. FatSecret synchronization
///
/// Uses Wisp's idiomatic patterns for request/response handling
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import meal_planner/meal_sync.{type MealSelection, MealSelection}
import meal_planner/mvp_recipes
import meal_planner/orchestrator
import meal_planner/tandoor/client.{type ClientConfig}
import meal_planner/web/responses
import wisp

/// Request to generate a meal plan
type MealPlanRequest {
  MealPlanRequest(
    /// List of recipe selections (recipe_id, date, meal_type, servings)
    selections: List(MealSelection),
  )
}

/// Response with complete meal plan
/// Generate a complete meal plan
/// POST /api/meal-planning/generate
///
/// Request body:
/// ```json
/// {
///   "selections": [
///     {
///       "date": "2025-12-16",
///       "meal_type": "dinner",
///       "recipe_id": 1,
///       "servings": 2.0
///     }
///   ]
/// }
/// ```
///
/// Response:
/// ```json
/// {
///   "recipes_selected": 1,
///   "grocery_list_items": 12,
///   "total_prep_time_min": 60,
///   "formatted_plan": "... full formatted meal plan ..."
/// }
/// ```
pub fn handle_generate(
  req: wisp.Request,
  tandoor_config: ClientConfig,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_string_body(req)

  case parse_meal_plan_request(body) {
    Error(msg) -> responses.bad_request(msg)
    Ok(request) -> {
      case orchestrator.plan_meals(tandoor_config, request.selections) {
        Error(err) -> responses.bad_request(err)
        Ok(plan) -> {
          let formatted = orchestrator.format_meal_plan(plan)
          let grocery_count = list.length(plan.grocery_list.all_items)

          let response_data =
            json.object([
              #("recipes_selected", json.int(plan.recipes_selected)),
              #("grocery_list_items", json.int(grocery_count)),
              #(
                "total_prep_time_min",
                json.int(plan.meal_prep_plan.total_prep_time_min),
              ),
              #("formatted_plan", json.string(formatted)),
            ])

          responses.json_ok(response_data)
        }
      }
    }
  }
}

/// Sync meals to FatSecret diary
/// POST /api/meal-planning/sync
///
/// Request body:
/// ```json
/// {
///   "selections": [
///     {
///       "date": "2025-12-16",
///       "meal_type": "dinner",
///       "recipe_id": 1,
///       "servings": 2.0
///     }
///   ]
/// }
/// ```
///
/// Returns:
/// - 200: Success with sync results
/// - 400: Invalid request
/// - 500: Server error
pub fn handle_sync_meals(
  req: wisp.Request,
  _tandoor_config: ClientConfig,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_string_body(req)

  case parse_meal_plan_request(body) {
    Error(msg) -> responses.bad_request(msg)
    Ok(request) -> {
      // For now, just return a message that sync is ready
      // Full implementation would need FatSecret OAuth token from request or database
      let response_data =
        json.object([
          #("status", json.string("ready_for_sync")),
          #("meals_to_sync", json.int(list.length(request.selections))),
          #(
            "message",
            json.string(
              "Meals ready to sync to FatSecret. FatSecret OAuth token needed.",
            ),
          ),
        ])

      responses.json_ok(response_data)
    }
  }
}

/// Get list of available MVP recipes
/// GET /api/meal-planning/recipes
///
/// Response:
/// ```json
/// {
///   "recipes": [
///     {
///       "name": "Lean Beef with Peppers",
///       "protein_g": 45.0,
///       "fat_g": 12.0,
///       "carbs_g": 8.0
///     },
///     ...
///   ]
/// }
/// ```
pub fn handle_get_recipes(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let recipes = mvp_recipes.all_recipes()

  let recipe_json =
    recipes
    |> list.map(fn(recipe) {
      json.object([
        #("name", json.string(recipe.name)),
        #("protein_g", json.float(recipe.macros.protein)),
        #("fat_g", json.float(recipe.macros.fat)),
        #("carbs_g", json.float(recipe.macros.carbs)),
      ])
    })

  let response_data =
    json.object([
      #("count", json.int(list.length(recipes))),
      #("recipes", json.array(recipe_json, fn(x) { x })),
    ])

  responses.json_ok(response_data)
}

// ============================================================================
// JSON Parsing
// ============================================================================

fn parse_meal_plan_request(body: String) -> Result(MealPlanRequest, String) {
  let decoder = meal_plan_request_decoder()
  case json.parse(body, decoder) {
    Ok(request) -> Ok(request)
    Error(_) -> Error("Invalid request: expected JSON with selections array")
  }
}

fn meal_plan_request_decoder() -> decode.Decoder(MealPlanRequest) {
  use selections <- decode.field(
    "selections",
    decode.list(meal_selection_decoder()),
  )
  decode.success(MealPlanRequest(selections: selections))
}

fn meal_selection_decoder() -> decode.Decoder(MealSelection) {
  use date <- decode.field("date", decode.string)
  use meal_type <- decode.field("meal_type", decode.string)
  use recipe_id <- decode.field("recipe_id", decode.int)
  use servings <- decode.field("servings", decode.float)
  decode.success(MealSelection(
    date: date,
    meal_type: meal_type,
    recipe_id: recipe_id,
    servings: servings,
  ))
}
