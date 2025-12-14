/// HTTP handlers for FatSecret Favorites endpoints
///
/// Routes:
///   POST/DELETE /api/fatsecret/favorites/foods/:food_id
///   GET /api/fatsecret/favorites/foods
///   GET /api/fatsecret/favorites/foods/most-eaten
///   GET /api/fatsecret/favorites/foods/recently-eaten
///   POST/DELETE /api/fatsecret/favorites/recipes/:recipe_id
///   GET /api/fatsecret/favorites/recipes
import gleam/http.{Delete, Get, Post}
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/favorites/service
import meal_planner/fatsecret/favorites/types
import meal_planner/fatsecret/service as fatsecret_service
import pog
import wisp.{type Request}

/// POST /api/fatsecret/favorites/foods/:food_id - Add food to favorites
pub fn add_favorite_food(
  req: Request,
  conn: pog.Connection,
  food_id: String,
) -> Response(String) {
  case req.method {
    Post -> {
      case service.add_favorite_food(conn, food_id) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Food added to favorites")),
              ]),
            ),
            200,
          )
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

/// DELETE /api/fatsecret/favorites/foods/:food_id - Remove food from favorites
pub fn delete_favorite_food(
  req: Request,
  conn: pog.Connection,
  food_id: String,
) -> Response(String) {
  case req.method {
    Delete -> {
      case service.delete_favorite_food(conn, food_id) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Food removed from favorites")),
              ]),
            ),
            200,
          )
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Delete])
  }
}

/// GET /api/fatsecret/favorites/foods - Get favorite foods
pub fn get_favorite_foods(
  req: Request,
  conn: pog.Connection,
) -> Response(String) {
  case req.method {
    Get -> {
      let query_params = wisp.get_query(req)
      let max_results = parse_int_param(query_params, "max_results")
      let page_number = parse_int_param(query_params, "page")

      case service.get_favorite_foods(conn, max_results, page_number) {
        Ok(response) -> {
          let foods_json =
            list.map(response.foods, fn(food) {
              json.object([
                #("food_id", json.string(food.food_id)),
                #("food_name", json.string(food.food_name)),
                #("food_type", json.string(food.food_type)),
                #("brand_name", case food.brand_name {
                  Some(b) -> json.string(b)
                  None -> json.null()
                }),
                #("food_description", json.string(food.food_description)),
                #("food_url", json.string(food.food_url)),
              ])
            })

          wisp.json_response(
            json.to_string(
              json.object([
                #("foods", json.array(foods_json)),
                #("max_results", json.int(response.max_results)),
                #("total_results", json.int(response.total_results)),
                #("page_number", json.int(response.page_number)),
              ]),
            ),
            200,
          )
        }
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

/// GET /api/fatsecret/favorites/foods/most-eaten - Get most eaten foods
pub fn get_most_eaten(req: Request, conn: pog.Connection) -> Response(String) {
  case req.method {
    Get -> {
      let query_params = wisp.get_query(req)
      let meal_filter = parse_meal_filter(query_params)

      case service.get_most_eaten(conn, meal_filter) {
        Ok(response) -> {
          let foods_json =
            list.map(response.foods, fn(food) {
              json.object([
                #("food_id", json.string(food.food_id)),
                #("food_name", json.string(food.food_name)),
                #("food_type", json.string(food.food_type)),
                #("brand_name", case food.brand_name {
                  Some(b) -> json.string(b)
                  None -> json.null()
                }),
                #("food_description", json.string(food.food_description)),
                #("food_url", json.string(food.food_url)),
                #("eat_count", json.int(food.eat_count)),
              ])
            })

          wisp.json_response(
            json.to_string(
              json.object([
                #("foods", json.array(foods_json)),
                #("meal", case response.meal {
                  Some(m) -> json.string(m)
                  None -> json.null()
                }),
              ]),
            ),
            200,
          )
        }
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

/// GET /api/fatsecret/favorites/foods/recently-eaten - Get recently eaten foods
pub fn get_recently_eaten(
  req: Request,
  conn: pog.Connection,
) -> Response(String) {
  case req.method {
    Get -> {
      let query_params = wisp.get_query(req)
      let meal_filter = parse_meal_filter(query_params)

      case service.get_recently_eaten(conn, meal_filter) {
        Ok(response) -> {
          let foods_json =
            list.map(response.foods, fn(food) {
              json.object([
                #("food_id", json.string(food.food_id)),
                #("food_name", json.string(food.food_name)),
                #("food_type", json.string(food.food_type)),
                #("brand_name", case food.brand_name {
                  Some(b) -> json.string(b)
                  None -> json.null()
                }),
                #("food_description", json.string(food.food_description)),
                #("food_url", json.string(food.food_url)),
              ])
            })

          wisp.json_response(
            json.to_string(
              json.object([
                #("foods", json.array(foods_json)),
                #("meal", case response.meal {
                  Some(m) -> json.string(m)
                  None -> json.null()
                }),
              ]),
            ),
            200,
          )
        }
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

/// POST /api/fatsecret/favorites/recipes/:recipe_id - Add recipe to favorites
pub fn add_favorite_recipe(
  req: Request,
  conn: pog.Connection,
  recipe_id: String,
) -> Response(String) {
  case req.method {
    Post -> {
      case service.add_favorite_recipe(conn, recipe_id) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Recipe added to favorites")),
              ]),
            ),
            200,
          )
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Post])
  }
}

