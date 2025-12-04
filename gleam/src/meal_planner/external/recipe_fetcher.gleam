//// External Recipe API Fetcher
////
//// Unified interface for fetching recipes from external APIs.

import gleam/dynamic/decode.{type Decoder}
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/types.{
  type Ingredient, type Macros, type Recipe, Ingredient, Low, Macros, Recipe,
}

pub type RecipeSource {
  TheMealDB
  Spoonacular
}

pub type FetchError {
  NetworkError(String)
  ParseError(String)
  RateLimitError
  ApiKeyMissing
  RecipeNotFound(String)
  InvalidQuery(String)
}

type MealDbResponse {
  MealDbResponse(meals: Option(List(MealDbMeal)))
}

type MealDbMeal {
  MealDbMeal(
    id_meal: String,
    str_meal: String,
    str_category: Option(String),
    str_instructions: String,
    str_ingredient1: Option(String),
    str_ingredient2: Option(String),
    str_ingredient3: Option(String),
    str_ingredient4: Option(String),
    str_ingredient5: Option(String),
    str_measure1: Option(String),
    str_measure2: Option(String),
    str_measure3: Option(String),
    str_measure4: Option(String),
    str_measure5: Option(String),
  )
}

pub fn fetch_recipe(
  source: RecipeSource,
  recipe_id: String,
) -> Result(Recipe, FetchError) {
  case source {
    TheMealDB -> themealdb_fetch_recipe(recipe_id)
    Spoonacular -> Error(ApiKeyMissing)
  }
}

pub fn search_recipes(
  source: RecipeSource,
  query: String,
  limit: Int,
) -> Result(List(Recipe), FetchError) {
  let validated_limit = case limit {
    l if l < 1 -> 1
    l if l > 100 -> 100
    l -> l
  }

  case source {
    TheMealDB -> themealdb_search_recipes(query, validated_limit)
    Spoonacular -> Error(ApiKeyMissing)
  }
}

pub fn source_name(source: RecipeSource) -> String {
  case source {
    TheMealDB -> "TheMealDB"
    Spoonacular -> "Spoonacular"
  }
}

pub fn requires_api_key(source: RecipeSource) -> Bool {
  case source {
    TheMealDB -> False
    Spoonacular -> True
  }
}

pub fn fetch_recipes_batch(
  source: RecipeSource,
  recipe_ids: List(String),
) -> Result(List(Recipe), FetchError) {
  recipe_ids
  |> list.try_map(fn(id) { fetch_recipe(source, id) })
}

pub fn error_message(error: FetchError) -> String {
  case error {
    NetworkError(msg) -> "Network error: " <> msg
    ParseError(msg) -> "Failed to parse response: " <> msg
    RateLimitError -> "Rate limit exceeded. Please try again later."
    ApiKeyMissing -> "API key required but not provided"
    RecipeNotFound(id) -> "Recipe not found: " <> id
    InvalidQuery(msg) -> "Invalid query: " <> msg
  }
}

fn themealdb_fetch_recipe(recipe_id: String) -> Result(Recipe, FetchError) {
  case recipe_id {
    "" -> Error(InvalidQuery("Recipe ID cannot be empty"))
    _ -> {
      let url =
        "https://www.themealdb.com/api/json/v1/1/lookup.php?i=" <> recipe_id
      use response <- result.try(make_http_request(url))
      use meal_response <- result.try(parse_meal_response(response))
      case meal_response.meals {
        Some([meal, ..]) -> meal_to_recipe(meal)
        _ -> Error(RecipeNotFound(recipe_id))
      }
    }
  }
}

fn themealdb_search_recipes(
  query: String,
  limit: Int,
) -> Result(List(Recipe), FetchError) {
  case query {
    "" -> Error(InvalidQuery("Search query cannot be empty"))
    _ -> {
      let url = "https://www.themealdb.com/api/json/v1/1/search.php?s=" <> query
      use response <- result.try(make_http_request(url))
      use meal_response <- result.try(parse_meal_response(response))
      case meal_response.meals {
        Some(meals) -> meals |> list.take(limit) |> list.try_map(meal_to_recipe)
        None -> Ok([])
      }
    }
  }
}

fn make_http_request(url: String) -> Result(String, FetchError) {
  let request_result =
    request.to(url)
    |> result.map_error(fn(_) { NetworkError("Failed to create request") })
  use req <- result.try(request_result)
  httpc.send(req)
  |> result.map(fn(response) { response.body })
  |> result.map_error(fn(_) { NetworkError("HTTP request failed") })
}

fn parse_meal_response(
  json_string: String,
) -> Result(MealDbResponse, FetchError) {
  json.parse(json_string, using: meal_response_decoder())
  |> result.map_error(fn(_) { ParseError("Failed to parse TheMealDB response") })
}

