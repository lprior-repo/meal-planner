//// Email Template Module
////
//// This module provides HTML email template rendering functions for the meal planner.
//// It generates plain HTML email strings suitable for sending via email services.
////
//// Example:
//// ```gleam
//// let summary = WeeklySummary(
////   total_logs: 21,
////   avg_protein: 150.0,
////   avg_fat: 50.0,
////   avg_carbs: 200.0,
////   top_foods: ["Chicken", "Broccoli", "Rice"],
//// )
//// let html = render_weekly_email(summary)
//// ```

import gleam/int
import gleam/list
import gleam/string

/// Weekly nutrition summary data for email rendering
pub type WeeklySummary {
  WeeklySummary(
    total_logs: Int,
    avg_protein: Float,
    avg_fat: Float,
    avg_carbs: Float,
    top_foods: List(String),
  )
}

/// Format a float to 1 decimal place
fn format_float(value: Float) -> String {
  let whole = string.inspect(value |> int.floor)
  let decimal = int.floor({ value *. 10.0 } -. { int.floor(value) *. 10.0 })
  whole <> "." <> string.inspect(decimal)
}

/// Render a weekly nutrition summary as plain HTML email
///
/// Creates a well-formatted HTML email showing:
/// - Total food logs for the week
/// - Average daily macronutrients (protein, fat, carbs)
/// - Top 5 most logged foods
///
/// Returns a complete HTML string suitable for sending as email body.
pub fn render_weekly_email(summary: WeeklySummary) -> String {
  let top_foods_html =
    summary.top_foods
    |> list.take(5)
    |> list.map(fn(food) { "      <li>" <> food <> "</li>\n" })
    |> string.concat()

  "<!DOCTYPE html>\n"
  <> "<html>\n"
  <> "<head>\n"
  <> "  <meta charset=\"UTF-8\">\n"
  <> "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
  <> "  <title>Weekly Nutrition Summary</title>\n"
  <> "  <style>\n"
  <> "    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }\n"
  <> "    .container { max-width: 600px; margin: 0 auto; padding: 20px; }\n"
  <> "    .header { background-color: #4CAF50; color: white; padding: 20px; border-radius: 4px; margin-bottom: 20px; }\n"
  <> "    .section { margin-bottom: 20px; }\n"
  <> "    .section h2 { color: #2c3e50; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }\n"
  <> "    .macro { display: inline-block; width: 30%; margin: 10px; padding: 10px; background-color: #f5f5f5; border-radius: 4px; text-align: center; }\n"
  <> "    .macro-label { font-weight: bold; color: #4CAF50; }\n"
  <> "    .macro-value { font-size: 24px; color: #2c3e50; margin-top: 5px; }\n"
  <> "    ul { list-style-position: inside; }\n"
  <> "    li { padding: 5px 0; }\n"
  <> "    .footer { font-size: 12px; color: #999; text-align: center; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 10px; }\n"
  <> "  </style>\n"
  <> "</head>\n"
  <> "<body>\n"
  <> "  <div class=\"container\">\n"
  <> "    <div class=\"header\">\n"
  <> "      <h1>Weekly Nutrition Summary</h1>\n"
  <> "      <p>Here's your nutritional progress for the week</p>\n"
  <> "    </div>\n"
  <> "\n"
  <> "    <div class=\"section\">\n"
  <> "      <h2>Food Logs</h2>\n"
  <> "      <p>Total food logs recorded: <strong>"
  <> string.inspect(summary.total_logs)
  <> "</strong></p>\n"
  <> "    </div>\n"
  <> "\n"
  <> "    <div class=\"section\">\n"
  <> "      <h2>Average Daily Macronutrients</h2>\n"
  <> "      <div style=\"text-align: center;\">\n"
  <> "        <div class=\"macro\">\n"
  <> "          <div class=\"macro-label\">Protein</div>\n"
  <> "          <div class=\"macro-value\">"
  <> format_float(summary.avg_protein)
  <> "g</div>\n"
  <> "        </div>\n"
  <> "        <div class=\"macro\">\n"
  <> "          <div class=\"macro-label\">Fat</div>\n"
  <> "          <div class=\"macro-value\">"
  <> format_float(summary.avg_fat)
  <> "g</div>\n"
  <> "        </div>\n"
  <> "        <div class=\"macro\">\n"
  <> "          <div class=\"macro-label\">Carbs</div>\n"
  <> "          <div class=\"macro-value\">"
  <> format_float(summary.avg_carbs)
  <> "g</div>\n"
  <> "        </div>\n"
  <> "      </div>\n"
  <> "    </div>\n"
  <> "\n"
  <> "    <div class=\"section\">\n"
  <> "      <h2>Top Foods This Week</h2>\n"
  <> "      <ul>\n"
  <> top_foods_html
  <> "      </ul>\n"
  <> "    </div>\n"
  <> "\n"
  <> "    <div class=\"footer\">\n"
  <> "      <p>This is an automated email from your Meal Planner. Please do not reply to this email.</p>\n"
  <> "    </div>\n"
  <> "  </div>\n"
  <> "</body>\n"
  <> "</html>\n"
}
