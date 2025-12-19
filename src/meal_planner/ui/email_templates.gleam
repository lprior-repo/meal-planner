/// Email template rendering module
///
/// This module provides HTML email templates for:
/// - Weekly nutrition summaries
/// - NCP (Nutrition Compliance Plan) alerts
/// - Daily advisor recommendations
///
/// Templates use inline CSS for maximum email client compatibility.
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/advisor/daily_recommendations.{
  type AdvisorEmail, type MacroTrend,
}
import meal_planner/storage/logs/summaries.{
  type FoodSummaryItem, type WeeklySummary,
}
import meal_planner/types.{type Macros}

// ============================================================================
// Weekly Summary Email
// ============================================================================

/// Render a weekly nutrition summary as HTML email
/// Returns a complete HTML email with inline styles
pub fn render_weekly_email(summary: WeeklySummary) -> String {
  let total_cals =
    calculate_calories(summary.avg_protein, summary.avg_fat, summary.avg_carbs)

  let header = render_header("Your Weekly Nutrition Summary")
  let stats_section =
    render_stats_section(
      summary.total_logs,
      summary.avg_protein,
      summary.avg_fat,
      summary.avg_carbs,
      total_cals,
    )
  let foods_section = render_foods_section(summary.by_food)
  let footer = render_footer()

  wrap_in_html_template(header <> stats_section <> foods_section <> footer)
}

/// Render an NCP (Nutrition Compliance Plan) alert email
/// Used when macros are significantly off target
pub fn render_ncp_alert_email(
  current: Macros,
  target: Macros,
  deficit: Macros,
) -> String {
  let header = render_header("Nutrition Alert: Macro Imbalance Detected")

  let alert_body =
    "<div style=\"background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 20px; margin: 20px 0;\">"
    <> "<h2 style=\"color: #856404; margin: 0 0 15px 0;\">Action Required</h2>"
    <> "<p style=\"color: #856404; margin: 0 0 10px 0;\">Your nutrition intake is significantly below target.</p>"
    <> "</div>"

  let comparison = render_macro_comparison(current, target, deficit)
  let recommendations = render_recommendations(deficit)
  let footer = render_footer()

  wrap_in_html_template(
    header <> alert_body <> comparison <> recommendations <> footer,
  )
}

// ============================================================================
// HTML Component Renderers
// ============================================================================

fn render_header(title: String) -> String {
  "<div style=\"background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center;\">"
  <> "<h1 style=\"color: white; margin: 0; font-size: 28px; font-weight: 600;\">"
  <> title
  <> "</h1>"
  <> "</div>"
}

fn render_stats_section(
  total_logs: Int,
  avg_protein: Float,
  avg_fat: Float,
  avg_carbs: Float,
  total_cals: Float,
) -> String {
  "<div style=\"padding: 30px; background-color: #f8f9fa;\">"
  <> "<h2 style=\"color: #333; margin: 0 0 20px 0;\">Summary Statistics</h2>"
  <> "<div style=\"display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;\">"
  <> render_stat_card(
    "Total Meals Logged",
    int.to_string(total_logs),
    "#667eea",
  )
  <> render_stat_card(
    "Avg Calories/Day",
    float_to_string(total_cals, 0),
    "#764ba2",
  )
  <> render_stat_card(
    "Avg Protein",
    float_to_string(avg_protein, 1) <> "g",
    "#10b981",
  )
  <> render_stat_card("Avg Fat", float_to_string(avg_fat, 1) <> "g", "#f59e0b")
  <> render_stat_card(
    "Avg Carbs",
    float_to_string(avg_carbs, 1) <> "g",
    "#3b82f6",
  )
  <> "</div>"
  <> "</div>"
}

fn render_stat_card(label: String, value: String, color: String) -> String {
  "<div style=\"background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);\">"
  <> "<div style=\"font-size: 14px; color: #6b7280; margin-bottom: 8px;\">"
  <> label
  <> "</div>"
  <> "<div style=\"font-size: 32px; font-weight: bold; color: "
  <> color
  <> ";\">"
  <> value
  <> "</div>"
  <> "</div>"
}

