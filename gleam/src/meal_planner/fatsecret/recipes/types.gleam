/// FatSecret Recipes API types
/// API Docs: https://platform.fatsecret.com/api/Default.aspx?screen=rapiref2&method=recipe.get.v2
import gleam/option.{type Option}

/// Opaque type for recipe IDs to prevent mixing with other ID types
pub opaque type RecipeId {
  RecipeId(String)
}

/// Create a RecipeId from a string
pub fn recipe_id(id: String) -> RecipeId {
  RecipeId(id)
}

/// Convert RecipeId to string
pub fn recipe_id_to_string(id: RecipeId) -> String {
  let RecipeId(s) = id
  s
}

/// Ingredient in a recipe
pub type RecipeIngredient {
  RecipeIngredient(
    food_id: String,
    food_name: String,
    serving_id: Option(String),
    number_of_units: Float,
    measurement_description: String,
    ingredient_description: String,
    ingredient_url: Option(String),
  )
}

/// Direction/step in recipe preparation
pub type RecipeDirection {
  RecipeDirection(direction_number: Int, direction_description: String)
}

/// Recipe category/type (simple string like "Main Dish", "Appetizers", etc.)
pub type RecipeType =
  String

/// Complete recipe details (from recipe.get.v2)
pub type Recipe {
  Recipe(
    recipe_id: RecipeId,
    recipe_name: String,
    recipe_url: String,
    recipe_description: String,
    recipe_image: Option(String),
    number_of_servings: Float,
    preparation_time_min: Option(Int),
    cooking_time_min: Option(Int),
    rating: Option(Float),
    recipe_types: List(RecipeType),
    ingredients: List(RecipeIngredient),
    directions: List(RecipeDirection),
    // Nutritional information per serving
    calories: Option(Float),
    carbohydrate: Option(Float),
    protein: Option(Float),
    fat: Option(Float),
    saturated_fat: Option(Float),
    polyunsaturated_fat: Option(Float),
    monounsaturated_fat: Option(Float),
    cholesterol: Option(Float),
    sodium: Option(Float),
    potassium: Option(Float),
    fiber: Option(Float),
    sugar: Option(Float),
    vitamin_a: Option(Float),
    vitamin_c: Option(Float),
    calcium: Option(Float),
    iron: Option(Float),
  )
}

/// Recipe search result item (from recipes.search.v3)
pub type RecipeSearchResult {
  RecipeSearchResult(
    recipe_id: RecipeId,
    recipe_name: String,
    recipe_description: String,
    recipe_url: String,
    recipe_image: Option(String),
  )
}

/// Response from recipes.search.v3
pub type RecipeSearchResponse {
  RecipeSearchResponse(
    recipes: List(RecipeSearchResult),
    max_results: Int,
    total_results: Int,
    page_number: Int,
  )
}

/// Response from recipe_types.get.v2
pub type RecipeTypesResponse {
  RecipeTypesResponse(recipe_types: List(RecipeType))
}
