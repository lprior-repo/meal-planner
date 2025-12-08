/// Output formatting functions for meal plans and recipes
///
/// Provides text formatting for terminal display and email output.
/// Note: Most formatting logic has been moved to the data types to avoid
/// feature envy. This module now coordinates higher-level output.
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import meal_planner/env.{type RequiredVars}
import meal_planner/meal_plan.{
  type DailyPlan, type Meal, type WeeklyMealPlan, daily_plan_macros,
  format_daily_plan, format_meal_timing, format_portion,
  format_weekly_plan_header, meal_macros, weekly_plan_macros,
}
import meal_planner/shopping_list.{
  type CategorizedShoppingList, organize_shopping_list,
}
import meal_planner/types.{
  type Ingredient, type Macros, type Recipe, type UserProfile, Macros,
  daily_calorie_target, ingredient_to_shopping_list_line,
  is_vertical_diet_compliant, macros_calories, macros_to_string,
  macros_to_string_with_calories, recipe_to_display_string,
  user_profile_to_display_string,
}

/// Format macros as a compact string (e.g., "P:40g F:20g C:30g")
/// Delegates to types.macros_to_string
pub fn format_macros(m: Macros) -> String {
  macros_to_string(m)
}

/// Format macros with calories
/// Delegates to types.macros_to_string_with_calories
pub fn format_macros_with_calories(m: Macros) -> String {
  macros_to_string_with_calories(m)
}

/// Format a recipe for display
/// Delegates to types.recipe_to_display_string
pub fn format_recipe(recipe: Recipe) -> String {
  recipe_to_display_string(recipe)
}

/// Format user profile with calculated targets
/// Delegates to types.user_profile_to_display_string
pub fn format_user_profile(profile: UserProfile) -> String {
  user_profile_to_display_string(profile)
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
        list.map(items, ingredient_to_shopping_list_line)
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

/// Format weekly summary
fn format_weekly_summary(plan: WeeklyMealPlan) -> String {
  let total = weekly_plan_macros(plan)
  // Count days efficiently
  let days_count = list.fold(plan.days, 0, fn(acc, _) { acc + 1 })
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

// Helper functions for float conversion (these are now in types.gleam as well)

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

  // Count total and compliant recipes in one pass
  let #(total_count, compliant_count) =
    list.fold(recipes, #(0, 0), fn(acc, recipe) {
      let is_compliant = case is_vertical_diet_compliant(recipe) {
        True -> 1
        False -> 0
      }
      #(acc.0 + 1, acc.1 + is_compliant)
    })

  io.println("Total Recipes: " <> int.to_string(total_count))

  let compliance_rate = case total_count {
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
  io.println("Non-Compliant: " <> int.to_string(total_count - compliant_count))
  io.println("==== END AUDIT ====")
}

/// Convert float to string
fn float_to_string(f: Float) -> String {
  float.to_string(f)
}
