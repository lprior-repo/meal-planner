//// API handler for custom foods endpoints
////
//// Provides endpoints for:
//// - POST /api/custom-foods - Create a custom food
//// - GET /api/custom-foods - List user's custom foods
//// - GET /api/custom-foods/:id - Get a specific custom food
//// - PUT /api/custom-foods/:id - Update a custom food
//// - DELETE /api/custom-foods/:id - Delete a custom food
//// - GET /api/custom-foods/search?q=query - Search custom foods

import gleam/dynamic/decode
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/uri
import meal_planner/storage
import meal_planner/storage/profile.{NotFound}
import meal_planner/types
import pog
import wisp

// ============================================================================
// Handler Context
// ============================================================================

/// Context for custom foods handlers
pub type Context {
  Context(db: pog.Connection)
}

// ============================================================================
// Main API Handlers
// ============================================================================

/// Route custom foods API requests
pub fn api_custom_foods(
  req: wisp.Request,
  path: List(String),
  ctx: Context,
) -> wisp.Response {
  case path {
    // POST /api/custom-foods - Create custom food
    [] if req.method == http.Post -> create_custom_food(req, ctx)
    // GET /api/custom-foods - List custom foods
    [] if req.method == http.Get -> list_custom_foods(req, ctx)
    // GET /api/custom-foods/:id - Get specific custom food
    [id] if req.method == http.Get -> get_custom_food(req, id, ctx)
    // PUT /api/custom-foods/:id - Update custom food
    [id] if req.method == http.Put -> update_custom_food(req, id, ctx)
    // DELETE /api/custom-foods/:id - Delete custom food
    [id] if req.method == http.Delete -> delete_custom_food(req, id, ctx)
    // GET /api/custom-foods/search?q=query - Search custom foods
    ["search"] if req.method == http.Get -> search_custom_foods(req, ctx)
    _ -> wisp.method_not_allowed([http.Get, http.Post, http.Put, http.Delete])
  }
}

// ============================================================================
// Create Custom Food
// ============================================================================

/// POST /api/custom-foods
/// Creates a new custom food entry
/// Expected request body:
/// {
///   "name": "string",
///   "brand": "string | null",
///   "description": "string | null",
///   "serving_size": float,
///   "serving_unit": "string",
///   "protein": float,
///   "fat": float,
///   "carbs": float,
///   "calories": float,
///   "micronutrients": { ... } | null
/// }
fn create_custom_food(req: wisp.Request, ctx: Context) -> wisp.Response {
  use json_data <- wisp.require_json(req)

  let result = {
    use name <- decode.field("name", decode.string)
    use brand <- decode.field("brand", decode.optional(decode.string))
    use description <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use serving_size <- decode.field("serving_size", decode.float)
    use serving_unit <- decode.field("serving_unit", decode.string)
    use protein <- decode.field("protein", decode.float)
    use fat <- decode.field("fat", decode.float)
    use carbs <- decode.field("carbs", decode.float)
    use calories <- decode.field("calories", decode.float)
    use micronutrients <- decode.field(
      "micronutrients",
      decode.optional(micronutrients_decoder()),
    )

    // Generate ID and get user_id (would be from auth context in real impl)
    let id = create_id()
    let user_id = "user_default"

    decode.success(types.CustomFood(
      id: id,
      user_id: user_id,
      name: name,
      brand: brand,
      description: description,
      serving_size: serving_size,
      serving_unit: serving_unit,
      macros: types.Macros(protein: protein, fat: fat, carbs: carbs),
      calories: calories,
      micronutrients: micronutrients,
    ))
  }

  case decode.run(json_data, result) {
    Ok(custom_food) -> {
      let user_id = "user_default"
      case storage.create_custom_food(ctx.db, user_id, custom_food) {
        Ok(created) -> {
          wisp.json_response(
            json.to_string(types.custom_food_to_json(created)),
            201,
          )
        }
        Error(_err) -> {
          wisp.response(500)
          |> wisp.string_body("Failed to create custom food")
        }
      }
    }
    Error(_decode_err) -> {
      wisp.response(400)
      |> wisp.string_body("Invalid request body")
    }
  }
}

// ============================================================================
// List Custom Foods
// ============================================================================

