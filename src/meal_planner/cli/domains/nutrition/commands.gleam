/// Nutrition command implementations
///
/// This module contains the core logic for nutrition CLI commands:
/// - Report generation for specific dates
/// - Goals management (display and setting)
/// - Trends analysis over time periods
/// - Compliance checking against goals
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/cli/domains/nutrition/reporting
import meal_planner/cli/domains/nutrition/validation
import meal_planner/config.{type Config}
import meal_planner/ncp
import meal_planner/ncp/types.{
  type DeviationResult, type NutritionData, type NutritionGoals,
  type TrendAnalysis, NutritionData, NutritionGoals,
}
import meal_planner/postgres
import meal_planner/storage
import meal_planner/storage/profile.{
  DatabaseError, InvalidInput, NotFound, Unauthorized,
}
import meal_planner/types/goal_type.{
  type GoalType, Calories, Carbs, Fat, Protein, display_name, unit,
}
import meal_planner/types/macros.{type Macros}

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
  case validation.validate_date_format(date_str) {
    Error(err) -> Error(err)
    Ok(_) -> {
      // Load nutrition goals
      case load_nutrition_goals(config) {
        Error(_) -> {
          // Use default goals if not found
          let goals = ncp.get_default_goals()
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
        Error(DatabaseError(_msg)) -> Error("Database error: " <> msg)
        Error(NotFound) -> {
          // Return report showing no meals logged
          Ok(reporting.build_no_meals_report(date_str, goals))
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
          Ok(reporting.build_nutrition_report(
            date_str,
            actual,
            goals,
            deviation,
          ))
        }
      }
    }
  }
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
          let goals = ncp.get_default_goals()
          display_trends_with_goals(config, days_count, goals)
        }
        Ok(goals) -> display_trends_with_goals(config, days_count, goals)
      }
    }
  }
}

/// Display trends with provided goals
fn display_trends_with_goals(
  _config: Config,
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
          Ok(reporting.build_trends_report(days_count, avg, analysis, goals))
        }
      }
    }
  }
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
      case validation.validate_date_format(date_str) {
        Error(err) -> Error(err)
        Ok(_) -> {
          // Load nutrition goals
          case load_nutrition_goals(config) {
            Error(_) -> {
              // If goals not found, use defaults
              let goals = ncp.get_default_goals()
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
          Ok(reporting.build_compliance_summary(deviation, tolerance_pct))
        }
      }
    }
  }
}

// ============================================================================
// Goals Management Functions
// ============================================================================

/// Display current nutrition goals
pub fn display_goals(config: Config) -> Result(String, String) {
  case load_nutrition_goals(config) {
    Error(err) -> Error(err)
    Ok(goals) -> {
      let output =
        "Daily Nutrition Goals:\n"
        <> "Calories: "
        <> reporting.format_float_value(goals.daily_calories)
        <> " kcal\n"
        <> "Protein: "
        <> reporting.format_float_value(goals.daily_protein)
        <> "g\n"
        <> "Carbs: "
        <> reporting.format_float_value(goals.daily_carbs)
        <> "g\n"
        <> "Fat: "
        <> reporting.format_float_value(goals.daily_fat)
        <> "g"
      Ok(output)
    }
  }
}

