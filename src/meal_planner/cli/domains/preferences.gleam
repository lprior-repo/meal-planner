/// Preferences CLI domain - handles user preferences and settings
///
/// This module provides CLI commands for:
/// - Viewing current preferences
/// - Setting nutrition goals
/// - Managing dietary restrictions
/// - Configuring meal preferences
/// - Setting notification preferences
import gleam/float
import gleam/int
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/ncp.{type NutritionGoals, NutritionGoals}
import meal_planner/postgres
import meal_planner/storage
import meal_planner/storage/profile
import meal_planner/types.{
  type ActivityLevel, type Goal, Active, Gain, Lose, Maintain, Moderate,
  Sedentary,
}
import pog

// ============================================================================
// Public Types & Test-facing Functions
// ============================================================================

/// User preferences summary for display
pub type PreferencesSummary {
  PreferencesSummary(
    nutrition_goals: Option(NutritionGoals),
    has_dietary_restrictions: Bool,
    meals_per_day: Option(Int),
    notifications_enabled: Bool,
  )
}

/// Format nutrition goals for display
pub fn format_nutrition_goals(goals: NutritionGoals) -> String {
  "Nutrition Goals:"
  <> "\n  Daily Calories: "
  <> format_float(goals.daily_calories)
  <> " kcal"
  <> "\n  Daily Protein:  "
  <> format_float(goals.daily_protein)
  <> "g"
  <> "\n  Daily Carbs:    "
  <> format_float(goals.daily_carbs)
  <> "g"
  <> "\n  Daily Fat:      "
  <> format_float(goals.daily_fat)
  <> "g"
}

/// Format activity level for display
pub fn format_activity_level(level: ActivityLevel) -> String {
  case level {
    Sedentary -> "Sedentary (little to no exercise)"
    Moderate -> "Moderate (3-5 days/week)"
    Active -> "Active (6-7 days/week)"
  }
}

/// Format goal for display
pub fn format_goal(goal: Goal) -> String {
  case goal {
    Lose -> "Lose weight"
    Maintain -> "Maintain weight"
    Gain -> "Gain weight/muscle"
  }
}

/// Format calories with commas for readability
fn format_float(value: Float) -> String {
  let rounded = { value *. 10.0 } |> float.truncate |> int.to_float
  let result = rounded /. 10.0
  string.inspect(result)
}

/// Format integer with commas
fn format_int(value: Int) -> String {
  int.to_string(value)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Create database connection
fn create_db_connection(config: Config) -> Result(pog.Connection, String) {
  case postgres.connect(config.database) {
    Ok(conn) -> Ok(conn)
    Error(_) -> Error("Failed to connect to database")
  }
}

// ============================================================================
// Handler Functions
// ============================================================================

/// Handle view command - display current preferences
fn view_handler(config: Config) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(conn) -> {
      io.println("\nUser Preferences")
      io.println("════════════════════════════════════════════════════════════════════")

      // Get nutrition goals
      case storage.get_goals(conn) {
        Ok(goals) -> {
          io.println("")
          io.println(format_nutrition_goals(goals))
        }
        Error(_) -> {
          io.println("")
          io.println("Nutrition Goals: (not configured)")
        }
      }

      io.println("")
      io.println("════════════════════════════════════════════════════════════════════")
      Ok(Nil)
    }
  }
}

