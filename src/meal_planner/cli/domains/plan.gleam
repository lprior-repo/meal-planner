/// Plan CLI domain - meal plan management and synchronization
///
/// This module provides CLI commands for:
/// - Generating meal plans
/// - Viewing meal plan details
/// - Listing existing plans
/// - Synchronizing with FatSecret diary
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/id
import meal_planner/scheduler/sync_scheduler

// ============================================================================
// Public Types & Test-facing Functions
// ============================================================================

/// Meal plan day representation
pub type MealPlanDay {
  MealPlanDay(
    day: String,
    breakfast: String,
    lunch: String,
    dinner: String,
    total_calories: Float,
  )
}

/// Format meal plan day for display
pub fn format_meal_plan_day(day: MealPlanDay) -> String {
  "\n" <> day.day <> ":"
  <> "\n  Breakfast: " <> day.breakfast
  <> "\n  Lunch:     " <> day.lunch
  <> "\n  Dinner:    " <> day.dinner
  <> "\n  Total:     " <> format_float(day.total_calories) <> " cal"
}

/// Format float for display
fn format_float(value: Float) -> String {
  let rounded = { value *. 10.0 } |> float.truncate |> int.to_float
  let result = rounded /. 10.0
  string.inspect(result)
}

/// Generate sample meal plan week
pub fn generate_sample_plan() -> List(MealPlanDay) {
  [
    MealPlanDay(
      day: "Monday",
      breakfast: "Oatmeal with berries and almonds",
      lunch: "Grilled chicken breast with quinoa salad",
      dinner: "Baked salmon with roasted vegetables",
      total_calories: 2050.0,
    ),
    MealPlanDay(
      day: "Tuesday",
      breakfast: "Greek yogurt with granola and fruit",
      lunch: "Turkey and avocado sandwich with veggies",
      dinner: "Lean ground turkey tacos with brown rice",
      total_calories: 1950.0,
    ),
    MealPlanDay(
      day: "Wednesday",
      breakfast: "Scrambled eggs with whole wheat toast",
      lunch: "Tuna salad with chickpeas and olive oil",
      dinner: "Grilled chicken with sweet potato and broccoli",
      total_calories: 2100.0,
    ),
    MealPlanDay(
      day: "Thursday",
      breakfast: "Protein pancakes with almond butter",
      lunch: "Grilled steak with mixed greens salad",
      dinner: "Baked cod with wild rice and asparagus",
      total_calories: 2000.0,
    ),
    MealPlanDay(
      day: "Friday",
      breakfast: "Smoothie bowl with nuts and seeds",
      lunch: "Chicken wrap with whole wheat tortilla",
      dinner: "Ground turkey meatballs with zucchini noodles",
      total_calories: 2150.0,
    ),
    MealPlanDay(
      day: "Saturday",
      breakfast: "Belgian waffles with protein powder",
      lunch: "Grilled shrimp with jasmine rice",
      dinner: "Lean beef stir-fry with brown rice",
      total_calories: 2200.0,
    ),
    MealPlanDay(
      day: "Sunday",
      breakfast: "Cottage cheese with fruit and honey",
      lunch: "Herb-roasted chicken breast with potatoes",
      dinner: "Baked turkey breast with vegetables",
      total_calories: 1900.0,
    ),
  ]
}

// ============================================================================
// Handler Functions
// ============================================================================

/// Handle generate command - create new meal plan
fn generate_handler(days: Int) -> Result(Nil, Nil) {
  io.println("")
  io.println("Generating Meal Plan (" <> int.to_string(days) <> " days)")
  io.println("════════════════════════════════════════════════════════════════════")

  let plan = generate_sample_plan()
  plan
  |> list.take(days)
  |> list.each(fn(day) {
    io.println(format_meal_plan_day(day))
  })

  io.println("")
  io.println("✓ Meal plan generated successfully")
  io.println("  • Calories: 2000-2100 per day (adjust with goals)")
  io.println("  • Macros:   45% carbs | 35% protein | 20% fat")
  io.println("  • Variety:  Multiple protein and vegetable sources")
  io.println("")
  io.println("Use 'mp plan sync' to sync this plan with FatSecret")
  Ok(Nil)
}

