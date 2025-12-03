/// Output formatting functions for meal plans and recipes
///
/// Provides text formatting for terminal display and email output.
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import meal_planner/env.{type RequiredVars}
import meal_planner/meal_plan.{
  type DailyPlan, type Meal, type WeeklyMealPlan, daily_plan_macros, meal_macros,
  weekly_plan_macros,
}
import meal_planner/shopping_list.{
  type CategorizedShoppingList, organize_shopping_list,
}
import meal_planner/types.{
  type ActivityLevel, type Goal, type Ingredient, type Macros, type Recipe,
  type UserProfile, Active, Gain, Lose, Macros, Maintain, Moderate, Sedentary,
  daily_calorie_target, daily_carb_target, daily_fat_target,
  daily_protein_target, is_vertical_diet_compliant, macros_calories,
}

/// Format macros as a compact string (e.g., "P:40g F:20g C:30g")
pub fn format_macros(m: Macros) -> String {
  let p = float.round(m.protein)
  let f = float.round(m.fat)
  let c = float.round(m.carbs)

  "P:"
  <> int.to_string(p)
  <> "g F:"
  <> int.to_string(f)
  <> "g C:"
  <> int.to_string(c)
  <> "g"
}

/// Format macros with calories
pub fn format_macros_with_calories(m: Macros) -> String {
  let cal = float.round(macros_calories(m))
  format_macros(m) <> " (" <> int.to_string(cal) <> " cal)"
}

/// Format a recipe for display
pub fn format_recipe(recipe: Recipe) -> String {
  let ingredients_str =
    list.map(recipe.ingredients, fn(ing) {
      "  - " <> ing.name <> ": " <> ing.quantity
    })
    |> string.join("\n")

  let instructions_str =
    list.index_map(recipe.instructions, fn(inst, i) {
      "  " <> int.to_string(i + 1) <> ". " <> inst
    })
    |> string.join("\n")

  recipe.name
  <> "\n"
  <> "Macros: "
  <> format_macros(recipe.macros)
  <> "\n\n"
  <> "Ingredients:\n"
  <> ingredients_str
  <> "\n\n"
  <> "Instructions:\n"
  <> instructions_str
}

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

/// Format activity level as string
fn format_activity_level(level: ActivityLevel) -> String {
  case level {
    Sedentary -> "Sedentary"
    Moderate -> "Moderate"
    Active -> "Active"
  }
}

/// Format goal as string
fn format_goal(goal: Goal) -> String {
  case goal {
    Gain -> "Gain"
    Maintain -> "Maintain"
    Lose -> "Lose"
  }
}

/// Format user profile with calculated targets
pub fn format_user_profile(profile: UserProfile) -> String {
  let protein = float.round(daily_protein_target(profile))
  let fat = float.round(daily_fat_target(profile))
  let carbs = float.round(daily_carb_target(profile))
  let calories = float.round(daily_calorie_target(profile))

  "==== YOUR VERTICAL DIET PROFILE ====\n"
  <> "Bodyweight: "
  <> float_to_string_rounded(profile.bodyweight)
  <> " lbs\n"
  <> "Activity Level: "
  <> format_activity_level(profile.activity_level)
  <> "\n"
  <> "Goal: "
  <> format_goal(profile.goal)
  <> "\n"
  <> "Meals per Day: "
  <> int.to_string(profile.meals_per_day)
  <> "\n\n"
  <> "--- Daily Macro Targets ---\n"
  <> "Calories: "
  <> int.to_string(calories)
  <> "\n"
  <> "Protein: "
  <> int.to_string(protein)
  <> "g\n"
  <> "Fat: "
  <> int.to_string(fat)
  <> "g\n"
  <> "Carbs: "
  <> int.to_string(carbs)
  <> "g\n"
  <> "===================================="
}

/// Format a daily meal plan
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
  <> format_macros(day_macros)
  <> "\n"
  <> meals_str
}

/// Format a single meal entry with timing
fn format_meal_entry(meal: Meal, index: Int, start_hour: Int) -> String {
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
  <> format_macros(macros)
}

/// Format portion size (e.g., "1.0x portion" or "1.5x")
fn format_portion(portion: Float) -> String {
  float_to_string_1dp(portion) <> "x portion"
}

/// Format categorized shopping list
pub fn format_categorized_shopping_list(list: CategorizedShoppingList) -> String {
  let sections = [
    format_category_section("Protein", list.protein),
    format_category_section("Dairy", list.dairy),
    format_category_section("Produce", list.produce),
    format_category_section("Grains", list.grains),
    format_category_section("Fats & Oils", list.fats),
    format_category_section("Seasonings", list.seasonings),
    format_category_section("Other", list.other),
  ]

  "=== Shopping List (by category) ==="
  <> list.filter(sections, fn(s) { s != "" })
  |> string.join("")
}

