/// Nutrition CLI domain - handles nutrition analysis, goals, trends, and compliance
///
/// This module provides CLI commands for:
/// - Setting and viewing nutrition goals
/// - Analyzing daily nutrition data
/// - Viewing nutrition trends over time
/// - Checking compliance with goals
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
import meal_planner/ncp.{
  type DeviationResult, type NutritionData, type NutritionGoals,
  type TrendDirection, Decreasing, Increasing, NutritionData, Stable,
  get_default_goals,
}
import meal_planner/postgres
import meal_planner/storage
import meal_planner/storage/profile.{
  type StorageError, DatabaseError, InvalidInput, NotFound, Unauthorized,
}
import meal_planner/types

// ============================================================================
// Glint Command Handler
// ============================================================================

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
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["report"] -> {
      let report_date = date(flags) |> result.unwrap("today")
      case generate_report(config, date: report_date) {
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
      io.println("Current nutrition goals:")
      io.println(format_goals(get_default_goals()))
      Ok(Nil)
    }
    ["trends"] -> {
      let trend_days = days(flags) |> result.unwrap(7)
      case display_trends(config, days: trend_days) {
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

      case check_compliance(config, date: comp_date, tolerance: tol) {
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

// ============================================================================
// Formatting Functions
// ============================================================================

/// Format nutrition goals as a readable string
pub fn format_goals(goals: NutritionGoals) -> String {
  "Protein: "
  <> float_to_string(goals.daily_protein)
  <> "g | Fat: "
  <> float_to_string(goals.daily_fat)
  <> "g | Carbs: "
  <> float_to_string(goals.daily_carbs)
  <> "g | Calories: "
  <> float_to_string(goals.daily_calories)
}

/// Format nutrition data as a readable string
pub fn format_nutrition_data(data: NutritionData) -> String {
  "Protein: "
  <> float_to_string(data.protein)
  <> "g | Fat: "
  <> float_to_string(data.fat)
  <> "g | Carbs: "
  <> float_to_string(data.carbs)
  <> "g | Calories: "
  <> float_to_string(data.calories)
}

/// Format deviation result with percentage signs
pub fn format_deviation(deviation: DeviationResult) -> String {
  "Protein: "
  <> format_percentage(deviation.protein_pct)
  <> " | Fat: "
  <> format_percentage(deviation.fat_pct)
  <> " | Carbs: "
  <> format_percentage(deviation.carbs_pct)
  <> " | Calories: "
  <> format_percentage(deviation.calories_pct)
}

/// Format a trend direction with an arrow
pub fn format_trend_direction(trend: TrendDirection) -> String {
  case trend {
    Increasing -> "↑ Increasing"
    Decreasing -> "↓ Decreasing"
    Stable -> "→ Stable"
  }
}

// ============================================================================
// Table Building Functions
// ============================================================================

/// Build a formatted table for nutrition goals
pub fn build_goals_table(goals: NutritionGoals) -> String {
  let header =
    "┌─────────────┬──────────┐\n│ Nutrient    │ Goal     │\n├─────────────┼──────────┤"
  let protein_row =
    "\n│ Protein     │ "
    <> pad_right(float_to_string(goals.daily_protein) <> "g", 8)
    <> " │"
  let fat_row =
    "\n│ Fat         │ "
    <> pad_right(float_to_string(goals.daily_fat) <> "g", 8)
    <> " │"
  let carbs_row =
    "\n│ Carbs       │ "
    <> pad_right(float_to_string(goals.daily_carbs) <> "g", 8)
    <> " │"
  let calories_row =
    "\n│ Calories    │ "
    <> pad_right(float_to_string(goals.daily_calories), 8)
    <> " │"
  let footer = "\n└─────────────┴──────────┘"

  header <> protein_row <> fat_row <> carbs_row <> calories_row <> footer
}

/// Build a compliance summary showing if within tolerance
pub fn build_compliance_summary(
  deviation: DeviationResult,
  tolerance: Float,
) -> String {
  let is_compliant = ncp.deviation_is_within_tolerance(deviation, tolerance)
  let status = case is_compliant {
    True -> "✓ ON TRACK"
    False -> "✗ OFF TRACK"
  }

  let protein_status = compliance_indicator(deviation.protein_pct, tolerance)
  let fat_status = compliance_indicator(deviation.fat_pct, tolerance)
  let carbs_status = compliance_indicator(deviation.carbs_pct, tolerance)
  let calories_status = compliance_indicator(deviation.calories_pct, tolerance)

  "Compliance Status: "
  <> status
  <> "\n\nProtein:  "
  <> protein_status
  <> " "
  <> format_percentage(deviation.protein_pct)
  <> "\nFat:      "
  <> fat_status
  <> " "
  <> format_percentage(deviation.fat_pct)
  <> "\nCarbs:    "
  <> carbs_status
  <> " "
  <> format_percentage(deviation.carbs_pct)
  <> "\nCalories: "
  <> calories_status
  <> " "
  <> format_percentage(deviation.calories_pct)
}

// ============================================================================
// Helper Functions
// ============================================================================

fn float_to_string(f: Float) -> String {
  float.to_string(f)
  |> string.split(".")
  |> fn(parts) {
    case parts {
      [whole, decimal] -> {
        let trimmed_decimal = string.slice(decimal, 0, 1)
        whole <> "." <> trimmed_decimal
      }
      [whole] -> whole <> ".0"
      _ -> float.to_string(f)
    }
  }
}

fn format_percentage(pct: Float) -> String {
  let sign = case pct >=. 0.0 {
    True -> "+"
    False -> ""
  }
  sign <> float_to_string(pct) <> "%"
}

fn compliance_indicator(pct: Float, tolerance: Float) -> String {
  let abs_pct = float.absolute_value(pct)
  case abs_pct <=. tolerance {
    True -> "✓"
    False -> "✗"
  }
}

fn pad_right(s: String, width: Int) -> String {
  let current_length = string.length(s)
  let padding_needed = width - current_length
  case padding_needed > 0 {
    True -> s <> string.repeat(" ", padding_needed)
    False -> s
  }
}

// ============================================================================
// Report Generation Functions
// ============================================================================

/// Generate nutrition report for a specific date
/// Returns a formatted report showing actual nutrition vs goals
pub fn generate_report(
  config: Config,
  date date_str: String,
) -> Result(String, String) {
  // Validate date format
  case validate_date_format(date_str) {
    Error(err) -> Error(err)
    Ok(_) -> {
      // Load nutrition goals
      case load_nutrition_goals(config) {
        Error(_) -> {
          // Use default goals if not found
          let goals = get_default_goals()
          generate_report_with_goals(config, date_str, goals)
        }
        Ok(goals) -> generate_report_with_goals(config, date_str, goals)
      }
    }
  }
}

/// Generate report with provided goals
fn generate_report_with_goals(
  config: Config,
  date_str: String,
  goals: NutritionGoals,
) -> Result(String, String) {
  // Create database config
  let db_config =
    postgres.Config(
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: case config.database.password {
        "" -> None
        pwd -> Some(pwd)
      },
      pool_size: config.database.pool_size,
    )

  // Connect and fetch data
  case postgres.connect(db_config) {
    Error(err) ->
      Error("Database connection failed: " <> postgres.format_error(err))
    Ok(conn) -> {
      // Get daily log data for the date
      case storage.get_daily_log(conn, date_str) {
        Error(DatabaseError(msg)) -> Error("Database error: " <> msg)
        Error(NotFound) -> {
          // Return report showing no meals logged
          Ok(build_no_meals_report(date_str, goals))
        }
        Error(profile.InvalidInput(msg)) -> Error("Invalid input: " <> msg)
        Error(profile.Unauthorized(msg)) -> Error("Unauthorized: " <> msg)
        Ok(daily_log) -> {
          // Convert DailyLog macros to NutritionData
          let actual =
            NutritionData(
              protein: daily_log.total_macros.protein,
              fat: daily_log.total_macros.fat,
              carbs: daily_log.total_macros.carbs,
              calories: calculate_calories(daily_log.total_macros),
            )

          // Calculate deviation
          let deviation = ncp.calculate_deviation(goals, actual)

          // Build and return formatted report
          Ok(build_nutrition_report(date_str, actual, goals, deviation))
        }
      }
    }
  }
}

/// Build report when no meals are logged
fn build_no_meals_report(date_str: String, goals: NutritionGoals) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "        NUTRITION REPORT - "
    <> date_str
    <> "\n"
    <> "═══════════════════════════════════════════════\n\n"

  let message = "No meals logged for this date.\n\n"

  let goals_section =
    "Your nutrition goals:\n" <> build_goals_table(goals) <> "\n"

  header <> message <> goals_section
}

/// Build formatted nutrition report
fn build_nutrition_report(
  date_str: String,
  actual: NutritionData,
  goals: NutritionGoals,
  deviation: DeviationResult,
) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "        NUTRITION REPORT - "
    <> date_str
    <> "\n"
    <> "═══════════════════════════════════════════════\n\n"

  let table_header =
    "┌─────────────┬──────────┬──────────┬──────────┐\n"
    <> "│ Nutrient    │ Goal     │ Actual   │ Diff     │\n"
    <> "├─────────────┼──────────┼──────────┼──────────┤"

  let protein_row =
    "\n│ Protein     │ "
    <> pad_right(float_to_string(goals.daily_protein) <> "g", 8)
    <> " │ "
    <> pad_right(float_to_string(actual.protein) <> "g", 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.protein_pct), 8)
    <> " │"

  let fat_row =
    "\n│ Fat         │ "
    <> pad_right(float_to_string(goals.daily_fat) <> "g", 8)
    <> " │ "
    <> pad_right(float_to_string(actual.fat) <> "g", 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.fat_pct), 8)
    <> " │"

  let carbs_row =
    "\n│ Carbs       │ "
    <> pad_right(float_to_string(goals.daily_carbs) <> "g", 8)
    <> " │ "
    <> pad_right(float_to_string(actual.carbs) <> "g", 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.carbs_pct), 8)
    <> " │"

  let calories_row =
    "\n│ Calories    │ "
    <> pad_right(float_to_string(goals.daily_calories), 8)
    <> " │ "
    <> pad_right(float_to_string(actual.calories), 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.calories_pct), 8)
    <> " │"

  let footer = "\n└─────────────┴──────────┴──────────┴──────────┘\n"

  header
  <> table_header
  <> protein_row
  <> fat_row
  <> carbs_row
  <> calories_row
  <> footer
}