fn meal_response_decoder() -> Decoder(MealDbResponse) {
  use meals <- decode.field(
    "meals",
    decode.optional(decode.list(meal_decoder())),
  )
  decode.success(MealDbResponse(meals: meals))
}

fn meal_decoder() -> Decoder(MealDbMeal) {
  use id_meal <- decode.field("idMeal", decode.string)
  use str_meal <- decode.field("strMeal", decode.string)
  use str_category <- decode.field(
    "strCategory",
    decode.optional(decode.string),
  )
  use str_instructions <- decode.field("strInstructions", decode.string)
  use str_ingredient1 <- decode.field(
    "strIngredient1",
    decode.optional(decode.string),
  )
  use str_ingredient2 <- decode.field(
    "strIngredient2",
    decode.optional(decode.string),
  )
  use str_ingredient3 <- decode.field(
    "strIngredient3",
    decode.optional(decode.string),
  )
  use str_ingredient4 <- decode.field(
    "strIngredient4",
    decode.optional(decode.string),
  )
  use str_ingredient5 <- decode.field(
    "strIngredient5",
    decode.optional(decode.string),
  )
  use str_measure1 <- decode.field(
    "strMeasure1",
    decode.optional(decode.string),
  )
  use str_measure2 <- decode.field(
    "strMeasure2",
    decode.optional(decode.string),
  )
  use str_measure3 <- decode.field(
    "strMeasure3",
    decode.optional(decode.string),
  )
  use str_measure4 <- decode.field(
    "strMeasure4",
    decode.optional(decode.string),
  )
  use str_measure5 <- decode.field(
    "strMeasure5",
    decode.optional(decode.string),
  )
  decode.success(MealDbMeal(
    id_meal: id_meal,
    str_meal: str_meal,
    str_category: str_category,
    str_instructions: str_instructions,
    str_ingredient1: str_ingredient1,
    str_ingredient2: str_ingredient2,
    str_ingredient3: str_ingredient3,
    str_ingredient4: str_ingredient4,
    str_ingredient5: str_ingredient5,
    str_measure1: str_measure1,
    str_measure2: str_measure2,
    str_measure3: str_measure3,
    str_measure4: str_measure4,
    str_measure5: str_measure5,
  ))
}

fn meal_to_recipe(meal: MealDbMeal) -> Result(Recipe, FetchError) {
  let ingredients = extract_ingredients(meal)
  let instructions = parse_instructions(meal.str_instructions)
  let category = option.unwrap(meal.str_category, "imported")
  let macros = estimate_macros(ingredients)
  Ok(Recipe(
    id: "themealdb-" <> meal.id_meal,
    name: meal.str_meal,
    ingredients: ingredients,
    instructions: instructions,
    macros: macros,
    servings: 4,
    category: category,
    fodmap_level: Low,
    vertical_compliant: False,
  ))
}

fn extract_ingredients(meal: MealDbMeal) -> List(Ingredient) {
  let pairs = [
    #(meal.str_ingredient1, meal.str_measure1),
    #(meal.str_ingredient2, meal.str_measure2),
    #(meal.str_ingredient3, meal.str_measure3),
    #(meal.str_ingredient4, meal.str_measure4),
    #(meal.str_ingredient5, meal.str_measure5),
  ]
  pairs
  |> list.filter_map(fn(pair) {
    case pair {
      #(Some(ing), Some(measure)) -> {
        let trimmed_ing = string.trim(ing)
        let trimmed_measure = string.trim(measure)
        case trimmed_ing, trimmed_measure {
          "", _ -> Error(Nil)
          _, "" -> Error(Nil)
          _, _ -> Ok(Ingredient(name: trimmed_ing, quantity: trimmed_measure))
        }
      }
      #(Some(ing), None) -> {
        let trimmed = string.trim(ing)
        case trimmed {
          "" -> Error(Nil)
          _ -> Ok(Ingredient(name: trimmed, quantity: "To taste"))
        }
      }
      _ -> Error(Nil)
    }
  })
}

fn parse_instructions(instructions: String) -> List(String) {
  instructions
  |> string.split("\r\n")
  |> list.flat_map(fn(line) { string.split(line, "\n") })
  |> list.map(string.trim)
  |> list.filter(fn(s) { s != "" })
}

fn estimate_macros(ingredients: List(Ingredient)) -> Macros {
  let count = list.length(ingredients)
  case count {
    0 -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
    1 | 2 -> Macros(protein: 15.0, fat: 8.0, carbs: 25.0)
    3 | 4 | 5 -> Macros(protein: 25.0, fat: 12.0, carbs: 35.0)
    _ -> Macros(protein: 30.0, fat: 15.0, carbs: 45.0)
  }
}
