/// JSON decoders for FatSecret Favorites API responses
///
/// Handles the complex nested structure of FatSecret API responses,
/// including single vs. array food/recipe responses.
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None}
import meal_planner/fatsecret/favorites/types

pub type DecodeError {
  ParseError(message: String)
}

/// Decode a FavoriteFood from JSON
fn favorite_food_decoder() -> decode.Decoder(types.FavoriteFood) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use brand_name <- decode.optional_field(
    "brand_name",
    None,
    decode.optional(decode.string),
  )
  use food_description <- decode.field("food_description", decode.string)
  use food_url <- decode.field("food_url", decode.string)
  use serving_id <- decode.field("serving_id", decode.string)
  use number_of_units <- decode.field("number_of_units", decode.string)
  decode.success(types.FavoriteFood(
    food_id:,
    food_name:,
    food_type:,
    brand_name:,
    food_description:,
    food_url:,
    serving_id:,
    number_of_units:,
  ))
}

/// Decode a MostEatenFood from JSON
fn most_eaten_food_decoder() -> decode.Decoder(types.MostEatenFood) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use brand_name <- decode.optional_field(
    "brand_name",
    None,
    decode.optional(decode.string),
  )
  use food_description <- decode.field("food_description", decode.string)
  use food_url <- decode.field("food_url", decode.string)
  use serving_id <- decode.field("serving_id", decode.string)
  use number_of_units <- decode.field("number_of_units", decode.string)
  decode.success(types.MostEatenFood(
    food_id:,
    food_name:,
    food_type:,
    brand_name:,
    food_description:,
    food_url:,
    serving_id:,
    number_of_units:,
  ))
}

/// Decode a RecentlyEatenFood from JSON
fn recently_eaten_food_decoder() -> decode.Decoder(types.RecentlyEatenFood) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use brand_name <- decode.optional_field(
    "brand_name",
    None,
    decode.optional(decode.string),
  )
  use food_description <- decode.field("food_description", decode.string)
  use food_url <- decode.field("food_url", decode.string)
  use serving_id <- decode.field("serving_id", decode.string)
  use number_of_units <- decode.field("number_of_units", decode.string)
  decode.success(types.RecentlyEatenFood(
    food_id:,
    food_name:,
    food_type:,
    brand_name:,
    food_description:,
    food_url:,
    serving_id:,
    number_of_units:,
  ))
}

/// Decode a FavoriteRecipe from JSON
fn favorite_recipe_decoder() -> decode.Decoder(types.FavoriteRecipe) {
  use recipe_id <- decode.field("recipe_id", decode.string)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use recipe_description <- decode.field("recipe_description", decode.string)
  use recipe_url <- decode.field("recipe_url", decode.string)
  use recipe_image <- decode.optional_field(
    "recipe_image",
    None,
    decode.optional(decode.string),
  )
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
    decode.at(["foods", "food"], decode.list(favorite_food_decoder()))

  case json.parse(body, list_decoder) {
    Ok(foods) -> Ok(types.FavoriteFoodsResponse(foods:))
    Error(_) -> {
      // Try single item
      let single_decoder = decode.at(["foods", "food"], favorite_food_decoder())
      case json.parse(body, single_decoder) {
        Ok(food) -> Ok(types.FavoriteFoodsResponse(foods: [food]))
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
    decode.at(["foods", "food"], decode.list(most_eaten_food_decoder()))

  case json.parse(body, list_decoder) {
    Ok(foods) -> Ok(types.MostEatenResponse(foods:))
    Error(_) -> {
      // Try single item
      let single_decoder =
        decode.at(["foods", "food"], most_eaten_food_decoder())
      case json.parse(body, single_decoder) {
        Ok(food) -> Ok(types.MostEatenResponse(foods: [food]))
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
    decode.at(["foods", "food"], decode.list(recently_eaten_food_decoder()))

  case json.parse(body, list_decoder) {
    Ok(foods) -> Ok(types.RecentlyEatenResponse(foods:))
    Error(_) -> {
      // Try single item
      let single_decoder =
        decode.at(["foods", "food"], recently_eaten_food_decoder())
      case json.parse(body, single_decoder) {
        Ok(food) -> Ok(types.RecentlyEatenResponse(foods: [food]))
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
    decode.at(["recipes", "recipe"], decode.list(favorite_recipe_decoder()))

  case json.parse(body, list_decoder) {
    Ok(recipes) -> Ok(types.FavoriteRecipesResponse(recipes:))
    Error(_) -> {
      // Try single item
      let single_decoder =
        decode.at(["recipes", "recipe"], favorite_recipe_decoder())
      case json.parse(body, single_decoder) {
        Ok(recipe) -> Ok(types.FavoriteRecipesResponse(recipes: [recipe]))
        Error(_) ->
          Error(ParseError("Failed to parse favorite recipes response"))
      }
    }
  }
}