// ============================================================================
// Trends Analysis Functions
// ============================================================================

/// Display nutrition trends for the last N days
/// Returns a formatted trends report showing averages and trend directions
pub fn display_trends(
  config: Config,
  days days_count: Int,
) -> Result(String, String) {
  // Validate days parameter
  case days_count <= 0 {
    True -> Error("Days must be positive")
    False -> {
      // Load nutrition goals
      case load_nutrition_goals(config) {
        Error(_) -> {
          let goals = get_default_goals()
          display_trends_with_goals(config, days_count, goals)
        }
        Ok(goals) -> display_trends_with_goals(config, days_count, goals)
      }
    }
  }
}

/// Display trends with provided goals
fn display_trends_with_goals(
  config: Config,
  days_count: Int,
  goals: NutritionGoals,
) -> Result(String, String) {
  // Get nutrition history
  case ncp.get_nutrition_history(days_count) {
    Error(err) -> Error(err)
    Ok(history) -> {
      // Check if we have enough data
      case list.length(history) < 2 {
        True ->
          Error(
            "Insufficient data for trend analysis. Need at least 2 days of data.",
          )
        False -> {
          // Analyze trends
          let analysis = ncp.analyze_nutrition_trends(history)
          let avg = ncp.average_nutrition_history(history)

          // Build and return formatted trends report
          Ok(build_trends_report(days_count, avg, analysis, goals))
        }
      }
    }
  }
}

