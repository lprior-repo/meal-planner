/// Tests for NCP Controller - Nutrition Control Plane
///
/// Tests the control loop, alert generation, and metrics tracking
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/ncp.{
  DeviationResult, NutritionData, NutritionGoals, NutritionState,
  RecipeSuggestion, ReconciliationResult, ScoredRecipe,
}
import meal_planner/ncp_alerts
import meal_planner/ncp_controller
import meal_planner/ncp_metrics
import meal_planner/types.{Macros}

// ============================================================================
// Controller Configuration Tests
// ============================================================================

pub fn default_config_has_15_minute_interval_test() {
  let config = ncp_controller.default_config()
  // 15 minutes = 900,000 ms
  should.equal(config.reconcile_interval_ms, 900_000)
}

pub fn default_config_has_reasonable_thresholds_test() {
  let config = ncp_controller.default_config()
  should.equal(config.warning_threshold_pct, 10.0)
  should.equal(config.critical_threshold_pct, 20.0)
}

pub fn quick_config_has_30_second_interval_test() {
  let config = ncp_controller.quick_config()
  should.equal(config.reconcile_interval_ms, 30_000)
}

// ============================================================================
// Alert Level Tests
// ============================================================================

pub fn alert_level_to_string_critical_test() {
  ncp_alerts.level_to_string(ncp_alerts.Critical)
  |> should.equal("CRITICAL")
}

pub fn alert_level_to_string_warning_test() {
  ncp_alerts.level_to_string(ncp_alerts.Warning)
  |> should.equal("WARNING")
}

pub fn alert_level_to_string_info_test() {
  ncp_alerts.level_to_string(ncp_alerts.Info)
  |> should.equal("INFO")
}

pub fn critical_has_highest_priority_test() {
  let critical_priority = ncp_alerts.level_priority(ncp_alerts.Critical)
  let warning_priority = ncp_alerts.level_priority(ncp_alerts.Warning)
  let info_priority = ncp_alerts.level_priority(ncp_alerts.Info)

  // Lower number = higher priority
  should.be_true(critical_priority < warning_priority)
  should.be_true(warning_priority < info_priority)
}

pub fn sort_alerts_by_priority_test() {
  let alerts = [
    ncp_alerts.new_alert(ncp_alerts.Info, "source1", "info message"),
    ncp_alerts.new_alert(ncp_alerts.Critical, "source2", "critical message"),
    ncp_alerts.new_alert(ncp_alerts.Warning, "source3", "warning message"),
  ]

  let sorted = ncp_alerts.sort_by_priority(alerts)

  // First alert should be critical
  case sorted {
    [first, second, third] -> {
      should.equal(first.level, ncp_alerts.Critical)
      should.equal(second.level, ncp_alerts.Warning)
      should.equal(third.level, ncp_alerts.Info)
    }
    _ -> should.fail()
  }
}

pub fn filter_alerts_by_level_test() {
  let alerts = [
    ncp_alerts.new_alert(ncp_alerts.Info, "source1", "info"),
    ncp_alerts.new_alert(ncp_alerts.Critical, "source2", "critical"),
    ncp_alerts.new_alert(ncp_alerts.Warning, "source3", "warning"),
  ]

  // Filter to warning and above (Critical + Warning)
  let filtered = ncp_alerts.filter_by_level(alerts, ncp_alerts.Warning)
  should.equal(list.length(filtered), 2)
}

// ============================================================================
// Alert Generation Tests
// ============================================================================

pub fn protein_deficit_alert_critical_for_large_deficit_test() {
  let alert = ncp_alerts.protein_deficit_alert(25.0)
  should.equal(alert.level, ncp_alerts.Critical)
  should.equal(alert.source, "protein_tracking")
}

pub fn protein_deficit_alert_warning_for_medium_deficit_test() {
  let alert = ncp_alerts.protein_deficit_alert(15.0)
  should.equal(alert.level, ncp_alerts.Warning)
}

pub fn protein_deficit_alert_info_for_small_deficit_test() {
  let alert = ncp_alerts.protein_deficit_alert(5.0)
  should.equal(alert.level, ncp_alerts.Info)
}

pub fn calorie_surplus_alert_critical_for_large_surplus_test() {
  let alert = ncp_alerts.calorie_surplus_alert(25.0)
  should.equal(alert.level, ncp_alerts.Critical)
  should.equal(alert.source, "calorie_tracking")
}

pub fn consistency_alert_critical_for_3_days_off_track_test() {
  let alert = ncp_alerts.consistency_alert(3)
  should.equal(alert.level, ncp_alerts.Critical)
}

pub fn consistency_alert_warning_for_2_days_off_track_test() {
  let alert = ncp_alerts.consistency_alert(2)
  should.equal(alert.level, ncp_alerts.Warning)
}

// ============================================================================
// Metrics Tests
// ============================================================================

pub fn new_metrics_starts_with_zero_counts_test() {
  let metrics = ncp_metrics.new_metrics()
  should.equal(metrics.reconciliation_count, 0)
  should.equal(metrics.on_track_count, 0)
  should.equal(metrics.off_track_count, 0)
  should.equal(metrics.alerts_sent, 0)
}

