/// Nutrition Control Plane MVP Handler
import gleam/float
import gleam/http
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import meal_planner/mvp_recipes
import meal_planner/ncp
import meal_planner/types.{type Macros, Macros}
import meal_planner/web/responses
import wisp

pub fn handle(
  req: wisp.Request,
  segments: List(String),
) -> option.Option(wisp.Response) {
  case segments {
    ["api", "nutrition", "daily-status"] -> Some(daily_status_handler(req))
    ["api", "nutrition", "recommend-dinner"] ->
      Some(recommend_dinner_handler(req))
    _ -> None
  }
}

fn daily_status_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let recipes = mvp_recipes.all_recipes()
  let query = wisp.get_query(req)

  case parse_meals_from_query(query) {
    [] -> responses.bad_request("meals parameter required")
    meals -> {
      let consumed = calculate_consumed(meals, recipes)
      let goals = ncp.get_default_goals()
      let deviation = ncp.calculate_deviation(goals, consumed)
      let on_track = ncp.deviation_is_within_tolerance(deviation, 10.0)

      let body =
        json.object([
          #("consumed", nutrition_data_to_json(consumed)),
          #("goals", goals_to_json(goals)),
          #("deviation", deviation_to_json(deviation)),
          #("on_track", json.bool(on_track)),
        ])

      responses.json_ok(body)
    }
  }
}

fn recommend_dinner_handler(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let recipes = mvp_recipes.all_recipes()
  let query = wisp.get_query(req)

  case parse_meals_from_query(query) {
    [] -> responses.bad_request("meals parameter required")
    meals -> {
      let consumed = calculate_consumed(meals, recipes)
      let goals = ncp.get_default_goals()
      let deviation = ncp.calculate_deviation(goals, consumed)
      let suggestions = ncp.select_top_recipes(deviation, recipes, 3)

      let rec_json =
        json.array(suggestions, fn(s) {
          json.object([
            #("name", json.string(s.recipe_name)),
            #("reason", json.string(s.reason)),
            #("score", json.float(s.score)),
          ])
        })

      let body =
        json.object([
          #("consumed", nutrition_data_to_json(consumed)),
          #("goals", goals_to_json(goals)),
          #("deviation", deviation_to_json(deviation)),
          #("recommendations", rec_json),
        ])

      responses.json_ok(body)
    }
  }
}

// ============================================================================
// Helpers
// ============================================================================

fn parse_meals_from_query(
  query: List(#(String, String)),
) -> List(#(String, Float)) {
  case list.find(query, fn(q) { q.0 == "meals" }) {
    Ok(#(_, meals_str)) -> {
      string.split(meals_str, ";")
      |> list.filter_map(fn(pair) {
        case string.split(pair, ",") {
          [name, servings_str] -> {
            case float.parse(servings_str) {
              Ok(servings) -> Ok(#(name, servings))
              Error(_) -> Error(Nil)
            }
          }
          _ -> Error(Nil)
        }
      })
    }
    _ -> []
  }
}

fn calculate_consumed(
  meals: List(#(String, Float)),
  recipes: List(ncp.ScoredRecipe),
) -> ncp.NutritionData {
  let totals =
    list.fold(meals, Macros(0.0, 0.0, 0.0), fn(acc, meal) {
      let #(name, servings) = meal
      case list.find(recipes, fn(r) { r.name == name }) {
        Ok(recipe) -> {
          let m = recipe.macros
          Macros(
            acc.protein +. { m.protein *. servings },
            acc.fat +. { m.fat *. servings },
            acc.carbs +. { m.carbs *. servings },
          )
        }
        Error(_) -> acc
      }
    })

  ncp.NutritionData(
    protein: totals.protein,
    fat: totals.fat,
    carbs: totals.carbs,
    calories: calc_calories(totals),
  )
}

fn calc_calories(m: Macros) -> Float {
  { m.protein *. 4.0 } +. { m.fat *. 9.0 } +. { m.carbs *. 4.0 }
}

fn nutrition_data_to_json(n: ncp.NutritionData) -> json.Json {
  json.object([
    #("protein", json.float(n.protein)),
    #("fat", json.float(n.fat)),
    #("carbs", json.float(n.carbs)),
    #("calories", json.float(n.calories)),
  ])
}

fn goals_to_json(g: ncp.NutritionGoals) -> json.Json {
  json.object([
    #("protein", json.float(g.daily_protein)),
    #("fat", json.float(g.daily_fat)),
    #("carbs", json.float(g.daily_carbs)),
    #("calories", json.float(g.daily_calories)),
  ])
}

fn deviation_to_json(d: ncp.DeviationResult) -> json.Json {
  json.object([
    #("protein_pct", json.float(d.protein_pct)),
    #("fat_pct", json.float(d.fat_pct)),
    #("carbs_pct", json.float(d.carbs_pct)),
    #("calories_pct", json.float(d.calories_pct)),
  ])
}
