/// Recipe filter module for the Meal Planner API
/// Provides filtering functionality for recipes by macros and category
import gleam/float
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/mealie/types

/// Recipe filter parameters from query string
pub type FilterParams {
  FilterParams(
    category: Option(String),
    min_protein: Option(Float),
    max_protein: Option(Float),
    min_fat: Option(Float),
    max_fat: Option(Float),
    min_carbs: Option(Float),
    max_carbs: Option(Float),
    min_calories: Option(Float),
    max_calories: Option(Float),
  )
}

/// Filtered recipe item in response
pub type FilteredRecipeItem {
  FilteredRecipeItem(
    id: String,
    name: String,
    category: String,
    protein: Float,
    fat: Float,
    carbs: Float,
    calories: Float,
    servings: Int,
  )
}

/// Convert optional string to optional float
pub fn string_to_float(value: Option(String)) -> Option(Float) {
  case value {
    Some(s) ->
      case float.parse(s) {
        Ok(f) -> Some(f)
        Error(_) -> None
      }
    None -> None
  }
}

/// Check if a value is within a range (min/max optional)
pub fn in_range(value: Float, min: Option(Float), max: Option(Float)) -> Bool {
  let above_min = case min {
    Some(m) -> value >=. m
    None -> True
  }
  let below_max = case max {
    Some(m) -> value <=. m
    None -> True
  }
  above_min && below_max
}

/// Filter recipe based on criteria
pub fn matches_criteria(
  recipe: FilteredRecipeItem,
  params: FilterParams,
) -> Bool {
  let category_match = case params.category {
    Some(cat) -> recipe.category == cat
    None -> True
  }

  let protein_match =
    in_range(recipe.protein, params.min_protein, params.max_protein)
  let fat_match = in_range(recipe.fat, params.min_fat, params.max_fat)
  let carbs_match = in_range(recipe.carbs, params.min_carbs, params.max_carbs)
  let calories_match =
    in_range(recipe.calories, params.min_calories, params.max_calories)

  category_match && protein_match && fat_match && carbs_match && calories_match
}

/// Convert Mealie recipe summary to filterable item
pub fn recipe_summary_to_filtered_item(
  recipe: types.MealieRecipeSummary,
) -> FilteredRecipeItem {
  FilteredRecipeItem(
    id: recipe.id,
    name: recipe.name,
    category: recipe.category,
    protein: recipe.protein,
    fat: recipe.fat,
    carbs: recipe.carbs,
    calories: recipe.calories,
    servings: recipe.servings,
  )
}

/// Filter a list of recipes based on parameters
pub fn filter_recipes(
  recipes: List(FilteredRecipeItem),
  params: FilterParams,
) -> List(FilteredRecipeItem) {
  recipes |> list.filter(fn(recipe) { matches_criteria(recipe, params) })
}