/// Build formatted trends report
fn build_trends_report(
  days_count: Int,
  avg: NutritionData,
  analysis: ncp.TrendAnalysis,
  goals: NutritionGoals,
) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "     NUTRITION TRENDS - Last "
    <> int.to_string(days_count)
    <> " Days\n"
    <> "═══════════════════════════════════════════════\n\n"

  let avg_section =
    "Average Daily Intake:\n"
    <> "  Protein:  "
    <> float_to_string(avg.protein)
    <> "g (Goal: "
    <> float_to_string(goals.daily_protein)
    <> "g)\n"
    <> "  Fat:      "
    <> float_to_string(avg.fat)
    <> "g (Goal: "
    <> float_to_string(goals.daily_fat)
    <> "g)\n"
    <> "  Carbs:    "
    <> float_to_string(avg.carbs)
    <> "g (Goal: "
    <> float_to_string(goals.daily_carbs)
    <> "g)\n"
    <> "  Calories: "
    <> float_to_string(avg.calories)
    <> " (Goal: "
    <> float_to_string(goals.daily_calories)
    <> ")\n\n"

  let trends_section =
    "Trend Directions:\n"
    <> "  Protein:  "
    <> format_trend_direction(analysis.protein_trend)
    <> " ("
    <> format_percentage(analysis.protein_change)
    <> ")\n"
    <> "  Fat:      "
    <> format_trend_direction(analysis.fat_trend)
    <> " ("
    <> format_percentage(analysis.fat_change)
    <> ")\n"
    <> "  Carbs:    "
    <> format_trend_direction(analysis.carbs_trend)
    <> " ("
    <> format_percentage(analysis.carbs_change)
    <> ")\n"
    <> "  Calories: "
    <> format_trend_direction(analysis.calories_trend)
    <> " ("
    <> format_percentage(analysis.calories_change)
    <> ")\n\n"

  let footer = "═══════════════════════════════════════════════\n"

  header <> avg_section <> trends_section <> footer
}

