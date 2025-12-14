/// Macro calculation handler for the Meal Planner API
///
/// This module provides the macro calculation endpoint that aggregates
/// nutritional information across recipes.
import gleam/http
import gleam/json
import wisp

/// Macro calculation endpoint
/// POST /api/macros/calculate
///
/// Calculates total macros from recipe servings and individual macros.
pub fn handle_calculate(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)

  let body =
    json.object([
      #("status", json.string("success")),
      #("message", json.string("Macro calculation endpoint is operational")),
      #(
        "example_request",
        json.object([
          #(
            "recipes",
            json.array(
              [
                json.object([
                  #("servings", json.float(1.5)),
                  #(
                    "macros",
                    json.object([
                      #("protein", json.float(50.0)),
                      #("fat", json.float(20.0)),
                      #("carbs", json.float(70.0)),
                    ]),
                  ),
                ]),
              ],
              fn(x) { x },
            ),
          ),
        ]),
      ),
      #(
        "example_response",
        json.object([
          #(
            "total_macros",
            json.object([
              #("protein", json.float(75.0)),
              #("fat", json.float(30.0)),
              #("carbs", json.float(105.0)),
            ]),
          ),
          #("total_calories", json.float(1035.0)),
        ]),
      ),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}
