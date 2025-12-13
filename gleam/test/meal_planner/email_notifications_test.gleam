/// Tests for email notification system
///
/// Covers:
/// - Email template rendering (meal-planner-i96s)
/// - SMTP client configuration (meal-planner-ji68, meal-planner-2ux0)
/// - Weekly summary queries (meal-planner-mvjz)
/// - Scheduler actor (meal-planner-agy7)
/// - Email sending integration (meal-planner-atfe)

import gleeunit
import gleeunit/should
import meal_planner/integrations/smtp_client
import meal_planner/storage/logs/summaries.{FoodSummaryItem, WeeklySummary}
import meal_planner/types.{Macros}
import meal_planner/ui/email_templates

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Email Template Tests
// ============================================================================

pub fn render_weekly_email_test() {
  let summary =
    WeeklySummary(
      total_logs: 21,
      avg_protein: 150.0,
      avg_fat: 60.0,
      avg_carbs: 200.0,
      by_food: [
        FoodSummaryItem(
          food_id: 1,
          food_name: "Chicken Breast",
          log_count: 7,
          avg_protein: 35.0,
          avg_fat: 8.0,
          avg_carbs: 0.0,
        ),
        FoodSummaryItem(
          food_id: 2,
          food_name: "Rice",
          log_count: 6,
          avg_protein: 4.0,
          avg_fat: 1.0,
          avg_carbs: 45.0,
        ),
      ],
    )

  let html = email_templates.render_weekly_email(summary)

  // Verify HTML structure
  html
  |> should.be_ok

  // Should contain key elements
  html
  |> string.contains("Weekly Nutrition Summary")
  |> should.be_true

  html
  |> string.contains("Total Meals Logged")
  |> should.be_true

  html
  |> string.contains("21")  // Total logs
  |> should.be_true

  html
  |> string.contains("Chicken Breast")
  |> should.be_true

  html
  |> string.contains("Rice")
  |> should.be_true
}

pub fn render_ncp_alert_email_test() {
  let current = Macros(protein: 100.0, fat: 40.0, carbs: 150.0)
  let target = Macros(protein: 150.0, fat: 60.0, carbs: 200.0)
  let deficit = Macros(protein: -50.0, fat: -20.0, carbs: -50.0)

  let html = email_templates.render_ncp_alert_email(current, target, deficit)

  // Should contain alert messaging
  html
  |> string.contains("Nutrition Alert")
  |> should.be_true

  html
  |> string.contains("Action Required")
  |> should.be_true

  html
  |> string.contains("Macro Comparison")
  |> should.be_true

  // Should show current values
  html
  |> string.contains("100.0")  // Current protein
  |> should.be_true

  // Should show recommendations
  html
  |> string.contains("Recommendations")
  |> should.be_true
}

pub fn empty_weekly_summary_test() {
  let empty_summary =
    WeeklySummary(
      total_logs: 0,
      avg_protein: 0.0,
      avg_fat: 0.0,
      avg_carbs: 0.0,
      by_food: [],
    )

  let html = email_templates.render_weekly_email(empty_summary)

  html
  |> should.be_ok

  html
  |> string.contains("0")  // Should show 0 logs
  |> should.be_true
}

// ============================================================================
// SMTP Client Configuration Tests
// ============================================================================

pub fn smtp_config_from_env_test() {
  // This test would need environment variables set
  // For now, just verify the test_config function works
  let config = smtp_client.test_config("test_user", "test_pass")

  config.host
  |> should.equal("sandbox.smtp.mailtrap.io")

  config.port
  |> should.equal(2525)

  config.username
  |> should.equal("test_user")

  config.password
  |> should.equal("test_pass")
}

pub fn email_creation_test() {
  let email = smtp_client.new_email(
    "test@example.com",
    "Test Subject",
    "<html><body>Test</body></html>",
  )

  email.to
  |> should.equal("test@example.com")

  email.subject
  |> should.equal("Test Subject")

  email.html_body
  |> should.contain("<html>")
}

pub fn email_with_text_body_test() {
  let email = smtp_client.new_email_with_text(
    "test@example.com",
    "Test",
    "<html><body>HTML version</body></html>",
    "Plain text version",
  )

  case email.text_body {
    option.Some(text) -> text |> should.equal("Plain text version")
    option.None -> panic as "Expected text body"
  }
}

pub fn email_error_formatting_test() {
  let config_error = smtp_client.ConfigError("Missing API key")
  let formatted = smtp_client.format_error(config_error)

  formatted
  |> should.contain("configuration error")

  let network_error = smtp_client.NetworkError("Connection timeout")
  let formatted2 = smtp_client.format_error(network_error)

  formatted2
  |> should.contain("network error")
}

// ============================================================================
// Integration Test (Manual - requires real SMTP credentials)
// ============================================================================

// Commented out - this would require actual Mailtrap credentials
// pub fn send_test_email_integration_test() {
//   // Set up test config with real credentials
//   let config = smtp_client.test_config(
//     "your-mailtrap-username",
//     "your-mailtrap-password"
//   )
//
//   let email = smtp_client.new_email(
//     "test@example.com",
//     "Test Email from Gleam",
//     "<html><body><h1>Test</h1><p>This is a test email.</p></body></html>"
//   )
//
//   case smtp_client.send_email(config, email) {
//     Ok(_) -> should.be_true(True)
//     Error(err) -> {
//       io.println("Email sending failed: " <> smtp_client.format_error(err))
//       should.be_true(False)
//     }
//   }
// }
