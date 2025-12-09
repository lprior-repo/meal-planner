/// Meal planning types for daily and weekly plans
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/types.{
  type Ingredient, type Macros, type Recipe, type UserProfile, Low, Macros,
  Recipe, activity_level_to_display_string, daily_carb_target, daily_fat_target,
  daily_protein_target, float_to_1dp_string, goal_to_display_string,
  macros_scale, macros_to_string,
}

/// Meal represents a recipe with a portion size multiplier
pub type Meal {
  Meal(recipe: Recipe, portion_size: Float)
}

/// Calculate macros for a meal adjusted by portion size
pub fn meal_macros(m: Meal) -> Macros {
  macros_scale(m.recipe.macros, m.portion_size)
}

/// DailyPlan represents all meals for a single day
pub type DailyPlan {
  DailyPlan(day_name: String, meals: List(Meal))
}

/// Create a default empty recipe
pub fn default_recipe() -> Recipe {
  Recipe(
    id: "",
    name: "",
    ingredients: [],
    instructions: [],
    macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    servings: 1,
    category: "",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Calculate total macros for a daily plan
pub fn daily_plan_macros(plan: DailyPlan) -> Macros {
  list_fold(
    plan.meals,
    Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    fn(acc, meal) {
      let m = meal_macros(meal)
      Macros(
        protein: acc.protein +. m.protein,
        fat: acc.fat +. m.fat,
        carbs: acc.carbs +. m.carbs,
      )
    },
  )
}

fn list_fold(list: List(a), acc: b, f: fn(b, a) -> b) -> b {
  case list {
    [] -> acc
    [first, ..rest] -> list_fold(rest, f(acc, first), f)
  }
}

/// WeeklyMealPlan represents 7 days of meal plans
pub type WeeklyMealPlan {
  WeeklyMealPlan(
    days: List(DailyPlan),
    shopping_list: List(Ingredient),
    user_profile: UserProfile,
  )
}

/// Calculate total macros for the entire week
pub fn weekly_plan_macros(plan: WeeklyMealPlan) -> Macros {
  list_fold(plan.days, Macros(protein: 0.0, fat: 0.0, carbs: 0.0), fn(acc, day) {
    let m = daily_plan_macros(day)
    Macros(
      protein: acc.protein +. m.protein,
      fat: acc.fat +. m.fat,
      carbs: acc.carbs +. m.carbs,
    )
  })
}

/// Calculate average daily macros for the week
pub fn weekly_plan_avg_daily_macros(plan: WeeklyMealPlan) -> Macros {
  let total = weekly_plan_macros(plan)
  let days = int_to_float(list_length(plan.days))
  case days {
    0.0 -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
    _ ->
      Macros(
        protein: total.protein /. days,
        fat: total.fat /. days,
        carbs: total.carbs /. days,
      )
  }
}

fn list_length(list: List(a)) -> Int {
  case list {
    [] -> 0
    [_, ..rest] -> 1 + list_length(rest)
  }
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

// ============================================================================
// Formatting Functions (moved from output.gleam to avoid feature envy)
// ============================================================================

/// Format meal timing display (e.g., "[7:00 AM] Meal 1")
pub fn format_meal_timing(meal_number: Int, hour: Int) -> String {
  let #(display_hour, ampm) = case hour >= 12 {
    True -> {
      let h = case hour > 12 {
        True -> hour - 12
        False -> 12
      }
      #(h, "PM")
    }
    False -> {
      let h = case hour == 0 {
        True -> 12
        False -> hour
      }
      #(h, "AM")
    }
  }

  "["
  <> int.to_string(display_hour)
  <> ":00 "
  <> ampm
  <> "] Meal "
  <> int.to_string(meal_number)
}

/// Format portion size (e.g., "1.0x portion" or "1.5x")
pub fn format_portion(portion: Float) -> String {
  float_to_1dp_string(portion) <> "x portion"
}

/// Format a single meal entry with timing and macros
pub fn format_meal_entry(meal: Meal, index: Int, start_hour: Int) -> String {
  let meal_number = index + 1
  let hour = start_hour + index * 4
  // 4 hours apart
  let timing = format_meal_timing(meal_number, hour)
  let macros = meal_macros(meal)
  let portion_str = format_portion(meal.portion_size)

  timing
  <> ": "
  <> meal.recipe.name
  <> " ("
  <> portion_str
  <> ")\n"
  <> "          "
  <> macros_to_string(macros)
}

/// Format a daily meal plan with all meals and totals
pub fn format_daily_plan(plan: DailyPlan, start_hour: Int) -> String {
  let day_macros = daily_plan_macros(plan)

  let meals_str =
    list.index_map(plan.meals, fn(meal, i) {
      format_meal_entry(meal, i, start_hour)
    })
    |> string.join("\n")

  "--- "
  <> plan.day_name
  <> " ---\n"
  <> "Day Total: "
  <> macros_to_string(day_macros)
  <> "\n"
  <> meals_str
}

/// Format weekly plan header with user profile and daily targets
pub fn format_weekly_plan_header(profile: UserProfile) -> String {
  "=== Weekly Meal Plan ===\n"
  <> "Profile: "
  <> user_profile_header_line(profile)
}

/// Format the single line with profile info for the header
fn user_profile_header_line(profile: UserProfile) -> String {
  let protein = float_to_int_rounded(daily_protein_target(profile))
  let fat = float_to_int_rounded(daily_fat_target(profile))
  let carbs = float_to_int_rounded(daily_carb_target(profile))

  float_to_int_rounded_string(profile.bodyweight)
  <> " lbs, "
  <> activity_level_to_display_string(profile.activity_level)
  <> ", "
  <> goal_to_display_string(profile.goal)
  <> "\n"
  <> "Daily Targets: "
  <> "P:"
  <> int.to_string(protein)
  <> "g F:"
  <> int.to_string(fat)
  <> "g C:"
  <> int.to_string(carbs)
  <> "g"
}

/// Helper: Round float to nearest integer
fn float_to_int_rounded(f: Float) -> Int {
  float.round(f)
}

/// Helper: Format rounded float as string
fn float_to_int_rounded_string(f: Float) -> String {
  int.to_string(float_to_int_rounded(f))
}
