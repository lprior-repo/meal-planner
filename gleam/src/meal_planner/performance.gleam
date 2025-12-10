/// Performance monitoring and benchmarking utilities
/// Tracks query execution times and cache performance
/// Target: Monitor 50% DB load reduction in Phase 2
///
/// SLA Targets (per meal-planner-ous8):
/// - Dashboard load time: <20ms
/// - Search latency: <5ms
/// - Cache hit rate: >80%
/// - Automated alerts for regressions
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/nutrition_constants as constants
import meal_planner/query_cache

// ============================================================================
// Performance Tracking Types
// ============================================================================

pub type PerformanceMetrics {
  PerformanceMetrics(
    query_name: String,
    total_queries: Int,
    cache_hits: Int,
    cache_misses: Int,
    avg_cached_time_ms: Float,
    avg_uncached_time_ms: Float,
    total_time_saved_ms: Float,
    db_load_reduction_percent: Float,
  )
}

pub type BenchmarkResult {
  BenchmarkResult(
    test_name: String,
    iterations: Int,
    avg_time_ms: Float,
    min_time_ms: Float,
    max_time_ms: Float,
    queries_per_second: Float,
  )
}

/// Endpoint types for SLA monitoring
pub type Endpoint {
  Dashboard
  Search
  FoodLookup
}

/// SLA check result with target and actual values
pub type SlaResult {
  SlaResult(
    endpoint: Endpoint,
    target_ms: Float,
    actual_ms: Float,
    passed: Bool,
    sample_count: Int,
  )
}

/// Alert severity levels
pub type AlertSeverity {
  Warning
  Critical
}

/// Performance alert for SLA violations or regressions
pub type PerformanceAlert {
  SlaViolation(endpoint: Endpoint, target_ms: Float, actual_ms: Float)
  CacheHitRateLow(target_rate: Float, actual_rate: Float)
  Regression(
    metric_name: String,
    baseline_ms: Float,
    current_ms: Float,
    degradation_percent: Float,
  )
}

/// Aggregate monitoring state for ongoing tracking
pub type MonitoringState {
  MonitoringState(
    dashboard_samples: List(Float),
    search_samples: List(Float),
    cache_hit_rates: List(Float),
    alerts: List(PerformanceAlert),
  )
}

// ============================================================================
// Performance Monitoring
// ============================================================================

/// Calculate cache hit rate
pub fn calculate_hit_rate(hits: Int, total: Int) -> Float {
  case total > 0 {
    True -> int.to_float(hits) /. int.to_float(total)
    False -> 0.0
  }
}

/// Calculate time saved by caching
pub fn calculate_time_saved(
  cached_time_ms: Float,
  uncached_time_ms: Float,
  cache_hits: Int,
) -> Float {
  let time_per_hit = uncached_time_ms -. cached_time_ms
  time_per_hit *. int.to_float(cache_hits)
}

/// Calculate DB load reduction percentage
pub fn calculate_db_load_reduction(cache_hits: Int, total_queries: Int) -> Float {
  let hit_rate = calculate_hit_rate(cache_hits, total_queries)
  // Each cache hit eliminates a DB query, so hit_rate = load reduction
  hit_rate *. int.to_float(constants.percent_multiplier)
}

/// Generate performance report
pub fn generate_performance_report(
  cache_stats: query_cache.CacheStats,
  avg_cached_time: Float,
  avg_uncached_time: Float,
) -> PerformanceMetrics {
  let total = cache_stats.hits + cache_stats.misses
  let time_saved =
    calculate_time_saved(avg_cached_time, avg_uncached_time, cache_stats.hits)
  let db_reduction = calculate_db_load_reduction(cache_stats.hits, total)

  PerformanceMetrics(
    query_name: "search_foods",
    total_queries: total,
    cache_hits: cache_stats.hits,
    cache_misses: cache_stats.misses,
    avg_cached_time_ms: avg_cached_time,
    avg_uncached_time_ms: avg_uncached_time,
    total_time_saved_ms: time_saved,
    db_load_reduction_percent: db_reduction,
  )
}

