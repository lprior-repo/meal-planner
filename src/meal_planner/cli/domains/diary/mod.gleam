/// Diary CLI domain - main entry point and command registration
///
/// This module provides the main entry point for diary CLI commands.
/// It registers all diary subcommands with Glint and routes to appropriate handlers.
///
/// Available commands:
/// - view: Display food entries for a specific date
/// - add: Add a food entry to the diary
/// - delete: Remove a food entry from the diary
/// - sync: Sync recipes between Tandoor and FatSecret
import gleam/io
import gleam/result
import glint
import meal_planner/cli/domains/diary/commands/add
import meal_planner/cli/domains/diary/commands/delete
import meal_planner/cli/domains/diary/commands/sync
import meal_planner/cli/domains/diary/commands/view
import meal_planner/config.{type Config}

/// Diary domain command for Glint CLI
///
/// Registers all diary subcommands and handles routing to appropriate handlers.
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage FatSecret food diary entries")
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Date for diary (YYYY-MM-DD or 'today')")
    |> glint.flag_default("today"),
  )
  use meal_type <- glint.flag(
    glint.string_flag("meal-type")
    |> glint.flag_help("Meal type (breakfast, lunch, dinner, snack)")
    |> glint.flag_default("lunch"),
  )
  use servings <- glint.flag(
    glint.string_flag("servings")
    |> glint.flag_help("Number of servings")
    |> glint.flag_default("1.0"),
  )
  use start_date <- glint.flag(
    glint.string_flag("start-date")
    |> glint.flag_help("Start date for sync (YYYY-MM-DD)"),
  )
  use end_date <- glint.flag(
    glint.string_flag("end-date")
    |> glint.flag_help("End date for sync (YYYY-MM-DD)"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["view"] -> {
      let diary_date = date(flags) |> result.unwrap("today")
      view.view_handler(config, diary_date)
    }
    ["add", food_name] -> {
      let diary_date = date(flags) |> result.unwrap("today")
      let meal_type_str = meal_type(flags) |> result.unwrap("lunch")
      let servings_str = servings(flags) |> result.unwrap("1.0")
      add.add_handler(
        config,
        food_name,
        diary_date,
        meal_type_str,
        servings_str,
      )
    }
    ["delete", entry_id] -> {
      delete.delete_handler(config, entry_id)
    }
    ["sync", "to-tandoor"] -> {
      case start_date(flags), end_date(flags) {
        Ok(start), Ok(end) -> sync.sync_to_tandoor_handler(config, start, end)
        _, _ -> {
          io.println("Error: Both --start-date and --end-date are required")
          io.println(
            "Usage: mp diary sync to-tandoor --start-date YYYY-MM-DD --end-date YYYY-MM-DD",
          )
          Error(Nil)
        }
      }
    }
    ["sync", "from-fatsecret"] -> {
      case start_date(flags), end_date(flags) {
        Ok(start), Ok(end) ->
          sync.sync_from_fatsecret_handler(config, start, end)
        _, _ -> {
          io.println("Error: Both --start-date and --end-date are required")
          io.println(
            "Usage: mp diary sync from-fatsecret --start-date YYYY-MM-DD --end-date YYYY-MM-DD",
          )
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("Diary commands:")
      io.println("")
      io.println("  mp diary view [--date YYYY-MM-DD]")
      io.println(
        "    Display food entries for a specific date (default: today)",
      )
      io.println("")
      io.println(
        "  mp diary add <FOOD_NAME> [--date YYYY-MM-DD] [--meal-type lunch] [--servings 1.0]",
      )
      io.println("    Add a food entry to the diary by searching FatSecret")
      io.println("")
      io.println("  mp diary delete <ENTRY_ID>")
      io.println("    Remove a food entry from the diary")
      io.println("")
      io.println(
        "  mp diary sync to-tandoor --start-date YYYY-MM-DD --end-date YYYY-MM-DD",
      )
      io.println("    Sync FatSecret diary to Tandoor meal plan")
      io.println("")
      io.println(
        "  mp diary sync from-fatsecret --start-date YYYY-MM-DD --end-date YYYY-MM-DD",
      )
      io.println("    Sync Tandoor meal plan to FatSecret diary")
      io.println("")
      io.println("Examples:")
      io.println("  mp diary view")
      io.println("  mp diary view --date 2025-12-20")
      io.println(
        "  mp diary add \"Chicken Breast\" --date 2025-12-24 --meal-type lunch --servings 1.5",
      )
      io.println("  mp diary delete 12345")
      io.println(
        "  mp diary sync to-tandoor --start-date 2025-12-20 --end-date 2025-12-25",
      )
      Ok(Nil)
    }
  }
}
