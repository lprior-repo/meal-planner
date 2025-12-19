/// NCP Controller - The heart of the Nutrition Control Plane
///
/// Implements a Kubernetes-inspired control loop that continuously reconciles
/// actual nutritional state with desired state (goals). Uses Erlang/OTP for
/// fault tolerance and scheduled execution.
///
/// ## Control Loop Pattern (Cockcroft/K8s style)
///
/// 1. Observe: Read current nutrition state from food logs
/// 2. Diff: Calculate deviation from goals
/// 3. Act: Generate recommendations, send alerts, update metrics
/// 4. Repeat: Schedule next reconciliation
///
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import meal_planner/migrate
import meal_planner/ncp.{
  type AdjustmentPlan, type DeviationResult, type NutritionGoals,
  type NutritionState, type RecipeSuggestion, type ReconciliationResult,
  type ScoredRecipe, AdjustmentPlan, DeviationResult, NutritionData,
  NutritionGoals, RecipeSuggestion,
}
import meal_planner/ncp_alerts.{type Alert, type AlertLevel}
import meal_planner/ncp_metrics.{type ControllerMetrics}
import meal_planner/storage
import meal_planner/types.{type Recipe, Macros}

/// Controller configuration
pub type ControllerConfig {
  ControllerConfig(
    /// Interval between reconciliation runs (in milliseconds)
    reconcile_interval_ms: Int,
    /// Deviation threshold for warnings (percentage)
    warning_threshold_pct: Float,
    /// Deviation threshold for critical alerts (percentage)
    critical_threshold_pct: Float,
    /// Maximum number of recipe suggestions to generate
    max_suggestions: Int,
    /// Number of days of history to analyze
    history_days: Int,
    /// Email address for notifications (None = disabled)
    notification_email: Option(String),
    /// Mailtrap API token (None = disabled)
    mailtrap_token: Option(String),
  )
}

/// Default controller configuration
pub fn default_config() -> ControllerConfig {
  ControllerConfig(
    // 15 minutes = 900,000 ms
    reconcile_interval_ms: 900_000,
    warning_threshold_pct: 10.0,
    critical_threshold_pct: 20.0,
    max_suggestions: 3,
    history_days: 7,
    notification_email: None,
    mailtrap_token: None,
  )
}

/// Quick reconciliation config (for testing/demo)
pub fn quick_config() -> ControllerConfig {
  ControllerConfig(
    // 30 seconds for demo
    reconcile_interval_ms: 30_000,
    warning_threshold_pct: 10.0,
    critical_threshold_pct: 20.0,
    max_suggestions: 3,
    history_days: 7,
    notification_email: None,
    mailtrap_token: None,
  )
}

/// Controller state
pub type ControllerState {
  ControllerState(
    config: ControllerConfig,
    /// Last reconciliation result
    last_result: Option(ReconciliationResult),
    /// Current metrics
    metrics: ControllerMetrics,
    /// Pending alerts to be processed
    pending_alerts: List(Alert),
    /// Whether the controller is running
    is_running: Bool,
  )
}

/// Messages the controller can receive
pub type ControllerMessage {
  /// Trigger a reconciliation run
  Reconcile
  /// Stop the controller
  Stop
  /// Get current status
  GetStatus(Subject(ControllerStatus))
  /// Update configuration
  UpdateConfig(ControllerConfig)
  /// Clear pending alerts
  ClearAlerts
  /// Force alert check
  CheckAlerts
}

/// Status response for GetStatus queries
pub type ControllerStatus {
  ControllerStatus(
    is_running: Bool,
    last_result: Option(ReconciliationResult),
    metrics: ControllerMetrics,
    pending_alerts: List(Alert),
  )
}

/// Start the NCP controller as an OTP actor
pub fn start(
  config: ControllerConfig,
) -> actor.StartResult(Subject(ControllerMessage)) {
  let initial_state =
    ControllerState(
      config: config,
      last_result: None,
      metrics: ncp_metrics.new_metrics(),
      pending_alerts: [],
      is_running: True,
    )

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start
}

/// Start with default configuration
pub fn start_default() -> actor.StartResult(Subject(ControllerMessage)) {
  start(default_config())
}

/// Handle incoming messages
fn handle_message(
  state: ControllerState,
  message: ControllerMessage,
) -> actor.Next(ControllerState, ControllerMessage) {
  case message {
    Reconcile -> handle_reconcile(state)
    Stop -> actor.stop()
    GetStatus(reply_to) -> handle_get_status(state, reply_to)
    UpdateConfig(new_config) -> handle_update_config(state, new_config)
    ClearAlerts -> handle_clear_alerts(state)
    CheckAlerts -> handle_check_alerts(state)
  }
}

