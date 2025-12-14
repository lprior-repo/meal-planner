/// FatSecret Recipes HTTP handlers
/// Endpoints for browsing and searching recipes
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import meal_planner/fatsecret/recipes/service
import meal_planner/fatsecret/recipes/types
import wisp

/// GET /api/fatsecret/recipes/:id
/// Get recipe details by ID
pub fn handle_get_recipe(req: wisp.Request, recipe_id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case service.get_recipe(types.recipe_id(recipe_id)) {
    Ok(recipe) -> {
      let json_response = encode_recipe(recipe)
      wisp.json_response(json.to_string(json_response), 200)
    }
    Error(service.NotConfigured) ->
      error_response(500, "FatSecret API not configured")
    Error(service.ApiError(e)) ->
      error_response(
        500,
        "Failed to get recipe: " <> service.error_to_string(service.ApiError(e)),
      )
  }
}

/// GET /api/fatsecret/recipes/search?q=query&page=1&max_results=20
/// Search for recipes
pub fn handle_search_recipes(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)

  let query =
    list.find(query_params, fn(p) { p.0 == "q" })
    |> result.map(fn(p) { p.1 })
    |> result.unwrap("")

  case string.is_empty(query) {
    True -> error_response(400, "Missing 'q' query parameter")
    False -> {
      let page_number =
        list.find(query_params, fn(p) { p.0 == "page" })
        |> result.try(fn(p) { int.parse(p.1) })
        |> option.from_result

      let max_results =
        list.find(query_params, fn(p) { p.0 == "max_results" })
        |> result.try(fn(p) { int.parse(p.1) })
        |> option.from_result

      case service.search_recipes(query, page_number, max_results) {
        Ok(search_response) -> {
          let json_response = encode_search_response(search_response)
          wisp.json_response(json.to_string(json_response), 200)
        }
        Error(service.NotConfigured) ->
          error_response(500, "FatSecret API not configured")
        Error(service.ApiError(e)) ->
          error_response(
            500,
            "Failed to search recipes: "
              <> service.error_to_string(service.ApiError(e)),
          )
      }
    }
  }
}

/// GET /api/fatsecret/recipes/types
/// Get all recipe types/categories
pub fn handle_get_recipe_types(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  case service.get_recipe_types() {
    Ok(types_response) -> {
      let json_response = encode_recipe_types_response(types_response)
      wisp.json_response(json.to_string(json_response), 200)
    }
    Error(service.NotConfigured) ->
      error_response(500, "FatSecret API not configured")
    Error(service.ApiError(e)) ->
      error_response(
        500,
        "Failed to get recipe types: "
          <> service.error_to_string(service.ApiError(e)),
      )
  }
}

/// GET /api/fatsecret/recipes/search/type/:type_id?page=1&max_results=20
/// Search recipes by type/category
pub fn handle_search_recipes_by_type(
  req: wisp.Request,
  type_id: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)

  let page_number =
    list.find(query_params, fn(p) { p.0 == "page" })
    |> result.try(fn(p) { int.parse(p.1) })
    |> option.from_result

  let max_results =
    list.find(query_params, fn(p) { p.0 == "max_results" })
    |> result.try(fn(p) { int.parse(p.1) })
    |> option.from_result

  case service.search_recipes_by_type(type_id, page_number, max_results) {
    Ok(search_response) -> {
      let json_response = encode_search_response(search_response)
      wisp.json_response(json.to_string(json_response), 200)
    }
    Error(service.NotConfigured) ->
      error_response(500, "FatSecret API not configured")
    Error(service.ApiError(e)) ->
      error_response(
        500,
        "Failed to search recipes by type: "
          <> service.error_to_string(service.ApiError(e)),
      )
  }
}

// =============================================================================
// JSON Encoders
// =============================================================================

fn encode_recipe(recipe: types.Recipe) -> json.Json {
  json.object([
    #("recipe_id", json.string(types.recipe_id_to_string(recipe.recipe_id))),
    #("recipe_name", json.string(recipe.recipe_name)),
    #("recipe_url", json.string(recipe.recipe_url)),
    #("recipe_description", json.string(recipe.recipe_description)),
    #("recipe_image", encode_optional_string(recipe.recipe_image)),
    #("number_of_servings", json.float(recipe.number_of_servings)),
    #("preparation_time_min", encode_optional_int(recipe.preparation_time_min)),
    #("cooking_time_min", encode_optional_int(recipe.cooking_time_min)),
    #("rating", encode_optional_float(recipe.rating)),
    #("recipe_types", json.array(recipe.recipe_types, encode_recipe_type)),
    #("ingredients", json.array(recipe.ingredients, encode_ingredient)),
    #("directions", json.array(recipe.directions, encode_direction)),
    #("nutrition", encode_nutrition(recipe)),
  ])
}