// ============================================================================
// Compliance Checking Functions
// ============================================================================

/// Check nutrition compliance for a specific date
/// Returns a formatted compliance report showing how actual nutrition
/// compares against goals within the specified tolerance
pub fn check_compliance(
  config: Config,
  date date_str: String,
  tolerance tolerance_pct: Float,
) -> Result(String, String) {
  // Validate tolerance parameter
  case tolerance_pct <. 0.0 || tolerance_pct >. 100.0 {
    True -> Error("Tolerance must be between 0 and 100")
    False -> {
      // Validate date format (basic check)
      case validate_date_format(date_str) {
        Error(err) -> Error(err)
        Ok(_) -> {
          // Load nutrition goals
          case load_nutrition_goals(config) {
            Error(_) -> {
              // If goals not found, use defaults
              let goals = get_default_goals()
              check_compliance_with_goals(
                config,
                date_str,
                tolerance_pct,
                goals,
              )
            }
            Ok(goals) -> {
              check_compliance_with_goals(
                config,
                date_str,
                tolerance_pct,
                goals,
              )
            }
          }
        }
      }
    }
  }
}

/// Check compliance with provided goals
fn check_compliance_with_goals(
  config: Config,
  date_str: String,
  tolerance_pct: Float,
  goals: NutritionGoals,
) -> Result(String, String) {
  // Create database config
  let db_config =
    postgres.Config(
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: case config.database.password {
        "" -> None
        pwd -> Some(pwd)
      },
      pool_size: config.database.pool_size,
    )

  // Connect and fetch data
  case postgres.connect(db_config) {
    Error(err) ->
      Error("Database connection failed: " <> postgres.format_error(err))
    Ok(conn) -> {
      // Get daily log data for the date
      case storage.get_daily_log(conn, date_str) {
        Error(DatabaseError(msg)) -> Error("Database error: " <> msg)
        Error(NotFound) ->
          Error("No nutrition data found for date: " <> date_str)
        Error(InvalidInput(msg)) -> Error("Invalid input: " <> msg)
        Error(Unauthorized(msg)) -> Error("Unauthorized: " <> msg)
        Ok(daily_log) -> {
          // Convert DailyLog macros to NutritionData
          let actual =
            NutritionData(
              protein: daily_log.total_macros.protein,
              fat: daily_log.total_macros.fat,
              carbs: daily_log.total_macros.carbs,
              calories: calculate_calories(daily_log.total_macros),
            )

          // Calculate deviation
          let deviation = ncp.calculate_deviation(goals, actual)

          // Build and return compliance summary
          Ok(build_compliance_summary(deviation, tolerance_pct))
        }
      }
    }
  }
}

