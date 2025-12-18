/// Ingredients handlers for Tandoor Recipe Manager
///
/// This module handles HTTP requests for ingredients endpoints:
/// - GET /api/tandoor/ingredients - List ingredients (read-only)
import gleam/http
import gleam/json
import gleam/option
import meal_planner/tandoor/api/ingredient/list as ingredient_list
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/handlers/helpers
import meal_planner/tandoor/types/recipe/ingredient.{type Ingredient}
import wisp

// =============================================================================
// Ingredients Collection Handler
// =============================================================================

/// Handle requests to the ingredients collection endpoint
///
/// Supports:
/// - GET: List all ingredients
pub fn handle_ingredients_collection(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> handle_list_ingredients(req)
    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn handle_list_ingredients(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case
        ingredient_list.list_ingredients(
          config,
          limit: option.None,
          page: option.None,
        )
      {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(ingredient) {
              encode_ingredient_detail(ingredient)
            })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}

// =============================================================================
// Ingredient JSON Encoding
// =============================================================================

fn encode_ingredient_detail(ingredient: Ingredient) -> json.Json {
  let food_json = case ingredient.food {
    option.Some(food) ->
      json.object([
        #("id", json.int(ids.food_id_to_int(food.id))),
        #("name", json.string(food.name)),
        #("plural_name", helpers.encode_optional_string(food.plural_name)),
        #("description", json.string(food.description)),
      ])
    option.None -> json.null()
  }

  let unit_json = case ingredient.unit {
    option.Some(unit) ->
      json.object([
        #("id", json.int(unit.id)),
        #("name", json.string(unit.name)),
        #("plural_name", helpers.encode_optional_string(unit.plural_name)),
      ])
    option.None -> json.null()
  }

  json.object([
    #("id", json.int(ingredient.id)),
    #("food", food_json),
    #("unit", unit_json),
    #("amount", json.float(ingredient.amount)),
    #("note", helpers.encode_optional_string(ingredient.note)),
    #("order", json.int(ingredient.order)),
    #("is_header", json.bool(ingredient.is_header)),
    #("no_amount", json.bool(ingredient.no_amount)),
    #("original_text", helpers.encode_optional_string(ingredient.original_text)),
  ])
}