fn encode_ingredient(ingredient: types.RecipeIngredient) -> json.Json {
  json.object([
    #("food_id", json.string(ingredient.food_id)),
    #("food_name", json.string(ingredient.food_name)),
    #("serving_id", encode_optional_string(ingredient.serving_id)),
    #("number_of_units", json.float(ingredient.number_of_units)),
    #(
      "measurement_description",
      json.string(ingredient.measurement_description),
    ),
    #("ingredient_description", json.string(ingredient.ingredient_description)),
    #("ingredient_url", encode_optional_string(ingredient.ingredient_url)),
  ])
}

fn encode_direction(direction: types.RecipeDirection) -> json.Json {
  json.object([
    #("direction_number", json.int(direction.direction_number)),
    #("direction_description", json.string(direction.direction_description)),
  ])
}

fn encode_recipe_type(recipe_type: types.RecipeType) -> json.Json {
  json.object([
    #("recipe_type_id", json.string(recipe_type.recipe_type_id)),
    #("recipe_type", json.string(recipe_type.recipe_type)),
  ])
}

fn encode_nutrition(recipe: types.Recipe) -> json.Json {
  json.object([
    #("calories", encode_optional_float(recipe.calories)),
    #("carbohydrate", encode_optional_float(recipe.carbohydrate)),
    #("protein", encode_optional_float(recipe.protein)),
    #("fat", encode_optional_float(recipe.fat)),
    #("saturated_fat", encode_optional_float(recipe.saturated_fat)),
    #("polyunsaturated_fat", encode_optional_float(recipe.polyunsaturated_fat)),
    #("monounsaturated_fat", encode_optional_float(recipe.monounsaturated_fat)),
    #("cholesterol", encode_optional_float(recipe.cholesterol)),
    #("sodium", encode_optional_float(recipe.sodium)),
    #("potassium", encode_optional_float(recipe.potassium)),
    #("fiber", encode_optional_float(recipe.fiber)),
    #("sugar", encode_optional_float(recipe.sugar)),
    #("vitamin_a", encode_optional_float(recipe.vitamin_a)),
    #("vitamin_c", encode_optional_float(recipe.vitamin_c)),
    #("calcium", encode_optional_float(recipe.calcium)),
    #("iron", encode_optional_float(recipe.iron)),
  ])
}

fn encode_search_result(result: types.RecipeSearchResult) -> json.Json {
  json.object([
    #("recipe_id", json.string(types.recipe_id_to_string(result.recipe_id))),
    #("recipe_name", json.string(result.recipe_name)),
    #("recipe_description", json.string(result.recipe_description)),
    #("recipe_url", json.string(result.recipe_url)),
    #("recipe_image", encode_optional_string(result.recipe_image)),
  ])
}

fn encode_search_response(response: types.RecipeSearchResponse) -> json.Json {
  json.object([
    #("recipes", json.array(response.recipes, encode_search_result)),
    #("max_results", json.int(response.max_results)),
    #("total_results", json.int(response.total_results)),
    #("page_number", json.int(response.page_number)),
  ])
}

fn encode_recipe_types_response(
  response: types.RecipeTypesResponse,
) -> json.Json {
  json.object([
    #("recipe_types", json.array(response.recipe_types, encode_recipe_type)),
  ])
}

fn encode_optional_string(opt: option.Option(String)) -> json.Json {
  case opt {
    option.Some(s) -> json.string(s)
    option.None -> json.null()
  }
}

fn encode_optional_int(opt: option.Option(Int)) -> json.Json {
  case opt {
    option.Some(i) -> json.int(i)
    option.None -> json.null()
  }
}

fn encode_optional_float(opt: option.Option(Float)) -> json.Json {
  case opt {
    option.Some(f) -> json.float(f)
    option.None -> json.null()
  }
}

fn error_response(status: Int, message: String) -> wisp.Response {
  let body =
    json.object([#("error", json.string(message))])
    |> json.to_string

  wisp.json_response(body, status)
}
