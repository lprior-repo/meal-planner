//// TheMealDB API Client
////
//// Implementation for fetching recipes from TheMealDB (https://www.themealdb.com).
//// This is a free API that does not require an API key.
////
//// ## API Endpoints
////
//// - Lookup by ID: `https://www.themealdb.com/api/json/v1/1/lookup.php?i={id}`
//// - Search by name: `https://www.themealdb.com/api/json/v1/1/search.php?s={query}`

import gleam/dynamic.{type DecodeError, type Decoder, type Dynamic}
import gleam/dynamic/decode
import gleam/float
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/external/recipe_fetcher.{
  type FetchError, InvalidQuery, NetworkError, ParseError, RecipeNotFound,
}
import meal_planner/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, Ingredient, Low,
  Macros, Recipe,
}

// ============================================================================
// API Response Types
// ============================================================================

/// TheMealDB API response wrapper
type MealDbResponse {
  MealDbResponse(meals: Option(List(MealDbMeal)))
}

/// Single meal from TheMealDB
type MealDbMeal {
  MealDbMeal(
    id_meal: String,
    str_meal: String,
    str_category: Option(String),
    str_instructions: String,
    // Ingredients and measures (up to 20)
    str_ingredient1: Option(String),
    str_ingredient2: Option(String),
    str_ingredient3: Option(String),
    str_ingredient4: Option(String),
    str_ingredient5: Option(String),
    str_ingredient6: Option(String),
    str_ingredient7: Option(String),
    str_ingredient8: Option(String),
    str_ingredient9: Option(String),
    str_ingredient10: Option(String),
    str_measure1: Option(String),
    str_measure2: Option(String),
    str_measure3: Option(String),
    str_measure4: Option(String),
    str_measure5: Option(String),
    str_measure6: Option(String),
    str_measure7: Option(String),
    str_measure8: Option(String),
    str_measure9: Option(String),
    str_measure10: Option(String),
  )
}

// ============================================================================
// Public API Functions
// ============================================================================

/// Fetch a single recipe by ID from TheMealDB
pub fn fetch_recipe(recipe_id: String) -> Result(Recipe, FetchError) {
  case recipe_id {
    "" -> Error(InvalidQuery("Recipe ID cannot be empty"))
    _ -> {
      let url =
        "https://www.themealdb.com/api/json/v1/1/lookup.php?i=" <> recipe_id

      use response <- result.try(make_http_request(url))
      use meal_response <- result.try(parse_meal_response(response))

      case meal_response.meals {
        Some([meal, ..]) -> meal_to_recipe(meal)
        Some([]) | None -> Error(RecipeNotFound(recipe_id))
        _ -> Error(RecipeNotFound(recipe_id))
      }
    }
  }
}

/// Search for recipes by query string
pub fn search_recipes(
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
        Some(meals) -> {
          meals
          |> list.take(limit)
          |> list.try_map(meal_to_recipe)
        }
        None -> Ok([])
      }
    }
  }
}

// ============================================================================
// HTTP and Parsing
// ============================================================================

/// Make HTTP request to TheMealDB API
fn make_http_request(url: String) -> Result(String, FetchError) {
  let request_result =
    request.to(url)
    |> result.map_error(fn(_) {
      NetworkError("Failed to create request for: " <> url)
    })

  use req <- result.try(request_result)

  httpc.send(req)
  |> result.map(fn(response) { response.body })
  |> result.map_error(fn(_) { NetworkError("HTTP request failed") })
}

/// Parse JSON response into MealDbResponse
fn parse_meal_response(
  json_string: String,
) -> Result(MealDbResponse, FetchError) {
  json.decode(json_string, meal_response_decoder())
  |> result.map_error(fn(_) { ParseError("Failed to parse TheMealDB response") })
}

// ============================================================================
// JSON Decoders
// ============================================================================

/// Decoder for MealDbResponse
fn meal_response_decoder() -> Decoder(MealDbResponse) {
  use meals <- decode.field(
    "meals",
    decode.optional(decode.list(meal_decoder())),
  )
  decode.success(MealDbResponse(meals: meals))
}

