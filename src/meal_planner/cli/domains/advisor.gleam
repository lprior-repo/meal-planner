/// Advisor CLI domain - handles AI-powered meal planning advice
///
/// This module provides CLI commands for:
/// - Getting daily nutrition recommendations
/// - Viewing weekly nutrition trends
/// - Receiving personalized meal suggestions
/// - Analyzing eating patterns
import birl
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/advisor/daily_recommendations
import meal_planner/advisor/recommendations
import meal_planner/advisor/weekly_trends
import meal_planner/config.{type Config}
import meal_planner/postgres
import pog

// ============================================================================
// Public API - Test-facing Functions
// ============================================================================

/// Format a Macros value for display
pub fn format_macros(macros: daily_recommendations.Macros) -> String {
  format_float(macros.calories)
  <> " cal | P: "
  <> format_float(macros.protein)
  <> "g C: "
  <> format_float(macros.carbs)
  <> "g F: "
  <> format_float(macros.fat)
  <> "g"
}

/// Format an insight for display
pub fn format_insight(insight: String) -> String {
  "  • " <> insight
}

/// Format a MacroTrend for display
pub fn format_macro_trend(trend: daily_recommendations.MacroTrend) -> String {
  "7-Day Averages: "
  <> format_float(trend.avg_calories)
  <> " cal | P: "
  <> format_float(trend.avg_protein)
  <> "g C: "
  <> format_float(trend.avg_carbs)
  <> "g F: "
  <> format_float(trend.avg_fat)
  <> "g"
}

/// Format a WeeklyTrends summary for display
pub fn format_weekly_trends(trends: weekly_trends.WeeklyTrends) -> String {
  let header =
    "Weekly Trends ("
    <> int.to_string(trends.days_analyzed)
    <> " days analyzed)"

  let averages =
    "Averages: "
    <> format_float(trends.avg_calories)
    <> " cal | P: "
    <> format_float(trends.avg_protein)
    <> "g C: "
    <> format_float(trends.avg_carbs)
    <> "g F: "
    <> format_float(trends.avg_fat)
    <> "g"

  let best_worst =
    "Best day: " <> trends.best_day <> " | Worst day: " <> trends.worst_day

  header <> "\n" <> averages <> "\n" <> best_worst
}

/// Format a MealAdjustment for display
pub fn format_meal_adjustment(
  adjustment: recommendations.MealAdjustment,
) -> String {
  let action =
    recommendations.adjustment_type_to_string(adjustment.adjustment_type)
  let nutrient = string.capitalise(adjustment.nutrient)
  let amount = format_float(adjustment.amount)

  "  ["
  <> int.to_string(adjustment.priority)
  <> "] "
  <> action
  <> " "
  <> nutrient
  <> " by "
  <> amount
  <> case adjustment.nutrient {
    "calories" -> ""
    _ -> "g"
  }
}

/// Format an Insight for display
pub fn format_recommendation_insight(insight: recommendations.Insight) -> String {
  let category = recommendations.insight_category_to_string(insight.category)
  let impact = recommendations.impact_level_to_string(insight.impact)

  "  [" <> impact <> "] " <> category <> ": " <> insight.message
}

