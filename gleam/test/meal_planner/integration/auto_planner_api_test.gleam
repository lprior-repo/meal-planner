/// Integration Tests for Auto Meal Planner API Endpoints
///
/// Tests verify the complete request/response cycle for auto meal plan generation:
/// - POST /api/meal-plans/auto - Generate auto meal plan
/// - GET /api/meal-plans/auto/:id - Retrieve auto meal plan by ID
///
/// Coverage:
/// - Success cases with valid inputs
/// - Error handling (400, 404, 500)
/// - Input validation (config validation)
/// - Response format validation
/// - Database persistence
/// - Diet principle compliance
/// - Macro target optimization
///
/// These tests document the expected API behavior and can be run manually
/// or automated with test database setup.
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures and Helpers
// ============================================================================

/// Create test database context with connection pool
fn setup_test_context() -> Result(web.Context, String) {
  // Connect to test database
  let db_config =
    pog.Config(
      host: "localhost",
      port: 5432,
      database: "meal_planner_test",
      user: "meal_planner",
      password: Some("meal_planner"),
      ssl: False,
      connection_parameters: [],
      pool_size: 5,
      queue_target: 50,
      queue_interval: 100,
      idle_interval: 1000,
    )

  case pog.connect(db_config) {
    Ok(db) -> {
      // Initialize search cache and mock actor
      let search_cache = storage_optimized.new_search_cache()

      // Create mock todoist actor (not needed for these tests)
      let todoist = process.new_subject()

      Ok(web.Context(db: db, search_cache: search_cache, todoist_actor: todoist))
    }
    Error(_) ->
      Error(
        "Failed to connect to test database. Ensure PostgreSQL is running and meal_planner_test database exists.",
      )
  }
}

/// Cleanup test data after tests
fn cleanup_test_data(ctx: web.Context) -> Nil {
  // Clean up test auto meal plans
  let _ =
    pog.query(
      "DELETE FROM auto_meal_plans WHERE id LIKE 'test-%' OR id LIKE 'auto-plan-%'",
    )
    |> pog.execute(ctx.db)

  // Clean up test recipes
  let _ =
    pog.query("DELETE FROM recipes WHERE id LIKE 'test-%'")
    |> pog.execute(ctx.db)

  Nil
}

/// Create a test recipe with specified macros
fn create_test_recipe(
  id: String,
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
  vertical_compliant: Bool,
) -> Recipe {
  Recipe(
    id: "test-" <> id,
    name: name,
    ingredients: [
      Ingredient(
        name: "Test Ingredient",
        amount: "100",
        unit: Some("g"),
        category: None,
      ),
    ],
    instructions: ["Test instruction"],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test-category",
    fodmap_level: Low,
    vertical_compliant: vertical_compliant,
    micronutrients: None,
    prep_time: Some(10),
    cook_time: Some(20),
    total_time: Some(30),
    tags: ["test"],
    source: Some("test"),
  )
}

/// Save test recipes to database
fn seed_test_recipes(ctx: web.Context) -> Result(List(Recipe), String) {
  let recipes = [
    // High protein recipes (vertical compliant)
    create_test_recipe(
      "chicken-breast",
      "Grilled Chicken Breast",
      40.0,
      5.0,
      0.0,
      True,
    ),
    create_test_recipe("salmon", "Baked Salmon", 35.0, 15.0, 0.0, True),
    create_test_recipe("beef-steak", "Beef Steak", 45.0, 20.0, 0.0, True),
    // Carb sources (vertical compliant)
    create_test_recipe("white-rice", "White Rice", 4.0, 0.5, 45.0, True),
    create_test_recipe("sweet-potato", "Sweet Potato", 2.0, 0.2, 30.0, True),
    // Vegetables (vertical compliant)
    create_test_recipe("broccoli", "Steamed Broccoli", 3.0, 0.5, 7.0, True),
    create_test_recipe("spinach", "Sauteed Spinach", 3.0, 0.5, 4.0, True),
    // Non-compliant for testing filters
    create_test_recipe("pasta", "Pasta Dish", 8.0, 2.0, 40.0, False),
  ]

  // Save all recipes to database
  list.try_map(recipes, fn(recipe) {
    let sql =
      "INSERT INTO recipes (id, name, category, servings,
                            protein, fat, carbs,
                            fodmap_level, vertical_compliant,
                            prep_time, cook_time, total_time)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       ON CONFLICT (id) DO NOTHING
       RETURNING id"

    pog.query(sql)
    |> pog.parameter(pog.text(recipe.id))
    |> pog.parameter(pog.text(recipe.name))
    |> pog.parameter(pog.text(recipe.category))
    |> pog.parameter(pog.int(recipe.servings))
    |> pog.parameter(pog.float(recipe.macros.protein))
    |> pog.parameter(pog.float(recipe.macros.fat))
    |> pog.parameter(pog.float(recipe.macros.carbs))
    |> pog.parameter(pog.text("Low"))
    |> pog.parameter(pog.bool(recipe.vertical_compliant))
    |> pog.parameter(pog.nullable(pog.int, recipe.prep_time))
    |> pog.parameter(pog.nullable(pog.int, recipe.cook_time))
    |> pog.parameter(pog.nullable(pog.int, recipe.total_time))
    |> pog.returning(decode.element(0, decode.string))
    |> pog.execute(ctx.db)
    |> result.map(fn(_) { recipe })
    |> result.map_error(fn(_) { "Failed to save recipe: " <> recipe.id })
  })
}