/// DELETE /api/fatsecret/favorites/recipes/:recipe_id - Remove recipe from favorites
pub fn delete_favorite_recipe(
  req: Request,
  conn: pog.Connection,
  recipe_id: String,
) -> Response(String) {
  case req.method {
    Delete -> {
      case service.delete_favorite_recipe(conn, recipe_id) {
        Ok(_) ->
          wisp.json_response(
            json.to_string(
              json.object([
                #("success", json.bool(True)),
                #("message", json.string("Recipe removed from favorites")),
              ]),
            ),
            200,
          )
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Delete])
  }
}

/// GET /api/fatsecret/favorites/recipes - Get favorite recipes
pub fn get_favorite_recipes(
  req: Request,
  conn: pog.Connection,
) -> Response(String) {
  case req.method {
    Get -> {
      let query_params = wisp.get_query(req)
      let max_results = parse_int_param(query_params, "max_results")
      let page_number = parse_int_param(query_params, "page")

      case service.get_favorite_recipes(conn, max_results, page_number) {
        Ok(response) -> {
          let recipes_json =
            list.map(response.recipes, fn(recipe) {
              json.object([
                #("recipe_id", json.string(recipe.recipe_id)),
                #("recipe_name", json.string(recipe.recipe_name)),
                #("recipe_description", json.string(recipe.recipe_description)),
                #("recipe_url", json.string(recipe.recipe_url)),
                #("recipe_image", case recipe.recipe_image {
                  Some(img) -> json.string(img)
                  None -> json.null()
                }),
              ])
            })

          wisp.json_response(
            json.to_string(
              json.object([
                #("recipes", json.array(recipes_json)),
                #("max_results", json.int(response.max_results)),
                #("total_results", json.int(response.total_results)),
                #("page_number", json.int(response.page_number)),
              ]),
            ),
            200,
          )
        }
        Error(e) -> error_response(e)
      }
    }
    _ -> wisp.method_not_allowed([Get])
  }
}

// =============================================================================
// Helpers
// =============================================================================

/// Parse optional integer query parameter
fn parse_int_param(
  params: List(#(String, String)),
  key: String,
) -> option.Option(Int) {
  params
  |> list.key_find(key)
  |> result.then(int.parse)
  |> option.from_result
}

/// Parse meal filter from query params
fn parse_meal_filter(
  params: List(#(String, String)),
) -> option.Option(types.MealFilter) {
  case list.key_find(params, "meal") {
    Ok("all") -> Some(types.AllMeals)
    Ok("breakfast") -> Some(types.Breakfast)
    Ok("lunch") -> Some(types.Lunch)
    Ok("dinner") -> Some(types.Dinner)
    Ok("snack") | Ok("other") -> Some(types.Snack)
    _ -> None
  }
}

/// Convert service error to HTTP error response
fn error_response(error: fatsecret_service.ServiceError) -> Response(String) {
  case error {
    fatsecret_service.NotConnected ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("not_connected")),
            #(
              "message",
              json.string(
                "FatSecret account not connected. Please connect first.",
              ),
            ),
          ]),
        ),
        401,
      )

    fatsecret_service.NotConfigured ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("not_configured")),
            #(
              "message",
              json.string("FatSecret API credentials not configured."),
            ),
          ]),
        ),
        500,
      )

    fatsecret_service.AuthRevoked ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("auth_revoked")),
            #(
              "message",
              json.string(
                "FatSecret authorization revoked. Please reconnect your account.",
              ),
            ),
          ]),
        ),
        401,
      )

    fatsecret_service.EncryptionError(msg) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("encryption_error")),
            #("message", json.string(msg)),
          ]),
        ),
        500,
      )

    fatsecret_service.ApiError(_) | fatsecret_service.StorageError(_) ->
      wisp.json_response(
        json.to_string(
          json.object([
            #("error", json.string("api_error")),
            #("message", json.string(fatsecret_service.error_to_string(error))),
          ]),
        ),
        500,
      )
  }
}
