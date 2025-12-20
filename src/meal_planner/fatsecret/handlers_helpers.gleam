/// Common helpers for FatSecret HTTP handlers
///
/// Consolidates duplicate code across multiple handlers:
/// - JSON encoding for optional values
/// - Query parameter parsing
/// - Success/error response builders
/// - Food and recipe JSON encoders
///
/// Re-exports common functions from shared/response_encoders to reduce duplication.
import gleam/float
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/foods/types as food_types
import meal_planner/fatsecret/recipes/types as recipe_types
import meal_planner/fatsecret/service as fatsecret_service
import wisp

// =============================================================================
// Optional Value JSON Encoders
// =============================================================================

/// Encode an optional String to JSON (null if None)
pub fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

/// Encode an optional Int to JSON (null if None)
pub fn encode_optional_int(opt: Option(Int)) -> json.Json {
  case opt {
    Some(i) -> json.int(i)
    None -> json.null()
  }
}

/// Encode an optional Float to JSON (null if None)
pub fn encode_optional_float(opt: Option(Float)) -> json.Json {
  case opt {
    Some(f) -> json.float(f)
    None -> json.null()
  }
}

// =============================================================================
// Query Parameter Parsing
// =============================================================================

/// Get query parameter value by key, returning Option(String)
pub fn get_query_param(
  params: List(#(String, String)),
  key: String,
) -> Option(String) {
  list.find(params, fn(param) { param.0 == key })
  |> result.map(fn(param) { param.1 })
  |> option.from_result
}

/// Parse optional integer query parameter
pub fn parse_int_param(
  params: List(#(String, String)),
  key: String,
) -> Option(Int) {
  params
  |> list.key_find(key)
  |> result.try(int.parse)
  |> option.from_result
}

/// Parse optional float query parameter
pub fn parse_float_param(
  params: List(#(String, String)),
  key: String,
) -> Option(Float) {
  params
  |> list.key_find(key)
  |> result.try(fn(s) {
    string.replace(s, ",", ".")
    |> float.parse
  })
  |> option.from_result
}

// =============================================================================
// Response Builders
// =============================================================================

/// Create a JSON error response
pub fn error_response(status: Int, message: String) -> wisp.Response {
  json.object([#("error", json.string(message))])
  |> json.to_string
  |> wisp.json_response(status)
}

/// Create a service error response based on error type
pub fn service_error_response(
  error: fatsecret_service.ServiceError,
) -> wisp.Response {
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

/// Create a success response with custom data
pub fn success_response(data: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(data), 200)
}

/// Create a simple success message response
pub fn success_message(message: String) -> wisp.Response {
  json.object([
    #("success", json.bool(True)),
    #("message", json.string(message)),
  ])
  |> json.to_string
  |> wisp.json_response(200)
}

// =============================================================================
// Food JSON Encoders
// =============================================================================

/// Encode a Food to JSON
pub fn encode_food(food: food_types.Food) -> json.Json {
  json.object([
    #("food_id", json.string(food_types.food_id_to_string(food.food_id))),
    #("food_name", json.string(food.food_name)),
    #("food_type", json.string(food.food_type)),
    #("food_url", json.string(food.food_url)),
    #("brand_name", encode_optional_string(food.brand_name)),
    #("servings", json.array(food.servings, encode_serving)),
  ])
}

/// Encode a Serving to JSON
pub fn encode_serving(serving: food_types.Serving) -> json.Json {
  json.object([
    #(
      "serving_id",
      json.string(food_types.serving_id_to_string(serving.serving_id)),
    ),
    #("serving_description", json.string(serving.serving_description)),
    #("serving_url", json.string(serving.serving_url)),
    #(
      "metric_serving_amount",
      encode_optional_float(serving.metric_serving_amount),
    ),
    #(
      "metric_serving_unit",
      encode_optional_string(serving.metric_serving_unit),
    ),
    #("number_of_units", json.float(serving.number_of_units)),
    #("measurement_description", json.string(serving.measurement_description)),
    #("nutrition", encode_nutrition(serving.nutrition)),
  ])
}

/// Encode Food Nutrition to JSON
pub fn encode_nutrition(nutrition: food_types.Nutrition) -> json.Json {
  json.object([
    #("calories", json.float(nutrition.calories)),
    #("carbohydrate", json.float(nutrition.carbohydrate)),
    #("protein", json.float(nutrition.protein)),
    #("fat", json.float(nutrition.fat)),
    #("saturated_fat", encode_optional_float(nutrition.saturated_fat)),
    #(
      "polyunsaturated_fat",
      encode_optional_float(nutrition.polyunsaturated_fat),
    ),
    #(
      "monounsaturated_fat",
      encode_optional_float(nutrition.monounsaturated_fat),
    ),
    #("cholesterol", encode_optional_float(nutrition.cholesterol)),
    #("sodium", encode_optional_float(nutrition.sodium)),
    #("potassium", encode_optional_float(nutrition.potassium)),
    #("fiber", encode_optional_float(nutrition.fiber)),
    #("sugar", encode_optional_float(nutrition.sugar)),
    #("vitamin_a", encode_optional_float(nutrition.vitamin_a)),
    #("vitamin_c", encode_optional_float(nutrition.vitamin_c)),
    #("calcium", encode_optional_float(nutrition.calcium)),
    #("iron", encode_optional_float(nutrition.iron)),
  ])
}