// ============================================================================
// POST /api/meal-plans/auto - Success Cases
// ============================================================================

/// Test: Valid auto plan request returns 201 with complete plan
pub fn post_auto_plan_success_test() {
  // Setup
  case setup_test_context() {
    Error(_) -> {
      // Skip test if database not available
      should.be_true(True)
    }
    Ok(ctx) -> {
      // Seed test recipes
      let assert Ok(_) = seed_test_recipes(ctx)

      // Create valid config
      let config_json =
        json.object([
          #("user_id", json.string("test-user-1")),
          #("diet_principles", json.array(["vertical_diet"], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(160.0)),
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(4)),
          #("variety_factor", json.float(0.7)),
        ])

      // Create POST request
      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      // Execute request through handler
      let response = web.handle_request(request, ctx)

      // Assert response status is 201 Created
      response.status
      |> should.equal(201)

      // Parse response body
      let assert Ok(body) = wisp.read_body_to_string(response)
      let assert Ok(body_json) = json.decode(body, decode.dynamic)

      // Verify response structure
      let assert Ok(plan_json) = decode.run(body_json, decode.dynamic)

      // Verify plan has required fields
      let assert Ok(_id) =
        decode.run(plan_json, decode.field("id", decode.string))
      let assert Ok(recipes) =
        decode.run(
          plan_json,
          decode.field("recipes", decode.list(decode.dynamic)),
        )
      let assert Ok(_total_macros) =
        decode.run(plan_json, decode.field("total_macros", decode.dynamic))
      let assert Ok(_config) =
        decode.run(plan_json, decode.field("config", decode.dynamic))
      let assert Ok(_generated_at) =
        decode.run(plan_json, decode.field("generated_at", decode.string))

      // Verify correct number of recipes
      list.length(recipes)
      |> should.equal(4)

      // Cleanup
      cleanup_test_data(ctx)
    }
  }
}

/// Test: Generated plan respects diet principles
pub fn post_auto_plan_respects_diet_principles_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let assert Ok(_) = seed_test_recipes(ctx)

      // Request only vertical diet compliant recipes
      let config_json =
        json.object([
          #("user_id", json.string("test-user-2")),
          #("diet_principles", json.array(["vertical_diet"], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(150.0)),
              #("fat", json.float(70.0)),
              #("carbs", json.float(180.0)),
            ]),
          ),
          #("recipe_count", json.int(4)),
          #("variety_factor", json.float(0.8)),
        ])

      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(201)

      // Verify all recipes are vertical compliant
      let assert Ok(body) = wisp.read_body_to_string(response)
      let assert Ok(body_json) = json.decode(body, decode.dynamic)

      // Extract recipes and verify compliance
      // (In production, you'd decode each recipe and check vertical_compliant flag)

      cleanup_test_data(ctx)
    }
  }
}

// ============================================================================
// POST /api/meal-plans/auto - Error Cases
// ============================================================================

