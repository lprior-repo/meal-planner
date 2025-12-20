/// Diary CLI domain - handles FatSecret food diary management
///
/// This module provides CLI commands for:
/// - Viewing daily food logs
/// - Adding meals to diary
/// - Deleting entries
/// - Viewing meal history
import birl
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/fatsecret/diary/service as diary_service
import meal_planner/fatsecret/diary/types as diary_types
import meal_planner/fatsecret/diary/types.{
  type FoodEntry, type MealType, Breakfast, Dinner, Lunch, Snack,
}
import meal_planner/postgres
import pog

// ============================================================================
// Public API - Test-facing Functions
// ============================================================================

/// Format a food entry for display in a table row
///
/// Formats a FoodEntry into a readable string with ID, name, meal type,
/// calories, and macro breakdown.
pub fn format_food_entry_row(entry: FoodEntry) -> String {
  let FoodEntry(
    food_entry_id,
    food_entry_name,
    _food_entry_description,
    _food_id,
    _serving_id,
    _meal,
    _date_int,
    calories,
    protein,
    carbohydrates,
    fat,
  ) = entry

  let id_str = entry.food_entry_id |> diary_types.food_entry_id_to_string
  let cal_str = format_float(calories)
  let protein_str = format_float(protein)
  let carb_str = format_float(carbohydrates)
  let fat_str = format_float(fat)

  "  ["
  <> id_str
  <> "] "
  <> food_entry_name
  <> " | "
  <> cal_str
  <> "cal | P:"
  <> protein_str
  <> "g C:"
  <> carb_str
  <> "g F:"
  <> fat_str
  <> "g"
}

/// Calculate total nutrition for a list of entries
///
/// Sums calories, protein, carbs, and fat across all entries.
pub type DayNutrition {
  DayNutrition(
    calories: Float,
    protein: Float,
    carbohydrates: Float,
    fat: Float,
  )
}

pub fn calculate_day_nutrition(entries: List(FoodEntry)) -> DayNutrition {
  entries
  |> list.fold(
    DayNutrition(calories: 0.0, protein: 0.0, carbohydrates: 0.0, fat: 0.0),
    fn(acc, entry) {
      let FoodEntry(
        _,
        _,
        _,
        _,
        _,
        _,
        _,
        calories,
        protein,
        carbohydrates,
        fat,
      ) = entry
      DayNutrition(
        calories: acc.calories +. calories,
        protein: acc.protein +. protein,
        carbohydrates: acc.carbohydrates +. carbohydrates,
        fat: acc.fat +. fat,
      )
    },
  )
}

/// Format nutrition summary for display
///
/// Returns a formatted string showing total calories and macros.
pub fn format_nutrition_summary(nutrition: DayNutrition) -> String {
  "═══════════════════════════════════════════════════════════════════"
  <> "\nDailyTotal: "
  <> format_float(nutrition.calories)
  <> "cal | P:"
  <> format_float(nutrition.protein)
  <> "g C:"
  <> format_float(nutrition.carbohydrates)
  <> "g F:"
  <> format_float(nutrition.fat)
  <> "g"
}

/// Parse a date string (YYYY-MM-DD) to days since Unix epoch
///
/// Returns Option(Int) - None if parse fails.
pub fn parse_date_to_int(date_str: String) -> Option(Int) {
  case date_str {
    "today" -> {
      let now = birl.now()
      let today_midnight =
        now
        |> birl.set_time_of_day(0, 0, 0, 0)
      let epoch = birl.from_unix(0)
      let days =
        birl.difference(today_midnight, epoch)
        |> birl.duration_to_seconds
        |> int.divide(86400)
      case days {
        Ok(d) -> Some(d)
        Error(_) -> None
      }
    }
    _ -> {
      // Try to parse YYYY-MM-DD format
      case string.split(date_str, "-") {
        [year_str, month_str, day_str] -> {
          case
            int.parse(year_str),
            int.parse(month_str),
            int.parse(day_str),
          {
            Ok(year), Ok(month), Ok(day) -> {
              // Create a date and convert to days since epoch
              case birl.from_iso8601(date_str <> "T00:00:00Z") {
                Ok(dt) -> {
                  let epoch = birl.from_unix(0)
                  let days_duration =
                    birl.difference(dt, epoch)
                    |> birl.duration_to_seconds
                    |> int.divide(86400)
                  case days_duration {
                    Ok(d) -> Some(d)
                    Error(_) -> None
                  }
                }
                Error(_) -> None
              }
            }
            _, _, _ -> None
          }
        }
        _ -> None
      }
    }
  }
}

