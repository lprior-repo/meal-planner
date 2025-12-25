/// Mapper for converting Tandoor API types to internal Recipe types
///
/// This module provides functions to convert data structures received from the
/// Tandoor recipe manager API into the internal Recipe format used by the meal planner.
///
/// Tandoor API responses include detailed recipe information with nutrition data,
/// steps with ingredient references, and metadata. This mapper normalizes that
/// data into a consistent internal format for storage and processing.
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import meal_planner/id
import meal_planner/types/macros.{type Macros, Macros, calories}
import meal_planner/types/recipe.{
  type FodmapLevel, type Ingredient, type Recipe, High, Ingredient, Low, Medium,
  Recipe,
}

/// Tandoor API nutrition data structure
/// Represents nutritional information from Tandoor recipes
pub type TandoorNutrition {
  TandoorNutrition(
    energy: Option(Float),
    // Energy in kcal
    protein: Option(Float),
    // Protein in grams
    fat: Option(Float),
    // Fat in grams
    carbohydrates: Option(Float),
    // Carbohydrates in grams
  )
}

/// Tandoor API recipe step with instructions
/// Steps can reference ingredients used in that step
pub type TandoorRecipeStep {
  TandoorRecipeStep(
    step: Int,
    instruction: String,
    ingredients: List(Int),
    // IDs of ingredients in this step
  )
}

/// Tandoor API recipe response
/// This is the main structure returned from Tandoor API endpoints
pub type TandoorRecipe {
  TandoorRecipe(
    id: Int,
    name: String,
    slug: String,
    author: String,
    description: String,
    keywords: List(String),
    servings: Int,
    servings_text: String,
    prep_time: Int,
    cook_time: Int,
    nutrition: Option(TandoorNutrition),
    steps: List(TandoorRecipeStep),
  )
}

/// Convert a Tandoor recipe to internal Recipe format
///
/// This is the main conversion function that transforms Tandoor API data into
/// the internal representation. It handles:
/// - ID generation from Tandoor ID
/// - Nutrition data normalization
/// - Step conversion to instructions
/// - Default values for optional fields
///
/// Parameters:
/// - tandoor_recipe: The recipe data from Tandoor API
///
/// Returns:
/// - Ok(Recipe): Successfully converted recipe
/// - Error(String): Conversion error description
pub fn tandoor_to_recipe(
  tandoor_recipe: TandoorRecipe,
) -> Result(Recipe, String) {
  use macros <- result.try(
    extract_macros(tandoor_recipe.nutrition)
    |> result.replace_error("Failed to extract nutrition data"),
  )

  let instructions = extract_instructions(tandoor_recipe.steps)
  let category = extract_category(tandoor_recipe.keywords)
  let recipe_id = id.recipe_id(string.lowercase(tandoor_recipe.slug))

  // Infer FODMAP level from keywords or description
  let fodmap_level =
    infer_fodmap_level(tandoor_recipe.keywords, tandoor_recipe.description)

  // Check if recipe is Vertical Diet compliant from keywords
  let is_vertical_compliant =
    string.lowercase(string.concat(tandoor_recipe.keywords))
    |> string.contains("vertical-diet")

  Ok(Recipe(
    id: recipe_id,
    name: tandoor_recipe.name,
    ingredients: [],
    // TODO: Parse ingredients from steps when available
    instructions: instructions,
    macros: macros,
    servings: tandoor_recipe.servings,
    category: category,
    fodmap_level: fodmap_level,
    vertical_compliant: is_vertical_compliant,
  ))
}

/// Extract macros from Tandoor nutrition data
///
/// Converts the optional Tandoor nutrition structure to internal Macros type.
/// Returns default zero macros if nutrition data is missing.
///
/// Parameters:
/// - nutrition: Optional Tandoor nutrition data
///
/// Returns:
/// - Ok(Macros): Successfully extracted macros
/// - Error(String): Invalid nutrition data
fn extract_macros(nutrition: Option(TandoorNutrition)) -> Result(Macros, Nil) {
  case nutrition {
    Some(nut) -> {
      let protein = nut.protein |> option.unwrap(0.0)
      let fat = nut.fat |> option.unwrap(0.0)
      let carbs = nut.carbohydrates |> option.unwrap(0.0)
      Ok(Macros(protein: protein, fat: fat, carbs: carbs))
    }
    None -> {
      // Return zero macros if nutrition data not available
      Ok(Macros(protein: 0.0, fat: 0.0, carbs: 0.0))
    }
  }
}

