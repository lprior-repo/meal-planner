/// FatSecret Recipes API JSON decoders
import gleam/dynamic/decode
import gleam/option.{None, Some}
import meal_planner/fatsecret/recipes/types

/// Decode recipe ingredient from JSON
pub fn recipe_ingredient_decoder() -> decode.Decoder(types.RecipeIngredient) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use serving_id <- decode.optional_field(
    "serving_id",
    None,
    decode.optional(decode.string),
  )
  use number_of_units <- decode.field("number_of_units", decode.float)
  use measurement_description <- decode.field(
    "measurement_description",
    decode.string,
  )
  use ingredient_description <- decode.field(
    "ingredient_description",
    decode.string,
  )
  use ingredient_url <- decode.optional_field(
    "ingredient_url",
    None,
    decode.optional(decode.string),
  )

  decode.success(types.RecipeIngredient(
    food_id:,
    food_name:,
    serving_id:,
    number_of_units:,
    measurement_description:,
    ingredient_description:,
    ingredient_url:,
  ))
}

/// Decode recipe direction from JSON
pub fn recipe_direction_decoder() -> decode.Decoder(types.RecipeDirection) {
  use direction_number <- decode.field("direction_number", decode.int)
  use direction_description <- decode.field(
    "direction_description",
    decode.string,
  )

  decode.success(types.RecipeDirection(
    direction_number:,
    direction_description:,
  ))
}

/// Decode recipe type from JSON (simple string)
pub fn recipe_type_decoder() -> decode.Decoder(types.RecipeType) {
  decode.string
}

/// Decode complete recipe from JSON (recipe.get.v2)
pub fn recipe_decoder() -> decode.Decoder(types.Recipe) {
  use recipe_id <- decode.field("recipe_id", decode.string)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use recipe_url <- decode.field("recipe_url", decode.string)
  use recipe_description <- decode.field("recipe_description", decode.string)
  use recipe_image <- decode.optional_field(
    "recipe_image",
    None,
    decode.optional(decode.string),
  )
  use number_of_servings <- decode.field("number_of_servings", decode.float)
  use preparation_time_min <- decode.optional_field(
    "preparation_time_min",
    None,
    decode.optional(decode.int),
  )
  use cooking_time_min <- decode.optional_field(
    "cooking_time_min",
    None,
    decode.optional(decode.int),
  )
  use rating <- decode.optional_field(
    "rating",
    None,
    decode.optional(decode.float),
  )

  // Recipe types can be a list or a single object
  use recipe_types <- decode.field(
    "recipe_types",
    decode.one_of(
      decode.at(["recipe_type"], decode.list(recipe_type_decoder())),
      [
        decode.at(
          ["recipe_type"],
          decode.map(recipe_type_decoder(), fn(rt) { [rt] }),
        ),
      ],
    ),
  )

  // Ingredients can be a list or a single object
  use ingredients <- decode.field(
    "ingredients",
    decode.one_of(
      decode.at(["ingredient"], decode.list(recipe_ingredient_decoder())),
      [
        decode.at(
          ["ingredient"],
          decode.map(recipe_ingredient_decoder(), fn(ing) { [ing] }),
        ),
      ],
    ),
  )

  // Directions can be a list or a single object
  use directions <- decode.field(
    "directions",
    decode.one_of(
      decode.at(["direction"], decode.list(recipe_direction_decoder())),
      [
        decode.at(
          ["direction"],
          decode.map(recipe_direction_decoder(), fn(dir) { [dir] }),
        ),
      ],
    ),
  )

  // Nutritional information (all optional)
  use calories <- decode.optional_field(
    "calories",
    None,
    decode.optional(decode.float),
  )
  use carbohydrate <- decode.optional_field(
    "carbohydrate",
    None,
    decode.optional(decode.float),
  )
  use protein <- decode.optional_field(
    "protein",
    None,
    decode.optional(decode.float),
  )
  use fat <- decode.optional_field("fat", None, decode.optional(decode.float))
  use saturated_fat <- decode.optional_field(
    "saturated_fat",
    None,
    decode.optional(decode.float),
  )
  use polyunsaturated_fat <- decode.optional_field(
    "polyunsaturated_fat",
    None,
    decode.optional(decode.float),
  )
  use monounsaturated_fat <- decode.optional_field(
    "monounsaturated_fat",
    None,
    decode.optional(decode.float),
  )
  use cholesterol <- decode.optional_field(
    "cholesterol",
    None,
    decode.optional(decode.float),
  )
  use sodium <- decode.optional_field(
    "sodium",
    None,
    decode.optional(decode.float),
  )
  use potassium <- decode.optional_field(
    "potassium",
    None,
    decode.optional(decode.float),
  )
  use fiber <- decode.optional_field(
    "fiber",
    None,
    decode.optional(decode.float),
  )
  use sugar <- decode.optional_field(
    "sugar",
    None,
    decode.optional(decode.float),
  )
  use vitamin_a <- decode.optional_field(
    "vitamin_a",
    None,
    decode.optional(decode.float),
  )
  use vitamin_c <- decode.optional_field(
    "vitamin_c",
    None,
    decode.optional(decode.float),
  )
  use calcium <- decode.optional_field(
    "calcium",
    None,
    decode.optional(decode.float),
  )
  use iron <- decode.optional_field("iron", None, decode.optional(decode.float))

  decode.success(types.Recipe(
    recipe_id: types.recipe_id(recipe_id),
    recipe_name:,
    recipe_url:,
    recipe_description:,
    recipe_image:,
    number_of_servings:,
    preparation_time_min:,
    cooking_time_min:,
    rating:,
    recipe_types:,
    ingredients:,
    directions:,
    calories:,
    carbohydrate:,
    protein:,
    fat:,
    saturated_fat:,
    polyunsaturated_fat:,
    monounsaturated_fat:,
    cholesterol:,
    sodium:,
    potassium:,
    fiber:,
    sugar:,
    vitamin_a:,
    vitamin_c:,
    calcium:,
    iron:,
  ))
}

