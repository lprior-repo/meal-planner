/// Integration tests for FatSecret Saved Meals routes
///
/// Tests verify that:
/// 1. Routes are correctly matched by the router
/// 2. Handler functions are properly called
/// 3. HTTP methods are validated
/// 4. Path parameters are correctly extracted
import gleam/http
import gleam/option.{None}
import gleeunit/should
import meal_planner/config
import meal_planner/web/router
import pog
import meal_planner/test_helpers/database
import wisp
import wisp/testing

pub fn saved_meals_list_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // GET /api/fatsecret/saved-meals should return 401 (not connected)
  let request =
    testing.get("/api/fatsecret/saved-meals", [])
    |> testing.set_method(http.Get)

  let response = router.handle_request(request, ctx)

  // Should get 401 (NotConnected) not 404
  response.status
  |> should.equal(401)
}

pub fn saved_meals_create_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // POST /api/fatsecret/saved-meals
  let body =
    "{\"name\":\"Test Meal\",\"description\":\"Test\",\"meals\":[\"breakfast\"]}"

  let request =
    testing.post("/api/fatsecret/saved-meals", [], body)
    |> testing.set_method(http.Post)
    |> testing.set_header("content-type", "application/json")

  let response = router.handle_request(request, ctx)

  // Should get 401 (NotConnected) or 400 (invalid JSON), not 404
  response.status
  |> should.not_equal(404)
}

pub fn saved_meals_edit_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // PUT /api/fatsecret/saved-meals/123
  let body = "{\"name\":\"Updated Meal\"}"

  let request =
    testing.put("/api/fatsecret/saved-meals/123", [], body)
    |> testing.set_method(http.Put)
    |> testing.set_header("content-type", "application/json")

  let response = router.handle_request(request, ctx)

  // Should get 401 or 400, not 404
  response.status
  |> should.not_equal(404)
}

pub fn saved_meals_delete_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // DELETE /api/fatsecret/saved-meals/123
  let request =
    testing.delete("/api/fatsecret/saved-meals/123", [])
    |> testing.set_method(http.Delete)

  let response = router.handle_request(request, ctx)

  // Should get 401, not 404
  response.status
  |> should.not_equal(404)
}

pub fn saved_meals_items_list_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // GET /api/fatsecret/saved-meals/123/items
  let request =
    testing.get("/api/fatsecret/saved-meals/123/items", [])
    |> testing.set_method(http.Get)

  let response = router.handle_request(request, ctx)

  // Should get 401, not 404
  response.status
  |> should.not_equal(404)
}

pub fn saved_meals_items_add_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // POST /api/fatsecret/saved-meals/123/items
  let body =
    "{\"food_id\":\"456\",\"serving_id\":\"789\",\"number_of_units\":1.0}"

  let request =
    testing.post("/api/fatsecret/saved-meals/123/items", [], body)
    |> testing.set_method(http.Post)
    |> testing.set_header("content-type", "application/json")

  let response = router.handle_request(request, ctx)

  // Should get 401 or 400, not 404
  response.status
  |> should.not_equal(404)
}

pub fn saved_meals_items_edit_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // PUT /api/fatsecret/saved-meals/123/items/456
  let body = "{\"number_of_units\":2.0}"

  let request =
    testing.put("/api/fatsecret/saved-meals/123/items/456", [], body)
    |> testing.set_method(http.Put)
    |> testing.set_header("content-type", "application/json")

  let response = router.handle_request(request, ctx)

  // Should get 401 or 400, not 404
  response.status
  |> should.not_equal(404)
}

pub fn saved_meals_items_delete_route_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // DELETE /api/fatsecret/saved-meals/123/items/456
  let request =
    testing.delete("/api/fatsecret/saved-meals/123/items/456", [])
    |> testing.set_method(http.Delete)

  let response = router.handle_request(request, ctx)

  // Should get 401, not 404
  response.status
  |> should.not_equal(404)
}

pub fn saved_meals_method_not_allowed_test() {
  use db <- database.with_test_transaction()
  let ctx = setup_context(db)

  // PATCH /api/fatsecret/saved-meals (method not allowed)
  let request =
    testing.patch("/api/fatsecret/saved-meals", [], "")
    |> testing.set_method(http.Patch)

  let response = router.handle_request(request, ctx)

  // Should get 405 (Method Not Allowed), not 404
  response.status
  |> should.equal(405)
}

// Helper function to create test context
fn setup_context(db: pog.Connection) -> router.Context {
  let cfg =
    config.Config(
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        database: "meal_planner_test",
        user: "postgres",
        password: None,
      ),
      server: config.ServerConfig(port: 8080, environment: "test"),
      tandoor: None,
    )

  router.Context(config: cfg, db: db)
}