/// Encode FoodSearchResult to JSON
pub fn encode_food_search_result(
  result: food_types.FoodSearchResult,
) -> json.Json {
  json.object([
    #("food_id", json.string(food_types.food_id_to_string(result.food_id))),
    #("food_name", json.string(result.food_name)),
    #("food_type", json.string(result.food_type)),
    #("food_description", json.string(result.food_description)),
    #("brand_name", encode_optional_string(result.brand_name)),
    #("food_url", json.string(result.food_url)),
  ])
}

/// Encode a favorite food (simplified) to JSON
pub fn encode_favorite_food(
  food: #(String, String, String, Option(String), String, String),
) -> json.Json {
  let #(food_id, food_name, food_type, brand_name, food_description, food_url) =
    food
  json.object([
    #("food_id", json.string(food_id)),
    #("food_name", json.string(food_name)),
    #("food_type", json.string(food_type)),
    #("brand_name", encode_optional_string(brand_name)),
    #("food_description", json.string(food_description)),
    #("food_url", json.string(food_url)),
  ])
}

// =============================================================================
// Recipe JSON Encoders
// =============================================================================

/// Encode a Recipe to JSON
pub fn encode_recipe(recipe: recipe_types.Recipe) -> json.Json {
  json.object([
    #(
      "recipe_id",
      json.string(recipe_types.recipe_id_to_string(recipe.recipe_id)),
    ),
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
    #("nutrition", encode_recipe_nutrition(recipe)),
  ])
}

/// Encode an Ingredient to JSON
pub fn encode_ingredient(ingredient: recipe_types.RecipeIngredient) -> json.Json {
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

/// Encode a Direction to JSON
pub fn encode_direction(direction: recipe_types.RecipeDirection) -> json.Json {
  json.object([
    #("direction_number", json.int(direction.direction_number)),
    #("direction_description", json.string(direction.direction_description)),
  ])
}

/// Encode a RecipeType (String) to JSON
pub fn encode_recipe_type(recipe_type: recipe_types.RecipeType) -> json.Json {
  json.string(recipe_type)
}

/// Encode Recipe Nutrition to JSON
pub fn encode_recipe_nutrition(recipe: recipe_types.Recipe) -> json.Json {
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

/// Encode RecipeSearchResult to JSON
pub fn encode_recipe_search_result(
  result: recipe_types.RecipeSearchResult,
) -> json.Json {
  json.object([
    #(
      "recipe_id",
      json.string(recipe_types.recipe_id_to_string(result.recipe_id)),
    ),
    #("recipe_name", json.string(result.recipe_name)),
    #("recipe_description", json.string(result.recipe_description)),
    #("recipe_url", json.string(result.recipe_url)),
    #("recipe_image", encode_optional_string(result.recipe_image)),
  ])
}

/// Encode a favorite recipe (simplified) to JSON
pub fn encode_favorite_recipe(
  recipe: #(String, String, String, String, Option(String)),
) -> json.Json {
  let #(recipe_id, recipe_name, recipe_description, recipe_url, recipe_image) =
    recipe
  json.object([
    #("recipe_id", json.string(recipe_id)),
    #("recipe_name", json.string(recipe_name)),
    #("recipe_description", json.string(recipe_description)),
    #("recipe_url", json.string(recipe_url)),
    #("recipe_image", encode_optional_string(recipe_image)),
  ])
}

// =============================================================================
// Validation Helpers
// =============================================================================

/// Clamp an integer to a range
pub fn clamp(value: Int, min: Int, max: Int) -> Int {
  case value {
    _ if value < min -> min
    _ if value > max -> max
    _ -> value
  }
}

/// Clamp page limit to valid range (1-50)
pub fn clamp_limit(limit: Int) -> Int {
  clamp(limit, 1, 50)
}

/// Validate that a required string parameter is not empty
pub fn validate_required_string(
  value: Option(String),
  param_name: String,
) -> Result(String, #(Int, String)) {
  case value {
    None -> Error(#(400, "Missing required query parameter: " <> param_name))
    Some(s) -> {
      case string.is_empty(s) {
        True ->
          Error(#(400, "Query parameter '" <> param_name <> "' cannot be empty"))
        False -> Ok(s)
      }
    }
  }
}

// =============================================================================
// HTTP Method Helpers
// =============================================================================

/// Check if request method matches expected method
pub fn require_method(
  req: wisp.Request,
  expected: http.Method,
) -> Result(Nil, wisp.Response) {
  case req.method == expected {
    True -> Ok(Nil)
    False -> Error(wisp.method_not_allowed([expected]))
  }
}

/// Encode FoodSuggestion to JSON
pub fn encode_food_suggestion(
  suggestion: food_types.FoodSuggestion,
) -> json.Json {
  json.object([
    #("food_id", json.string(food_types.food_id_to_string(suggestion.food_id))),
    #("food_name", json.string(suggestion.food_name)),
  ])
}

/// Encode RecipeSuggestion to JSON
pub fn encode_recipe_suggestion(
  suggestion: recipe_types.RecipeSuggestion,
) -> json.Json {
  json.object([
    #(
      "recipe_id",
      json.string(recipe_types.recipe_id_to_string(suggestion.recipe_id)),
    ),
    #("recipe_name", json.string(suggestion.recipe_name)),
  ])
}
