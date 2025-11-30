/// Weekly plan generation following Vertical Diet guidelines
///
/// Creates 7-day meal plans with proper meal distribution and portion sizing.
import gleam/list
import meal_planner/meal_plan.{
  type DailyPlan, type Meal, type WeeklyMealPlan, DailyPlan, Meal,
  WeeklyMealPlan,
}
import meal_planner/meal_selection.{select_meals_for_week}
import meal_planner/portion.{calculate_portion_for_target}
import meal_planner/types.{
  type Ingredient, type Macros, type Recipe, type UserProfile, Macros,
  daily_carb_target, daily_fat_target, daily_protein_target,
}

/// Day names for weekly plan generation
pub fn day_names() -> List(String) {
  ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
}

/// Generate a 7-day meal plan using Vertical Diet distribution
pub fn generate_weekly_plan(
  profile: UserProfile,
  recipes: List(Recipe),
) -> WeeklyMealPlan {
  // Calculate daily macro targets from profile
  let daily_macros =
    Macros(
      protein: daily_protein_target(profile),
      fat: daily_fat_target(profile),
      carbs: daily_carb_target(profile),
    )

  // Select meals for the week using Vertical Diet distribution
  let total_meals = 7 * profile.meals_per_day
  let selection = select_meals_for_week(recipes, total_meals)
  let selected_recipes = selection.selected_recipes

  // Distribute selected recipes across days
  let #(days, _remaining_recipes) =
    list.fold(day_names(), #([], selected_recipes), fn(acc, day_name) {
      let #(built_days, available_recipes) = acc
      let #(daily_plan, remaining) =
        build_daily_plan(
          day_name,
          daily_macros,
          profile.meals_per_day,
          available_recipes,
        )
      #([daily_plan, ..built_days], remaining)
    })

  // Reverse to get correct order (Monday first)
  let ordered_days = list.reverse(days)

  // Generate shopping list from all meals
  let shopping_list = generate_shopping_list(ordered_days)

  WeeklyMealPlan(
    days: ordered_days,
    shopping_list: shopping_list,
    user_profile: profile,
  )
}

/// Build a single day's meal plan
fn build_daily_plan(
  day_name: String,
  daily_macros: Macros,
  meals_per_day: Int,
  available_recipes: List(Recipe),
) -> #(DailyPlan, List(Recipe)) {
  // Per-meal macro target
  let meals_float = int_to_float(meals_per_day)
  let per_meal_macros =
    Macros(
      protein: daily_macros.protein /. meals_float,
      fat: daily_macros.fat /. meals_float,
      carbs: daily_macros.carbs /. meals_float,
    )

  // Take meals_per_day recipes from available list
  let #(meals, remaining) =
    take_recipes_as_meals(available_recipes, meals_per_day, per_meal_macros, [])

  #(DailyPlan(day_name: day_name, meals: meals), remaining)
}

/// Take n recipes and convert to meals with portion calculations
fn take_recipes_as_meals(
  recipes: List(Recipe),
  count: Int,
  target_macros: Macros,
  acc: List(Meal),
) -> #(List(Meal), List(Recipe)) {
  case count, recipes {
    0, _ -> #(list.reverse(acc), recipes)
    _, [] -> #(list.reverse(acc), [])
    n, [recipe, ..rest] -> {
      let portion = calculate_portion_for_target(recipe, target_macros)
      let meal = Meal(recipe: recipe, portion_size: portion.scale_factor)
      take_recipes_as_meals(rest, n - 1, target_macros, [meal, ..acc])
    }
  }
}

/// Generate consolidated shopping list from all meals
fn generate_shopping_list(days: List(DailyPlan)) -> List(Ingredient) {
  // Collect all ingredients from all meals
  let all_ingredients =
    list.flat_map(days, fn(day) {
      list.flat_map(day.meals, fn(meal) { meal.recipe.ingredients })
    })

  // Aggregate by ingredient name (simple approach - just keep unique names)
  aggregate_ingredients(all_ingredients, [])
}

/// Aggregate ingredients by name
fn aggregate_ingredients(
  ingredients: List(Ingredient),
  acc: List(Ingredient),
) -> List(Ingredient) {
  case ingredients {
    [] -> acc
    [ing, ..rest] -> {
      case has_ingredient(acc, ing.name) {
        True -> aggregate_ingredients(rest, acc)
        False -> aggregate_ingredients(rest, [ing, ..acc])
      }
    }
  }
}

/// Check if ingredient list already has an ingredient with given name
fn has_ingredient(ingredients: List(Ingredient), name: String) -> Bool {
  list.any(ingredients, fn(ing) { ing.name == name })
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