/// Parse a date string to days since Unix epoch
pub fn parse_date_to_int(date_str: String) -> option.Option(Int) {
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
          case
            #(int.parse(year_str), int.parse(month_str), int.parse(day_str))
          {
            #(Ok(_year), Ok(_month), Ok(_day)) -> {
              case birl.from_naive(date_str <> "T00:00:00") {
                Ok(dt) -> {
                  let seconds = birl.to_unix(dt)
                  let days = seconds / 86_400
                  Some(days)
                }
                Error(_) -> None
              }
            }
            _ -> None
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

// ============================================================================
// Handler Functions
// ============================================================================

/// Handle daily command - display daily nutrition analysis
fn daily_handler(config: Config, date_str: String) -> Result(Nil, Nil) {
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
          case
            daily_recommendations.generate_daily_advisor_email(conn, date_int)
          {
            Ok(email) -> {
              io.println("")
              io.println("🍽️  Daily Nutrition Advisor - " <> email.date)
              io.println(
                "═══════════════════════════════════════════════════════════════════",
              )
              io.println("")

              // Show actual vs target
              io.println("📊 Actual:  " <> format_macros(email.actual_macros))
              io.println("🎯 Target:  " <> format_macros(email.target_macros))
              io.println("")

              // Show insights
              io.println("💡 Insights:")
              case email.insights {
                [] -> io.println("  (No specific insights for today)")
                insights -> {
                  insights
                  |> list.each(fn(insight) {
                    io.println(format_insight(insight))
                  })
                }
              }
              io.println("")

              // Show 7-day trend if available
              case email.seven_day_trend {
                Some(trend) -> {
                  io.println("📈 " <> format_macro_trend(trend))
                }
                None -> {
                  io.println("📈 (Not enough data for 7-day trend)")
                }
              }
              io.println("")

              Ok(Nil)
            }
            Error(err) -> {
              io.println("Error: " <> err)
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

/// Handle trends command - display weekly nutrition trends
fn trends_handler(config: Config, days: Int) -> Result(Nil, Nil) {
  case parse_date_to_int("today") {
    None -> {
      io.println("Error: Failed to get current date")
      Error(Nil)
    }
    Some(today_int) -> {
      case create_db_connection(config) {
        Error(err) -> {
          io.println("Error: " <> err)
          Error(Nil)
        }
        Ok(conn) -> {
          case weekly_trends.analyze_weekly_trends(conn, today_int) {
            Ok(trends) -> {
              io.println("")
              io.println(
                "📊 Weekly Nutrition Trends (last "
                <> int.to_string(days)
                <> " days)",
              )
              io.println(
                "═══════════════════════════════════════════════════════════════════",
              )
              io.println("")

              // Summary
              io.println(
                "Days analyzed: " <> int.to_string(trends.days_analyzed),
              )
              io.println("")

              // Averages
              io.println("📈 Daily Averages:")
              io.println(
                "  Calories: " <> format_float(trends.avg_calories) <> " cal",
              )
              io.println(
                "  Protein:  " <> format_float(trends.avg_protein) <> "g",
              )
              io.println(
                "  Carbs:    " <> format_float(trends.avg_carbs) <> "g",
              )
              io.println("  Fat:      " <> format_float(trends.avg_fat) <> "g")
              io.println("")

              // Best/Worst days
              io.println("📅 Performance:")
              io.println("  Best day:  " <> trends.best_day)
              io.println("  Worst day: " <> trends.worst_day)
              io.println("")

              // Patterns
              io.println("🔍 Patterns Identified:")
              case trends.patterns {
                [] -> io.println("  ✓ No concerning patterns detected")
                patterns -> {
                  patterns
                  |> list.each(fn(pattern) { io.println("  • " <> pattern) })
                }
              }
              io.println("")

              // Recommendations
              io.println("💡 Recommendations:")
              case trends.recommendations {
                [] -> io.println("  Keep up the great work!")
                recs -> {
                  recs
                  |> list.each(fn(rec) { io.println("  • " <> rec) })
                }
              }
              io.println("")

              Ok(Nil)
            }
            Error(weekly_trends.NoDataAvailable) -> {
              io.println("No diary data available for the requested period.")
              io.println(
                "Log some meals in your FatSecret diary to get trend analysis.",
              )
              Error(Nil)
            }
            Error(weekly_trends.DatabaseError(msg)) -> {
              io.println("Database error: " <> msg)
              Error(Nil)
            }
            Error(weekly_trends.ServiceError(msg)) -> {
              io.println("Service error: " <> msg)
              Error(Nil)
            }
            Error(weekly_trends.InvalidDateRange) -> {
              io.println("Error: Invalid date range")
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

/// Handle suggestions command - display personalized meal suggestions
fn suggestions_handler(config: Config) -> Result(Nil, Nil) {
  case parse_date_to_int("today") {
    None -> {
      io.println("Error: Failed to get current date")
      Error(Nil)
    }
    Some(today_int) -> {
      case create_db_connection(config) {
        Error(err) -> {
          io.println("Error: " <> err)
          Error(Nil)
        }
        Ok(conn) -> {
          // First get weekly trends
          case weekly_trends.analyze_weekly_trends(conn, today_int) {
            Ok(trends) -> {
              // Use default targets (same as weekly_trends uses)
              let targets =
                weekly_trends.NutritionTargets(
                  daily_protein: 150.0,
                  daily_carbs: 200.0,
                  daily_fat: 65.0,
                  daily_calories: 2000.0,
                )

              // Generate recommendations
              let report =
                recommendations.generate_recommendations(trends, targets)

              io.println("")
              io.println("🍽️  Personalized Meal Suggestions")
              io.println(
                "═══════════════════════════════════════════════════════════════════",
              )
              io.println("")

              // Compliance score
              io.println(
                "📊 Nutrition Compliance Score: "
                <> format_float(report.compliance_score)
                <> "/100",
              )
              io.println("")

              // Meal adjustments
              io.println("🔧 Meal Adjustments (by priority):")
              case report.meal_adjustments {
                [] -> io.println("  ✓ No adjustments needed!")
                adjustments -> {
                  adjustments
                  |> list.each(fn(adj) {
                    io.println(format_meal_adjustment(adj))
                    // Show food suggestions
                    adj.food_suggestions
                    |> list.take(3)
                    |> list.each(fn(food) { io.println("      → " <> food) })
                  })
                }
              }
              io.println("")

              // Insights
              io.println("💡 Insights:")
              case report.insights {
                [] -> io.println("  (No specific insights)")
                insights -> {
                  insights
                  |> list.each(fn(insight) {
                    io.println(format_recommendation_insight(insight))
                  })
                }
              }
              io.println("")

              Ok(Nil)
            }
            Error(weekly_trends.NoDataAvailable) -> {
              io.println("No diary data available for generating suggestions.")
              io.println(
                "Log some meals in your FatSecret diary to get personalized suggestions.",
              )
              Error(Nil)
            }
            Error(_) -> {
              io.println("Error: Failed to analyze nutrition data")
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

/// Handle patterns command - display eating pattern analysis
fn patterns_handler(config: Config) -> Result(Nil, Nil) {
  case parse_date_to_int("today") {
    None -> {
      io.println("Error: Failed to get current date")
      Error(Nil)
    }
    Some(today_int) -> {
      case create_db_connection(config) {
        Error(err) -> {
          io.println("Error: " <> err)
          Error(Nil)
        }
        Ok(conn) -> {
          case weekly_trends.analyze_weekly_trends(conn, today_int) {
            Ok(trends) -> {
              io.println("")
              io.println("🔍 Eating Pattern Analysis")
              io.println(
                "═══════════════════════════════════════════════════════════════════",
              )
              io.println("")

              io.println(
                "Days analyzed: " <> int.to_string(trends.days_analyzed),
              )
              io.println("")

              // Patterns section
              io.println("📋 Identified Patterns:")
              case trends.patterns {
                [] -> {
                  io.println("  ✓ No concerning patterns detected")
                  io.println("  Your nutrition is well-balanced!")
                }
                patterns -> {
                  patterns
                  |> list.each(fn(pattern) { io.println("  ⚠ " <> pattern) })
                }
              }
              io.println("")

              // Day-to-day variance analysis
              io.println("📅 Day Comparison:")
              io.println("  Best performance:  " <> trends.best_day)
              io.println("  Worst performance: " <> trends.worst_day)
              io.println("")

              // Actionable recommendations
              io.println("🎯 Action Items:")
              case trends.recommendations {
                [] -> io.println("  Keep up your current eating habits!")
                recs -> {
                  recs
                  |> list.take(3)
                  |> list.each(fn(rec) { io.println("  → " <> rec) })
                }
              }
              io.println("")

              Ok(Nil)
            }
            Error(weekly_trends.NoDataAvailable) -> {
              io.println("Not enough data to analyze patterns.")
              io.println(
                "Log meals for at least 3 days to see pattern analysis.",
              )
              Error(Nil)
            }
            Error(_) -> {
              io.println("Error: Failed to analyze patterns")
              Error(Nil)
            }
          }
        }
      }
    }
  }
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Advisor domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help(
    "Get AI-powered meal planning advice and recommendations",
  )
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days for trend analysis")
    |> glint.flag_default(7),
  )
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Date for analysis (YYYY-MM-DD or 'today')")
    |> glint.flag_default("today"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["daily"] -> {
      let analysis_date = date(flags) |> result.unwrap("today")
      daily_handler(config, analysis_date)
    }
    ["trends"] -> {
      let trend_days = days(flags) |> result.unwrap(7)
      trends_handler(config, trend_days)
    }
    ["suggestions"] -> {
      suggestions_handler(config)
    }
    ["patterns"] -> {
      patterns_handler(config)
    }
    _ -> {
      io.println("Advisor commands:")
      io.println("")
      io.println("  mp advisor daily [--date YYYY-MM-DD]")
      io.println("    Get daily nutrition analysis and recommendations")
      io.println("")
      io.println("  mp advisor trends [--days N]")
      io.println(
        "    Analyze nutrition trends over the past N days (default: 7)",
      )
      io.println("")
      io.println("  mp advisor suggestions")
      io.println("    Get personalized meal suggestions based on your patterns")
      io.println("")
      io.println("  mp advisor patterns")
      io.println("    Analyze your eating patterns and identify improvements")
      io.println("")
      io.println("Examples:")
      io.println("  mp advisor daily")
      io.println("  mp advisor daily --date 2025-12-20")
      io.println("  mp advisor trends --days 14")
      io.println("  mp advisor suggestions")
      io.println("  mp advisor patterns")
      Ok(Nil)
    }
  }
}
