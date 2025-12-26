/// Nutrition CLI domain - Main entry point
///
/// This module provides CLI commands for:
/// - Setting and viewing nutrition goals
/// - Analyzing daily nutrition data
/// - Viewing nutrition trends over time
/// - Checking compliance with goals
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import glint
import meal_planner/cli/domains/nutrition/commands
import meal_planner/config.{type Config}

/// Nutrition domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage nutrition goals and analysis")
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Date for nutrition report (YYYY-MM-DD)")
    |> glint.flag_default("today"),
  )
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days for trends")
    |> glint.flag_default(7),
  )
  use tolerance <- glint.flag(
    glint.float_flag("tolerance")
    |> glint.flag_help("Tolerance percentage for compliance check")
    |> glint.flag_default(10.0),
  )
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
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["report"] -> {
      let report_date = date(flags) |> result.unwrap("today")
      case commands.generate_report(config, date: report_date) {
        Ok(report) -> {
          io.println(report)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error generating report: " <> err)
          Error(Nil)
        }
      }
    }
    ["goals"] -> {
      // Check if any goal flags were provided
      let calories_val = case calories(flags) {
        Ok(val) -> Some(val)
        Error(_) -> None
      }
      let protein_val = case protein(flags) {
        Ok(val) -> Some(val)
        Error(_) -> None
      }
      let carbs_val = case carbs(flags) {
        Ok(val) -> Some(val)
        Error(_) -> None
      }
      let fat_val = case fat(flags) {
        Ok(val) -> Some(val)
        Error(_) -> None
      }

      case calories_val, protein_val, carbs_val, fat_val {
        None, None, None, None -> {
          // No flags provided, display current goals
          case commands.display_goals(config) {
            Ok(output) -> {
              io.println(output)
              Ok(Nil)
            }
            Error(_) -> {
              io.println("Using default nutrition goals")
              Ok(Nil)
            }
          }
        }
        _, _, _, _ -> {
          // At least one flag provided, set goals
          let results = [
            case calories_val {
              Some(val) ->
                commands.set_goal(config, goal_type: "calories", value: val)
              None -> Ok("")
            },
            case protein_val {
              Some(val) ->
                commands.set_goal(config, goal_type: "protein", value: val)
              None -> Ok("")
            },
            case carbs_val {
              Some(val) ->
                commands.set_goal(config, goal_type: "carbs", value: val)
              None -> Ok("")
            },
            case fat_val {
              Some(val) ->
                commands.set_goal(config, goal_type: "fat", value: val)
              None -> Ok("")
            },
          ]

          // Check if all succeeded
          let all_ok =
            list.all(results, fn(r) {
              case r {
                Ok(_) -> True
                Error(_) -> False
              }
            })

          case all_ok {
            True -> {
              io.println("✓ Nutrition goals updated successfully")
              case commands.display_goals(config) {
                Ok(output) -> {
                  io.println("\n" <> output)
                  Ok(Nil)
                }
                Error(_) -> Ok(Nil)
              }
            }
            False -> {
              // Find first error
              let error_msg =
                list.find(results, fn(r) {
                  case r {
                    Error(_) -> True
                    Ok(_) -> False
                  }
                })
                |> result.unwrap(Error("Unknown error"))

              case error_msg {
                Error(msg) -> {
                  io.println("Error: " <> msg)
                  Error(Nil)
                }
                Ok(_) -> Error(Nil)
              }
            }
          }
        }
      }
    }
    ["trends"] -> {
      let trend_days = days(flags) |> result.unwrap(7)
      case commands.display_trends(config, days: trend_days) {
        Ok(report) -> {
          io.println(report)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error displaying trends: " <> err)
          Error(Nil)
        }
      }
    }
    ["compliance"] -> {
      let comp_date = date(flags) |> result.unwrap("today")
      let tol = tolerance(flags) |> result.unwrap(10.0)

      case commands.check_compliance(config, date: comp_date, tolerance: tol) {
        Ok(report) -> {
          io.println(report)
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error checking compliance: " <> err)
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("Nutrition commands:")
      io.println("  mp nutrition report --date 2025-12-19")
      io.println("  mp nutrition goals")
      io.println("  mp nutrition trends --days 7")
      io.println("  mp nutrition compliance --date 2025-12-19 --tolerance 10")
      Ok(Nil)
    }
  }
}