pub fn record_reconciliation_increments_count_test() {
  let metrics = ncp_metrics.new_metrics()
  let result = create_test_reconciliation_result(True)

  let updated = ncp_metrics.record_reconciliation(metrics, result)

  should.equal(updated.reconciliation_count, 1)
  should.equal(updated.on_track_count, 1)
  should.equal(updated.off_track_count, 0)
}

pub fn record_off_track_result_increments_off_track_count_test() {
  let metrics = ncp_metrics.new_metrics()
  let result = create_test_reconciliation_result(False)

  let updated = ncp_metrics.record_reconciliation(metrics, result)

  should.equal(updated.reconciliation_count, 1)
  should.equal(updated.on_track_count, 0)
  should.equal(updated.off_track_count, 1)
}

pub fn add_alerts_increments_alert_count_test() {
  let metrics = ncp_metrics.new_metrics()
  let updated = ncp_metrics.add_alerts(metrics, 3)
  should.equal(updated.alerts_sent, 3)
}

pub fn consistency_rate_calculates_correctly_test() {
  let metrics = ncp_metrics.new_metrics()

  // Record 3 on-track results
  let on_track_result = create_test_reconciliation_result(True)
  let metrics = ncp_metrics.record_reconciliation(metrics, on_track_result)
  let metrics = ncp_metrics.record_reconciliation(metrics, on_track_result)
  let metrics = ncp_metrics.record_reconciliation(metrics, on_track_result)

  // Record 1 off-track result
  let off_track_result = create_test_reconciliation_result(False)
  let metrics = ncp_metrics.record_reconciliation(metrics, off_track_result)

  // Consistency should be 75% (3/4)
  should.equal(metrics.consistency_rate, 75.0)
}

pub fn is_consistent_true_when_above_80_percent_test() {
  let metrics =
    ncp_metrics.ControllerMetrics(
      reconciliation_count: 10,
      on_track_count: 9,
      off_track_count: 1,
      alerts_sent: 0,
      avg_protein_deviation: 0.0,
      avg_fat_deviation: 0.0,
      avg_carbs_deviation: 0.0,
      max_protein_deviation: 0.0,
      max_fat_deviation: 0.0,
      max_carbs_deviation: 0.0,
      last_reconciliation: None,
      consistency_rate: 90.0,
    )

  should.be_true(ncp_metrics.is_consistent(metrics))
}

pub fn is_consistent_false_when_below_80_percent_test() {
  let metrics =
    ncp_metrics.ControllerMetrics(
      reconciliation_count: 10,
      on_track_count: 7,
      off_track_count: 3,
      alerts_sent: 0,
      avg_protein_deviation: 0.0,
      avg_fat_deviation: 0.0,
      avg_carbs_deviation: 0.0,
      max_protein_deviation: 0.0,
      max_fat_deviation: 0.0,
      max_carbs_deviation: 0.0,
      last_reconciliation: None,
      consistency_rate: 70.0,
    )

  should.be_false(ncp_metrics.is_consistent(metrics))
}

pub fn health_score_is_bounded_0_to_100_test() {
  let metrics =
    ncp_metrics.ControllerMetrics(
      reconciliation_count: 100,
      on_track_count: 100,
      off_track_count: 0,
      alerts_sent: 0,
      avg_protein_deviation: 0.0,
      avg_fat_deviation: 0.0,
      avg_carbs_deviation: 0.0,
      max_protein_deviation: 0.0,
      max_fat_deviation: 0.0,
      max_carbs_deviation: 0.0,
      last_reconciliation: None,
      consistency_rate: 100.0,
    )

  let score = ncp_metrics.get_health_score(metrics)
  should.be_true(score >= 0)
  should.be_true(score <= 100)
}

pub fn export_metrics_returns_all_key_metrics_test() {
  let metrics = ncp_metrics.new_metrics()
  let exported = ncp_metrics.export_metrics(metrics)

  // Should have 12 metrics
  should.equal(list.length(exported), 12)

  // Check that key metrics are present
  let metric_names = list.map(exported, fn(m) { m.0 })
  should.be_true(list.contains(metric_names, "ncp_reconciliation_count"))
  should.be_true(list.contains(metric_names, "ncp_consistency_rate_pct"))
  should.be_true(list.contains(metric_names, "ncp_health_score"))
}

// ============================================================================
// Helper Functions
// ============================================================================

fn create_test_reconciliation_result(
  within_tolerance: Bool,
) -> ReconciliationResult {
  ncp.ReconciliationResult(
    date: "2025-12-02",
    average_consumed: NutritionData(
      protein: 160.0,
      fat: 55.0,
      carbs: 230.0,
      calories: 2100.0,
    ),
    goals: NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    ),
    deviation: DeviationResult(
      protein_pct: -11.1,
      fat_pct: -8.3,
      carbs_pct: -8.0,
      calories_pct: -16.0,
    ),
    plan: ncp.AdjustmentPlan(
      deviation: DeviationResult(
        protein_pct: -11.1,
        fat_pct: -8.3,
        carbs_pct: -8.0,
        calories_pct: -16.0,
      ),
      suggestions: [],
    ),
    within_tolerance: within_tolerance,
  )
}