fn render_foods_section(foods: List(FoodSummaryItem)) -> String {
  case foods {
    [] -> ""
    _ -> {
      let top_foods = list.take(foods, 10)

      "<div style=\"padding: 30px;\">"
      <> "<h2 style=\"color: #333; margin: 0 0 20px 0;\">Top Foods This Week</h2>"
      <> "<table style=\"width: 100%; border-collapse: collapse; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);\">"
      <> "<thead>"
      <> "<tr style=\"background-color: #f8f9fa;\">"
      <> "<th style=\"padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6;\">Food</th>"
      <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Meals</th>"
      <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Protein</th>"
      <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Fat</th>"
      <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Carbs</th>"
      <> "</tr>"
      <> "</thead>"
      <> "<tbody>"
      <> render_food_rows(top_foods)
      <> "</tbody>"
      <> "</table>"
      <> "</div>"
    }
  }
}

fn render_food_rows(foods: List(FoodSummaryItem)) -> String {
  foods
  |> list.map(fn(food) {
    "<tr style=\"border-bottom: 1px solid #dee2e6;\">"
    <> "<td style=\"padding: 12px;\">"
    <> food.food_name
    <> "</td>"
    <> "<td style=\"padding: 12px; text-align: center;\">"
    <> int.to_string(food.log_count)
    <> "</td>"
    <> "<td style=\"padding: 12px; text-align: center;\">"
    <> float_to_string(food.avg_protein, 1)
    <> "g</td>"
    <> "<td style=\"padding: 12px; text-align: center;\">"
    <> float_to_string(food.avg_fat, 1)
    <> "g</td>"
    <> "<td style=\"padding: 12px; text-align: center;\">"
    <> float_to_string(food.avg_carbs, 1)
    <> "g</td>"
    <> "</tr>"
  })
  |> string.join("")
}

fn render_macro_comparison(
  current: Macros,
  target: Macros,
  deficit: Macros,
) -> String {
  "<div style=\"padding: 30px;\">"
  <> "<h2 style=\"color: #333; margin: 0 0 20px 0;\">Macro Comparison</h2>"
  <> "<table style=\"width: 100%; border-collapse: collapse; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);\">"
  <> "<thead>"
  <> "<tr style=\"background-color: #f8f9fa;\">"
  <> "<th style=\"padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6;\">Macro</th>"
  <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Current</th>"
  <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Target</th>"
  <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Deficit</th>"
  <> "</tr>"
  <> "</thead>"
  <> "<tbody>"
  <> render_macro_row(
    "Protein",
    current.protein,
    target.protein,
    deficit.protein,
  )
  <> render_macro_row("Fat", current.fat, target.fat, deficit.fat)
  <> render_macro_row("Carbs", current.carbs, target.carbs, deficit.carbs)
  <> "</tbody>"
  <> "</table>"
  <> "</div>"
}

fn render_macro_row(
  name: String,
  current: Float,
  target: Float,
  deficit: Float,
) -> String {
  let deficit_color = case deficit <. 0.0 {
    True -> "#dc2626"
    False -> "#10b981"
  }

  "<tr style=\"border-bottom: 1px solid #dee2e6;\">"
  <> "<td style=\"padding: 12px;\">"
  <> name
  <> "</td>"
  <> "<td style=\"padding: 12px; text-align: center;\">"
  <> float_to_string(current, 1)
  <> "g</td>"
  <> "<td style=\"padding: 12px; text-align: center;\">"
  <> float_to_string(target, 1)
  <> "g</td>"
  <> "<td style=\"padding: 12px; text-align: center; color: "
  <> deficit_color
  <> "; font-weight: bold;\">"
  <> float_to_string(deficit, 1)
  <> "g</td>"
  <> "</tr>"
}

