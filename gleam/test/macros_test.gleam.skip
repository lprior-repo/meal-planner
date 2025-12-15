import gleam/json
import gleeunit
import gleeunit/should
import meal_planner/web/handlers/macros
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn calculate_macros_with_float_servings_test() {
  let request_body =
    json.object([
      #(
        "recipes",
        json.array([
          json.object([
            #("recipe_id", json.string("test-1")),
            #("servings", json.float(2.0)),
            #(
              "macros",
              json.object([
                #("protein", json.float(30.0)),
                #("fat", json.float(10.0)),
                #("carbs", json.float(40.0)),
              ]),
            ),
          ]),
        ]),
      ),
    ])
    |> json.to_string

  let request = testing.post("/api/macros/calculate", [], request_body)
  let response = macros.handle_calculate(request)

  response.status
  |> should.equal(200)
}

pub fn calculate_macros_with_int_servings_test() {
  // This is the FIX - previously this would fail because int servings weren't supported
  let request_body =
    json.object([
      #(
        "recipes",
        json.array([
          json.object([
            #("recipe_id", json.string("test-1")),
            #("servings", json.int(2)),
            // Integer instead of float!
            #(
              "macros",
              json.object([
                #("protein", json.int(30)),
                // Integer values
                #("fat", json.int(10)),
                #("carbs", json.int(40)),
              ]),
            ),
          ]),
        ]),
      ),
    ])
    |> json.to_string

  let request = testing.post("/api/macros/calculate", [], request_body)
  let response = macros.handle_calculate(request)

  response.status
  |> should.equal(200)
}

pub fn calculate_macros_multiple_recipes_test() {
  let request_body =
    json.object([
      #(
        "recipes",
        json.array([
          json.object([
            #("recipe_id", json.string("test-1")),
            #("servings", json.int(2)),
            #(
              "macros",
              json.object([
                #("protein", json.int(30)),
                #("fat", json.int(10)),
                #("carbs", json.int(40)),
              ]),
            ),
          ]),
          json.object([
            #("recipe_id", json.string("test-2")),
            #("servings", json.float(1.5)),
            #(
              "macros",
              json.object([
                #("protein", json.float(20.0)),
                #("fat", json.float(5.0)),
                #("carbs", json.float(30.0)),
              ]),
            ),
          ]),
        ]),
      ),
    ])
    |> json.to_string

  let request = testing.post("/api/macros/calculate", [], request_body)
  let response = macros.handle_calculate(request)

  response.status
  |> should.equal(200)
}