/// Format a single category section
fn format_category_section(name: String, items: List(Ingredient)) -> String {
  case items {
    [] -> ""
    _ -> {
      let items_str =
        list.map(items, fn(ing) { "    - " <> ing.name <> ": " <> ing.quantity })
        |> string.join("\n")

      "\n\n  " <> name <> ":\n" <> items_str
    }
  }
}

/// Format a complete weekly meal plan
pub fn format_weekly_plan(plan: WeeklyMealPlan) -> String {
  let header = format_weekly_plan_header(plan.user_profile)

  let days_str =
    list.map(plan.days, fn(day) { format_daily_plan(day, 7) })
    |> string.join("\n\n")

  let summary = format_weekly_summary(plan)

  let shopping = case plan.shopping_list {
    [] -> ""
    ingredients -> {
      let categorized = organize_shopping_list(ingredients)
      "\n\n" <> format_categorized_shopping_list(categorized)
    }
  }

  header <> "\n\n" <> days_str <> "\n\n" <> summary <> shopping
}

/// Format weekly plan header
fn format_weekly_plan_header(profile: UserProfile) -> String {
  "=== Weekly Meal Plan ===\n"
  <> "Profile: "
  <> float_to_string_rounded(profile.bodyweight)
  <> " lbs, "
  <> format_activity_level(profile.activity_level)
  <> ", "
  <> format_goal(profile.goal)
  <> "\n"
  <> "Daily Targets: "
  <> "P:"
  <> int.to_string(float.round(daily_protein_target(profile)))
  <> "g F:"
  <> int.to_string(float.round(daily_fat_target(profile)))
  <> "g C:"
  <> int.to_string(float.round(daily_carb_target(profile)))
  <> "g"
}

/// Format weekly summary
fn format_weekly_summary(plan: WeeklyMealPlan) -> String {
  let total = weekly_plan_macros(plan)
  let days_count = list.length(plan.days)
  let avg = case days_count {
    0 -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
    n ->
      Macros(
        protein: total.protein /. int_to_float(n),
        fat: total.fat /. int_to_float(n),
        carbs: total.carbs /. int_to_float(n),
      )
  }

  "=== Weekly Summary ===\n"
  <> "Total:     "
  <> format_macros_with_calories(total)
  <> "\n"
  <> "Daily Avg: "
  <> format_macros_with_calories(avg)
}

/// Format weekly plan for email
pub fn format_weekly_plan_email(plan: WeeklyMealPlan) -> String {
  format_weekly_plan(plan)
}

// Helper functions

/// Round a float and format as string with no decimals
fn float_to_string_rounded(f: Float) -> String {
  int.to_string(float.round(f))
}

/// Format float with 1 decimal place
fn float_to_string_1dp(f: Float) -> String {
  let whole = float.truncate(f)
  let frac = float.round({ f -. int_to_float(whole) } *. 10.0)
  int.to_string(whole) <> "." <> int.to_string(frac)
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

/// Print weekly meal plan to terminal
pub fn print_weekly_plan(plan: WeeklyMealPlan) -> Nil {
  io.println(format_weekly_plan(plan))
}

/// Send weekly meal plan via email
pub fn send_weekly_plan_email(
  plan: WeeklyMealPlan,
  config: RequiredVars,
) -> Result(Nil, String) {
  // For now, just print the email content
  io.println("=== Email Content ===")
  io.println(format_weekly_plan_email(plan))
  io.println("To: " <> config.recipient_email)
  io.println(
    "From: " <> config.sender_name <> " <" <> config.sender_email <> ">",
  )
  Ok(Nil)
}

/// Print audit report for recipes
pub fn print_audit_report(recipes: List(Recipe)) -> Nil {
  io.println("==== VERTICAL DIET RECIPE AUDIT ====")
  io.println("Total Recipes: " <> int.to_string(list.length(recipes)))

  let compliant = list.filter(recipes, is_vertical_diet_compliant)
  let compliant_count = list.length(compliant)
  let compliance_rate = case list.length(recipes) {
    0 -> 0.0
    n -> int_to_float(compliant_count) /. int_to_float(n) *. 100.0
  }

  io.println(
    "Compliant (Low-FODMAP): "
    <> int.to_string(compliant_count)
    <> " ("
    <> float_to_string(compliance_rate)
    <> "%)",
  )
  io.println(
    "Non-Compliant: " <> int.to_string(list.length(recipes) - compliant_count),
  )
  io.println("==== END AUDIT ====")
}

/// Convert float to string
fn float_to_string(f: Float) -> String {
  float.to_string(f)
}