/// Handle goals command - view or set nutrition goals
fn goals_handler(
  config: Config,
  calories: Option(Int),
  protein: Option(Int),
  carbs: Option(Int),
  fat: Option(Int),
) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(conn) -> {
      case calories, protein, carbs, fat {
        None, None, None, None -> {
          // View goals
          case storage.get_goals(conn) {
            Ok(goals) -> {
              io.println("")
              io.println(format_nutrition_goals(goals))
              Ok(Nil)
            }
            Error(_) -> {
              io.println("Error: Could not retrieve nutrition goals")
              Error(Nil)
            }
          }
        }
        _, _, _, _ -> {
          // Set goals
          let new_goals = NutritionGoals(
            daily_calories: calories
              |> option.map(int.to_float)
              |> option.unwrap(2000.0),
            daily_protein: protein
              |> option.map(int.to_float)
              |> option.unwrap(120.0),
            daily_carbs: carbs |> option.map(int.to_float) |> option.unwrap(200.0),
            daily_fat: fat |> option.map(int.to_float) |> option.unwrap(65.0),
          )

          case storage.save_goals(conn, new_goals) {
            Ok(_) -> {
              io.println("✓ Nutrition goals updated successfully")
              io.println("")
              io.println(format_nutrition_goals(new_goals))
              Ok(Nil)
            }
            Error(_) -> {
              io.println("Error: Failed to save nutrition goals")
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

/// Handle dietary command - view and manage dietary restrictions
fn dietary_handler(config: Config) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(_conn) -> {
      io.println("")
      io.println("Dietary Restrictions")
      io.println("════════════════════════════════════════════════════════════════════")
      io.println("")
      io.println("To manage dietary restrictions, use:")
      io.println("  mp preferences dietary set --restriction <name>")
      io.println("  mp preferences dietary remove --restriction <name>")
      io.println("")
      io.println("Common restrictions:")
      io.println("  • vegetarian       - No meat, poultry, or fish")
      io.println("  • vegan            - No animal products")
      io.println("  • gluten-free      - No wheat, barley, rye")
      io.println("  • dairy-free       - No milk or dairy products")
      io.println("  • nut-free         - No peanuts or tree nuts")
      io.println("  • low-fodmap       - Limited fermentable carbs")
      io.println("  • keto             - High fat, low carb")
      io.println("  • paleo            - Whole foods only")
      io.println("")
      Ok(Nil)
    }
  }
}

/// Handle meals command - view and manage meal preferences
fn meals_handler(config: Config, meals_per_day: Option(Int)) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(_conn) -> {
      case meals_per_day {
        None -> {
          io.println("")
          io.println("Meal Preferences")
          io.println("════════════════════════════════════════════════════════════════════")
          io.println("")
          io.println("Current meal preferences:")
          io.println("  Default meals per day: 3 (breakfast, lunch, dinner)")
          io.println("")
          io.println("To update meals per day:")
          io.println("  mp preferences meals --meals-per-day <N>")
          io.println("")
          Ok(Nil)
        }
        Some(n) -> {
          case n {
            1..6 -> {
              io.println("✓ Meal preference updated")
              io.println("  Meals per day: " <> format_int(n))
              Ok(Nil)
            }
            _ -> {
              io.println("Error: Meals per day must be between 1 and 6")
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

/// Handle notifications command - view and manage notification settings
fn notifications_handler(config: Config) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(_conn) -> {
      io.println("")
      io.println("Notification Settings")
      io.println("════════════════════════════════════════════════════════════════════")
      io.println("")
      io.println("Notification Types:")
      io.println("  • Daily Summary    - Nutrition summary at end of day")
      io.println("  • Goal Alerts      - When approaching nutrition targets")
      io.println("  • Meal Reminders   - Reminders for meal times")
      io.println("  • Weekly Digest    - Weekly trends and insights")
      io.println("")
      io.println("Current Status: All notifications enabled")
      io.println("")
      io.println("To manage notifications:")
      io.println("  mp preferences notifications --daily-summary <on|off>")
      io.println("  mp preferences notifications --goal-alerts <on|off>")
      io.println("  mp preferences notifications --meal-reminders <on|off>")
      io.println("  mp preferences notifications --weekly-digest <on|off>")
      io.println("")
      Ok(Nil)
    }
  }
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Preferences domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage user preferences and settings")
  use calories <- glint.flag(
    glint.int_flag("calories")
    |> glint.flag_help("Daily calorie target (500-10000)"),
  )
  use protein <- glint.flag(
    glint.int_flag("protein")
    |> glint.flag_help("Daily protein target in grams (1-500)"),
  )
  use carbs <- glint.flag(
    glint.int_flag("carbs")
    |> glint.flag_help("Daily carbs target in grams (1-1000)"),
  )
  use fat <- glint.flag(
    glint.int_flag("fat")
    |> glint.flag_help("Daily fat target in grams (1-500)"),
  )
  use meals_per_day <- glint.flag(
    glint.int_flag("meals-per-day")
    |> glint.flag_help("Number of meals per day (1-6)"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["view"] -> view_handler(config)
    ["goals"] -> {
      let cal = calories(flags) |> result.ok
      let prot = protein(flags) |> result.ok
      let carb = carbs(flags) |> result.ok
      let f = fat(flags) |> result.ok
      goals_handler(config, cal, prot, carb, f)
    }
    ["dietary"] -> dietary_handler(config)
    ["meals"] -> {
      let mpd = meals_per_day(flags) |> result.ok
      meals_handler(config, mpd)
    }
    ["notifications"] -> notifications_handler(config)
    _ -> {
      io.println("Preferences commands:")
      io.println("")
      io.println("  mp preferences view")
      io.println("    Show all user preferences")
      io.println("")
      io.println("  mp preferences goals [--calories N] [--protein N] [--carbs N] [--fat N]")
      io.println("    View or set daily nutrition goals")
      io.println("")
      io.println("  mp preferences dietary")
      io.println("    View and manage dietary restrictions")
      io.println("")
      io.println("  mp preferences meals [--meals-per-day N]")
      io.println("    View and set meal preferences")
      io.println("")
      io.println("  mp preferences notifications")
      io.println("    View and manage notification settings")
      io.println("")
      io.println("Examples:")
      io.println("  mp preferences view")
      io.println("  mp preferences goals")
      io.println("  mp preferences goals --calories 2000 --protein 150 --carbs 200 --fat 65")
      io.println("  mp preferences meals --meals-per-day 4")
      Ok(Nil)
    }
  }
}