fn render_recommendations(deficit: Macros) -> String {
  "<div style=\"padding: 30px; background-color: #f0f9ff;\">"
  <> "<h2 style=\"color: #333; margin: 0 0 20px 0;\">Recommendations</h2>"
  <> "<ul style=\"margin: 0; padding-left: 20px; line-height: 1.8;\">"
  <> render_recommendation_items(deficit)
  <> "</ul>"
  <> "</div>"
}

fn render_recommendation_items(deficit: Macros) -> String {
  let items = []

  let items = case deficit.protein <. -10.0 {
    True -> [
      "<li>Add high-protein foods: lean meats, fish, eggs, Greek yogurt, or protein powder</li>",
      ..items
    ]
    False -> items
  }

  let items = case deficit.fat <. -10.0 {
    True -> [
      "<li>Include healthy fats: avocado, nuts, olive oil, or fatty fish</li>",
      ..items
    ]
    False -> items
  }

  let items = case deficit.carbs <. -20.0 {
    True -> [
      "<li>Add complex carbs: rice, sweet potatoes, oats, or whole grain bread</li>",
      ..items
    ]
    False -> items
  }

  case items {
    [] -> "<li>Great job! All macros are on target.</li>"
    _ -> string.join(items, "")
  }
}

fn render_footer() -> String {
  "<div style=\"padding: 30px; background-color: #1f2937; text-align: center;\">"
  <> "<p style=\"color: #9ca3af; margin: 0 0 10px 0;\">Meal Planner - Your Nutrition Companion</p>"
  <> "<p style=\"color: #6b7280; margin: 0; font-size: 12px;\">This is an automated email. Do not reply.</p>"
  <> "</div>"
}

fn wrap_in_html_template(body: String) -> String {
  "<!DOCTYPE html>"
  <> "<html lang=\"en\">"
  <> "<head>"
  <> "<meta charset=\"UTF-8\">"
  <> "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
  <> "<title>Meal Planner</title>"
  <> "</head>"
  <> "<body style=\"margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;\">"
  <> "<div style=\"max-width: 600px; margin: 0 auto; background-color: white;\">"
  <> body
  <> "</div>"
  <> "</body>"
  <> "</html>"
}

// ============================================================================
// Helper Functions
// ============================================================================

fn calculate_calories(protein: Float, fat: Float, carbs: Float) -> Float {
  protein *. 4.0 +. fat *. 9.0 +. carbs *. 4.0
}

fn float_to_string(value: Float, decimals: Int) -> String {
  case decimals {
    0 -> {
      let rounded = float.round(value)
      int.to_string(rounded)
    }
    1 -> {
      let multiplied = value *. 10.0
      let rounded_int = float.round(multiplied)
      let int_val = float.truncate(int.to_float(rounded_int))
      let whole = int_val / 10
      let decimal = int_val % 10
      int.to_string(whole) <> "." <> int.to_string(decimal)
    }
    _ -> {
      // For 2+ decimals, just use default float formatting
      float.to_string(value)
    }
  }
}

// ============================================================================
// Daily Advisor Email
// ============================================================================

/// Render a daily nutrition advisor email with recommendations
/// Returns a complete HTML email with inline styles
pub fn render_daily_advisor_email(advisor: AdvisorEmail) -> String {
  let header = render_header("Daily Nutrition Recap - " <> advisor.date)

  let today_stats =
    render_daily_stats_section(advisor.actual_macros, advisor.target_macros)

  let insights_section = render_insights_section(advisor.insights)

  let trend_section = case advisor.seven_day_trend {
    Some(trend) -> render_trend_section(trend)
    None -> ""
  }

  let footer = render_footer()

  wrap_in_html_template(
    header <> today_stats <> insights_section <> trend_section <> footer,
  )
}