/// Run a reconciliation cycle
fn handle_reconcile(
  state: ControllerState,
) -> actor.Next(ControllerState, ControllerMessage) {
  io.println("[NCP Controller] Running reconciliation...")

  // Get database path
  let db_path = migrate.get_db_path()

  // Run reconciliation with database connection
  let result =
    storage.with_connection(db_path, fn(conn) {
      // 1. OBSERVE: Get current nutrition state
      let history = case
        storage.get_nutrition_history(conn, state.config.history_days)
      {
        Ok(h) -> h
        Error(_) -> []
      }

      // Get goals
      let goals = case storage.get_goals(conn) {
        Ok(g) -> g
        Error(_) -> ncp.get_default_goals()
      }

      // Get available recipes for suggestions
      let recipes = case storage.get_all_recipes(conn) {
        Ok(r) -> list.map(r, recipe_to_scored)
        Error(_) -> []
      }

      // 2. DIFF: Calculate deviation
      let today = get_today_date()
      let reconciliation_result =
        ncp.run_reconciliation(
          history,
          goals,
          recipes,
          state.config.warning_threshold_pct,
          state.config.max_suggestions,
          today,
        )

      reconciliation_result
    })

  // 3. ACT: Generate alerts based on deviation
  let new_alerts = generate_alerts(result, state.config)

  // Update metrics
  let new_metrics =
    state.metrics
    |> ncp_metrics.record_reconciliation(result)
    |> ncp_metrics.add_alerts(list.length(new_alerts))

  // Log status
  log_reconciliation_result(result)

  // Process alerts (email notifications if configured)
  process_alerts(new_alerts, state.config)

  // Schedule next reconciliation
  let self = process.self()
  schedule_next_reconcile(self, state.config.reconcile_interval_ms)

  // Update state
  let new_state =
    ControllerState(
      ..state,
      last_result: Some(result),
      metrics: new_metrics,
      pending_alerts: list.append(state.pending_alerts, new_alerts),
    )

  actor.continue(new_state)
}

/// Handle status query
fn handle_get_status(
  state: ControllerState,
  reply_to: Subject(ControllerStatus),
) -> actor.Next(ControllerState, ControllerMessage) {
  let status =
    ControllerStatus(
      is_running: state.is_running,
      last_result: state.last_result,
      metrics: state.metrics,
      pending_alerts: state.pending_alerts,
    )
  process.send(reply_to, status)
  actor.continue(state)
}

/// Handle config update
fn handle_update_config(
  state: ControllerState,
  new_config: ControllerConfig,
) -> actor.Next(ControllerState, ControllerMessage) {
  io.println("[NCP Controller] Configuration updated")
  actor.continue(ControllerState(..state, config: new_config))
}

/// Clear pending alerts
fn handle_clear_alerts(
  state: ControllerState,
) -> actor.Next(ControllerState, ControllerMessage) {
  actor.continue(ControllerState(..state, pending_alerts: []))
}

/// Force alert check
fn handle_check_alerts(
  state: ControllerState,
) -> actor.Next(ControllerState, ControllerMessage) {
  case state.last_result {
    Some(result) -> {
      let alerts = generate_alerts(result, state.config)
      process_alerts(alerts, state.config)
      actor.continue(state)
    }
    None -> actor.continue(state)
  }
}

/// Generate alerts based on reconciliation result
fn generate_alerts(
  result: ReconciliationResult,
  config: ControllerConfig,
) -> List(Alert) {
  let dev = result.deviation
  let mut_alerts = []

  // Check protein deviation
  let protein_alert = check_macro_deviation("protein", dev.protein_pct, config)
  let mut_alerts = case protein_alert {
    Some(a) -> [a, ..mut_alerts]
    None -> mut_alerts
  }

  // Check fat deviation
  let fat_alert = check_macro_deviation("fat", dev.fat_pct, config)
  let mut_alerts = case fat_alert {
    Some(a) -> [a, ..mut_alerts]
    None -> mut_alerts
  }

  // Check carbs deviation
  let carbs_alert = check_macro_deviation("carbs", dev.carbs_pct, config)
  let mut_alerts = case carbs_alert {
    Some(a) -> [a, ..mut_alerts]
    None -> mut_alerts
  }

  // Add suggestion alert if we have recommendations
  let mut_alerts = case result.plan.suggestions {
    [] -> mut_alerts
    suggestions -> [
      ncp_alerts.new_alert(
        ncp_alerts.Info,
        "meal_suggestions",
        format_suggestions_message(suggestions),
      ),
      ..mut_alerts
    ]
  }

  mut_alerts
}

/// Check if a macro deviation warrants an alert
fn check_macro_deviation(
  macro_name: String,
  deviation_pct: Float,
  config: ControllerConfig,
) -> Option(Alert) {
  let abs_dev = float.absolute_value(deviation_pct)
  let direction = case deviation_pct <. 0.0 {
    True -> "under"
    False -> "over"
  }

  case abs_dev {
    d if d >=. config.critical_threshold_pct ->
      Some(ncp_alerts.new_alert(
        ncp_alerts.Critical,
        macro_name <> "_deviation",
        macro_name
          <> " is "
          <> float_to_string(abs_dev)
          <> "% "
          <> direction
          <> " target (critical)",
      ))
    d if d >=. config.warning_threshold_pct ->
      Some(ncp_alerts.new_alert(
        ncp_alerts.Warning,
        macro_name <> "_deviation",
        macro_name
          <> " is "
          <> float_to_string(abs_dev)
          <> "% "
          <> direction
          <> " target",
      ))
    _ -> None
  }
}

