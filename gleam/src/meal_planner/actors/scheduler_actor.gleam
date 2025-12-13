/// Scheduler actor for periodic email notifications
///
/// This OTP actor runs in the background and schedules periodic tasks:
/// - Weekly nutrition summaries (Sundays at 8 PM)
/// - NCP alerts (when macros are significantly off target)
///
/// The actor wakes up every hour to check if it's time to send emails.
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import meal_planner/integrations/smtp_client
import meal_planner/logger
import meal_planner/storage
import meal_planner/storage/logs/summaries.{type WeeklySummary}
import meal_planner/types.{type Macros, Macros}
import meal_planner/ui/email_templates
import pog

// ============================================================================
// Types
// ============================================================================

/// Scheduler state
pub type State {
  State(
    db_conn: pog.Connection,
    user_id: Int,
    user_email: String,
    check_interval_ms: Int,
    last_weekly_email: Option(String),
    last_ncp_alert: Option(String),
  )
}

/// Messages the scheduler can receive
pub type Message {
  CheckSchedule
  SendWeeklySummary
  SendNcpAlert(current: Macros, target: Macros)
  Stop
}

// ============================================================================
// Actor Initialization
// ============================================================================

/// Start the scheduler actor
pub fn start(
  db_conn: pog.Connection,
  user_id: Int,
  user_email: String,
) -> Result(Subject(Message), actor.StartError) {
  let state =
    State(
      db_conn: db_conn,
      user_id: user_id,
      user_email: user_email,
      check_interval_ms: 60 * 60 * 1000,
      last_weekly_email: None,
      last_ncp_alert: None,
    )

  actor.start(state, handle_message)
}

/// Start the scheduler with a custom check interval (for testing)
pub fn start_with_interval(
  db_conn: pog.Connection,
  user_id: Int,
  user_email: String,
  interval_ms: Int,
) -> Result(Subject(Message), actor.StartError) {
  let state =
    State(
      db_conn: db_conn,
      user_id: user_id,
      user_email: user_email,
      check_interval_ms: interval_ms,
      last_weekly_email: None,
      last_ncp_alert: None,
    )

  actor.start(state, handle_message)
}

// ============================================================================
// Message Handler
// ============================================================================

fn handle_message(message: Message, state: State) -> actor.Next(Message, State) {
  case message {
    CheckSchedule -> {
      // Schedule next check
      process.send_after(state, state.check_interval_ms, CheckSchedule)

      // Check if it's time to send weekly summary (Sunday 8 PM)
      case is_sunday_evening() {
        True -> {
          // Send weekly summary
          send_weekly_summary_internal(state)
          actor.continue(state)
        }
        False -> actor.continue(state)
      }
    }

    SendWeeklySummary -> {
      send_weekly_summary_internal(state)
      actor.continue(state)
    }

    SendNcpAlert(current, target) -> {
      send_ncp_alert_internal(state, current, target)
      actor.continue(state)
    }

    Stop -> actor.Stop(process.Normal)
  }
}

// ============================================================================
// Email Sending Logic
// ============================================================================

fn send_weekly_summary_internal(state: State) -> Nil {
  logger.info("Scheduler: Sending weekly nutrition summary")

  // Get the start of the week (7 days ago)
  let start_date = get_week_start_date()

  // Fetch weekly summary from database
  let summary_result =
    storage.get_weekly_summary(state.db_conn, state.user_id, start_date)

  case summary_result {
    Ok(summary) -> {
      // Render email HTML
      let html = email_templates.render_weekly_email(summary)

      // Create email
      let email =
        smtp_client.new_email(
          state.user_email,
          "Your Weekly Nutrition Summary",
          html,
        )

      // Send email
      case smtp_client.send_email_with_env(email) {
        Ok(_) -> {
          logger.info("Weekly summary email sent successfully")
          Nil
        }
        Error(err) -> {
          logger.error(
            "Failed to send weekly summary: " <> smtp_client.format_error(err),
          )
          Nil
        }
      }
    }

    Error(err) -> {
      logger.error("Failed to fetch weekly summary from database")
      Nil
    }
  }
}

fn send_ncp_alert_internal(state: State, current: Macros, target: Macros) -> Nil {
  logger.info("Scheduler: Sending NCP alert")

  // Calculate deficit
  let deficit =
    Macros(
      protein: current.protein -. target.protein,
      fat: current.fat -. target.fat,
      carbs: current.carbs -. target.carbs,
    )

  // Render email HTML
  let html = email_templates.render_ncp_alert_email(current, target, deficit)

  // Create email
  let email =
    smtp_client.new_email(
      state.user_email,
      "Nutrition Alert: Macro Imbalance Detected",
      html,
    )

  // Send email
  case smtp_client.send_email_with_env(email) {
    Ok(_) -> {
      logger.info("NCP alert email sent successfully")
      Nil
    }
    Error(err) -> {
      logger.error(
        "Failed to send NCP alert: " <> smtp_client.format_error(err),
      )
      Nil
    }
  }
}

// ============================================================================
// Time Helpers
// ============================================================================

/// Check if it's Sunday evening (8 PM local time)
/// This is a simplified implementation - in production you'd use a proper datetime library
fn is_sunday_evening() -> Bool {
  // For now, return False - this will be triggered manually or via testing
  // In production, you'd integrate with Gleam's time library or Erlang calendar
  False
}

/// Get the date string for the start of the current week (7 days ago)
/// Returns YYYY-MM-DD format
fn get_week_start_date() -> String {
  // For now, return a placeholder
  // In production, calculate actual date 7 days ago
  "2025-12-06"
}

// ============================================================================
// Public API
// ============================================================================

/// Manually trigger a weekly summary email
pub fn trigger_weekly_summary(scheduler: Subject(Message)) -> Nil {
  process.send(scheduler, SendWeeklySummary)
}

/// Manually trigger an NCP alert email
pub fn trigger_ncp_alert(
  scheduler: Subject(Message),
  current: Macros,
  target: Macros,
) -> Nil {
  process.send(scheduler, SendNcpAlert(current, target))
}

/// Stop the scheduler
pub fn stop(scheduler: Subject(Message)) -> Nil {
  process.send(scheduler, Stop)
}