/// Format a float to 1 decimal place for display
fn format_float(value: Float) -> String {
  let rounded = { value *. 10.0 } |> float.truncate |> int.to_float
  let result = rounded /. 10.0
  string.inspect(result)
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

/// Format meal type for display
fn format_meal_type(meal: MealType) -> String {
  case meal {
    Breakfast -> "Breakfast"
    Lunch -> "Lunch"
    Dinner -> "Dinner"
    Snack -> "Snack"
  }
}

// ============================================================================
// Handler Functions
// ============================================================================

/// Handle view command - display food entries for a specific date
fn view_handler(config: Config, date_str: String) -> Result(Nil, Nil) {
  case parse_date_to_int(date_str) {
    None -> {
      io.println("Error: Invalid date format. Use YYYY-MM-DD or 'today'")
      Error(Nil)
    }
    Some(date_int) -> {
      case create_db_connection(config) {
        Error(err) -> {
          io.println("Error: " <> err)
          Error(Nil)
        }
        Ok(conn) -> {
          case diary_service.get_day_entries(conn, date_int) {
            Ok(entries) -> {
              io.println("\nFatSecret Food Diary - " <> date_str)
              io.println(
                "═══════════════════════════════════════════════════════════════════",
              )

              case entries {
                [] -> {
                  io.println("(No entries for this date)")
                }
                _ -> {
                  entries
                  |> list.each(fn(entry) {
                    io.println(format_food_entry_row(entry))
                  })
                }
              }

              let nutrition = calculate_day_nutrition(entries)
              io.println(format_nutrition_summary(nutrition))
              Ok(Nil)
            }
            Error(diary_service.NotConfigured) -> {
              io.println("Error: FatSecret is not configured")
              io.println("Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET")
              Error(Nil)
            }
            Error(diary_service.AuthRevoked) -> {
              io.println("Error: FatSecret authentication has been revoked")
              io.println("Please re-authorize the application")
              Error(Nil)
            }
            Error(diary_service.NotConnected) -> {
              io.println("Error: Could not retrieve FatSecret authentication")
              Error(Nil)
            }
            Error(_) -> {
              io.println("Error: Failed to retrieve diary entries")
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

/// Handle delete command - remove a food entry from diary
fn delete_handler(config: Config, entry_id_str: String) -> Result(Nil, Nil) {
  case create_db_connection(config) {
    Error(err) -> {
      io.println("Error: " <> err)
      Error(Nil)
    }
    Ok(conn) -> {
      let entry_id = diary_types.food_entry_id(entry_id_str)
      case diary_service.delete_food_entry(conn, entry_id) {
        Ok(_) -> {
          io.println("✓ Food entry deleted successfully")
          Ok(Nil)
        }
        Error(diary_service.NotConfigured) -> {
          io.println("Error: FatSecret is not configured")
          Error(Nil)
        }
        Error(diary_service.AuthRevoked) -> {
          io.println("Error: FatSecret authentication has been revoked")
          Error(Nil)
        }
        Error(_) -> {
          io.println("Error: Failed to delete entry: " <> entry_id_str)
          Error(Nil)
        }
      }
    }
  }
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Diary domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage FatSecret food diary entries")
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Date for diary (YYYY-MM-DD or 'today')")
    |> glint.flag_default("today"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["view"] -> {
      let diary_date = date(flags) |> result.unwrap("today")
      view_handler(config, diary_date)
    }
    ["delete", entry_id] -> {
      delete_handler(config, entry_id)
    }
    _ -> {
      io.println("Diary commands:")
      io.println("")
      io.println("  mp diary view [--date YYYY-MM-DD]")
      io.println("    Display food entries for a specific date (default: today)")
      io.println("")
      io.println("  mp diary delete <ENTRY_ID>")
      io.println("    Remove a food entry from the diary")
      io.println("")
      io.println("Examples:")
      io.println("  mp diary view")
      io.println("  mp diary view --date 2025-12-20")
      io.println("  mp diary delete 12345")
      Ok(Nil)
    }
  }
}
