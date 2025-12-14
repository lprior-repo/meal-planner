/// JSON decoders for FatSecret Favorites API responses
///
/// Handles the complex nested structure of FatSecret API responses,
/// including single vs. array food/recipe responses.
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/fatsecret/favorites/types

pub type DecodeError {
  ParseError(message: String)
}

/// Decode a FavoriteFood from JSON
fn favorite_food_decoder() -> decode.Decoder(types.FavoriteFood) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use brand_name <- decode.optional_field("brand_name", decode.string)
  use food_description <- decode.field("food_description", decode.string)
  use food_url <- decode.field("food_url", decode.string)
  decode.success(types.FavoriteFood(
    food_id:,
    food_name:,
    food_type:,
    brand_name:,
    food_description:,
    food_url:,
  ))
}

/// Decode a MostEatenFood from JSON
fn most_eaten_food_decoder() -> decode.Decoder(types.MostEatenFood) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use brand_name <- decode.optional_field("brand_name", decode.string)
  use food_description <- decode.field("food_description", decode.string)
  use food_url <- decode.field("food_url", decode.string)
  use eat_count <- decode.field("eat_count", decode.int)
  decode.success(types.MostEatenFood(
    food_id:,
    food_name:,
    food_type:,
    brand_name:,
    food_description:,
    food_url:,
    eat_count:,
  ))
}

/// Decode a RecentlyEatenFood from JSON
fn recently_eaten_food_decoder() -> decode.Decoder(types.RecentlyEatenFood) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use brand_name <- decode.optional_field("brand_name", decode.string)
  use food_description <- decode.field("food_description", decode.string)
  use food_url <- decode.field("food_url", decode.string)
  decode.success(types.RecentlyEatenFood(
    food_id:,
    food_name:,
    food_type:,
    brand_name:,
    food_description:,
    food_url:,
  ))
}

/// Decode a FavoriteRecipe from JSON
fn favorite_recipe_decoder() -> decode.Decoder(types.FavoriteRecipe) {
  use recipe_id <- decode.field("recipe_id", decode.string)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use recipe_description <- decode.field("recipe_description", decode.string)
  use recipe_url <- decode.field("recipe_url", decode.string)
  use recipe_image <- decode.optional_field("recipe_image", decode.string)
  decode.success(types.FavoriteRecipe(
    recipe_id:,
    recipe_name:,
    recipe_description:,
    recipe_url:,
    recipe_image:,
  ))
}

