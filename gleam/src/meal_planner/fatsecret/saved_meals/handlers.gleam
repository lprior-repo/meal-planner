/// FatSecret Saved Meals HTTP Handlers
///
/// Routes:
/// - POST   /api/fatsecret/saved-meals          - Create saved meal
/// - GET    /api/fatsecret/saved-meals          - List saved meals (optional ?meal=breakfast)
/// - PUT    /api/fatsecret/saved-meals/:id      - Edit saved meal
/// - DELETE /api/fatsecret/saved-meals/:id      - Delete saved meal
/// - GET    /api/fatsecret/saved-meals/:id/items - Get meal items
/// - POST   /api/fatsecret/saved-meals/:id/items - Add meal item
/// - PUT    /api/fatsecret/saved-meals/:id/items/:item_id - Edit meal item
/// - DELETE /api/fatsecret/saved-meals/:id/items/:item_id - Delete meal item
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import meal_planner/fatsecret/saved_meals/service
import meal_planner/fatsecret/saved_meals/types
import pog
import wisp

// =============================================================================
// Saved Meal Handlers
// =============================================================================

/// POST /api/fatsecret/saved-meals
/// Create a new saved meal template
/// Body: {"name": "...", "description": "...", "meals": ["breakfast", "lunch"]}
pub fn handle_create_saved_meal(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_json(req)

  let decoder = {
    use name <- decode.field("name", decode.string)
    use description <- decode.optional_field(
      "description",
      None,
      decode.optional(decode.string),
    )
    use meal_strings <- decode.field("meals", decode.list(decode.string))
    let meals = list.filter_map(meal_strings, types.meal_type_from_string)
    decode.success(#(name, description, meals))
  }

  case decode.run(body, decoder) {
    Ok(#(name, description, meals)) -> {
      case service.create_saved_meal(conn, name, description, meals) {
        Ok(id) -> {
          let response =
            json.object([
              #("success", json.bool(True)),
              #("saved_meal_id", json.string(types.saved_meal_id_to_string(id))),
            ])
            |> json.to_string
          wisp.json_response(response, 201)
        }
        Error(e) -> error_response(500, service.error_to_string(e))
      }
    Error(_) -> error_response(400, "Invalid request body")
  }
}

/// GET /api/fatsecret/saved-meals?meal=breakfast
/// Get user's saved meals, optionally filtered by meal type
pub fn handle_get_saved_meals(
  req: wisp.Request,
  conn: pog.Connection,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)
  let meal_filter =
    list.find(query_params, fn(p) { p.0 == "meal" })
    |> result.map(fn(p) { p.1 })
    |> result.try(types.meal_type_from_string)
    |> option.from_result

  case service.get_saved_meals(conn, meal_filter) {
    Ok(response) -> {
      let meals_json =
        response.saved_meals
        |> list.map(saved_meal_to_json)
        |> json.array(fn(x) { x })

      let json_response =
        json.object([
          #("saved_meals", meals_json),
          #("meal_filter", case response.meal_filter {
            Some(f) -> json.string(f)
            None -> json.null()
          }),
        ])
        |> json.to_string

      wisp.json_response(json_response, 200)
    Error(service.NotConnected) ->
      error_response(
        401,
        "Not connected to FatSecret. Visit /fatsecret/connect to authorize.",
      )
    Error(service.AuthRevoked) ->
      error_response(
        401,
        "FatSecret authorization was revoked. Please reconnect.",
      )
    Error(e) -> error_response(500, service.error_to_string(e))
  }
}