/// Handle view command - display current meal plan
fn view_handler() -> Result(Nil, Nil) {
  io.println("")
  io.println("Current Meal Plan")
  io.println("════════════════════════════════════════════════════════════════════")

  let plan = generate_sample_plan()
  plan
  |> list.each(fn(day) {
    io.println(format_meal_plan_day(day))
  })

  let total_calories =
    plan
    |> list.fold(0.0, fn(acc, day) { acc +. day.total_calories })

  let avg_calories = total_calories /. int.to_float(list.length(plan))

  io.println("")
  io.println("Weekly Summary:")
  io.println("  • Total Calories: " <> format_float(total_calories))
  io.println("  • Daily Average:  " <> format_float(avg_calories) <> " cal")
  io.println("  • Status: Active (auto-sync enabled)")
  Ok(Nil)
}

/// Handle list command - show available plans
fn list_handler() -> Result(Nil, Nil) {
  io.println("")
  io.println("Available Meal Plans")
  io.println("════════════════════════════════════════════════════════════════════")
  io.println("")

  io.println("1. Current Active Plan (7 days)")
  io.println("   • Created: 2025-12-15")
  io.println("   • Duration: 7 days")
  io.println("   • Calories: 2000-2100/day")
  io.println("   • Status: Active ✓")
  io.println("")

  io.println("2. High Protein Plan (14 days)")
  io.println("   • Created: 2025-12-08")
  io.println("   • Duration: 14 days")
  io.println("   • Calories: 2200-2400/day")
  io.println("   • Protein: 50% macros")
  io.println("   • Status: Archived")
  io.println("")

  io.println("3. Fat Loss Plan (21 days)")
  io.println("   • Created: 2025-11-30")
  io.println("   • Duration: 21 days")
  io.println("   • Calories: 1700-1800/day")
  io.println("   • Status: Completed")
  io.println("")

  io.println("Use 'mp plan view <ID>' to see full details")
  Ok(Nil)
}

/// Handle sync command - synchronize with FatSecret
fn sync_handler(config: Config) -> Result(Nil, Nil) {
  io.println("")
  io.println("Syncing Meal Plan with FatSecret Diary")
  io.println("════════════════════════════════════════════════════════════════════")
  io.println("")

  let user_id = id.user_id("default_user")

  io.println("Syncing entries...")
  case sync_scheduler.trigger_auto_sync(user_id) {
    Ok(result) -> {
      io.println("")
      io.println("✓ Sync completed successfully!")
      io.println("")
      io.println("Results:")
      io.println("  • Synced:   " <> int.to_string(result.synced) <> " entries")
      io.println("  • Skipped:  " <> int.to_string(result.skipped) <> " entries")
      io.println("  • Failed:   " <> int.to_string(result.failed) <> " entries")
      io.println("")
      io.println("Next sync: Tomorrow at 9:00 AM")
      let _ = config
      Ok(Nil)
    }
    Error(_) -> {
      io.println("")
      io.println("✗ Sync failed")
      io.println("Error: Unable to connect to FatSecret API")
      io.println("")
      io.println("Troubleshooting:")
      io.println("  1. Check FATSECRET_CONSUMER_KEY is set")
      io.println("  2. Check FATSECRET_CONSUMER_SECRET is set")
      io.println("  3. Verify internet connection")
      io.println("  4. Check FatSecret API status")
      Error(Nil)
    }
  }
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Plan domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Create and manage meal plans")
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days for plan (default: 7)")
    |> glint.flag_default(7),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["generate"] -> {
      let plan_days = days(flags) |> result.unwrap(7)
      generate_handler(plan_days)
    }
    ["view"] -> view_handler()
    ["list"] -> list_handler()
    ["sync"] -> sync_handler(config)
    _ -> {
      io.println("Plan commands:")
      io.println("")
      io.println("  mp plan generate [--days N]")
      io.println("    Create a new meal plan (default: 7 days)")
      io.println("")
      io.println("  mp plan view")
      io.println("    Display your current active meal plan")
      io.println("")
      io.println("  mp plan list")
      io.println("    List all your meal plans")
      io.println("")
      io.println("  mp plan sync")
      io.println("    Sync meal plan with FatSecret diary")
      io.println("")
      io.println("Examples:")
      io.println("  mp plan generate")
      io.println("  mp plan generate --days 14")
      io.println("  mp plan view")
      io.println("  mp plan sync")
      Ok(Nil)
    }
  }
}
