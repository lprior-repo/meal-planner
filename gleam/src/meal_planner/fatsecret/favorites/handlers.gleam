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
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import meal_planner/fatsecret/favorites/service
import meal_planner/fatsecret/favorites/types
import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/fatsecret/handlers_helpers as helpers
import pog
import wisp.{type Request, type Response}

/// POST /api/fatsecret/favorites/foods/:food_id - Add food to favorites
pub fn add_favorite_food(
  req: Request,
  conn: pog.Connection,
  food_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Post)

  case service.add_favorite_food(conn, food_id) {
    Ok(_) -> helpers.success_message("Food added to favorites")
    Error(e) -> error_response(e)
  }
}

/// DELETE /api/fatsecret/favorites/foods/:food_id - Remove food from favorites
pub fn delete_favorite_food(
  req: Request,
  conn: pog.Connection,
  food_id: String,
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Delete)

  case service.delete_favorite_food(conn, food_id) {
    Ok(_) -> helpers.success_message("Food removed from favorites")
    Error(e) -> error_response(e)
  }
}

/// GET /api/fatsecret/favorites/foods - Get favorite foods
pub fn get_favorite_foods(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  let query_params = wisp.get_query(req)
  let max_results = helpers.parse_int_param(query_params, "max_results")
  let page_number = helpers.parse_int_param(query_params, "page")

  case service.get_favorite_foods(conn, max_results, page_number) {
    Ok(response) -> {
      let foods_json =
        list.map(response.foods, fn(food) {
          helpers.encode_favorite_food(#(
            food.food_id,
            food.food_name,
            food.food_type,
            food.brand_name,
            food.food_description,
            food.food_url,
          ))
        })

      json.object([#("foods", json.array(foods_json, fn(x) { x }))])
      |> json.to_string
      |> wisp.json_response(200)
    }

    Error(e) -> error_response(e)
  }
}

/// GET /api/fatsecret/favorites/foods/most-eaten - Get most eaten foods
pub fn get_most_eaten(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  let query_params = wisp.get_query(req)
  let meal_filter = parse_meal_filter(query_params)

  case service.get_most_eaten(conn, meal_filter) {
    Ok(response) -> {
      let foods_json =
        list.map(response.foods, fn(food) {
          helpers.encode_favorite_food(#(
            food.food_id,
            food.food_name,
            food.food_type,
            food.brand_name,
            food.food_description,
            food.food_url,
          ))
        })

      json.object([#("foods", json.array(foods_json, fn(x) { x }))])
      |> json.to_string
      |> wisp.json_response(200)
    }

    Error(e) -> error_response(e)
  }
}

/// GET /api/fatsecret/favorites/foods/recently-eaten - Get recently eaten foods
pub fn get_recently_eaten(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  let query_params = wisp.get_query(req)
  let meal_filter = parse_meal_filter(query_params)

  case service.get_recently_eaten(conn, meal_filter) {
    Ok(response) -> {
      let foods_json =
        list.map(response.foods, fn(food) {
          helpers.encode_favorite_food(#(
            food.food_id,
            food.food_name,
            food.food_type,
            food.brand_name,
            food.food_description,
            food.food_url,
          ))
        })

      json.object([#("foods", json.array(foods_json, fn(x) { x }))])
      |> json.to_string
      |> wisp.json_response(200)
    }

    Error(e) -> error_response(e)
  }
}

/// POST /api/fatsecret/favorites/recipes/:recipe_id - Add recipe to favorites
pub fn add_favorite_recipe(
  req: Request,
  conn: pog.Connection,
  recipe_id: String,
) -> Response {
  case req.method {
    Post -> {
      case service.add_favorite_recipe(conn, recipe_id) {
        Ok(_) -> helpers.success_message("Recipe added to favorites")
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
) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Delete)

  case service.delete_favorite_recipe(conn, recipe_id) {
    Ok(_) -> helpers.success_message("Recipe removed from favorites")
    Error(e) -> error_response(e)
  }
}

/// GET /api/fatsecret/favorites/recipes - Get favorite recipes
pub fn get_favorite_recipes(req: Request, conn: pog.Connection) -> Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, Get)

  let query_params = wisp.get_query(req)
  let max_results = helpers.parse_int_param(query_params, "max_results")
  let page_number = helpers.parse_int_param(query_params, "page")

  case service.get_favorite_recipes(conn, max_results, page_number) {
    Ok(response) -> {
      let recipes_json =
        list.map(response.recipes, fn(recipe) {
          helpers.encode_favorite_recipe(#(
            recipe.recipe_id,
            recipe.recipe_name,
            recipe.recipe_description,
            recipe.recipe_url,
            recipe.recipe_image,
          ))
        })

      json.object([#("recipes", json.array(recipes_json, fn(x) { x }))])
      |> json.to_string
      |> wisp.json_response(200)
    }

    Error(e) -> error_response(e)
  }
}

// =============================================================================
// Helpers
// =============================================================================

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
fn error_response(error: fatsecret_service.ServiceError) -> Response {
  helpers.service_error_response(error)
}