/// Decoder for MealDbMeal
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
  use str_ingredient6 <- decode.field(
    "strIngredient6",
    decode.optional(decode.string),
  )
  use str_ingredient7 <- decode.field(
    "strIngredient7",
    decode.optional(decode.string),
  )
  use str_ingredient8 <- decode.field(
    "strIngredient8",
    decode.optional(decode.string),
  )
  use str_ingredient9 <- decode.field(
    "strIngredient9",
    decode.optional(decode.string),
  )
  use str_ingredient10 <- decode.field(
    "strIngredient10",
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
  use str_measure6 <- decode.field(
    "strMeasure6",
    decode.optional(decode.string),
  )
  use str_measure7 <- decode.field(
    "strMeasure7",
    decode.optional(decode.string),
  )
  use str_measure8 <- decode.field(
    "strMeasure8",
    decode.optional(decode.string),
  )
  use str_measure9 <- decode.field(
    "strMeasure9",
    decode.optional(decode.string),
  )
  use str_measure10 <- decode.field(
    "strMeasure10",
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
    str_ingredient6: str_ingredient6,
    str_ingredient7: str_ingredient7,
    str_ingredient8: str_ingredient8,
    str_ingredient9: str_ingredient9,
    str_ingredient10: str_ingredient10,
    str_measure1: str_measure1,
    str_measure2: str_measure2,
    str_measure3: str_measure3,
    str_measure4: str_measure4,
    str_measure5: str_measure5,
    str_measure6: str_measure6,
    str_measure7: str_measure7,
    str_measure8: str_measure8,
    str_measure9: str_measure9,
    str_measure10: str_measure10,
  ))
}

// ============================================================================
// Type Conversion
// ============================================================================

/// Convert TheMealDB meal to internal Recipe type
fn meal_to_recipe(meal: MealDbMeal) -> Result(Recipe, FetchError) {
  let ingredients = extract_ingredients(meal)
  let instructions = parse_instructions(meal.str_instructions)
  let category = option.unwrap(meal.str_category, "imported")

  // TheMealDB doesn't provide nutrition data, so we use placeholder values
  // In production, you'd integrate with a nutrition API or database
  let macros = estimate_macros(ingredients)

  Ok(Recipe(
    id: "themealdb-" <> meal.id_meal,
    name: meal.str_meal,
    ingredients: ingredients,
    instructions: instructions,
    macros: macros,
    servings: 4,
    // Default to 4 servings (TheMealDB doesn't specify)
    category: category,
    fodmap_level: Low,
    // Default to Low (would need FODMAP analysis)
    vertical_compliant: False,
    // Cannot determine without nutritional data
  ))
}

/// Extract ingredients from TheMealDB meal
fn extract_ingredients(meal: MealDbMeal) -> List(Ingredient) {
  let ingredient_pairs = [
    #(meal.str_ingredient1, meal.str_measure1),
    #(meal.str_ingredient2, meal.str_measure2),
    #(meal.str_ingredient3, meal.str_measure3),
    #(meal.str_ingredient4, meal.str_measure4),
    #(meal.str_ingredient5, meal.str_measure5),
    #(meal.str_ingredient6, meal.str_measure6),
    #(meal.str_ingredient7, meal.str_measure7),
    #(meal.str_ingredient8, meal.str_measure8),
    #(meal.str_ingredient9, meal.str_measure9),
    #(meal.str_ingredient10, meal.str_measure10),
  ]

  ingredient_pairs
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

/// Parse instruction string into list of steps
fn parse_instructions(instructions: String) -> List(String) {
  instructions
  |> string.split("\r\n")
  |> list.flat_map(fn(line) { string.split(line, "\n") })
  |> list.map(string.trim)
  |> list.filter(fn(s) { s != "" })
}

/// Estimate macros based on ingredients (placeholder)
/// In production, this would query a nutritional database
fn estimate_macros(ingredients: List(Ingredient)) -> Macros {
  let ingredient_count = list.length(ingredients)

  // Very rough estimates per serving (assuming 4 servings)
  // These are placeholder values - real implementation would look up nutrition
  case ingredient_count {
    0 -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
    1 | 2 -> Macros(protein: 15.0, fat: 8.0, carbs: 25.0)
    3 | 4 | 5 -> Macros(protein: 25.0, fat: 12.0, carbs: 35.0)
    _ -> Macros(protein: 30.0, fat: 15.0, carbs: 45.0)
  }
}
