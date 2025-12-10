/// NCP Metrics - Observability for the Nutrition Control Plane
///
/// Implements metrics collection following Cockcroft's observability principles.
/// Tracks key performance indicators for nutrition automation.
///
import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import meal_planner/ncp.{type ReconciliationResult}

/// Controller metrics state
pub type ControllerMetrics {
  ControllerMetrics(
    /// Total number of reconciliations run
    reconciliation_count: Int,
    /// Number of times within tolerance
    on_track_count: Int,
    /// Number of times outside tolerance
    off_track_count: Int,
    /// Total alerts generated
    alerts_sent: Int,
    /// Running average protein deviation
    avg_protein_deviation: Float,
    /// Running average fat deviation
    avg_fat_deviation: Float,
    /// Running average carbs deviation
    avg_carbs_deviation: Float,
    /// Maximum protein deviation seen
    max_protein_deviation: Float,
    /// Maximum fat deviation seen
    max_fat_deviation: Float,
    /// Maximum carbs deviation seen
    max_carbs_deviation: Float,
    /// Last reconciliation timestamp
    last_reconciliation: Option(String),
    /// Consistency rate (% of reconciliations on track)
    consistency_rate: Float,
  )
}

/// Create new metrics instance
pub fn new_metrics() -> ControllerMetrics {
  ControllerMetrics(
    reconciliation_count: 0,
    on_track_count: 0,
    off_track_count: 0,
    alerts_sent: 0,
    avg_protein_deviation: 0.0,
    avg_fat_deviation: 0.0,
    avg_carbs_deviation: 0.0,
    max_protein_deviation: 0.0,
    max_fat_deviation: 0.0,
    max_carbs_deviation: 0.0,
    last_reconciliation: None,
    consistency_rate: 0.0,
  )
}

/// Record a reconciliation result
pub fn record_reconciliation(
  metrics: ControllerMetrics,
  result: ReconciliationResult,
) -> ControllerMetrics {
  let new_count = metrics.reconciliation_count + 1
  let new_on_track = case result.within_tolerance {
    True -> metrics.on_track_count + 1
    False -> metrics.on_track_count
  }
  let new_off_track = case result.within_tolerance {
    False -> metrics.off_track_count + 1
    True -> metrics.off_track_count
  }

  // Update running averages
  let dev = result.deviation
  let new_avg_protein =
    update_running_avg(
      metrics.avg_protein_deviation,
      dev.protein_pct,
      new_count,
    )
  let new_avg_fat =
    update_running_avg(metrics.avg_fat_deviation, dev.fat_pct, new_count)
  let new_avg_carbs =
    update_running_avg(metrics.avg_carbs_deviation, dev.carbs_pct, new_count)

  // Update max deviations
  let new_max_protein =
    float.max(
      metrics.max_protein_deviation,
      float.absolute_value(dev.protein_pct),
    )
  let new_max_fat =
    float.max(metrics.max_fat_deviation, float.absolute_value(dev.fat_pct))
  let new_max_carbs =
    float.max(metrics.max_carbs_deviation, float.absolute_value(dev.carbs_pct))

  // Calculate consistency rate
  let consistency = case new_count {
    0 -> 0.0
    n -> int_to_float(new_on_track) /. int_to_float(n) *. 100.0
  }

  ControllerMetrics(
    reconciliation_count: new_count,
    on_track_count: new_on_track,
    off_track_count: new_off_track,
    alerts_sent: metrics.alerts_sent,
    avg_protein_deviation: new_avg_protein,
    avg_fat_deviation: new_avg_fat,
    avg_carbs_deviation: new_avg_carbs,
    max_protein_deviation: new_max_protein,
    max_fat_deviation: new_max_fat,
    max_carbs_deviation: new_max_carbs,
    last_reconciliation: Some(result.date),
    consistency_rate: consistency,
  )
}

/// Add to alerts sent count
pub fn add_alerts(metrics: ControllerMetrics, count: Int) -> ControllerMetrics {
  ControllerMetrics(..metrics, alerts_sent: metrics.alerts_sent + count)
}

/// Get current consistency rate
pub fn get_consistency_rate(metrics: ControllerMetrics) -> Float {
  metrics.consistency_rate
}

/// Check if user is consistently on track (>= 80%)
pub fn is_consistent(metrics: ControllerMetrics) -> Bool {
  metrics.consistency_rate >=. 80.0
}