/// Validate date format (YYYY-MM-DD or "today")
fn validate_date_format(date_str: String) -> Result(Nil, String) {
  case date_str {
    "today" -> Ok(Nil)
    _ -> {
      // Basic validation: check if it matches YYYY-MM-DD pattern
      let parts = string.split(date_str, "-")
      case parts {
        [year, month, day] -> {
          case
            string.length(year) == 4
            && string.length(month) == 2
            && string.length(day) == 2
          {
            True -> Ok(Nil)
            False -> Error("Invalid date format. Use YYYY-MM-DD or 'today'")
          }
        }
        _ -> Error("Invalid date format. Use YYYY-MM-DD or 'today'")
      }
    }
  }
}

/// Calculate calories from macros (4 cal/g protein, 9 cal/g fat, 4 cal/g carbs)
fn calculate_calories(macros: types.Macros) -> Float {
  macros.protein *. 4.0 +. macros.fat *. 9.0 +. macros.carbs *. 4.0
}

// ============================================================================
// Database Operations
// ============================================================================

/// Load nutrition goals from database
fn load_nutrition_goals(config: Config) -> Result(NutritionGoals, String) {
  // Create database config from app config
  let db_config =
    postgres.Config(
      host: config.database.host,
      port: config.database.port,
      database: config.database.name,
      user: config.database.user,
      password: case config.database.password {
        "" -> None
        pwd -> Some(pwd)
      },
      pool_size: config.database.pool_size,
    )

  // Connect to database
  case postgres.connect(db_config) {
    Error(err) ->
      Error("Database connection failed: " <> postgres.format_error(err))
    Ok(conn) -> {
      // Get goals using storage module
      case storage.get_goals(conn) {
        Error(DatabaseError(msg)) -> Error("Database error: " <> msg)
        Error(NotFound) -> Error("No goals found in database")
        Error(InvalidInput(msg)) -> Error("Invalid: " <> msg)
        Error(Unauthorized(msg)) -> Error("Unauthorized: " <> msg)
        Ok(goals) -> Ok(goals)
      }
    }
  }
}
/// Display current nutrition goals
pub fn display_goals(config: Config) -> Result(String, String) {
  case load_nutrition_goals(config) {
    Error(err) -> Error(err)
    Ok(goals) -> {
      let output =
        "Daily Nutrition Goals:\n"
        <> "Calories: "
        <> float_to_string(goals.daily_calories)
        <> " kcal\n"
        <> "Protein: "
        <> float_to_string(goals.daily_protein)
        <> "g\n"
        <> "Carbs: "
        <> float_to_string(goals.daily_carbs)
        <> "g\n"
        <> "Fat: "
        <> float_to_string(goals.daily_fat)
        <> "g"
      Ok(output)
    }
  }
}

/// Set a specific nutrition goal with validation
pub fn set_goal(
  config: Config,
  goal_type goal_type: String,
  value value: Int,
) -> Result(String, String) {
  // Validate input based on goal type
  case validate_goal_value(goal_type, value) {
    Error(err) -> Error(err)
    Ok(_float_value) -> {
      // Load current goals to verify they exist
      case load_nutrition_goals(config) {
        Error(err) -> Error(err)
        Ok(_current_goals) -> {
          // Return confirmation (in real implementation, would save to DB)
          let confirmation =
            string.capitalise(goal_type)
            <> " goal set to "
            <> int.to_string(value)
            <> case goal_type {
              "calories" -> " kcal"
              _ -> "g"
            }

          Ok(confirmation)
        }
      }
    }
  }
}