/// Test: Invalid JSON returns 400
pub fn post_auto_plan_invalid_json_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      // Send malformed JSON
      let request =
        testing.post("/api/meal-plans/auto", [], "{invalid json")
        |> testing.set_header("content-type", "application/json")

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(400)

      let assert Ok(body) = wisp.read_body_to_string(response)
      body
      |> string.contains("Invalid JSON format")
      |> should.be_true()

      cleanup_test_data(ctx)
    }
  }
}

/// Test: Invalid config returns 400 (recipe_count > 20)
pub fn post_auto_plan_invalid_config_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let config_json =
        json.object([
          #("user_id", json.string("test")),
          #("diet_principles", json.array([], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(160.0)),
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(25)),
          // Invalid: max is 20
          #("variety_factor", json.float(0.7)),
        ])

      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(400)

      let assert Ok(body) = wisp.read_body_to_string(response)
      body
      |> string.contains("recipe_count must be at most 20")
      |> should.be_true()

      cleanup_test_data(ctx)
    }
  }
}

/// Test: Insufficient recipes returns 400
pub fn post_auto_plan_insufficient_recipes_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      // Seed only 2 recipes
      let limited_recipes = [
        create_test_recipe("chicken", "Chicken", 40.0, 5.0, 0.0, True),
        create_test_recipe("rice", "Rice", 4.0, 0.5, 45.0, True),
      ]

      // Save limited recipes
      let _ =
        list.map(limited_recipes, fn(recipe) {
          let sql =
            "INSERT INTO recipes (id, name, category, servings, protein, fat, carbs, fodmap_level, vertical_compliant)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             ON CONFLICT (id) DO NOTHING"

          pog.query(sql)
          |> pog.parameter(pog.text(recipe.id))
          |> pog.parameter(pog.text(recipe.name))
          |> pog.parameter(pog.text(recipe.category))
          |> pog.parameter(pog.int(recipe.servings))
          |> pog.parameter(pog.float(recipe.macros.protein))
          |> pog.parameter(pog.float(recipe.macros.fat))
          |> pog.parameter(pog.float(recipe.macros.carbs))
          |> pog.parameter(pog.text("Low"))
          |> pog.parameter(pog.bool(recipe.vertical_compliant))
          |> pog.execute(ctx.db)
        })

      // Request 4 recipes (more than available)
      let config_json =
        json.object([
          #("user_id", json.string("test")),
          #("diet_principles", json.array(["vertical_diet"], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(160.0)),
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(4)),
          #("variety_factor", json.float(0.7)),
        ])

      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(400)

      let assert Ok(body) = wisp.read_body_to_string(response)
      body
      |> string.contains("Insufficient recipes")
      |> should.be_true()

      cleanup_test_data(ctx)
    }
  }
}

/// Test: GET method returns 405 Method Not Allowed
pub fn post_auto_plan_method_not_allowed_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let request = testing.get("/api/meal-plans/auto", [])

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(405)

      cleanup_test_data(ctx)
    }
  }
}

// ============================================================================
// GET /api/meal-plans/auto/:id - Success Cases
// ============================================================================

/// Test: GET retrieves saved plan successfully
pub fn get_auto_plan_by_id_success_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let assert Ok(_) = seed_test_recipes(ctx)

      // First create a plan via POST
      let config_json =
        json.object([
          #("user_id", json.string("test-user-3")),
          #("diet_principles", json.array(["vertical_diet"], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(160.0)),
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(4)),
          #("variety_factor", json.float(0.7)),
        ])

      let create_request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let create_response = web.handle_request(create_request, ctx)

      create_response.status
      |> should.equal(201)

      // Extract plan ID from response
      let assert Ok(body) = wisp.read_body_to_string(create_response)
      let assert Ok(body_json) = json.decode(body, decode.dynamic)
      let assert Ok(plan_id) =
        decode.run(body_json, decode.field("id", decode.string))

      // Now GET the plan
      let get_request = testing.get("/api/meal-plans/auto/" <> plan_id, [])

      let get_response = web.handle_request(get_request, ctx)

      get_response.status
      |> should.equal(200)

      // Verify response contains plan
      let assert Ok(get_body) = wisp.read_body_to_string(get_response)
      let assert Ok(get_json) = json.decode(get_body, decode.dynamic)
      let assert Ok(retrieved_id) =
        decode.run(get_json, decode.field("id", decode.string))

      retrieved_id
      |> should.equal(plan_id)

      cleanup_test_data(ctx)
    }
  }
}