// ============================================================================
// Benchmarking
// ============================================================================

/// Run a benchmark test
pub fn benchmark(
  test_name: String,
  iterations: Int,
  test_fn: fn() -> Result(a, b),
) -> BenchmarkResult {
  let start_time = get_timestamp_ms()
  let _results = run_iterations(iterations, test_fn, [])
  let end_time = get_timestamp_ms()

  let total_time = int.to_float(end_time - start_time)
  let avg_time = total_time /. int.to_float(iterations)
  let queries_per_second =
    int.to_float(constants.milliseconds_per_second) /. avg_time

  BenchmarkResult(
    test_name: test_name,
    iterations: iterations,
    avg_time_ms: avg_time,
    min_time_ms: avg_time,
    max_time_ms: avg_time,
    queries_per_second: queries_per_second,
  )
}

/// Run benchmark iterations
fn run_iterations(
  remaining: Int,
  test_fn: fn() -> Result(a, b),
  _results: List(Result(a, b)),
) -> List(Result(a, b)) {
  case remaining {
    0 -> []
    n -> {
      let result = test_fn()
      [result, ..run_iterations(n - 1, test_fn, [])]
    }
  }
}

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

fn get_timestamp_ms() -> Int {
  // Convert to milliseconds
  get_timestamp() / 1_000_000
}

// ============================================================================
// Performance Comparison
// ============================================================================

/// Compare performance before and after optimization
pub fn compare_performance(
  before: BenchmarkResult,
  after: BenchmarkResult,
) -> Float {
  case after.avg_time_ms >. 0.0 {
    True -> before.avg_time_ms /. after.avg_time_ms
    False -> constants.min_speedup_factor
  }
}

/// Format performance improvement as percentage
pub fn format_improvement(speedup_factor: Float) -> String {
  let percent =
    { speedup_factor -. constants.min_speedup_factor }
    *. int.to_float(constants.percent_multiplier)
  let percent_str = float.to_string(percent)
  percent_str <> "% faster"
}

/// Format DB load reduction
pub fn format_db_reduction(reduction_percent: Float) -> String {
  let percent_str = float.to_string(reduction_percent)
  percent_str <> "% DB load reduction"
}

// ============================================================================
// Reporting
// ============================================================================

/// Print performance metrics to console
pub fn print_metrics(metrics: PerformanceMetrics) -> Nil {
  io.println("\n=== Performance Metrics ===")
  io.println("Query: " <> metrics.query_name)
  io.println("Total Queries: " <> int.to_string(metrics.total_queries))
  io.println("Cache Hits: " <> int.to_string(metrics.cache_hits))
  io.println("Cache Misses: " <> int.to_string(metrics.cache_misses))
  io.println(
    "Hit Rate: "
    <> float.to_string(
      calculate_hit_rate(metrics.cache_hits, metrics.total_queries)
      *. int.to_float(constants.percent_multiplier),
    )
    <> "%",
  )
  io.println(
    "Avg Cached Time: " <> float.to_string(metrics.avg_cached_time_ms) <> "ms",
  )
  io.println(
    "Avg Uncached Time: "
    <> float.to_string(metrics.avg_uncached_time_ms)
    <> "ms",
  )
  io.println(
    "Total Time Saved: " <> float.to_string(metrics.total_time_saved_ms) <> "ms",
  )
  io.println(
    "DB Load Reduction: "
    <> float.to_string(metrics.db_load_reduction_percent)
    <> "%",
  )
  io.println("========================\n")
}

/// Print benchmark results
pub fn print_benchmark(result: BenchmarkResult) -> Nil {
  io.println("\n=== Benchmark Results ===")
  io.println("Test: " <> result.test_name)
  io.println("Iterations: " <> int.to_string(result.iterations))
  io.println("Avg Time: " <> float.to_string(result.avg_time_ms) <> "ms")
  io.println("Queries/sec: " <> float.to_string(result.queries_per_second))
  io.println("========================\n")
}