/// PUT /api/fatsecret/saved-meals/:id
/// Edit a saved meal
/// Body: {"name": "...", "description": "...", "meals": ["breakfast"]}
pub fn handle_edit_saved_meal(
  req: wisp.Request,
  conn: pog.Connection,
  saved_meal_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Put)
  use body <- wisp.require_json(req)

  let decoder = {
    use name_opt <- decode.optional_field(
      "name",
      None,
      decode.optional(decode.string),
    )
    use desc_opt <- decode.optional_field(
      "description",
      None,
      decode.optional(decode.string),
    )
    use meals_opt <- decode.optional_field("meals", None, {
      use opt_strings <- decode.then(
        decode.optional(decode.list(decode.string)),
      )
      case opt_strings {
        Some(meal_strings) -> {
          let parsed =
            list.filter_map(meal_strings, types.meal_type_from_string)
          decode.success(Some(parsed))
        }
        None -> decode.success(None)
      }
    decode.success(#(name_opt, desc_opt, meals_opt))
  }

  case decode.run(body, decoder) {
    Ok(#(name_opt, desc_opt, meals_opt)) -> {
      let id = types.saved_meal_id_from_string(saved_meal_id)
      case service.edit_saved_meal(conn, id, name_opt, desc_opt, meals_opt) {
        Ok(Nil) -> {
          let response =
            json.object([#("success", json.bool(True))])
            |> json.to_string
          wisp.json_response(response, 200)
        }
        Error(e) -> error_response(500, service.error_to_string(e))
      }
    Error(_) -> error_response(400, "Invalid request body")
  }
}

/// DELETE /api/fatsecret/saved-meals/:id
/// Delete a saved meal
pub fn handle_delete_saved_meal(
  req: wisp.Request,
  conn: pog.Connection,
  saved_meal_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Delete)

  let id = types.saved_meal_id_from_string(saved_meal_id)
  case service.delete_saved_meal(conn, id) {
    Ok(Nil) -> {
      let response =
        json.object([#("success", json.bool(True))])
        |> json.to_string
      wisp.json_response(response, 200)
    Error(e) -> error_response(500, service.error_to_string(e))
  }
}

// =============================================================================
// Saved Meal Items Handlers
// =============================================================================

/// GET /api/fatsecret/saved-meals/:id/items
/// Get items in a saved meal
pub fn handle_get_saved_meal_items(
  req: wisp.Request,
  conn: pog.Connection,
  saved_meal_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let id = types.saved_meal_id_from_string(saved_meal_id)
  case service.get_saved_meal_items(conn, id) {
    Ok(response) -> {
      let items_json =
        response.items
        |> list.map(saved_meal_item_to_json)
        |> json.array(fn(x) { x })

      let json_response =
        json.object([
          #(
            "saved_meal_id",
            json.string(types.saved_meal_id_to_string(response.saved_meal_id)),
          ),
          #("items", items_json),
        ])
        |> json.to_string

      wisp.json_response(json_response, 200)
    Error(e) -> error_response(500, service.error_to_string(e))
  }
}

/// POST /api/fatsecret/saved-meals/:id/items
/// Add a food item to a saved meal
/// Body: {"food_id": "...", "serving_id": "...", "number_of_units": 1.5}
///    OR {"food_entry_name": "...", "serving_description": "...", "number_of_units": 1, "calories": 200, ...}
pub fn handle_add_saved_meal_item(
  req: wisp.Request,
  conn: pog.Connection,
  saved_meal_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_json(req)

  case parse_saved_meal_item_input(body) {
    Ok(item) -> {
      let id = types.saved_meal_id_from_string(saved_meal_id)
      case service.add_saved_meal_item(conn, id, item) {
        Ok(item_id) -> {
          let response =
            json.object([
              #("success", json.bool(True)),
              #(
                "saved_meal_item_id",
                json.string(types.saved_meal_item_id_to_string(item_id)),
              ),
            ])
            |> json.to_string
          wisp.json_response(response, 201)
        }
        Error(e) -> error_response(500, service.error_to_string(e))
      }
    Error(msg) -> error_response(400, msg)
  }
}

/// PUT /api/fatsecret/saved-meals/:id/items/:item_id
/// Edit a saved meal item
pub fn handle_edit_saved_meal_item(
  req: wisp.Request,
  conn: pog.Connection,
  _saved_meal_id: String,
  saved_meal_item_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Put)
  use body <- wisp.require_json(req)

  case parse_saved_meal_item_input(body) {
    Ok(item) -> {
      let item_id = types.saved_meal_item_id_from_string(saved_meal_item_id)
      case service.edit_saved_meal_item(conn, item_id, item) {
        Ok(Nil) -> {
          let response =
            json.object([#("success", json.bool(True))])
            |> json.to_string
          wisp.json_response(response, 200)
        }
        Error(e) -> error_response(500, service.error_to_string(e))
      }
    Error(msg) -> error_response(400, msg)
  }
}

/// DELETE /api/fatsecret/saved-meals/:id/items/:item_id
/// Delete a saved meal item
pub fn handle_delete_saved_meal_item(
  req: wisp.Request,
  conn: pog.Connection,
  _saved_meal_id: String,
  saved_meal_item_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Delete)

  let item_id = types.saved_meal_item_id_from_string(saved_meal_item_id)
  case service.delete_saved_meal_item(conn, item_id) {
    Ok(Nil) -> {
      let response =
        json.object([#("success", json.bool(True))])
        |> json.to_string
      wisp.json_response(response, 200)
    Error(e) -> error_response(500, service.error_to_string(e))
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

fn parse_saved_meal_item_input(
  body: dynamic.Dynamic,
) -> Result(types.SavedMealItemInput, String) {
  // Try ByFoodId first
  let by_food_id_decoder = {
    use food_id <- decode.field("food_id", decode.string)
    use serving_id <- decode.field("serving_id", decode.string)
    use number_of_units <- decode.field("number_of_units", decode.float)
    decode.success(types.ByFoodId(food_id:, serving_id:, number_of_units:))
  }

  case decode.run(body, by_food_id_decoder) {
    Ok(item) -> Ok(item)
    Error(_) -> {
      // Try ByNutrition
      let by_nutrition_decoder = {
        use food_entry_name <- decode.field("food_entry_name", decode.string)
        use serving_description <- decode.field(
          "serving_description",
          decode.string,
        )
        use number_of_units <- decode.field("number_of_units", decode.float)
        use calories <- decode.field("calories", decode.float)
        use carbohydrate <- decode.field("carbohydrate", decode.float)
        use protein <- decode.field("protein", decode.float)
        use fat <- decode.field("fat", decode.float)
        decode.success(types.ByNutrition(
          food_entry_name:,
          serving_description:,
          number_of_units:,
          calories:,
          carbohydrate:,
          protein:,
          fat:,
        ))
      }

      case decode.run(body, by_nutrition_decoder) {
        Ok(item) -> Ok(item)
        Error(_) ->
          Error(
            "Invalid item format. Provide either (food_id, serving_id, number_of_units) or (food_entry_name, serving_description, number_of_units, calories, carbohydrate, protein, fat)",
          )
      }
  }
}

fn saved_meal_to_json(meal: types.SavedMeal) -> json.Json {
  json.object([
    #(
      "saved_meal_id",
      json.string(types.saved_meal_id_to_string(meal.saved_meal_id)),
    ),
    #("saved_meal_name", json.string(meal.saved_meal_name)),
    #("saved_meal_description", case meal.saved_meal_description {
      Some(desc) -> json.string(desc)
      None -> json.null()
    #(
      "meals",
      json.array(meal.meals, fn(m) { json.string(types.meal_type_to_string(m)) }),
    ),
    #("calories", json.float(meal.calories)),
    #("carbohydrate", json.float(meal.carbohydrate)),
    #("protein", json.float(meal.protein)),
    #("fat", json.float(meal.fat)),
  ])
}

fn saved_meal_item_to_json(item: types.SavedMealItem) -> json.Json {
  json.object([
    #(
      "saved_meal_item_id",
      json.string(types.saved_meal_item_id_to_string(item.saved_meal_item_id)),
    ),
    #("food_id", json.string(item.food_id)),
    #("food_entry_name", json.string(item.food_entry_name)),
    #("serving_id", json.string(item.serving_id)),
    #("number_of_units", json.float(item.number_of_units)),
    #("calories", json.float(item.calories)),
    #("carbohydrate", json.float(item.carbohydrate)),
    #("protein", json.float(item.protein)),
    #("fat", json.float(item.fat)),
  ])
}

fn error_response(status: Int, message: String) -> wisp.Response {
  let body =
    json.object([#("error", json.string(message))])
    |> json.to_string

  wisp.json_response(body, status)
}
