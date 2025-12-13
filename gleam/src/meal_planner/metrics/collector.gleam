/// Metric collection and aggregation
/// Provides thread-safe metric collection with mutable storage
///
/// Responsibilities:
/// - Record timing measurements
/// - Aggregate statistics
/// - Calculate percentiles
/// - Export snapshots
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/metrics/types.{
  type Counter, type Gauge, type Metric, type MetricCategory,
  type MetricSnapshot, type OperationContext, type TimingMeasurement,
  type TimingStats, CounterMetric, CustomMetrics, GaugeMetric, MetricSnapshot,
  TandoorApiMetrics, TimingMetric, empty_timing_stats, new_counter_with_labels,
  new_gauge, update_timing_stats,
}

// ============================================================================
// Collector State
// ============================================================================

/// Mutable collector state for in-process metric collection
pub opaque type MetricCollector {
  MetricCollector(
    timing_stats: Dict(String, TimingStats),
    counters: Dict(String, Counter),
    gauges: Dict(String, Gauge),
    timing_samples: Dict(String, List(Float)),
  )
}

// ============================================================================
// Collector Creation and Management
// ============================================================================

/// Create a new empty metric collector
pub fn new_collector() -> MetricCollector {
  MetricCollector(
    timing_stats: dict.new(),
    counters: dict.new(),
    gauges: dict.new(),
    timing_samples: dict.new(),
  )
}

/// Record a timing measurement
pub fn record_timing(
  collector: MetricCollector,
  measurement: TimingMeasurement,
) -> MetricCollector {
  let operation = measurement.operation_name

  let updated_stats = case dict.get(collector.timing_stats, operation) {
    Ok(existing_stats) -> update_timing_stats(existing_stats, measurement)
    Error(Nil) -> {
      let new_stats = empty_timing_stats(operation)
      update_timing_stats(new_stats, measurement)
    }
  }

  let updated_samples = case dict.get(collector.timing_samples, operation) {
    Ok(samples) -> list.append(samples, [measurement.duration_ms])
    Error(Nil) -> [measurement.duration_ms]
  }

  let updated_percentiles = calculate_percentiles(updated_samples)

  let final_stats =
    TimingStats(
      ..updated_stats,
      p95_time_ms: updated_percentiles.0,
      p99_time_ms: updated_percentiles.1,
    )

  MetricCollector(
    timing_stats: dict.insert(collector.timing_stats, operation, final_stats),
    counters: collector.counters,
    gauges: collector.gauges,
    timing_samples: dict.insert(
      collector.timing_samples,
      operation,
      updated_samples,
    ),
  )
}