/// Print performance comparison
pub fn print_comparison(before: BenchmarkResult, after: BenchmarkResult) -> Nil {
  let speedup = compare_performance(before, after)
  let improvement = format_improvement(speedup)

  io.println("\n=== Performance Comparison ===")
  io.println("Before: " <> float.to_string(before.avg_time_ms) <> "ms")
  io.println("After: " <> float.to_string(after.avg_time_ms) <> "ms")
  io.println("Speedup: " <> float.to_string(speedup) <> "x")
  io.println("Improvement: " <> improvement)
  io.println("=============================\n")
}

// ============================================================================
// Phase 2 Verification
// ============================================================================

/// Verify Phase 2 performance targets
/// Target: 50% DB load reduction
pub fn verify_phase2_target(
  cache_stats: query_cache.CacheStats,
) -> Result(Nil, String) {
  let db_reduction =
    calculate_db_load_reduction(
      cache_stats.hits,
      cache_stats.hits + cache_stats.misses,
    )

  case db_reduction >=. constants.target_db_load_reduction_percent {
    True -> {
      io.println(
        "✓ Phase 2 target achieved: " <> format_db_reduction(db_reduction),
      )
      Ok(Nil)
    }
    False -> {
      io.println(
        "✗ Phase 2 target not met: "
        <> format_db_reduction(db_reduction)
        <> " (need "
        <> float.to_string(constants.target_db_load_reduction_percent)
        <> "%)",
      )
      Error("DB load reduction below target")
    }
  }
}

/// Generate comprehensive Phase 2 report
pub fn generate_phase2_report(
  cache_stats: query_cache.CacheStats,
  before_benchmark: BenchmarkResult,
  after_benchmark: BenchmarkResult,
) -> String {
  let speedup = compare_performance(before_benchmark, after_benchmark)
  let db_reduction =
    calculate_db_load_reduction(
      cache_stats.hits,
      cache_stats.hits + cache_stats.misses,
    )

  let report =
    string.concat([
      "\n",
      "╔════════════════════════════════════════════════════════════╗\n",
      "║         Phase 2: Database Query Optimization              ║\n",
      "╠════════════════════════════════════════════════════════════╣\n",
      "║ PERFORMANCE IMPROVEMENTS:                                  ║\n",
      "║                                                            ║\n",
      "║ Query Speedup:        ",
      float.to_string(speedup),
      "x                   ║\n",
      "║ DB Load Reduction:    ",
      float.to_string(db_reduction),
      "%                  ║\n",
      "║ Cache Hit Rate:       ",
      float.to_string(
        cache_stats.hit_rate *. int.to_float(constants.percent_multiplier),
      ),
      "%                  ║\n",
      "║                                                            ║\n",
      "║ OPTIMIZATIONS APPLIED:                                     ║\n",
      "║ ✓ Covering indexes for food_logs queries                  ║\n",
      "║ ✓ Partial indexes for search filtering                    ║\n",
      "║ ✓ LRU cache for popular search queries                    ║\n",
      "║ ✓ Query plan optimization with index hints                ║\n",
      "║ ✓ Performance monitoring and metrics                       ║\n",
      "║                                                            ║\n",
      "║ TARGET STATUS:                                             ║\n",
      "║ ",
      case db_reduction >=. constants.target_db_load_reduction_percent {
        True ->
          "✓ ACHIEVED: "
          <> float.to_string(constants.target_db_load_reduction_percent)
          <> "% DB load reduction target          "
        False ->
          "✗ NOT MET: Below "
          <> float.to_string(constants.target_db_load_reduction_percent)
          <> "% target                       "
      },
      "║\n",
      "╚════════════════════════════════════════════════════════════╝\n",
      "\n",
    ])

  report
}

// ============================================================================
// SLA Monitoring (meal-planner-ous8)
// ============================================================================

