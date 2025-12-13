/// NCP (Nutrition Control Plane) calculation performance monitoring
/// Tracks macro calculation, reconciliation, and scoring operations
///
/// Metrics collected:
/// - ncp_calculate_deviation_ms: Deviation calculation time (histogram)
/// - ncp_reconciliation_duration_ms: Full reconciliation time (histogram)
/// - ncp_recipe_scoring_ms: Recipe scoring operations (histogram)
/// - ncp_trend_analysis_ms: Nutrition trend analysis time (histogram)
/// - ncp_operations_total: Total NCP operations (counter)
/// - ncp_calculation_errors: Failed calculations (counter)
/// - ncp_consistency_rate: Consistency percentage (gauge)

import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/metrics/collector.{type MetricCollector}
import meal_planner/metrics/types.{
  type OperationContext, type TimingMeasurement, NcpCalculationMetrics,
  TimingMeasurement,
}

// ============================================================================
// Macro Calculation Monitoring
// ============================================================================

/// Start monitoring a macro calculation operation
pub fn start_macro_calculation(operation: String) -> OperationContext {
  let start_time_ms = get_timestamp_ms()

  types.OperationContext(
    operation_name: "ncp_macro_calculation_" <> operation,
    category: NcpCalculationMetrics,
    start_time_ms: start_time_ms,
    metadata: [#("operation_type", "macro_calculation"), #("operation", operation)],
  )
}

/// Record successful macro calculation
pub fn record_macro_calculation_success(
  collector: MetricCollector,
  context: OperationContext,
  macros_processed: Int,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement = TimingMeasurement(
    operation_name: context.operation_name,
    duration_ms: duration_ms,
    timestamp_ms: end_time_ms,
    success: True,
    error_message: "",
  )

  let collector = collector.record_timing(collector, measurement)

  // Record macros processed
  let collector =
    collector.record_counter(
      collector,
      "ncp_macros_calculated",
      macros_processed,
      [],
    )

  // Record throughput: macros per second
  let throughput = case duration_ms >. 0.0 {
    True -> int.to_float(macros_processed) /. duration_ms *. 1000.0
    False -> 0.0
  }

  collector.record_gauge(
    collector,
    "ncp_calculation_throughput",
    throughput,
    "macros_per_second",
    [],
  )
}

/// Record failed macro calculation
pub fn record_macro_calculation_failure(
  collector: MetricCollector,
  context: OperationContext,
  error_message: String,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement = TimingMeasurement(
    operation_name: context.operation_name,
    duration_ms: duration_ms,
    timestamp_ms: end_time_ms,
    success: False,
    error_message: error_message,
  )

  let collector = collector.record_timing(collector, measurement)

  collector.record_counter(
    collector,
    "ncp_calculation_errors",
    1,
    [#("operation", "macro_calculation")],
  )
}

// ============================================================================
// Deviation Calculation Monitoring
// ============================================================================

/// Start monitoring deviation calculation
pub fn start_deviation_calculation() -> OperationContext {
  let start_time_ms = get_timestamp_ms()

  types.OperationContext(
    operation_name: "ncp_calculate_deviation",
    category: NcpCalculationMetrics,
    start_time_ms: start_time_ms,
    metadata: [#("operation", "deviation_calculation")],
  )
}

/// Record successful deviation calculation
pub fn record_deviation_calculation_success(
  collector: MetricCollector,
  context: OperationContext,
  max_deviation_pct: Float,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement = TimingMeasurement(
    operation_name: context.operation_name,
    duration_ms: duration_ms,
    timestamp_ms: end_time_ms,
    success: True,
    error_message: "",
  )

  let collector = collector.record_timing(collector, measurement)

  // Record max deviation as gauge
  collector.record_gauge(
    collector,
    "ncp_max_deviation",
    max_deviation_pct,
    "percent",
    [],
  )
}

// ============================================================================
// Full Reconciliation Monitoring
// ============================================================================

/// Start monitoring a full NCP reconciliation
pub fn start_reconciliation(history_size: Int) -> OperationContext {
  let start_time_ms = get_timestamp_ms()

  types.OperationContext(
    operation_name: "ncp_run_reconciliation",
    category: NcpCalculationMetrics,
    start_time_ms: start_time_ms,
    metadata: [
      #("operation", "full_reconciliation"),
      #("history_size", int.to_string(history_size)),
    ],
  )
}

/// Record successful reconciliation with results
pub fn record_reconciliation_success(
  collector: MetricCollector,
  context: OperationContext,
  days_analyzed: Int,
  consistency_rate: Float,
  within_tolerance: Bool,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement = TimingMeasurement(
    operation_name: context.operation_name,
    duration_ms: duration_ms,
    timestamp_ms: end_time_ms,
    success: True,
    error_message: "",
  )

  let collector = collector.record_timing(collector, measurement)

  // Record consistency rate
  let collector =
    collector.record_gauge(
      collector,
      "ncp_consistency_rate",
      consistency_rate,
      "percent",
      [],
    )

  // Record if within tolerance
  let tolerance_status = case within_tolerance {
    True -> "within_tolerance"
    False -> "outside_tolerance"
  }

  let collector =
    collector.record_counter(
      collector,
      "ncp_tolerance_checks",
      1,
      [#("status", tolerance_status)],
    )

  // Record days analyzed
  collector.record_gauge(
    collector,
    "ncp_days_analyzed",
    int.to_float(days_analyzed),
    "days",
    [],
  )
}

// ============================================================================
// Recipe Scoring Monitoring
// ============================================================================

/// Start monitoring recipe scoring operation
pub fn start_recipe_scoring(recipe_count: Int) -> OperationContext {
  let start_time_ms = get_timestamp_ms()

  types.OperationContext(
    operation_name: "ncp_score_recipes",
    category: NcpCalculationMetrics,
    start_time_ms: start_time_ms,
    metadata: [
      #("operation", "recipe_scoring"),
      #("recipe_count", int.to_string(recipe_count)),
    ],
  )
}

/// Record successful recipe scoring
pub fn record_recipe_scoring_success(
  collector: MetricCollector,
  context: OperationContext,
  recipes_scored: Int,
  avg_score: Float,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement = TimingMeasurement(
    operation_name: context.operation_name,
    duration_ms: duration_ms,
    timestamp_ms: end_time_ms,
    success: True,
    error_message: "",
  )

  let collector = collector.record_timing(collector, measurement)

  // Record recipes scored
  let collector =
    collector.record_counter(
      collector,
      "ncp_recipes_scored",
      recipes_scored,
      [],
    )

  // Record average score
  let collector =
    collector.record_gauge(
      collector,
      "ncp_average_recipe_score",
      avg_score,
      "score",
      [],
    )

  // Record throughput: recipes per second
  let throughput = case duration_ms >. 0.0 {
    True -> int.to_float(recipes_scored) /. duration_ms *. 1000.0
    False -> 0.0
  }

  collector.record_gauge(
    collector,
    "ncp_recipe_scoring_throughput",
    throughput,
    "recipes_per_second",
    [],
  )
}

// ============================================================================
// Trend Analysis Monitoring
// ============================================================================

/// Start monitoring nutrition trend analysis
pub fn start_trend_analysis(history_size: Int) -> OperationContext {
  let start_time_ms = get_timestamp_ms()

  types.OperationContext(
    operation_name: "ncp_analyze_trends",
    category: NcpCalculationMetrics,
    start_time_ms: start_time_ms,
    metadata: [#("history_size", int.to_string(history_size))],
  )
}

/// Record successful trend analysis
pub fn record_trend_analysis_success(
  collector: MetricCollector,
  context: OperationContext,
  increasing_count: Int,
  decreasing_count: Int,
  stable_count: Int,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement = TimingMeasurement(
    operation_name: context.operation_name,
    duration_ms: duration_ms,
    timestamp_ms: end_time_ms,
    success: True,
    error_message: "",
  )

  let collector = collector.record_timing(collector, measurement)

  // Record trend distributions
  let collector =
    collector.record_counter(
      collector,
      "ncp_trends_increasing",
      increasing_count,
      [],
    )

  let collector =
    collector.record_counter(
      collector,
      "ncp_trends_decreasing",
      decreasing_count,
      [],
    )

  collector.record_counter(
    collector,
    "ncp_trends_stable",
    stable_count,
    [],
  )
}

// ============================================================================
// Variability Calculation Monitoring
// ============================================================================

/// Start monitoring variability calculation
pub fn start_variability_calculation() -> OperationContext {
  let start_time_ms = get_timestamp_ms()

  types.OperationContext(
    operation_name: "ncp_calculate_variability",
    category: NcpCalculationMetrics,
    start_time_ms: start_time_ms,
    metadata: [#("operation", "variability_calculation")],
  )
}

/// Record successful variability calculation
pub fn record_variability_calculation_success(
  collector: MetricCollector,
  context: OperationContext,
  protein_std_dev: Float,
  carbs_std_dev: Float,
  fat_std_dev: Float,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement = TimingMeasurement(
    operation_name: context.operation_name,
    duration_ms: duration_ms,
    timestamp_ms: end_time_ms,
    success: True,
    error_message: "",
  )

  let collector = collector.record_timing(collector, measurement)

  // Record standard deviations
  let collector =
    collector.record_gauge(
      collector,
      "ncp_protein_variability",
      protein_std_dev,
      "grams",
      [],
    )

  let collector =
    collector.record_gauge(
      collector,
      "ncp_carbs_variability",
      carbs_std_dev,
      "grams",
      [],
    )

  collector.record_gauge(
    collector,
    "ncp_fat_variability",
    fat_std_dev,
    "grams",
    [],
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

fn get_timestamp_ms() -> Int {
  get_timestamp() / 1_000_000
}

// ============================================================================
// Module-level type imports
// ============================================================================

import meal_planner/metrics/types
