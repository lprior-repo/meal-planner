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

import gleam/float
import gleam/int
import gleam/list
import gleam/string

// ============================================================================
// Email Template Types
// ============================================================================

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

/// Welcome email data for new users
pub type WelcomeData {
  WelcomeData(user_name: String, login_url: String)
}

/// Notification email data for meal reminders
pub type NotificationData {
  NotificationData(
    user_name: String,
    message: String,
    action_text: String,
    action_url: String,
  )
}

/// Password reset email data
pub type PasswordResetData {
  PasswordResetData(user_name: String, reset_url: String, expiry_hours: Int)
}

/// Daily summary email data
pub type DailySummaryData {
  DailySummaryData(
    date: String,
    total_calories: Float,
    protein: Float,
    fat: Float,
    carbs: Float,
    meals_logged: Int,
  )
}

/// Goal achievement notification data
pub type GoalAchievementData {
  GoalAchievementData(
    user_name: String,
    goal_description: String,
    achievement_date: String,
  )
}

/// Format a float to 1 decimal place
fn format_float(value: Float) -> String {
  let whole_int = float.truncate(value)
  let whole = whole_int |> int.to_string
  let decimal_part = value -. int.to_float(whole_int)
  let decimal = float.truncate(decimal_part *. 10.0) |> int.to_string
  whole <> "." <> decimal
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

// ============================================================================
// Helper Functions
// ============================================================================

/// Generate common email header HTML
fn email_header(title: String, subtitle: String) -> String {
  "    <div class=\"header\">\n"
  <> "      <h1>"
  <> title
  <> "</h1>\n"
  <> "      <p>"
  <> subtitle
  <> "</p>\n"
  <> "    </div>\n"
}

/// Generate common email footer HTML
fn email_footer() -> String {
  "    <div class=\"footer\">\n"
  <> "      <p>This is an automated email from your Meal Planner. Please do not reply to this email.</p>\n"
  <> "    </div>\n"
}

/// Generate common email styles CSS
fn email_styles() -> String {
  "  <style>\n"
  <> "    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }\n"
  <> "    .container { max-width: 600px; margin: 0 auto; padding: 20px; }\n"
  <> "    .header { background-color: #4CAF50; color: white; padding: 20px; border-radius: 4px; margin-bottom: 20px; }\n"
  <> "    .section { margin-bottom: 20px; padding: 15px; background-color: #f9f9f9; border-radius: 4px; }\n"
  <> "    .section h2 { color: #2c3e50; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }\n"
  <> "    .button { display: inline-block; padding: 12px 24px; background-color: #4CAF50; color: white !important; text-decoration: none; border-radius: 4px; margin: 10px 0; }\n"
  <> "    .button:hover { background-color: #45a049; }\n"
  <> "    .footer { font-size: 12px; color: #999; text-align: center; margin-top: 30px; border-top: 1px solid #ddd; padding-top: 10px; }\n"
  <> "    .macro { display: inline-block; width: 30%; margin: 5px; padding: 10px; background-color: #fff; border-radius: 4px; text-align: center; }\n"
  <> "    .macro-label { font-weight: bold; color: #4CAF50; }\n"
  <> "    .macro-value { font-size: 24px; color: #2c3e50; margin-top: 5px; }\n"
  <> "  </style>\n"
}

/// Generate email HTML wrapper
fn email_wrapper(title: String, body_content: String) -> String {
  "<!DOCTYPE html>\n"
  <> "<html>\n"
  <> "<head>\n"
  <> "  <meta charset=\"UTF-8\">\n"
  <> "  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n"
  <> "  <title>"
  <> title
  <> "</title>\n"
  <> email_styles()
  <> "</head>\n"
  <> "<body>\n"
  <> "  <div class=\"container\">\n"
  <> body_content
  <> "  </div>\n"
  <> "</body>\n"
  <> "</html>\n"
}

// ============================================================================
// Template Rendering Functions
// ============================================================================

/// Render a welcome email for new users
///
/// Creates a friendly welcome email with a call-to-action button to start using the app.
/// Includes personalized greeting and instructions for getting started.
///
/// Returns a complete HTML string suitable for sending as email body.
pub fn render_welcome_email(data: WelcomeData) -> String {
  let body =
    email_header(
      "Welcome to Meal Planner!",
      "Start tracking your nutrition today",
    )
    <> "    <div class=\"section\">\n"
    <> "      <p>Hi "
    <> data.user_name
    <> ",</p>\n"
    <> "      <p>Welcome to Meal Planner! We're excited to help you achieve your nutrition goals.</p>\n"
    <> "      <p>With Meal Planner, you can:</p>\n"
    <> "      <ul>\n"
    <> "        <li>Track your daily food intake and macros</li>\n"
    <> "        <li>Search from thousands of foods in the USDA database</li>\n"
    <> "        <li>Create custom foods and recipes</li>\n"
    <> "        <li>Monitor your progress towards your goals</li>\n"
    <> "      </ul>\n"
    <> "      <p style=\"text-align: center;\">\n"
    <> "        <a href=\""
    <> data.login_url
    <> "\" class=\"button\">Get Started</a>\n"
    <> "      </p>\n"
    <> "    </div>\n"
    <> email_footer()

  email_wrapper("Welcome to Meal Planner", body)
}

/// Render a notification email for meal reminders or alerts
///
/// Creates a notification email with a custom message and action button.
/// Useful for meal reminders, weekly summaries, or goal notifications.
///
/// Returns a complete HTML string suitable for sending as email body.
pub fn render_notification_email(data: NotificationData) -> String {
  let body =
    email_header("Meal Planner Notification", "You have a new update")
    <> "    <div class=\"section\">\n"
    <> "      <p>Hi "
    <> data.user_name
    <> ",</p>\n"
    <> "      <p>"
    <> data.message
    <> "</p>\n"
    <> "      <p style=\"text-align: center;\">\n"
    <> "        <a href=\""
    <> data.action_url
    <> "\" class=\"button\">"
    <> data.action_text
    <> "</a>\n"
    <> "      </p>\n"
    <> "    </div>\n"
    <> email_footer()

  email_wrapper("Meal Planner Notification", body)
}

/// Render a password reset email
///
/// Creates a secure password reset email with a time-limited reset link.
/// Includes security notice and expiration information.
///
/// Returns a complete HTML string suitable for sending as email body.
pub fn render_password_reset_email(data: PasswordResetData) -> String {
  let body =
    email_header("Reset Your Password", "Secure password reset link")
    <> "    <div class=\"section\">\n"
    <> "      <p>Hi "
    <> data.user_name
    <> ",</p>\n"
    <> "      <p>You requested to reset your password. Click the button below to set a new password:</p>\n"
    <> "      <p style=\"text-align: center;\">\n"
    <> "        <a href=\""
    <> data.reset_url
    <> "\" class=\"button\">Reset Password</a>\n"
    <> "      </p>\n"
    <> "      <p><strong>This link will expire in "
    <> int.to_string(data.expiry_hours)
    <> " hours.</strong></p>\n"
    <> "      <p style=\"color: #666; font-size: 14px;\">If you didn't request this password reset, please ignore this email. Your password will remain unchanged.</p>\n"
    <> "    </div>\n"
    <> email_footer()

  email_wrapper("Password Reset", body)
}

/// Render a daily summary email
///
/// Creates a daily nutrition summary showing total calories and macros for the day.
/// Includes number of meals logged and visual macro breakdown.
///
/// Returns a complete HTML string suitable for sending as email body.
pub fn render_daily_summary_email(data: DailySummaryData) -> String {
  let body =
    email_header("Daily Nutrition Summary", "Your progress for " <> data.date)
    <> "    <div class=\"section\">\n"
    <> "      <h2>Today's Summary</h2>\n"
    <> "      <p>Meals logged: <strong>"
    <> int.to_string(data.meals_logged)
    <> "</strong></p>\n"
    <> "      <p>Total calories: <strong>"
    <> format_float(data.total_calories)
    <> " cal</strong></p>\n"
    <> "    </div>\n"
    <> "    <div class=\"section\">\n"
    <> "      <h2>Macronutrients</h2>\n"
    <> "      <div style=\"text-align: center;\">\n"
    <> "        <div class=\"macro\">\n"
    <> "          <div class=\"macro-label\">Protein</div>\n"
    <> "          <div class=\"macro-value\">"
    <> format_float(data.protein)
    <> "g</div>\n"
    <> "        </div>\n"
    <> "        <div class=\"macro\">\n"
    <> "          <div class=\"macro-label\">Fat</div>\n"
    <> "          <div class=\"macro-value\">"
    <> format_float(data.fat)
    <> "g</div>\n"
    <> "        </div>\n"
    <> "        <div class=\"macro\">\n"
    <> "          <div class=\"macro-label\">Carbs</div>\n"
    <> "          <div class=\"macro-value\">"
    <> format_float(data.carbs)
    <> "g</div>\n"
    <> "        </div>\n"
    <> "      </div>\n"
    <> "    </div>\n"
    <> email_footer()

  email_wrapper("Daily Summary", body)
}

/// Render a goal achievement notification email
///
/// Creates a celebration email when a user achieves a nutrition goal.
/// Includes congratulatory message and achievement details.
///
/// Returns a complete HTML string suitable for sending as email body.
pub fn render_goal_achievement_email(data: GoalAchievementData) -> String {
  let body =
    email_header("Goal Achieved!", "Congratulations on your success")
    <> "    <div class=\"section\">\n"
    <> "      <p>Congratulations "
    <> data.user_name
    <> "!</p>\n"
    <> "      <p style=\"font-size: 18px; color: #4CAF50; font-weight: bold;\">You've achieved your goal!</p>\n"
    <> "      <p><strong>Goal:</strong> "
    <> data.goal_description
    <> "</p>\n"
    <> "      <p><strong>Achieved on:</strong> "
    <> data.achievement_date
    <> "</p>\n"
    <> "      <p>Keep up the great work! Consistency is key to maintaining your health and fitness goals.</p>\n"
    <> "    </div>\n"
    <> email_footer()

  email_wrapper("Goal Achieved", body)
}
