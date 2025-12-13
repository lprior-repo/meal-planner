/// Storage query performance monitoring
/// Tracks database query execution times and operation metrics
///
/// Metrics collected:
/// - storage_query_duration_ms: Query execution time (histogram)
/// - storage_query_errors: Failed queries (counter)
/// - storage_rows_affected: Rows modified by operations (counter)
/// - storage_cache_hit_rate: Cache effectiveness (gauge)
/// - storage_query_throughput: Queries per second (gauge)
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import meal_planner/metrics/collector.{type MetricCollector}
import meal_planner/metrics/types.{
  type OperationContext, type TimingMeasurement, StorageQueryMetrics,
  TimingMeasurement,
}

// ============================================================================
// Query Operation Monitoring
// ============================================================================

/// Start monitoring a storage query operation
pub fn start_query(query_type: String, table_name: String) -> OperationContext {
  let start_time_ms = get_timestamp_ms()
  let operation_name = "storage_query_" <> query_type <> "_" <> table_name

  types.OperationContext(
    operation_name: operation_name,
    category: StorageQueryMetrics,
    start_time_ms: start_time_ms,
    metadata: [#("query_type", query_type), #("table", table_name)],
  )
}

/// Record successful query completion
pub fn record_query_success(
  collector: MetricCollector,
  context: OperationContext,
  rows_returned: Int,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement =
    TimingMeasurement(
      operation_name: context.operation_name,
      duration_ms: duration_ms,
      timestamp_ms: end_time_ms,
      success: True,
      error_message: "",
    )

  let collector = collector.record_timing(collector, measurement)

  // Record rows returned
  let collector =
    collector.record_counter(
      collector,
      "storage_rows_returned",
      rows_returned,
      [],
    )

  // Record query efficiency (rows per millisecond)
  let efficiency = case duration_ms >. 0.0 {
    True -> int.to_float(rows_returned) /. duration_ms
    False -> 0.0
  }

  collector.record_gauge(
    collector,
    "storage_query_efficiency",
    efficiency,
    "rows_per_ms",
    [],
  )
}

/// Record failed query
pub fn record_query_failure(
  collector: MetricCollector,
  context: OperationContext,
  error_message: String,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement =
    TimingMeasurement(
      operation_name: context.operation_name,
      duration_ms: duration_ms,
      timestamp_ms: end_time_ms,
      success: False,
      error_message: error_message,
    )

  let collector = collector.record_timing(collector, measurement)

  // Extract query type from metadata
  let query_type = get_metadata_value(context.metadata, "query_type", "unknown")

  collector.record_counter(collector, "storage_query_errors", 1, [
    #("query_type", query_type),
  ])
}

// ============================================================================
// Data Modification Monitoring
// ============================================================================

/// Monitor INSERT operations
pub fn record_insert(
  collector: MetricCollector,
  table_name: String,
  rows_inserted: Int,
  duration_ms: Float,
) -> MetricCollector {
  let collector =
    collector.record_counter(collector, "storage_inserts", rows_inserted, [
      #("table", table_name),
    ])

  collector.record_gauge(
    collector,
    "storage_insert_duration",
    duration_ms,
    "ms",
    [#("table", table_name)],
  )
}

/// Monitor UPDATE operations
pub fn record_update(
  collector: MetricCollector,
  table_name: String,
  rows_updated: Int,
  duration_ms: Float,
) -> MetricCollector {
  let collector =
    collector.record_counter(collector, "storage_updates", rows_updated, [
      #("table", table_name),
    ])

  collector.record_gauge(
    collector,
    "storage_update_duration",
    duration_ms,
    "ms",
    [#("table", table_name)],
  )
}

/// Monitor DELETE operations
pub fn record_delete(
  collector: MetricCollector,
  table_name: String,
  rows_deleted: Int,
  duration_ms: Float,
) -> MetricCollector {
  let collector =
    collector.record_counter(collector, "storage_deletes", rows_deleted, [
      #("table", table_name),
    ])

  collector.record_gauge(
    collector,
    "storage_delete_duration",
    duration_ms,
    "ms",
    [#("table", table_name)],
  )
}

// ============================================================================
// Complex Query Monitoring (Daily Logs, Searches, etc.)
// ============================================================================

/// Monitor complex queries like get_daily_log
pub fn record_complex_query(
  collector: MetricCollector,
  query_name: String,
  duration_ms: Float,
  rows_processed: Int,
  success: Bool,
) -> MetricCollector {
  let collector =
    collector.record_counter(collector, "storage_complex_queries", 1, [
      #("query_name", query_name),
    ])

  let collector =
    collector.record_counter(
      collector,
      "storage_rows_processed",
      rows_processed,
      [#("query_name", query_name)],
    )

  let status = case success {
    True -> "success"
    False -> "failure"
  }

  let collector =
    collector.record_counter(collector, "storage_query_outcomes", 1, [
      #("status", status),
    ])

  collector.record_gauge(
    collector,
    "storage_complex_query_duration",
    duration_ms,
    "ms",
    [#("query_name", query_name)],
  )
}

// ============================================================================
// Cache Monitoring
// ============================================================================

/// Record cache hit
pub fn record_cache_hit(
  collector: MetricCollector,
  cache_key: String,
) -> MetricCollector {
  collector.record_counter(collector, "storage_cache_hits", 1, [
    #("cache_key", cache_key),
  ])
}

/// Record cache miss
pub fn record_cache_miss(
  collector: MetricCollector,
  cache_key: String,
) -> MetricCollector {
  collector.record_counter(collector, "storage_cache_misses", 1, [
    #("cache_key", cache_key),
  ])
}

/// Record overall cache hit rate
pub fn record_cache_statistics(
  collector: MetricCollector,
  total_hits: Int,
  total_misses: Int,
) -> MetricCollector {
  let total = total_hits + total_misses

  let hit_rate = case total > 0 {
    True -> int.to_float(total_hits) /. int.to_float(total) *. 100.0
    False -> 0.0
  }

  collector.record_gauge(
    collector,
    "storage_cache_hit_rate",
    hit_rate,
    "percent",
    [],
  )
}

// ============================================================================
// Batch Operation Monitoring
// ============================================================================

/// Monitor batch food log query
pub fn record_food_logs_batch(
  collector: MetricCollector,
  date: String,
  entries_returned: Int,
  duration_ms: Float,
) -> MetricCollector {
  let collector =
    collector.record_counter(
      collector,
      "storage_food_logs_fetched",
      entries_returned,
      [#("date", date)],
    )

  collector.record_gauge(
    collector,
    "storage_food_logs_duration",
    duration_ms,
    "ms",
    [#("date", date)],
  )
}

/// Monitor batch recent meals query
pub fn record_recent_meals_batch(
  collector: MetricCollector,
  meals_returned: Int,
  duration_ms: Float,
) -> MetricCollector {
  let collector =
    collector.record_counter(
      collector,
      "storage_recent_meals_fetched",
      meals_returned,
      [],
    )

  collector.record_gauge(
    collector,
    "storage_recent_meals_duration",
    duration_ms,
    "ms",
    [],
  )
}

// ============================================================================
// Connection Pool Monitoring
// ============================================================================

/// Monitor database connection pool state
pub fn record_connection_pool_state(
  collector: MetricCollector,
  active_connections: Int,
  idle_connections: Int,
  max_connections: Int,
) -> MetricCollector {
  let collector =
    collector.record_gauge(
      collector,
      "storage_active_connections",
      int.to_float(active_connections),
      "count",
      [],
    )

  let collector =
    collector.record_gauge(
      collector,
      "storage_idle_connections",
      int.to_float(idle_connections),
      "count",
      [],
    )

  let utilization = case max_connections > 0 {
    True ->
      int.to_float(active_connections) /. int.to_float(max_connections) *. 100.0
    False -> 0.0
  }

  collector.record_gauge(
    collector,
    "storage_connection_utilization",
    utilization,
    "percent",
    [],
  )
}

// ============================================================================
// Aggregate Statistics
// ============================================================================

/// Record period statistics (e.g., hourly report)
pub fn record_period_statistics(
  collector: MetricCollector,
  period_label: String,
  total_queries: Int,
  failed_queries: Int,
  avg_duration_ms: Float,
) -> MetricCollector {
  let collector =
    collector.record_counter(
      collector,
      "storage_period_total_queries",
      total_queries,
      [#("period", period_label)],
    )

  let collector =
    collector.record_counter(
      collector,
      "storage_period_failed_queries",
      failed_queries,
      [#("period", period_label)],
    )

  let success_rate = case total_queries > 0 {
    True ->
      int.to_float(total_queries - failed_queries)
      /. int.to_float(total_queries)
      *. 100.0
    False -> 0.0
  }

  let collector =
    collector.record_gauge(
      collector,
      "storage_period_success_rate",
      success_rate,
      "percent",
      [#("period", period_label)],
    )

  collector.record_gauge(
    collector,
    "storage_period_avg_duration",
    avg_duration_ms,
    "ms",
    [#("period", period_label)],
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get metadata value from context
fn get_metadata_value(
  metadata: List(#(String, String)),
  key: String,
  default: String,
) -> String {
  list.find(metadata, fn(item) {
    let #(k, _v) = item
    k == key
  })
  |> result.map(fn(item) {
    let #(_k, v) = item
    v
  })
  |> result.unwrap(default)
}

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

fn get_timestamp_ms() -> Int {
  get_timestamp() / 1_000_000
}