/// Extract instructions from Tandoor recipe steps
///
/// Converts the step list into a flat list of instruction strings.
/// Steps are sorted by step number and instructions are extracted.
///
/// Parameters:
/// - steps: List of TandoorRecipeStep
///
/// Returns:
/// - List of instruction strings in order
fn extract_instructions(steps: List(TandoorRecipeStep)) -> List(String) {
  steps
  |> list.sort(fn(a, b) {
    case a.step < b.step {
      True -> order.Lt
      False ->
        case a.step > b.step {
          True -> order.Gt
          False -> order.Eq
        }
    }
  })
  |> list.map(fn(step) { step.instruction })
}

/// Extract primary category from keywords
///
/// Examines the keyword list to determine the primary recipe category.
/// Looks for specific dietary keywords (protein, vegetable, etc).
/// Falls back to "other" if no recognized keywords found.
///
/// Parameters:
/// - keywords: List of keyword strings from recipe
///
/// Returns:
/// - Category string for the recipe
fn extract_category(keywords: List(String)) -> String {
  let lowercase_keywords =
    keywords
    |> list.map(string.lowercase)

  case list.find(lowercase_keywords, keyword_is_protein) {
    Ok(_) -> "Protein"
    Error(_) ->
      case list.find(lowercase_keywords, keyword_is_vegetable) {
        Ok(_) -> "Vegetable"
        Error(_) ->
          case list.find(lowercase_keywords, keyword_is_sauce) {
            Ok(_) -> "Sauce"
            Error(_) -> "Other"
          }
      }
  }
}

/// Check if keyword indicates protein category
fn keyword_is_protein(keyword: String) -> Bool {
  keyword == "protein"
  || keyword == "meat"
  || keyword == "beef"
  || keyword == "chicken"
  || keyword == "fish"
  || keyword == "seafood"
  || keyword == "pork"
  || keyword == "lamb"
}

/// Check if keyword indicates vegetable category
fn keyword_is_vegetable(keyword: String) -> Bool {
  keyword == "vegetable"
  || keyword == "vegetables"
  || keyword == "greens"
  || keyword == "salad"
  || keyword == "side"
}

/// Check if keyword indicates sauce category
fn keyword_is_sauce(keyword: String) -> Bool {
  keyword == "sauce" || keyword == "dressing"
}

/// Infer FODMAP level from recipe metadata
///
/// Attempts to determine FODMAP level based on:
/// 1. Explicit FODMAP keyword in keywords list
/// 2. Keywords that typically indicate low FODMAP (protein, rice)
/// 3. Default to Medium if unclear
///
/// Parameters:
/// - keywords: Recipe keyword list
/// - description: Recipe description text
///
/// Returns:
/// - FodmapLevel: Inferred level (Low, Medium, or High)
fn infer_fodmap_level(
  keywords: List(String),
  description: String,
) -> FodmapLevel {
  let lowercase_keywords =
    keywords
    |> list.map(string.lowercase)

  // Check for explicit FODMAP keywords
  case list.find(lowercase_keywords, fn(k) { k == "low-fodmap" }) {
    Ok(_) -> Low
    Error(_) ->
      case list.find(lowercase_keywords, fn(k) { k == "high-fodmap" }) {
        Ok(_) -> High
        Error(_) ->
          // Check for keywords that typically indicate low FODMAP
          case list.find(lowercase_keywords, keyword_suggests_low_fodmap) {
            Ok(_) -> Low
            Error(_) -> Medium
          }
      }
  }
}

/// Check if keyword suggests low FODMAP content
fn keyword_suggests_low_fodmap(keyword: String) -> Bool {
  keyword == "protein"
  || keyword == "meat"
  || keyword == "rice"
  || keyword == "beef"
  || keyword == "chicken"
  || keyword == "vertical-diet"
}

