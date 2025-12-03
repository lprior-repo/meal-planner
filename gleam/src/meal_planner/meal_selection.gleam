/// Meal selection logic following Vertical Diet distribution guidelines
import gleam/list
import gleam/string
import shared/types.{type Recipe, is_vertical_diet_compliant}

/// MealCategory represents the food category for selection distribution
pub type MealCategory {
  RedMeat
  Salmon
  Eggs
  Variety
}

/// MealSelectionConfig defines the distribution targets
pub type MealSelectionConfig {
  MealSelectionConfig(
    red_meat_min_percent: Float,
    red_meat_max_percent: Float,
    protein_min_percent: Float,
    protein_max_percent: Float,
    variety_max_percent: Float,
  )
}

/// MealSelectionResult tracks the distribution of selected meals
pub type MealSelectionResult {
  MealSelectionResult(
    selected_recipes: List(Recipe),
    red_meat_count: Int,
    salmon_count: Int,
    eggs_count: Int,
    variety_count: Int,
    total_count: Int,
  )
}

/// Distribution percentages for each meal category
pub type Distribution {
  Distribution(red_meat: Float, salmon: Float, eggs: Float, variety: Float)
}

/// DefaultMealSelectionConfig returns the Vertical Diet recommended distribution
pub fn default_meal_selection_config() -> MealSelectionConfig {
  MealSelectionConfig(
    red_meat_min_percent: 0.6,
    red_meat_max_percent: 0.7,
    protein_min_percent: 0.2,
    protein_max_percent: 0.3,
    variety_max_percent: 0.1,
  )
}

/// GetMealCategory determines the category of a recipe based on its ingredients and category
pub fn get_meal_category(recipe: Recipe) -> MealCategory {
  let category_lower = string.lowercase(recipe.category)
  let name_lower = string.lowercase(recipe.name)

  // Check for red meat categories
  case
    category_lower == "beef"
    || category_lower == "vertical-beef"
    || category_lower == "pork"
  {
    True -> RedMeat
    False ->
      case
        string.contains(name_lower, "salmon")
        || string.contains(category_lower, "salmon")
      {
        True -> Salmon
        False ->
          case
            string.contains(name_lower, "egg")
            || category_lower == "breakfast"
            || category_lower == "vertical-breakfast"
          {
            True -> Eggs
            False -> Variety
          }
      }
  }
}

/// GetDistribution returns the percentage distribution of meal categories
pub fn get_distribution(result: MealSelectionResult) -> Distribution {
  case result.total_count {
    0 -> Distribution(red_meat: 0.0, salmon: 0.0, eggs: 0.0, variety: 0.0)
    total -> {
      let total_float = int_to_float(total)
      Distribution(
        red_meat: int_to_float(result.red_meat_count) /. total_float,
        salmon: int_to_float(result.salmon_count) /. total_float,
        eggs: int_to_float(result.eggs_count) /. total_float,
        variety: int_to_float(result.variety_count) /. total_float,
      )
    }
  }
}

/// IsWithinTargets checks if the selection meets Vertical Diet distribution
pub fn is_within_targets(
  result: MealSelectionResult,
  config: MealSelectionConfig,
) -> Bool {
  case result.total_count {
    0 -> False
    _ -> {
      let dist = get_distribution(result)

      // Red meat should be 60-70%
      let red_meat_ok =
        dist.red_meat >=. config.red_meat_min_percent
        && dist.red_meat <=. config.red_meat_max_percent

      // Salmon + Eggs should be 20-30%
      let protein_alt = dist.salmon +. dist.eggs
      let protein_alt_ok =
        protein_alt >=. config.protein_min_percent
        && protein_alt <=. config.protein_max_percent

      // Variety should be at most 10%
      let variety_ok = dist.variety <=. config.variety_max_percent

      red_meat_ok && protein_alt_ok && variety_ok
    }
  }
}