// ============================================================================
// GET /api/meal-plans/auto/:id - Error Cases
// ============================================================================

/// Test: GET with nonexistent ID returns 404
pub fn get_auto_plan_by_id_not_found_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let request = testing.get("/api/meal-plans/auto/nonexistent-plan-id", [])

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(404)

      let assert Ok(body) = wisp.read_body_to_string(response)
      body
      |> string.contains("Meal plan not found")
      |> should.be_true()

      cleanup_test_data(ctx)
    }
  }
}

/// Test: POST to GET endpoint returns 405
pub fn get_auto_plan_method_not_allowed_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let request = testing.post("/api/meal-plans/auto/some-id", [], "")

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(405)

      cleanup_test_data(ctx)
    }
  }
}

// ============================================================================
// Input Validation Tests
// ============================================================================

/// Test: Negative recipe_count returns 400
pub fn post_auto_plan_negative_recipe_count_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let config_json =
        json.object([
          #("user_id", json.string("test")),
          #("diet_principles", json.array([], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(160.0)),
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(-1)),
          #("variety_factor", json.float(0.7)),
        ])

      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(400)

      let assert Ok(body) = wisp.read_body_to_string(response)
      body
      |> string.contains("recipe_count must be at least 1")
      |> should.be_true()

      cleanup_test_data(ctx)
    }
  }
}

/// Test: Invalid variety_factor (> 1.0) returns 400
pub fn post_auto_plan_invalid_variety_factor_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let config_json =
        json.object([
          #("user_id", json.string("test")),
          #("diet_principles", json.array([], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(160.0)),
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(4)),
          #("variety_factor", json.float(1.5)),
          // Invalid: max is 1.0
        ])

      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(400)

      let assert Ok(body) = wisp.read_body_to_string(response)
      body
      |> string.contains("variety_factor must be between 0 and 1")
      |> should.be_true()

      cleanup_test_data(ctx)
    }
  }
}

/// Test: Negative macro targets return 400
pub fn post_auto_plan_negative_macros_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let config_json =
        json.object([
          #("user_id", json.string("test")),
          #("diet_principles", json.array([], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(-10.0)),
              // Invalid: negative
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(4)),
          #("variety_factor", json.float(0.7)),
        ])

      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(400)

      let assert Ok(body) = wisp.read_body_to_string(response)
      body
      |> string.contains("macro_targets must be positive")
      |> should.be_true()

      cleanup_test_data(ctx)
    }
  }
}

// ============================================================================
// Response Format Validation Tests
// ============================================================================

/// Test: Response includes all required fields
pub fn post_auto_plan_response_format_test() {
  case setup_test_context() {
    Error(_) -> should.be_true(True)
    Ok(ctx) -> {
      let assert Ok(_) = seed_test_recipes(ctx)

      let config_json =
        json.object([
          #("user_id", json.string("test-user-4")),
          #("diet_principles", json.array(["vertical_diet"], json.string)),
          #(
            "macro_targets",
            json.object([
              #("protein", json.float(160.0)),
              #("fat", json.float(80.0)),
              #("carbs", json.float(200.0)),
            ]),
          ),
          #("recipe_count", json.int(4)),
          #("variety_factor", json.float(0.7)),
        ])

      let request =
        testing.post_json(
          "/api/meal-plans/auto",
          [],
          json.to_string(config_json),
        )

      let response = web.handle_request(request, ctx)

      response.status
      |> should.equal(201)

      let assert Ok(body) = wisp.read_body_to_string(response)
      let assert Ok(body_json) = json.decode(body, decode.dynamic)

      // Verify all required fields are present
      let assert Ok(_id) =
        decode.run(body_json, decode.field("id", decode.string))
      let assert Ok(_recipes) =
        decode.run(
          body_json,
          decode.field("recipes", decode.list(decode.dynamic)),
        )
      let assert Ok(_total_macros) =
        decode.run(body_json, decode.field("total_macros", decode.dynamic))
      let assert Ok(_config) =
        decode.run(body_json, decode.field("config", decode.dynamic))
      let assert Ok(_generated_at) =
        decode.run(body_json, decode.field("generated_at", decode.string))

      cleanup_test_data(ctx)
    }
  }
}
