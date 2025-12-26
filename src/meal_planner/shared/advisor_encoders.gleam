/// Response encoders for Advisor API types
///
/// Provides JSON encoding functions for all advisor domain types:
/// - AdvisorEmail (daily recommendations with macros and insights)
/// - WeeklyTrends (7-day pattern analysis)
/// - RecommendationReport (meal adjustments and suggestions)
/// - Supporting types (Macros, MacroTrend, MealAdjustment, Insight, etc.)
import gleam/json
import gleam/option.{type Option, None, Some}
import meal_planner/advisor/daily_recommendations as daily_rec
import meal_planner/advisor/recommendations as rec_types
import meal_planner/advisor/weekly_trends as trends_types
import meal_planner/shared/response_encoders

// =============================================================================
// Daily Recommendations Encoders
// =============================================================================

/// Encode AdvisorEmail to JSON
pub fn encode_advisor_email(email: daily_rec.AdvisorEmail) -> json.Json {
  json.object([
    #("date", json.string(email.date)),
    #("actual_macros", encode_macros(email.actual_macros)),
    #("target_macros", encode_macros(email.target_macros)),
    #("insights", json.array(email.insights, json.string)),
    #("seven_day_trend", encode_optional_macro_trend(email.seven_day_trend)),
  ])
}

/// Encode Macros to JSON
pub fn encode_macros(macros: daily_rec.Macros) -> json.Json {
  json.object([
    #("calories", json.float(macros.calories)),
    #("protein", json.float(macros.protein)),
    #("fat", json.float(macros.fat)),
    #("carbs", json.float(macros.carbs)),
  ])
}

/// Encode optional MacroTrend to JSON
pub fn encode_optional_macro_trend(
  trend: Option(daily_rec.MacroTrend),
) -> json.Json {
  case trend {
    Some(t) -> encode_macro_trend(t)
    None -> json.null()
  }
}

/// Encode MacroTrend to JSON
pub fn encode_macro_trend(trend: daily_rec.MacroTrend) -> json.Json {
  json.object([
    #("avg_calories", json.float(trend.avg_calories)),
    #("avg_protein", json.float(trend.avg_protein)),
    #("avg_fat", json.float(trend.avg_fat)),
    #("avg_carbs", json.float(trend.avg_carbs)),
  ])
}

// =============================================================================
// Weekly Trends Encoders
// =============================================================================

/// Encode WeeklyTrends to JSON
pub fn encode_weekly_trends(trends: trends_types.WeeklyTrends) -> json.Json {
  json.object([
    #("days_analyzed", json.int(trends.days_analyzed)),
    #("avg_calories", json.float(trends.avg_calories)),
    #("avg_protein", json.float(trends.avg_protein)),
    #("avg_fat", json.float(trends.avg_fat)),
    #("avg_carbs", json.float(trends.avg_carbs)),
    #("best_day", json.string(trends.best_day)),
    #("worst_day", json.string(trends.worst_day)),
    #("patterns", json.array(trends.patterns, json.string)),
    #("recommendations", json.array(trends.recommendations, json.string)),
  ])
}

/// Encode NutritionTargets to JSON
pub fn encode_nutrition_targets(
  targets: trends_types.NutritionTargets,
) -> json.Json {
  json.object([
    #("daily_calories", json.float(targets.daily_calories)),
    #("daily_protein", json.float(targets.daily_protein)),
    #("daily_fat", json.float(targets.daily_fat)),
    #("daily_carbs", json.float(targets.daily_carbs)),
  ])
}

// =============================================================================
// Recommendation Report Encoders
// =============================================================================

/// Encode RecommendationReport to JSON
pub fn encode_recommendation_report(
  report: rec_types.RecommendationReport,
) -> json.Json {
  json.object([
    #("compliance_score", json.float(report.compliance_score)),
    #(
      "meal_adjustments",
      json.array(report.meal_adjustments, encode_meal_adjustment),
    ),
    #("insights", json.array(report.insights, encode_insight)),
    #("trends", encode_weekly_trends(report.trends)),
  ])
}

/// Encode Macros from WeeklyTrends (avg values)
pub fn encode_macros_from_trends(
  macros: #(Float, Float, Float, Float),
) -> json.Json {
  let #(calories, protein, fat, carbs) = macros
  json.object([
    #("calories", json.float(calories)),
    #("protein", json.float(protein)),
    #("fat", json.float(fat)),
    #("carbs", json.float(carbs)),
  ])
}

/// Encode MealAdjustment to JSON
pub fn encode_meal_adjustment(adjustment: rec_types.MealAdjustment) -> json.Json {
  json.object([
    #("nutrient", json.string(adjustment.nutrient)),
    #(
      "adjustment_type",
      json.string(rec_types.adjustment_type_to_string(
        adjustment.adjustment_type,
      )),
    ),
    #("amount", json.float(adjustment.amount)),
    #("food_suggestions", json.array(adjustment.food_suggestions, json.string)),
  ])
}

/// Encode Insight to JSON
pub fn encode_insight(insight: rec_types.Insight) -> json.Json {
  json.object([
    #(
      "category",
      json.string(rec_types.insight_category_to_string(insight.category)),
    ),
    #("message", json.string(insight.message)),
    #("impact", json.string(rec_types.impact_level_to_string(insight.impact))),
  ])
}

// =============================================================================
// API Response Wrappers
// =============================================================================

/// Wrap advisor email in standard success response
pub fn success_advisor_email(email: daily_rec.AdvisorEmail) -> json.Json {
  response_encoders.success_with_data(encode_advisor_email(email))
}

/// Wrap weekly trends in standard success response
pub fn success_weekly_trends(trends: trends_types.WeeklyTrends) -> json.Json {
  response_encoders.success_with_data(encode_weekly_trends(trends))
}

/// Wrap recommendation report in standard success response
pub fn success_recommendations(
  report: rec_types.RecommendationReport,
) -> json.Json {
  response_encoders.success_with_data(encode_recommendation_report(report))
}