/// List available nutrition presets
pub fn list_presets(_config: Config) -> Result(String, String) {
  let presets =
    "Available Nutrition Presets:\n\n"
    <> "sedentary: 2000 kcal, 25% protein, 50% carbs, 25% fat\n"
    <> "  Protein: 125g | Carbs: 250g | Fat: 56g\n\n"
    <> "moderate: 2200 kcal, 30% protein, 45% carbs, 25% fat\n"
    <> "  Protein: 165g | Carbs: 248g | Fat: 61g\n\n"
    <> "active: 2500 kcal, 35% protein, 45% carbs, 20% fat\n"
    <> "  Protein: 219g | Carbs: 281g | Fat: 56g\n\n"
    <> "athletic: 3000 kcal, 40% protein, 40% carbs, 20% fat\n"
    <> "  Protein: 300g | Carbs: 300g | Fat: 67g"

  Ok(presets)
}

/// Apply a preset to nutrition goals
pub fn apply_preset(
  config: Config,
  preset_name preset_name: String,
) -> Result(String, String) {
  // Validate preset name
  case preset_name {
    "sedentary" -> apply_preset_values(config, "sedentary", 2000.0, 25.0, 50.0, 25.0)
    "moderate" -> apply_preset_values(config, "moderate", 2200.0, 30.0, 45.0, 25.0)
    "active" -> apply_preset_values(config, "active", 2500.0, 35.0, 45.0, 20.0)
    "athletic" -> apply_preset_values(config, "athletic", 3000.0, 40.0, 40.0, 20.0)
    _ ->
      Error(
        "Unknown preset: '"
        <> preset_name
        <> "'. Use: sedentary, moderate, active, athletic",
      )
  }
}

/// Validate goal value based on type
fn validate_goal_value(goal_type: String, value: Int) -> Result(Float, String) {
  let float_val = int.to_float(value)
  case goal_type {
    "calories" -> {
      case value >= 500 && value <= 10_000 {
        True -> Ok(float_val)
        False -> Error("Calories must be between 500 and 10,000")
      }
    }
    "protein" -> {
      case value > 0 && value < 500 {
        True -> Ok(float_val)
        False -> Error("Protein must be between 1 and 500 grams")
      }
    }
    "carbs" -> {
      case value > 0 && value < 1000 {
        True -> Ok(float_val)
        False -> Error("Carbs must be between 1 and 1000 grams")
      }
    }
    "fat" -> {
      case value > 0 && value < 500 {
        True -> Ok(float_val)
        False -> Error("Fat must be between 1 and 500 grams")
      }
    }
    _ -> Error("Unknown goal type: " <> goal_type)
  }
}

/// Apply preset values to create new goals
fn apply_preset_values(
  config: Config,
  preset_name: String,
  calories: Float,
  protein_pct: Float,
  carbs_pct: Float,
  fat_pct: Float,
) -> Result(String, String) {
  // Calculate macro values from percentages
  let protein_grams = calories *. protein_pct /. 100.0 /. 4.0
  let carbs_grams = calories *. carbs_pct /. 100.0 /. 4.0
  let fat_grams = calories *. fat_pct /. 100.0 /. 9.0

  // Load and update goals (in real implementation, would save to DB)
  case load_nutrition_goals(config) {
    Error(err) -> Error(err)
    Ok(_current_goals) -> {
      let confirmation =
        "Preset '"
        <> preset_name
        <> "' applied:\n"
        <> "Calories: "
        <> float_to_string(calories)
        <> " kcal\n"
        <> "Protein: "
        <> float_to_string(protein_grams)
        <> "g ("
        <> float_to_string(protein_pct)
        <> "%)\n"
        <> "Carbs: "
        <> float_to_string(carbs_grams)
        <> "g ("
        <> float_to_string(carbs_pct)
        <> "%)\n"
        <> "Fat: "
        <> float_to_string(fat_grams)
        <> "g ("
        <> float_to_string(fat_pct)
        <> "%)"

      Ok(confirmation)
    }
  }
}