/// Decode foods.get_favorites.v2 response
/// FatSecret returns single item as object, multiple as array - handle both
pub fn decode_favorite_foods(
  body: String,
) -> Result(types.FavoriteFoodsResponse, DecodeError) {
  // Try decoding as list first
  let list_decoder =
    decode.at(
      ["favorite_foods", "favorite_food"],
      decode.list(favorite_food_decoder()),
    )

  case json.parse(body, list_decoder) {
    Ok(foods) -> {
      // Extract pagination info
      case decode_pagination(body) {
        Ok(#(max_results, total_results, page_number)) ->
          Ok(types.FavoriteFoodsResponse(
            foods:,
            max_results:,
            total_results:,
            page_number:,
          ))
        Error(e) -> Error(e)
      }
    }
    Error(_) -> {
      // Try single item
      let single_decoder =
        decode.at(["favorite_foods", "favorite_food"], favorite_food_decoder())
      case json.parse(body, single_decoder) {
        Ok(food) -> {
          case decode_pagination(body) {
            Ok(#(max_results, total_results, page_number)) ->
              Ok(types.FavoriteFoodsResponse(
                foods: [food],
                max_results:,
                total_results:,
                page_number:,
              ))
            Error(e) -> Error(e)
          }
        }
        Error(_) -> Error(ParseError("Failed to parse favorite foods response"))
      }
    }
  }
}

/// Decode foods.get_most_eaten.v2 response
pub fn decode_most_eaten(
  body: String,
) -> Result(types.MostEatenResponse, DecodeError) {
  // Try decoding as list first
  let list_decoder =
    decode.at(["most_eaten", "food"], decode.list(most_eaten_food_decoder()))

  case json.parse(body, list_decoder) {
    Ok(foods) -> {
      let meal = extract_meal_type(body)
      Ok(types.MostEatenResponse(foods:, meal:))
    }
    Error(_) -> {
      // Try single item
      let single_decoder =
        decode.at(["most_eaten", "food"], most_eaten_food_decoder())
      case json.parse(body, single_decoder) {
        Ok(food) -> {
          let meal = extract_meal_type(body)
          Ok(types.MostEatenResponse(foods: [food], meal:))
        }
        Error(_) -> Error(ParseError("Failed to parse most eaten response"))
      }
    }
  }
}

/// Decode foods.get_recently_eaten.v2 response
pub fn decode_recently_eaten(
  body: String,
) -> Result(types.RecentlyEatenResponse, DecodeError) {
  // Try decoding as list first
  let list_decoder =
    decode.at(
      ["recently_eaten", "food"],
      decode.list(recently_eaten_food_decoder()),
    )

  case json.parse(body, list_decoder) {
    Ok(foods) -> {
      let meal = extract_meal_type(body)
      Ok(types.RecentlyEatenResponse(foods:, meal:))
    }
    Error(_) -> {
      // Try single item
      let single_decoder =
        decode.at(["recently_eaten", "food"], recently_eaten_food_decoder())
      case json.parse(body, single_decoder) {
        Ok(food) -> {
          let meal = extract_meal_type(body)
          Ok(types.RecentlyEatenResponse(foods: [food], meal:))
        }
        Error(_) -> Error(ParseError("Failed to parse recently eaten response"))
      }
    }
  }
}

/// Decode recipes.get_favorites.v2 response
pub fn decode_favorite_recipes(
  body: String,
) -> Result(types.FavoriteRecipesResponse, DecodeError) {
  // Try decoding as list first
  let list_decoder =
    decode.at(
      ["favorite_recipes", "favorite_recipe"],
      decode.list(favorite_recipe_decoder()),
    )

  case json.parse(body, list_decoder) {
    Ok(recipes) -> {
      case decode_pagination(body) {
        Ok(#(max_results, total_results, page_number)) ->
          Ok(types.FavoriteRecipesResponse(
            recipes:,
            max_results:,
            total_results:,
            page_number:,
          ))
        Error(e) -> Error(e)
      }
    }
    Error(_) -> {
      // Try single item
      let single_decoder =
        decode.at(
          ["favorite_recipes", "favorite_recipe"],
          favorite_recipe_decoder(),
        )
      case json.parse(body, single_decoder) {
        Ok(recipe) -> {
          case decode_pagination(body) {
            Ok(#(max_results, total_results, page_number)) ->
              Ok(types.FavoriteRecipesResponse(
                recipes: [recipe],
                max_results:,
                total_results:,
                page_number:,
              ))
            Error(e) -> Error(e)
          }
        }
        Error(_) ->
          Error(ParseError("Failed to parse favorite recipes response"))
      }
    }
  }
}

/// Helper to decode pagination info
fn decode_pagination(body: String) -> Result(#(Int, Int, Int), DecodeError) {
  let pagination_decoder = {
    use max_results <- decode.field("max_results", decode_string_int())
    use total_results <- decode.field("total_results", decode_string_int())
    use page_number <- decode.field("page_number", decode_string_int())
    decode.success(#(max_results, total_results, page_number))
  }

  case json.parse(body, pagination_decoder) {
    Ok(result) -> Ok(result)
    Error(_) -> Error(ParseError("Failed to parse pagination info"))
  }
}

/// Helper to extract meal type from response
fn extract_meal_type(body: String) -> Option(String) {
  let meal_decoder = decode.field("meal", decode.string)
  case json.parse(body, meal_decoder) {
    Ok(meal) -> Some(meal)
    Error(_) -> None
  }
}

/// Decode a string that may be an int (FatSecret sometimes returns ints as strings)
fn decode_string_int() -> decode.Decoder(Int) {
  decode.any([
    decode.int,
    {
      use str <- decode.then(decode.string)
      case int.parse(str) {
        Ok(i) -> decode.success(i)
        Error(_) -> decode.failure(str, "int")
      }
    },
  ])
}