/// Convert internal Recipe back to Tandoor format
///
/// This is useful for synchronizing local recipe changes back to Tandoor,
/// or for creating new recipes in Tandoor from internal recipes.
///
/// Parameters:
/// - recipe: Internal recipe format
///
/// Returns:
/// - TandoorRecipe: Recipe in Tandoor API format
pub fn recipe_to_tandoor(recipe: Recipe) -> TandoorRecipe {
  let slug = recipe.id |> id.recipe_id_to_string |> string.replace("_", "-")
  let keywords =
    build_keywords(
      recipe.category,
      recipe.fodmap_level,
      recipe.vertical_compliant,
    )

  let nutrition =
    TandoorNutrition(
      energy: Some(calories(recipe.macros)),
      protein: Some(recipe.macros.protein),
      fat: Some(recipe.macros.fat),
      carbohydrates: Some(recipe.macros.carbs),
    )

  let steps = build_recipe_steps(recipe.instructions)

  TandoorRecipe(
    id: 0,
    // Will be assigned by Tandoor
    name: recipe.name,
    slug: slug,
    author: "meal-planner",
    description: "",
    keywords: keywords,
    servings: recipe.servings,
    servings_text: int.to_string(recipe.servings) <> " servings",
    prep_time: 0,
    cook_time: 0,
    nutrition: Some(nutrition),
    steps: steps,
  )
}

/// Build keyword list for a recipe
fn build_keywords(
  category: String,
  fodmap_level: FodmapLevel,
  vertical_compliant: Bool,
) -> List(String) {
  let category_keyword = string.lowercase(category)
  let fodmap_keyword = case fodmap_level {
    Low -> "low-fodmap"
    Medium -> "medium-fodmap"
    High -> "high-fodmap"
  }
  let vertical_keyword = case vertical_compliant {
    True -> ["vertical-diet"]
    False -> []
  }

  [category_keyword, fodmap_keyword] |> list.append(vertical_keyword)
}

/// Build recipe steps from instruction list
fn build_recipe_steps(instructions: List(String)) -> List(TandoorRecipeStep) {
  instructions
  |> list.index_map(fn(instruction, index) {
    TandoorRecipeStep(
      step: index + 1,
      instruction: instruction,
      ingredients: [],
    )
  })
}

/// Helper type for ordering
type Order {
  Lt
  Eq
  Gt
}

/// Helper to convert recipes in bulk
///
/// Converts a list of Tandoor recipes to internal format, filtering out
/// any that fail to convert.
///
/// Parameters:
/// - tandoor_recipes: List of recipes from Tandoor API
///
/// Returns:
/// - List of successfully converted recipes
pub fn tandoor_recipes_to_list(
  tandoor_recipes: List(TandoorRecipe),
) -> List(Recipe) {
  tandoor_recipes
  |> list.filter_map(tandoor_to_recipe)
}

/// Helper to batch convert in bulk with error tracking
///
/// Converts a list of Tandoor recipes and returns both successful conversions
/// and any errors that occurred.
///
/// Parameters:
/// - tandoor_recipes: List of recipes from Tandoor API
///
/// Returns:
/// - #(successful_recipes, errors) tuple with conversions and error list
pub fn tandoor_recipes_to_list_with_errors(
  tandoor_recipes: List(TandoorRecipe),
) -> #(List(Recipe), List(#(Int, String))) {
  let results =
    tandoor_recipes
    |> list.map(fn(tandoor_recipe) {
      case tandoor_to_recipe(tandoor_recipe) {
        Ok(recipe) -> #(True, recipe, tandoor_recipe.id, "")
        Error(err) -> #(False, recipe_empty(), tandoor_recipe.id, err)
      }
    })

  let successful =
    results
    |> list.filter(fn(result) { result.0 })
    |> list.map(fn(result) { result.1 })

  let errors =
    results
    |> list.filter(fn(result) { !result.0 })
    |> list.map(fn(result) { #(result.2, result.3) })

  #(successful, errors)
}

/// Create an empty recipe for placeholder purposes
fn recipe_empty() -> Recipe {
  Recipe(
    id: id.recipe_id("unknown"),
    name: "Unknown Recipe",
    ingredients: [],
    instructions: [],
    macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    servings: 1,
    category: "Other",
    fodmap_level: Medium,
    vertical_compliant: False,
  )
}
