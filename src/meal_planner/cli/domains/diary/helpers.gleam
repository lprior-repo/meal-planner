/// Helper functions for diary CLI domain
///
/// This module provides utility functions for date parsing and database connection.
import birl
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/config.{type Config}
import meal_planner/postgres
import pog

/// Parse a date string (YYYY-MM-DD) to days since Unix epoch
///
/// Returns Option(Int) - None if parse fails or date is invalid.
/// Supports "today" as a special value for the current date.
pub fn parse_date_to_int(date_str: String) -> Option(Int) {
  case date_str {
    "today" -> {
      let now = birl.now()
      let today_seconds = birl.to_unix(now)
      // Calculate days since epoch (integer division to get day boundary)
      let days = today_seconds / 86_400
      Some(days)
    }
    _ -> {
      // Try to parse YYYY-MM-DD format
      case string.split(date_str, "-") {
        [year_str, month_str, day_str] -> {
          case int.parse(year_str), int.parse(month_str), int.parse(day_str) {
            Ok(_year), Ok(month), Ok(day) -> {
              // Validate month (1-12) and day (1-31)
              case month >= 1 && month <= 12 && day >= 1 && day <= 31 {
                True -> {
                  case birl.from_naive(date_str <> "T00:00:00") {
                    Ok(dt) -> {
                      let seconds = birl.to_unix(dt)
                      let days = seconds / 86_400
                      Some(days)
                    }
                    Error(_) -> None
                  }
                }
                False -> None
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

/// Create database connection
///
/// Returns Result(pog.Connection, String) - connection or error message.
pub fn create_db_connection(config: Config) -> Result(pog.Connection, String) {
  let db_config =
    postgres.Config(
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: Some(config.database.password),
      pool_size: config.database.pool_size,
    )
  case postgres.connect(db_config) {
    Ok(conn) -> Ok(conn)
    Error(_) -> Error("Failed to connect to database")
  }
}