/// Record a counter increment
pub fn record_counter(
  collector: MetricCollector,
  counter_name: String,
  amount: Int,
  labels: List(#(String, String)),
) -> MetricCollector {
  let key = format_counter_key(counter_name, labels)

  let updated_counter = case dict.get(collector.counters, key) {
    Ok(existing) -> types.Counter(..existing, value: existing.value + amount)
    Error(Nil) -> {
      let new_counter = new_counter_with_labels(counter_name, labels)
      types.Counter(..new_counter, value: amount)
    }
  }

  MetricCollector(
    timing_stats: collector.timing_stats,
    counters: dict.insert(collector.counters, key, updated_counter),
    gauges: collector.gauges,
    timing_samples: collector.timing_samples,
  )
}

/// Record a gauge value
pub fn record_gauge(
  collector: MetricCollector,
  gauge_name: String,
  value: Float,
  unit: String,
  labels: List(#(String, String)),
) -> MetricCollector {
  let key = format_gauge_key(gauge_name, labels)

  let updated_gauge = case dict.get(collector.gauges, key) {
    Ok(existing) -> types.Gauge(..existing, value: value)
    Error(Nil) -> {
      let new_gauge = new_gauge(gauge_name, unit)
      types.Gauge(..new_gauge, value: value, labels: labels)
    }
  }

  MetricCollector(
    timing_stats: collector.timing_stats,
    counters: collector.counters,
    gauges: dict.insert(collector.gauges, key, updated_gauge),
    timing_samples: collector.timing_samples,
  )
}

// ============================================================================
// Snapshot Generation
// ============================================================================

/// Generate a snapshot of all metrics in a category
pub fn snapshot_category(
  collector: MetricCollector,
  category: MetricCategory,
) -> MetricSnapshot {
  let timestamp = get_timestamp_ms()

  // Convert all stats, counters, and gauges to metrics
  let timing_metrics =
    dict.to_list(collector.timing_stats)
    |> list.map(fn(item) {
      let #(_key, stats) = item
      TimingMetric(stats)
    })

  let counter_metrics =
    dict.to_list(collector.counters)
    |> list.map(fn(item) {
      let #(_key, counter) = item
      CounterMetric(counter)
    })

  let gauge_metrics =
    dict.to_list(collector.gauges)
    |> list.map(fn(item) {
      let #(_key, gauge) = item
      GaugeMetric(gauge)
    })

  let all_metrics =
    list.concat([timing_metrics, counter_metrics, gauge_metrics])

  MetricSnapshot(
    category: category,
    timestamp_ms: timestamp,
    metrics: all_metrics,
  )
}

/// Generate snapshots for all categories
pub fn snapshot_all_categories(
  collector: MetricCollector,
) -> List(MetricSnapshot) {
  [
    snapshot_category(collector, TandoorApiMetrics),
    snapshot_category(collector, types.NcpCalculationMetrics),
    snapshot_category(collector, types.StorageQueryMetrics),
    snapshot_category(collector, types.MealGenerationMetrics),
    snapshot_category(collector, types.CacheMetrics),
  ]
}

// ============================================================================
// Statistics Functions
// ============================================================================

/// Calculate total operations
pub fn total_operations(collector: MetricCollector) -> Int {
  dict.to_list(collector.timing_stats)
  |> list.fold(0, fn(acc, item) {
    let #(_key, stats) = item
    acc + stats.count
  })
}

/// Calculate total failures
pub fn total_failures(collector: MetricCollector) -> Int {
  dict.to_list(collector.timing_stats)
  |> list.fold(0, fn(acc, item) {
    let #(_key, stats) = item
    acc + stats.failure_count
  })
}

/// Get success rate as percentage
pub fn success_rate(collector: MetricCollector) -> Float {
  let total = total_operations(collector)
  let failures = total_failures(collector)

  case total > 0 {
    True -> {
      let successes = total - failures
      int_to_float(successes) /. int_to_float(total) *. 100.0
    }
    False -> 0.0
  }
}

/// Get average response time across all operations
pub fn average_response_time(collector: MetricCollector) -> Float {
  let stats_list = dict.to_list(collector.timing_stats)

  case list.is_empty(stats_list) {
    True -> 0.0
    False -> {
      let #(total_time, count) =
        list.fold(stats_list, #(0.0, 0), fn(acc, item) {
          let #(_key, stats) = item
          #(acc.0 +. stats.total_time_ms, acc.1 + stats.count)
        })

      case count > 0 {
        True -> total_time /. int_to_float(count)
        False -> 0.0
      }
    }
  }
}

/// Get slowest operation
pub fn slowest_operation(collector: MetricCollector) -> Option(TimingStats) {
  dict.to_list(collector.timing_stats)
  |> list.sort(fn(a, b) {
    let #(_key_a, stats_a) = a
    let #(_key_b, stats_b) = b
    float.compare(stats_b.max_time_ms, stats_a.max_time_ms)
  })
  |> list.first()
  |> result.map(fn(item) {
    let #(_key, stats) = item
    stats
  })
  |> result.to_option()
}

// ============================================================================
// Percentile Calculation
// ============================================================================

/// Calculate P95 and P99 percentiles from sorted samples
fn calculate_percentiles(samples: List(Float)) -> #(Float, Float) {
  let count = list.length(samples)

  case count {
    0 -> #(0.0, 0.0)
    1 -> {
      let first = list.first(samples) |> result.unwrap(0.0)
      #(first, first)
    }
    _ -> {
      let sorted = list.sort(samples, float.compare)

      // P95: 95th percentile (0-indexed: position at 0.95 * (n-1))
      let p95_index = float.round(0.95 *. int_to_float(count - 1))
      let p95 = case list.at(sorted, p95_index) {
        Ok(val) -> val
        Error(Nil) -> list.last(sorted) |> result.unwrap(0.0)
      }

      // P99: 99th percentile
      let p99_index = float.round(0.99 *. int_to_float(count - 1))
      let p99 = case list.at(sorted, p99_index) {
        Ok(val) -> val
        Error(Nil) -> list.last(sorted) |> result.unwrap(0.0)
      }

      #(p95, p99)
    }
  }
}

// ============================================================================
// Key Formatting
// ============================================================================

/// Format a counter key with labels
fn format_counter_key(name: String, labels: List(#(String, String))) -> String {
  case list.is_empty(labels) {
    True -> name
    False -> {
      let label_str =
        labels
        |> list.map(fn(l) {
          let #(k, v) = l
          k <> "=" <> v
        })
        |> string.join(",")

      name <> "{" <> label_str <> "}"
    }
  }
}

/// Format a gauge key with labels
fn format_gauge_key(name: String, labels: List(#(String, String))) -> String {
  case list.is_empty(labels) {
    True -> name
    False -> {
      let label_str =
        labels
        |> list.map(fn(l) {
          let #(k, v) = l
          k <> "=" <> v
        })
        |> string.join(",")

      name <> "{" <> label_str <> "}"
    }
  }
}

// ============================================================================
// Time Utilities
// ============================================================================

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

/// Convert to milliseconds (system_time returns in nanoseconds)
pub fn get_timestamp_ms() -> Int {
  get_timestamp() / 1_000_000
}

/// Convert int to float
fn int_to_float(n: Int) -> Float {
  int.to_float(n)
}

// ============================================================================
// Helper Types
// ============================================================================

/// Option type for Gleam 1.0 compatibility
pub type Option(a) {
  Some(a)
  None
}

/// Result type for converting
pub type Result(a, b) {
  Ok(a)
  Error(b)
}

// Module-level result functions
import gleam/result

/// Convert Result to Option
fn result_to_option(r: Result(a, b)) -> Option(a) {
  case r {
    Ok(a) -> Some(a)
    Error(_) -> None
  }
}