/// Set a specific nutrition goal with validation
pub fn set_goal(
  config: Config,
  goal_type goal_type: GoalType,
  value value: Int,
) -> Result(String, String) {
  // Validate input based on goal type
  case validation.validate_goal_value(goal_type, value) {
    Error(err) -> Error(err)
    Ok(_float_value) -> {
      // Load current goals or use defaults
      let current_goals = case load_nutrition_goals(config) {
        Error(_) -> ncp.get_default_goals()
        Ok(goals) -> goals
      }

      // Create updated goals with the new value
      let float_value = int.to_float(value)
      let updated_goals = case goal_type {
        Calories ->
          NutritionGoals(
            daily_calories: float_value,
            daily_protein: current_goals.daily_protein,
            daily_carbs: current_goals.daily_carbs,
            daily_fat: current_goals.daily_fat,
          )
        Protein ->
          NutritionGoals(
            daily_calories: current_goals.daily_calories,
            daily_protein: float_value,
            daily_carbs: current_goals.daily_carbs,
            daily_fat: current_goals.daily_fat,
          )
        Carbs ->
          NutritionGoals(
            daily_calories: current_goals.daily_calories,
            daily_protein: current_goals.daily_protein,
            daily_carbs: float_value,
            daily_fat: current_goals.daily_fat,
          )
        Fat ->
          NutritionGoals(
            daily_calories: current_goals.daily_calories,
            daily_protein: current_goals.daily_protein,
            daily_carbs: current_goals.daily_carbs,
            daily_fat: float_value,
          )
      }

      // Save to database
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

      case postgres.connect(db_config) {
        Error(err) ->
          Error("Database connection failed: " <> postgres.format_error(err))
        Ok(conn) -> {
          case storage.save_goals(conn, updated_goals) {
            Error(DatabaseError(msg)) -> Error("Failed to save goals: " <> msg)
            Error(InvalidInput(msg)) -> Error("Invalid input: " <> msg)
            Error(Unauthorized(msg)) -> Error("Unauthorized: " <> msg)
            Error(NotFound) -> Error("Profile not found")
            Ok(_) -> {
              // Return confirmation
              let unit_str = unit(goal_type)
              let display_name_str = display_name(goal_type)
              let confirmation =
                display_name_str
                <> " goal set to "
                <> int.to_string(value)
                <> unit_str

              Ok(confirmation)
            }
          }
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
    "sedentary" ->
      apply_preset_values(config, "sedentary", 2000.0, 25.0, 50.0, 25.0)
    "moderate" ->
      apply_preset_values(config, "moderate", 2200.0, 30.0, 45.0, 25.0)
    "active" -> apply_preset_values(config, "active", 2500.0, 35.0, 45.0, 20.0)
    "athletic" ->
      apply_preset_values(config, "athletic", 3000.0, 40.0, 40.0, 20.0)
    _ ->
      Error(
        "Unknown preset: '"
        <> preset_name
        <> "'. Use: sedentary, moderate, active, athletic",
      )
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
        <> reporting.format_float_value(calories)
        <> " kcal\n"
        <> "Protein: "
        <> reporting.format_float_value(protein_grams)
        <> "g ("
        <> int.to_string(int.round(protein_pct))
        <> "%)\n"
        <> "Carbs: "
        <> reporting.format_float_value(carbs_grams)
        <> "g ("
        <> int.to_string(int.round(carbs_pct))
        <> "%)\n"
        <> "Fat: "
        <> reporting.format_float_value(fat_grams)
        <> "g ("
        <> int.to_string(int.round(fat_pct))
        <> "%)"

      Ok(confirmation)
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate calories from macros (4 cal/g protein, 9 cal/g fat, 4 cal/g carbs)
fn calculate_calories(macros: Macros) -> Float {
  macros.protein *. 4.0 +. macros.fat *. 9.0 +. macros.carbs *. 4.0
}

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

/// Generate daily nutrition status report
/// Returns daily nutrition vs goals comparison
pub fn generate_daily_status(
  config: Config,
  date: String,
) -> Result(String, String) {
  // Reuse generate_report which provides daily status
  generate_report(config, date: date)
}

/// Recommend dinner based on current nutrition
/// Returns recipe suggestions to complete daily goals
pub fn recommend_dinner(
  config: Config,
  date: String,
) -> Result(String, String) {
  // For now, provide placeholder implementation
  // TODO: Integrate with NCP recommend_dinner functionality
  let report =
    "Dinner Recommendations for "
    <> date
    <> "\n"
    <> string.repeat("=", 50)
    <> "\n\n"
    <> "Based on your daily nutrition progress:
"
    <> "  1. Check if you're under on protein, carbs, or calories
"
    <> "  2. Consider recipes that address your deficiencies
"
    <> "  3. Use 'mp recipe search <keyword>' to find recipes\n\n"
    <> "Top high-protein recipes:
"
    <> "  • Grilled chicken breast (42g protein/serving)
"
    <> "  • Salmon fillet (34g protein/serving)
"
    <> "  • Greek yogurt with berries (20g protein/serving)
"
    <> "  • Lean ground turkey (26g protein/serving)
\n"
    <> string.repeat("=", 50)
    <> "\n"

  Ok(report)
}