/// GET /api/custom-foods
/// Lists all custom foods for the current user
fn list_custom_foods(_req: wisp.Request, ctx: Context) -> wisp.Response {
  let user_id = "user_default"

  case storage.get_custom_foods_for_user(ctx.db, user_id) {
    Ok(foods) -> {
      let json_data = json.array(foods, types.custom_food_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(_err) -> {
      wisp.response(500)
      |> wisp.string_body("Failed to list custom foods")
    }
  }
}

// ============================================================================
// Get Single Custom Food
// ============================================================================

/// GET /api/custom-foods/:id
/// Gets a specific custom food by ID
fn get_custom_food(
  _req: wisp.Request,
  food_id: String,
  ctx: Context,
) -> wisp.Response {
  let user_id = "user_default"

  case storage.get_custom_food_by_id(ctx.db, user_id, food_id) {
    Ok(food) -> {
      wisp.json_response(json.to_string(types.custom_food_to_json(food)), 200)
    }
    Error(NotFound) -> {
      wisp.response(404)
      |> wisp.string_body("Custom food not found")
    }
    Error(_err) -> {
      wisp.response(500)
      |> wisp.string_body("Failed to retrieve custom food")
    }
  }
}

// ============================================================================
// Update Custom Food
// ============================================================================

/// PUT /api/custom-foods/:id
/// Updates an existing custom food
fn update_custom_food(
  req: wisp.Request,
  food_id: String,
  ctx: Context,
) -> wisp.Response {
  use json_data <- wisp.require_json(req)

  // First get the existing custom food to verify ownership
  let user_id = "user_default"

  case storage.get_custom_food_by_id(ctx.db, user_id, food_id) {
    Ok(existing_food) -> {
      // Explicitly type existing_food for closure capture
      let existing_food: types.CustomFood = existing_food

      // Decode the update payload
      let result = {
        use name <- decode.field("name", decode.optional(decode.string))
        use brand <- decode.field("brand", decode.optional(decode.string))
        use description <- decode.field(
          "description",
          decode.optional(decode.string),
        )
        use serving_size <- decode.field(
          "serving_size",
          decode.optional(decode.float),
        )
        use serving_unit <- decode.field(
          "serving_unit",
          decode.optional(decode.string),
        )
        use protein <- decode.field("protein", decode.optional(decode.float))
        use fat <- decode.field("fat", decode.optional(decode.float))
        use carbs <- decode.field("carbs", decode.optional(decode.float))
        use calories <- decode.field("calories", decode.optional(decode.float))
        use micronutrients <- decode.field(
          "micronutrients",
          decode.optional(micronutrients_decoder()),
        )

        // Merge with existing values
        let updated_food =
          types.CustomFood(
            id: existing_food.id,
            user_id: existing_food.user_id,
            name: name |> option.unwrap(existing_food.name),
            brand: brand |> option.or(existing_food.brand),
            description: description
              |> option.or(existing_food.description),
            serving_size: serving_size
              |> option.unwrap(existing_food.serving_size),
            serving_unit: serving_unit
              |> option.unwrap(existing_food.serving_unit),
            macros: types.Macros(
              protein: protein |> option.unwrap(existing_food.macros.protein),
              fat: fat |> option.unwrap(existing_food.macros.fat),
              carbs: carbs |> option.unwrap(existing_food.macros.carbs),
            ),
            calories: calories |> option.unwrap(existing_food.calories),
            micronutrients: micronutrients
              |> option.or(existing_food.micronutrients),
          )

        decode.success(updated_food)
      }

      case decode.run(json_data, result) {
        Ok(updated_food) -> {
          case storage.update_custom_food(ctx.db, user_id, updated_food) {
            Ok(saved) -> {
              wisp.json_response(
                json.to_string(types.custom_food_to_json(saved)),
                200,
              )
            }
            Error(_err) -> {
              wisp.response(500)
              |> wisp.string_body("Failed to update custom food")
            }
          }
        }
        Error(_decode_err) -> {
          wisp.response(400)
          |> wisp.string_body("Invalid request body")
        }
      }
    }
    Error(NotFound) -> {
      wisp.response(404)
      |> wisp.string_body("Custom food not found")
    }
    Error(_err) -> {
      wisp.response(500)
      |> wisp.string_body("Failed to retrieve custom food")
    }
  }
}

// ============================================================================
// Delete Custom Food
// ============================================================================

/// DELETE /api/custom-foods/:id
/// Deletes a custom food
fn delete_custom_food(
  _req: wisp.Request,
  food_id: String,
  ctx: Context,
) -> wisp.Response {
  let user_id = "user_default"

  case storage.delete_custom_food(ctx.db, user_id, food_id) {
    Ok(_) -> {
      wisp.response(204)
    }
    Error(NotFound) -> {
      wisp.response(404)
      |> wisp.string_body("Custom food not found")
    }
    Error(_err) -> {
      wisp.response(500)
      |> wisp.string_body("Failed to delete custom food")
    }
  }
}

// ============================================================================
// Search Custom Foods
// ============================================================================

/// GET /api/custom-foods/search?q=query&limit=10
/// Searches custom foods by name, brand, or description
fn search_custom_foods(req: wisp.Request, ctx: Context) -> wisp.Response {
  let query = get_query_param(req, "q")
  let limit = get_query_param_int(req, "limit", 10)
  let user_id = "user_default"

  case query {
    "" -> {
      wisp.response(400)
      |> wisp.string_body("Search query required")
    }
    q -> {
      case storage.search_custom_foods(ctx.db, user_id, q, limit) {
        Ok(foods) -> {
          let json_data = json.array(foods, types.custom_food_to_json)
          wisp.json_response(json.to_string(json_data), 200)
        }
        Error(_err) -> {
          wisp.response(500)
          |> wisp.string_body("Failed to search custom foods")
        }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Generate a unique ID for custom food
fn create_id() -> String {
  // In production, this would use a proper UUID library
  // For now, use timestamp-based ID
  "cf_" <> int.to_string(erlang_now())
}

/// Get external time function
@external(erlang, "erlang", "system_time")
fn erlang_now() -> Int

/// Get query parameter as string
fn get_query_param(req: wisp.Request, name: String) -> String {
  case req.query {
    Some(query_string) -> {
      case uri.parse_query(query_string) {
        Ok(params) -> {
          case list.find(params, fn(p) { p.0 == name }) {
            Ok(#(_, value)) -> value
            Error(_) -> ""
          }
        }
        Error(_) -> ""
      }
    }
    None -> ""
  }
}

/// Get query parameter as integer
fn get_query_param_int(req: wisp.Request, name: String, default: Int) -> Int {
  get_query_param(req, name)
  |> int.parse
  |> result.unwrap(default)
}

/// Decode micronutrients from JSON
fn micronutrients_decoder() -> decode.Decoder(types.Micronutrients) {
  use fiber <- decode.field("fiber", decode.optional(decode.float))
  use sugar <- decode.field("sugar", decode.optional(decode.float))
  use sodium <- decode.field("sodium", decode.optional(decode.float))
  use cholesterol <- decode.field("cholesterol", decode.optional(decode.float))
  use vitamin_a <- decode.field("vitamin_a", decode.optional(decode.float))
  use vitamin_c <- decode.field("vitamin_c", decode.optional(decode.float))
  use vitamin_d <- decode.field("vitamin_d", decode.optional(decode.float))
  use vitamin_e <- decode.field("vitamin_e", decode.optional(decode.float))
  use vitamin_k <- decode.field("vitamin_k", decode.optional(decode.float))
  use vitamin_b6 <- decode.field("vitamin_b6", decode.optional(decode.float))
  use vitamin_b12 <- decode.field("vitamin_b12", decode.optional(decode.float))
  use folate <- decode.field("folate", decode.optional(decode.float))
  use thiamin <- decode.field("thiamin", decode.optional(decode.float))
  use riboflavin <- decode.field("riboflavin", decode.optional(decode.float))
  use niacin <- decode.field("niacin", decode.optional(decode.float))
  use calcium <- decode.field("calcium", decode.optional(decode.float))
  use iron <- decode.field("iron", decode.optional(decode.float))
  use magnesium <- decode.field("magnesium", decode.optional(decode.float))
  use phosphorus <- decode.field("phosphorus", decode.optional(decode.float))
  use potassium <- decode.field("potassium", decode.optional(decode.float))
  use zinc <- decode.field("zinc", decode.optional(decode.float))

  decode.success(types.Micronutrients(
    fiber: fiber,
    sugar: sugar,
    sodium: sodium,
    cholesterol: cholesterol,
    vitamin_a: vitamin_a,
    vitamin_c: vitamin_c,
    vitamin_d: vitamin_d,
    vitamin_e: vitamin_e,
    vitamin_k: vitamin_k,
    vitamin_b6: vitamin_b6,
    vitamin_b12: vitamin_b12,
    folate: folate,
    thiamin: thiamin,
    riboflavin: riboflavin,
    niacin: niacin,
    calcium: calcium,
    iron: iron,
    magnesium: magnesium,
    phosphorus: phosphorus,
    potassium: potassium,
    zinc: zinc,
  ))
}