/// Create initial monitoring state
pub fn new_monitoring_state() -> MonitoringState {
  MonitoringState(
    dashboard_samples: [],
    search_samples: [],
    cache_hit_rates: [],
    alerts: [],
  )
}

/// Get SLA target for an endpoint
pub fn get_sla_target(endpoint: Endpoint) -> Float {
  case endpoint {
    Dashboard -> constants.sla_dashboard_load_ms
    Search -> constants.sla_search_latency_ms
    FoodLookup -> constants.sla_search_latency_ms
  }
}

/// Record a latency sample for an endpoint
pub fn record_sample(
  state: MonitoringState,
  endpoint: Endpoint,
  latency_ms: Float,
) -> MonitoringState {
  case endpoint {
    Dashboard ->
      MonitoringState(..state, dashboard_samples: [
        latency_ms,
        ..state.dashboard_samples
      ])
    Search ->
      MonitoringState(..state, search_samples: [
        latency_ms,
        ..state.search_samples
      ])
    FoodLookup ->
      MonitoringState(..state, search_samples: [
        latency_ms,
        ..state.search_samples
      ])
  }
}

/// Record a cache hit rate observation
pub fn record_cache_hit_rate(
  state: MonitoringState,
  hit_rate: Float,
) -> MonitoringState {
  MonitoringState(..state, cache_hit_rates: [hit_rate, ..state.cache_hit_rates])
}

/// Calculate average of a sample list
fn calculate_average(samples: List(Float)) -> Option(Float) {
  case samples {
    [] -> None
    _ -> {
      let sum = list.fold(samples, 0.0, fn(acc, x) { acc +. x })
      let count = list.length(samples)
      Some(sum /. int.to_float(count))
    }
  }
}

/// Check SLA compliance for an endpoint
pub fn check_sla(state: MonitoringState, endpoint: Endpoint) -> SlaResult {
  let samples = case endpoint {
    Dashboard -> state.dashboard_samples
    Search -> state.search_samples
    FoodLookup -> state.search_samples
  }

  let target = get_sla_target(endpoint)
  let sample_count = list.length(samples)

  case calculate_average(samples) {
    None ->
      SlaResult(
        endpoint: endpoint,
        target_ms: target,
        actual_ms: 0.0,
        passed: True,
        sample_count: 0,
      )
    Some(avg) ->
      SlaResult(
        endpoint: endpoint,
        target_ms: target,
        actual_ms: avg,
        passed: avg <=. target,
        sample_count: sample_count,
      )
  }
}

/// Check cache hit rate against SLA
pub fn check_cache_hit_rate_sla(
  state: MonitoringState,
) -> Result(Float, PerformanceAlert) {
  case calculate_average(state.cache_hit_rates) {
    None -> Ok(0.0)
    Some(avg) ->
      case avg >=. constants.sla_cache_hit_rate {
        True -> Ok(avg)
        False ->
          Error(CacheHitRateLow(
            target_rate: constants.sla_cache_hit_rate,
            actual_rate: avg,
          ))
      }
  }
}

// ============================================================================
// Regression Detection
// ============================================================================

/// Detect performance regression comparing baseline to current
pub fn detect_regression(
  metric_name: String,
  baseline_ms: Float,
  current_ms: Float,
) -> Option(PerformanceAlert) {
  case baseline_ms >. 0.0 {
    False -> None
    True -> {
      let degradation = { current_ms -. baseline_ms } /. baseline_ms *. 100.0
      case degradation >. constants.regression_threshold_percent {
        True ->
          Some(Regression(
            metric_name: metric_name,
            baseline_ms: baseline_ms,
            current_ms: current_ms,
            degradation_percent: degradation,
          ))
        False -> None
      }
    }
  }
}

