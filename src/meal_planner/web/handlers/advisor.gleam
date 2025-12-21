/// Advisor API handlers
///
/// Provides HTTP endpoints for meal planning advisor functionality:
/// - Daily recommendations (macros, insights, trends)
/// - Weekly trend analysis
/// - Meal adjustment suggestions
/// - Compliance scoring

import gleam/http
import gleam/int
import gleam/json
import gleam/result
import meal_planner/advisor/daily_recommendations
import meal_planner/advisor/recommendations
import meal_planner/advisor/weekly_trends
import meal_planner/fatsecret/diary/types as diary_types
import meal_planner/shared/advisor_encoders
import meal_planner/shared/response_encoders
import pog
import wisp

// =============================================================================
// Daily Recommendations Handlers
// =============================================================================

/// GET /api/advisor/daily
///
/// Returns daily recommendations for today with actual macros, targets,
/// insights, and 7-day trend analysis.
pub fn handle_daily_today(req: wisp.Request, db: pog.Connection) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  case req.method {
    http.Get -> {
      // Get today's date as days since epoch
      let today_int = get_today_int()

      case daily_recommendations.generate_daily_advisor_email(db, today_int) {
        Ok(email) -> {
          advisor_encoders.success_advisor_email(email)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(msg) -> {
          response_encoders.error_message(msg)
          |> json.to_string
          |> wisp.json_response(500)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

/// GET /api/advisor/daily/:date
///
/// Returns daily recommendations for a specific date (YYYY-MM-DD format).
/// Returns 400 if date format is invalid.
pub fn handle_daily_date(
  req: wisp.Request,
  date_str: String,
  db: pog.Connection,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  case req.method {
    http.Get -> {
      case diary_types.date_to_int(date_str) {
        Error(_) -> {
          response_encoders.error_message("Invalid date format. Use YYYY-MM-DD.")
          |> json.to_string
          |> wisp.json_response(400)
        }
        Ok(date_int) -> {
          case daily_recommendations.generate_daily_advisor_email(db, date_int) {
            Ok(email) -> {
              advisor_encoders.success_advisor_email(email)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(msg) -> {
              response_encoders.error_message(msg)
              |> json.to_string
              |> wisp.json_response(500)
            }
          }
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

// =============================================================================
// Weekly Trends Handlers
// =============================================================================

/// GET /api/advisor/trends
///
/// Returns 7-day trend analysis ending today with pattern analysis,
/// compliance score, and recommendations.
pub fn handle_trends_week(req: wisp.Request, db: pog.Connection) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  case req.method {
    http.Get -> {
      // Get today's date as days since epoch
      let today_int = get_today_int()

      case weekly_trends.analyze_weekly_trends(db, today_int) {
        Ok(trends) -> {
          advisor_encoders.success_weekly_trends(trends)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(msg) -> {
          let error_str = weekly_trends_error_to_string(msg)
          response_encoders.error_message(error_str)
          |> json.to_string
          |> wisp.json_response(500)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

/// GET /api/advisor/trends/:end_date
///
/// Returns 7-day trend analysis ending on a specific date.
/// Returns 400 if date format is invalid.
pub fn handle_trends_date(
  req: wisp.Request,
  end_date_str: String,
  db: pog.Connection,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  case req.method {
    http.Get -> {
      case diary_types.date_to_int(end_date_str) {
        Error(_) -> {
          response_encoders.error_message("Invalid date format. Use YYYY-MM-DD.")
          |> json.to_string
          |> wisp.json_response(400)
        }
        Ok(end_date_int) -> {
          case weekly_trends.analyze_weekly_trends(db, end_date_int) {
            Ok(trends) -> {
              advisor_encoders.success_weekly_trends(trends)
              |> json.to_string
              |> wisp.json_response(200)
            }
            Error(msg) -> {
              let error_str = weekly_trends_error_to_string(msg)
              response_encoders.error_message(error_str)
              |> json.to_string
              |> wisp.json_response(500)
            }
          }
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

// =============================================================================
// Suggestions & Compliance Handlers
// =============================================================================

/// GET /api/advisor/suggestions
///
/// Returns meal adjustment suggestions based on weekly trends and nutrition targets.
/// Provides actionable recommendations for macro balance and dietary improvements.
pub fn handle_suggestions(req: wisp.Request, db: pog.Connection) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  case req.method {
    http.Get -> {
      let today_int = get_today_int()

      // Analyze weekly trends ending today
      case weekly_trends.analyze_weekly_trends(db, today_int) {
        Error(msg) -> {
          let error_str = weekly_trends_error_to_string(msg)
          response_encoders.error_message(error_str)
          |> json.to_string
          |> wisp.json_response(500)
        }
        Ok(trends) -> {
          // Generate recommendations from trends
          let report = recommendations.generate_recommendations(
            trends,
            trends.target_macros,
          )

          advisor_encoders.success_recommendations(report)
          |> json.to_string
          |> wisp.json_response(200)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

/// GET /api/advisor/compliance
///
/// Returns compliance score for the past week (0-100 percentage).
/// Indicates how well actual nutrition matches targets.
pub fn handle_compliance(req: wisp.Request, db: pog.Connection) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes

  case req.method {
    http.Get -> {
      let today_int = get_today_int()

      case weekly_trends.analyze_weekly_trends(db, today_int) {
        Error(msg) -> {
          let error_str = weekly_trends_error_to_string(msg)
          response_encoders.error_message(error_str)
          |> json.to_string
          |> wisp.json_response(500)
        }
        Ok(trends) -> {
          // Return compliance score in simple format
          let response = json.object([
            #("compliance_score", json.float(trends.compliance_score)),
            #("status", json.string(compliance_status(trends.compliance_score))),
            #("days_analyzed", json.int(trends.days_analyzed)),
          ])

          response_encoders.success_with_data(response)
          |> json.to_string
          |> wisp.json_response(200)
        }
      }
    }
    _ -> wisp.method_not_allowed([http.Get])
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Get today's date as days since Unix epoch
fn get_today_int() -> Int {
  // Using a placeholder - in production this would be the actual current date
  // For now, returning 0 which represents 1970-01-01
  // This should be replaced with actual current date calculation
  0
}

/// Convert WeeklyTrends AnalysisError to string message
fn weekly_trends_error_to_string(error: weekly_trends.AnalysisError) -> String {
  case error {
    weekly_trends.NoDataAvailable ->
      "Insufficient diary data for trend analysis"
    weekly_trends.InvalidDateRange ->
      "Invalid date range for analysis"
    weekly_trends.DatabaseError(msg) -> "Database error: " <> msg
    weekly_trends.ServiceError(msg) -> "Service error: " <> msg
  }
}

/// Map compliance score to status string
fn compliance_status(score: Float) -> String {
  case score {
    _ if score >= 95.0 -> "excellent"
    _ if score >= 80.0 -> "good"
    _ if score >= 65.0 -> "fair"
    _ if score >= 50.0 -> "needs_improvement"
    _ -> "poor"
  }
}
