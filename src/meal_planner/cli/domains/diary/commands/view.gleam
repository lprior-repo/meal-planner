/// View commands for diary CLI domain
///
/// This module provides commands for viewing food diary entries.
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/cli/domains/diary/formatters
import meal_planner/cli/domains/diary/helpers
import meal_planner/cli/domains/diary/types
import meal_planner/config.{type Config}
import meal_planner/fatsecret/diary/service as diary_service

/// Handle view command - display food entries for a specific date
///
/// Displays all food entries for the given date with nutrition summary.
/// Date can be "today" or "YYYY-MM-DD" format.
pub fn view_handler(config: Config, date_str: String) -> Result(Nil, Nil) {
  case helpers.parse_date_to_int(date_str) {
    None -> {
      io.println("Error: Invalid date format. Use YYYY-MM-DD or 'today'")
      Error(Nil)
    }
    Some(date_int) -> {
      case helpers.create_db_connection(config) {
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
                    io.println(formatters.format_food_entry_row(entry))
                  })
                }
              }

              let nutrition = types.calculate_day_nutrition(entries)
              io.println(formatters.format_nutrition_summary(nutrition))
              Ok(Nil)
            }
            Error(diary_service.NotConfigured) -> {
              io.println("Error: FatSecret is not configured")
              io.println(
                "Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET",
              )
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