/// SelectMealsForWeek selects meals following Vertical Diet distribution
/// target_meals is the number of main meals to select (e.g., 21 for 7 days x 3 meals)
/// When there aren't enough recipes in certain categories, it fills remaining slots
/// from available recipes to ensure the target count is met.
pub fn select_meals_for_week(
  recipes: List(Recipe),
  target_meals: Int,
) -> MealSelectionResult {
  let config = default_meal_selection_config()

  // Categorize all available recipes, filtering for compliant only
  let compliant_recipes = list.filter(recipes, is_vertical_diet_compliant)
  let categorized =
    compliant_recipes
    |> list.fold(#([], [], [], []), fn(acc, recipe) {
      let #(red_meat, salmon, eggs, variety) = acc
      case get_meal_category(recipe) {
        RedMeat -> #([recipe, ..red_meat], salmon, eggs, variety)
        Salmon -> #(red_meat, [recipe, ..salmon], eggs, variety)
        Eggs -> #(red_meat, salmon, [recipe, ..eggs], variety)
        Variety -> #(red_meat, salmon, eggs, [recipe, ..variety])
      }
    })

  let #(red_meat_recipes, salmon_recipes, eggs_recipes, variety_recipes) =
    categorized

  // Calculate target counts (using middle of ranges)
  let red_meat_target = float_to_int(int_to_float(target_meals) *. 0.65)
  let protein_target = float_to_int(int_to_float(target_meals) *. 0.25)
  let max_variety =
    float_to_int(int_to_float(target_meals) *. config.variety_max_percent)
  let variety_target = {
    let remaining = target_meals - red_meat_target - protein_target
    case remaining > max_variety {
      True -> max_variety
      False -> remaining
    }
  }

  // Select red meat meals (cycle through if needed)
  let #(selected_red_meat, red_meat_count) =
    select_from_category(red_meat_recipes, red_meat_target)

  // Select salmon/eggs meals (alternate between them)
  let salmon_target = protein_target / 2
  let eggs_target = protein_target - salmon_target

  let #(selected_salmon, salmon_count) =
    select_from_category(salmon_recipes, salmon_target)
  let #(selected_eggs, eggs_count) =
    select_from_category(eggs_recipes, eggs_target)

  // If we couldn't fill salmon/eggs targets, add more from eggs
  let #(selected_eggs_extra, eggs_count_extra) = case
    salmon_count + eggs_count < protein_target && eggs_recipes != []
  {
    True -> {
      let remaining = protein_target - salmon_count - eggs_count
      select_from_category(eggs_recipes, remaining)
    }
    False -> #([], 0)
  }

  // Select variety meals
  let #(selected_variety, variety_count) =
    select_from_category(variety_recipes, variety_target)

  // Combine all selected recipes
  let initial_selected =
    list.flatten([
      selected_red_meat,
      selected_salmon,
      selected_eggs,
      selected_eggs_extra,
      selected_variety,
    ])

  let initial_count =
    red_meat_count + salmon_count + eggs_count + eggs_count_extra + variety_count

  // If we don't have enough recipes to meet the target, fill with available recipes
  // cycling through all compliant recipes to reach the target
  let #(final_selected, extra_count) = case
    initial_count < target_meals && compliant_recipes != []
  {
    True -> {
      let remaining = target_meals - initial_count
      let #(extra, extra_len) = select_from_category(compliant_recipes, remaining)
      #(list.append(initial_selected, extra), extra_len)
    }
    False -> #(initial_selected, 0)
  }

  MealSelectionResult(
    selected_recipes: final_selected,
    red_meat_count: red_meat_count + extra_count,
    salmon_count: salmon_count,
    eggs_count: eggs_count + eggs_count_extra,
    variety_count: variety_count,
    total_count: initial_count + extra_count,
  )
}

/// Helper function to select recipes from a category, cycling if necessary
fn select_from_category(
  recipes: List(Recipe),
  target: Int,
) -> #(List(Recipe), Int) {
  case list.length(recipes) {
    0 -> #([], 0)
    len -> {
      let selected =
        list.range(0, target - 1)
        |> list.filter_map(fn(i) {
          let idx = i % len
          get_at_index(recipes, idx)
        })
      #(selected, list.length(selected))
    }
  }
}

/// Helper to get element at index from a list
fn get_at_index(lst: List(a), index: Int) -> Result(a, Nil) {
  case index, lst {
    0, [first, ..] -> Ok(first)
    n, [_, ..rest] if n > 0 -> get_at_index(rest, n - 1)
    _, _ -> Error(Nil)
  }
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

@external(erlang, "erlang", "trunc")
fn float_to_int(f: Float) -> Int