/// Process alerts (send notifications if configured)
fn process_alerts(alerts: List(Alert), config: ControllerConfig) -> Nil {
  case alerts {
    [] -> Nil
    _ -> {
      // Log all alerts
      list.each(alerts, fn(alert) {
        let level_str = case alert.level {
          ncp_alerts.Critical -> "[CRITICAL]"
          ncp_alerts.Warning -> "[WARNING]"
          ncp_alerts.Info -> "[INFO]"
        }
        io.println(level_str <> " " <> alert.message)
      })

      // Send email for critical alerts if configured
      case config.notification_email, config.mailtrap_token {
        Some(email), Some(token) -> {
          let critical_alerts =
            list.filter(alerts, fn(a) { a.level == ncp_alerts.Critical })
          case critical_alerts {
            [] -> Nil
            _ -> {
              let _ = ncp_alerts.send_alert_email(critical_alerts, email, token)
              Nil
            }
          }
        }
        _, _ -> Nil
      }
    }
  }
}

/// Log reconciliation result
fn log_reconciliation_result(result: ReconciliationResult) -> Nil {
  io.println("───────────────────────────────────────")
  io.println("[NCP] Reconciliation Complete: " <> result.date)
  io.println(
    "  Protein: "
    <> float_to_string(result.average_consumed.protein)
    <> "g / "
    <> float_to_string(result.goals.daily_protein)
    <> "g ("
    <> format_deviation(result.deviation.protein_pct)
    <> ")",
  )
  io.println(
    "  Fat:     "
    <> float_to_string(result.average_consumed.fat)
    <> "g / "
    <> float_to_string(result.goals.daily_fat)
    <> "g ("
    <> format_deviation(result.deviation.fat_pct)
    <> ")",
  )
  io.println(
    "  Carbs:   "
    <> float_to_string(result.average_consumed.carbs)
    <> "g / "
    <> float_to_string(result.goals.daily_carbs)
    <> "g ("
    <> format_deviation(result.deviation.carbs_pct)
    <> ")",
  )
  io.println(
    "  Status:  "
    <> case result.within_tolerance {
      True -> "ON TRACK"
      False -> "NEEDS ADJUSTMENT"
    },
  )
  io.println("───────────────────────────────────────")
}

/// Format deviation with sign
fn format_deviation(pct: Float) -> String {
  let sign = case pct >=. 0.0 {
    True -> "+"
    False -> ""
  }
  sign <> float_to_string(pct) <> "%"
}

/// Format suggestions message
fn format_suggestions_message(suggestions: List(RecipeSuggestion)) -> String {
  "Recommended meals: "
  <> string.join(list.map(suggestions, fn(s) { s.recipe_name }), ", ")
}

/// Schedule next reconciliation
fn schedule_next_reconcile(
  self: Subject(ControllerMessage),
  delay_ms: Int,
) -> Nil {
  // Use Erlang timer to send message after delay
  let _ = send_after(self, Reconcile, delay_ms)
  Nil
}

/// Convert Recipe to ScoredRecipe for NCP
fn recipe_to_scored(recipe: Recipe) -> ScoredRecipe {
  ncp.ScoredRecipe(name: recipe.name, macros: recipe.macros)
}

/// Get today's date as string (YYYY-MM-DD)
fn get_today_date() -> String {
  // Use Erlang's date functions
  let #(year, month, day) = erlang_date()
  int.to_string(year) <> "-" <> pad_int(month) <> "-" <> pad_int(day)
}

/// Pad integer to 2 digits
fn pad_int(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}

/// Float to string with 1 decimal
fn float_to_string(f: Float) -> String {
  let rounded = float.round(f *. 10.0)
  let int_part = rounded / 10
  let dec_part = int.absolute_value(rounded) % 10
  int.to_string(int_part) <> "." <> int.to_string(dec_part)
}

// External Erlang functions
@external(erlang, "erlang", "date")
fn erlang_date() -> #(Int, Int, Int)

@external(erlang, "erlang", "send_after")
fn send_after(dest: Subject(a), msg: a, time: Int) -> Int

/// Run a single reconciliation (useful for CLI/testing)
pub fn run_once() -> ReconciliationResult {
  let db_path = migrate.get_db_path()

  storage.with_connection(db_path, fn(conn) {
    let history = case storage.get_nutrition_history(conn, 7) {
      Ok(h) -> h
      Error(_) -> []
    }

    let goals = case storage.get_goals(conn) {
      Ok(g) -> g
      Error(_) -> ncp.get_default_goals()
    }

    let recipes = case storage.get_all_recipes(conn) {
      Ok(r) -> list.map(r, recipe_to_scored)
      Error(_) -> []
    }

    let today = get_today_date()
    ncp.run_reconciliation(history, goals, recipes, 10.0, 3, today)
  })
}

/// Print formatted status report
pub fn print_status() -> Nil {
  let result = run_once()
  io.println(ncp.format_status_output(result))
}