/// Get health score (0-100)
/// Based on consistency, deviation averages, and alert frequency
pub fn get_health_score(metrics: ControllerMetrics) -> Int {
  // Start with consistency as base (40% weight)
  let consistency_score = metrics.consistency_rate *. 0.4

  // Add deviation score (40% weight) - lower deviation = higher score
  let avg_dev =
    {
      float.absolute_value(metrics.avg_protein_deviation)
      +. float.absolute_value(metrics.avg_fat_deviation)
      +. float.absolute_value(metrics.avg_carbs_deviation)
    }
    /. 3.0
  let deviation_score = float.max(0.0, { 100.0 -. avg_dev *. 2.0 }) *. 0.4

  // Add alert frequency score (20% weight) - fewer alerts = higher score
  let alert_rate = case metrics.reconciliation_count {
    0 -> 0.0
    n -> int_to_float(metrics.alerts_sent) /. int_to_float(n) *. 100.0
  }
  let alert_score = float.max(0.0, { 100.0 -. alert_rate *. 10.0 }) *. 0.2

  float.round(consistency_score +. deviation_score +. alert_score)
}

/// Format metrics for display
pub fn format_metrics(metrics: ControllerMetrics) -> String {
  let health = get_health_score(metrics)

  "NCP Controller Metrics\n"
  <> "======================\n"
  <> "Health Score: "
  <> int.to_string(health)
  <> "/100\n"
  <> "Reconciliations: "
  <> int.to_string(metrics.reconciliation_count)
  <> "\n"
  <> "On Track: "
  <> int.to_string(metrics.on_track_count)
  <> " ("
  <> float_to_string(metrics.consistency_rate)
  <> "%)\n"
  <> "Off Track: "
  <> int.to_string(metrics.off_track_count)
  <> "\n"
  <> "Alerts Sent: "
  <> int.to_string(metrics.alerts_sent)
  <> "\n"
  <> "\nDeviation Averages:\n"
  <> "  Protein: "
  <> float_to_string(metrics.avg_protein_deviation)
  <> "%\n"
  <> "  Fat:     "
  <> float_to_string(metrics.avg_fat_deviation)
  <> "%\n"
  <> "  Carbs:   "
  <> float_to_string(metrics.avg_carbs_deviation)
  <> "%\n"
  <> "\nMax Deviations:\n"
  <> "  Protein: "
  <> float_to_string(metrics.max_protein_deviation)
  <> "%\n"
  <> "  Fat:     "
  <> float_to_string(metrics.max_fat_deviation)
  <> "%\n"
  <> "  Carbs:   "
  <> float_to_string(metrics.max_carbs_deviation)
  <> "%\n"
  <> case metrics.last_reconciliation {
    Some(ts) -> "\nLast Reconciliation: " <> ts <> "\n"
    None -> ""
  }
}

/// Export metrics as key-value pairs (for Prometheus/StatsD style export)
pub fn export_metrics(metrics: ControllerMetrics) -> List(#(String, Float)) {
  [
    #("ncp_reconciliation_count", int_to_float(metrics.reconciliation_count)),
    #("ncp_on_track_count", int_to_float(metrics.on_track_count)),
    #("ncp_off_track_count", int_to_float(metrics.off_track_count)),
    #("ncp_alerts_sent", int_to_float(metrics.alerts_sent)),
    #("ncp_avg_protein_deviation_pct", metrics.avg_protein_deviation),
    #("ncp_avg_fat_deviation_pct", metrics.avg_fat_deviation),
    #("ncp_avg_carbs_deviation_pct", metrics.avg_carbs_deviation),
    #("ncp_max_protein_deviation_pct", metrics.max_protein_deviation),
    #("ncp_max_fat_deviation_pct", metrics.max_fat_deviation),
    #("ncp_max_carbs_deviation_pct", metrics.max_carbs_deviation),
    #("ncp_consistency_rate_pct", metrics.consistency_rate),
    #("ncp_health_score", int_to_float(get_health_score(metrics))),
  ]
}

// Helper functions

fn update_running_avg(old_avg: Float, new_value: Float, count: Int) -> Float {
  case count {
    0 -> new_value
    1 -> new_value
    n -> {
      let n_float = int_to_float(n)
      { old_avg *. { n_float -. 1.0 } +. new_value } /. n_float
    }
  }
}

fn float_to_string(f: Float) -> String {
  let rounded = float.round(f *. 10.0)
  let sign = case rounded < 0 {
    True -> "-"
    False -> ""
  }
  let abs_rounded = int_absolute(rounded)
  let int_part = abs_rounded / 10
  let dec_part = abs_rounded % 10
  sign <> int.to_string(int_part) <> "." <> int.to_string(dec_part)
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

@external(erlang, "erlang", "abs")
fn int_absolute(n: Int) -> Int