/// Decode recipe search result from JSON
pub fn recipe_search_result_decoder() -> decode.Decoder(
  types.RecipeSearchResult,
) {
  use recipe_id <- decode.field("recipe_id", decode.string)
  use recipe_name <- decode.field("recipe_name", decode.string)
  use recipe_description <- decode.field("recipe_description", decode.string)
  use recipe_url <- decode.field("recipe_url", decode.string)
  use recipe_image <- decode.optional_field(
    "recipe_image",
    None,
    decode.optional(decode.string),
  )

  decode.success(types.RecipeSearchResult(
    recipe_id: types.recipe_id(recipe_id),
    recipe_name:,
    recipe_description:,
    recipe_url:,
    recipe_image:,
  ))
}

/// Decode recipe search response from JSON (recipes.search.v3)
pub fn recipe_search_response_decoder() -> decode.Decoder(
  types.RecipeSearchResponse,
) {
  // The recipes field contains nested recipe/max_results/total_results/page_number
  // Structure: { recipes: { recipe: [...], max_results: N, total_results: N, page_number: N } }
  decode.at(["recipes"], {
    use recipes <- decode.optional_field(
      "recipe",
      [],
      decode.one_of(
        // Multiple results: recipes.recipe is an array
        decode.list(recipe_search_result_decoder()),
        [
          // Single result: recipes.recipe is an object
          decode.map(recipe_search_result_decoder(), fn(r) { [r] }),
        ],
      ),
    )
    use max_results <- decode.field("max_results", decode.int)
    use total_results <- decode.field("total_results", decode.int)
    use page_number <- decode.field("page_number", decode.int)

    decode.success(types.RecipeSearchResponse(
      recipes:,
      max_results:,
      total_results:,
      page_number:,
    ))
  })
}

/// Decode recipe types response from JSON (recipe_types.get.v2)
pub fn recipe_types_response_decoder() -> decode.Decoder(
  types.RecipeTypesResponse,
) {
  use recipe_types <- decode.field(
    "recipe_types",
    decode.one_of(
      decode.at(["recipe_type"], decode.list(recipe_type_decoder())),
      [
        decode.at(
          ["recipe_type"],
          decode.map(recipe_type_decoder(), fn(rt) { [rt] }),
        ),
      ],
    ),
  )

  decode.success(types.RecipeTypesResponse(recipe_types:))
}