fn render_daily_stats_section(
  actual: daily_recommendations.Macros,
  target: daily_recommendations.Macros,
) -> String {
  let cal_diff = actual.calories -. target.calories
  let cal_percent = cal_diff /. target.calories *. 100.0

  "<div style=\"padding: 30px; background-color: #f8f9fa;\">"
  <> "<h2 style=\"color: #333; margin: 0 0 20px 0;\">Today's Stats</h2>"
  <> "<table style=\"width: 100%; border-collapse: collapse; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1);\">"
  <> "<thead>"
  <> "<tr style=\"background-color: #f8f9fa;\">"
  <> "<th style=\"padding: 12px; text-align: left; border-bottom: 2px solid #dee2e6;\">Macro</th>"
  <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Actual</th>"
  <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Target</th>"
  <> "<th style=\"padding: 12px; text-align: center; border-bottom: 2px solid #dee2e6;\">Status</th>"
  <> "</tr>"
  <> "</thead>"
  <> "<tbody>"
  <> render_macro_status_row(
    "Calories",
    actual.calories,
    target.calories,
    "cal",
  )
  <> render_macro_status_row("Protein", actual.protein, target.protein, "g")
  <> render_macro_status_row("Fat", actual.fat, target.fat, "g")
  <> render_macro_status_row("Carbs", actual.carbs, target.carbs, "g")
  <> "</tbody>"
  <> "</table>"
  <> "</div>"
}

fn render_macro_status_row(
  name: String,
  actual: Float,
  target: Float,
  unit: String,
) -> String {
  let diff = actual -. target
  let percent_diff = diff /. target *. 100.0

  let status_color = case percent_diff {
    p if p <. -10.0 -> "#dc2626"
    // Red (under)
    p if p >. 10.0 -> "#f59e0b"
    // Orange (over)
    _ -> "#10b981"
    // Green (on track)
  }

  let status_text = case percent_diff {
    p if p <. -10.0 -> "Under (" <> float_to_string(percent_diff, 0) <> "%)"
    p if p >. 10.0 -> "Over (+" <> float_to_string(percent_diff, 0) <> "%)"
    _ -> "On Track"
  }

  "<tr style=\"border-bottom: 1px solid #dee2e6;\">"
  <> "<td style=\"padding: 12px;\">"
  <> name
  <> "</td>"
  <> "<td style=\"padding: 12px; text-align: center;\">"
  <> float_to_string(actual, 1)
  <> unit
  <> "</td>"
  <> "<td style=\"padding: 12px; text-align: center;\">"
  <> float_to_string(target, 1)
  <> unit
  <> "</td>"
  <> "<td style=\"padding: 12px; text-align: center; color: "
  <> status_color
  <> "; font-weight: bold;\">"
  <> status_text
  <> "</td>"
  <> "</tr>"
}

fn render_insights_section(insights: List(String)) -> String {
  case insights {
    [] -> ""
    _ -> {
      "<div style=\"padding: 30px; background-color: #f0f9ff;\">"
      <> "<h2 style=\"color: #333; margin: 0 0 20px 0;\">Insights & Recommendations</h2>"
      <> "<ul style=\"margin: 0; padding-left: 20px; line-height: 1.8;\">"
      <> render_insight_items(insights)
      <> "</ul>"
      <> "</div>"
    }
  }
}

fn render_insight_items(insights: List(String)) -> String {
  insights
  |> list.map(fn(insight) { "<li>" <> insight <> "</li>" })
  |> string.join("")
}

fn render_trend_section(trend: MacroTrend) -> String {
  "<div style=\"padding: 30px;\">"
  <> "<h2 style=\"color: #333; margin: 0 0 20px 0;\">7-Day Trend</h2>"
  <> "<div style=\"display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px;\">"
  <> render_stat_card(
    "Avg Calories",
    float_to_string(trend.avg_calories, 0),
    "#764ba2",
  )
  <> render_stat_card(
    "Avg Protein",
    float_to_string(trend.avg_protein, 1) <> "g",
    "#10b981",
  )
  <> render_stat_card(
    "Avg Fat",
    float_to_string(trend.avg_fat, 1) <> "g",
    "#f59e0b",
  )
  <> render_stat_card(
    "Avg Carbs",
    float_to_string(trend.avg_carbs, 1) <> "g",
    "#3b82f6",
  )
  <> "</div>"
  <> "</div>"
}