/// Run all SLA checks and collect alerts
pub fn run_sla_checks(state: MonitoringState) -> List(PerformanceAlert) {
  let dashboard_result = check_sla(state, Dashboard)
  let search_result = check_sla(state, Search)

  let alerts = []

  // Check dashboard SLA
  let alerts = case dashboard_result.passed {
    True -> alerts
    False -> [
      SlaViolation(
        endpoint: Dashboard,
        target_ms: dashboard_result.target_ms,
        actual_ms: dashboard_result.actual_ms,
      ),
      ..alerts
    ]
  }

  // Check search SLA
  let alerts = case search_result.passed {
    True -> alerts
    False -> [
      SlaViolation(
        endpoint: Search,
        target_ms: search_result.target_ms,
        actual_ms: search_result.actual_ms,
      ),
      ..alerts
    ]
  }

  // Check cache hit rate
  case check_cache_hit_rate_sla(state) {
    Ok(_) -> alerts
    Error(alert) -> [alert, ..alerts]
  }
}

/// Format an endpoint name as string
pub fn endpoint_to_string(endpoint: Endpoint) -> String {
  case endpoint {
    Dashboard -> "dashboard"
    Search -> "search"
    FoodLookup -> "food_lookup"
  }
}

/// Format an alert for logging/display
pub fn format_alert(alert: PerformanceAlert) -> String {
  case alert {
    SlaViolation(endpoint, target, actual) ->
      "[SLA VIOLATION] "
      <> endpoint_to_string(endpoint)
      <> ": "
      <> float.to_string(actual)
      <> "ms > "
      <> float.to_string(target)
      <> "ms target"

    CacheHitRateLow(target, actual) ->
      "[CACHE ALERT] Hit rate "
      <> float.to_string(actual *. 100.0)
      <> "% < "
      <> float.to_string(target *. 100.0)
      <> "% target"

    Regression(metric, baseline, current, degradation) ->
      "[REGRESSION] "
      <> metric
      <> ": "
      <> float.to_string(current)
      <> "ms (+"
      <> float.to_string(degradation)
      <> "% from "
      <> float.to_string(baseline)
      <> "ms baseline)"
  }
}

/// Print all current alerts
pub fn print_alerts(alerts: List(PerformanceAlert)) -> Nil {
  case alerts {
    [] -> io.println("✓ All SLA targets met, no regressions detected")
    _ -> {
      io.println("\n=== Performance Alerts ===")
      list.each(alerts, fn(alert) { io.println(format_alert(alert)) })
      io.println("==========================\n")
    }
  }
}

/// Generate SLA status report
pub fn generate_sla_report(state: MonitoringState) -> String {
  let dashboard = check_sla(state, Dashboard)
  let search = check_sla(state, Search)
  let cache_status = case check_cache_hit_rate_sla(state) {
    Ok(rate) -> "✓ " <> float.to_string(rate *. 100.0) <> "%"
    Error(_) -> "✗ Below target"
  }

  string.concat([
    "\n",
    "╔════════════════════════════════════════════════════════════╗\n",
    "║              SLA Performance Report                        ║\n",
    "╠════════════════════════════════════════════════════════════╣\n",
    "║ Dashboard Load Time:                                       ║\n",
    "║   Target: <",
    float.to_string(dashboard.target_ms),
    "ms  Actual: ",
    float.to_string(dashboard.actual_ms),
    "ms  ",
    case dashboard.passed {
      True -> "✓"
      False -> "✗"
    },
    "          ║\n",
    "║                                                            ║\n",
    "║ Search Latency:                                            ║\n",
    "║   Target: <",
    float.to_string(search.target_ms),
    "ms   Actual: ",
    float.to_string(search.actual_ms),
    "ms   ",
    case search.passed {
      True -> "✓"
      False -> "✗"
    },
    "           ║\n",
    "║                                                            ║\n",
    "║ Cache Hit Rate:                                            ║\n",
    "║   Target: >80%    Status: ",
    cache_status,
    "                     ║\n",
    "╚════════════════════════════════════════════════════════════╝\n",
    "\n",
  ])
}
