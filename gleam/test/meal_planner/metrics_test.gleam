/// Tests for Prometheus metrics collection and export
///
import gleam/list
import gleam/option
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/metrics/mod as metrics
import meal_planner/metrics/prometheus
import meal_planner/metrics/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Counter Tests
// ============================================================================

pub fn test_metrics_create_counter() {
  let registry = metrics.new_registry()
  let #(updated, counter) =
    metrics.get_or_create_counter(registry, "test_counter", "A test counter")

  counter.name |> should.equal("test_counter")
  counter.description |> should.equal("A test counter")
  counter.value |> should.equal(0)
  metrics.metrics_count(updated) |> should.equal(1)
}

pub fn test_metrics_increment_counter() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_counter(registry, "test_counter", "Test counter")
  let reg2 = metrics.increment_counter(reg1, "test_counter", 5)
  let reg3 = metrics.increment_counter(reg2, "test_counter", 3)

  let counter = case metrics.find_metric(reg3, "test_counter") {
    Some(metrics.CounterMetric(c)) -> c
    _ -> panic
  }

  counter.value |> should.equal(8)
}

pub fn test_metrics_counter_with_labels() {
  let registry = metrics.new_registry()
  let labels = [
    types.label("service", "storage"),
    types.label("operation", "query"),
  ]
  let #(updated, _counter) =
    metrics.get_or_create_counter_with_labels(
      registry,
      "storage_operations",
      "Storage operations",
      labels,
    )

  metrics.metrics_count(updated) |> should.equal(1)
}

pub fn test_metrics_increment_counter_with_labels() {
  let registry = metrics.new_registry()
  let labels = [
    types.label("service", "storage"),
    types.label("operation", "query"),
  ]
  let #(reg1, _) =
    metrics.get_or_create_counter_with_labels(
      registry,
      "storage_ops",
      "Storage ops",
      labels,
    )
  let reg2 =
    metrics.increment_counter_with_labels(reg1, "storage_ops", labels, 10)

  let metrics_list = metrics.find_metrics_by_name(reg2, "storage_ops")
  metrics_list |> list.length() |> should.equal(1)
}

// ============================================================================
// Gauge Tests
// ============================================================================

pub fn test_metrics_create_gauge() {
  let registry = metrics.new_registry()
  let #(updated, gauge) =
    metrics.get_or_create_gauge(
      registry,
      "active_connections",
      "Active connections",
    )

  gauge.name |> should.equal("active_connections")
  gauge.description |> should.equal("Active connections")
  gauge.value |> should.equal(0.0)
  metrics.metrics_count(updated) |> should.equal(1)
}

pub fn test_metrics_set_gauge() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_gauge(registry, "active_requests", "Active requests")
  let reg2 = metrics.set_gauge(reg1, "active_requests", 42.0)

  let gauge = case metrics.find_metric(reg2, "active_requests") {
    Some(metrics.GaugeMetric(g)) -> g
    _ -> panic
  }

  gauge.value |> should.equal(42.0)
}

pub fn test_metrics_add_gauge() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_gauge(registry, "memory_usage", "Memory usage")
  let reg2 = metrics.add_gauge(reg1, "memory_usage", 100.0)
  let reg3 = metrics.add_gauge(reg2, "memory_usage", 50.0)

  let gauge = case metrics.find_metric(reg3, "memory_usage") {
    Some(metrics.GaugeMetric(g)) -> g
    _ -> panic
  }

  gauge.value |> should.equal(150.0)
}

pub fn test_metrics_gauge_with_labels() {
  let registry = metrics.new_registry()
  let labels = [types.label("instance", "server-1")]
  let #(updated, _) =
    metrics.get_or_create_gauge_with_labels(
      registry,
      "cpu_usage",
      "CPU usage",
      labels,
    )

  metrics.metrics_count(updated) |> should.equal(1)
}

// ============================================================================
// Histogram Tests
// ============================================================================

pub fn test_metrics_create_histogram() {
  let registry = metrics.new_registry()
  let #(updated, histogram) =
    metrics.get_or_create_histogram(
      registry,
      "request_duration_ms",
      "Request duration",
      types.DefaultBuckets,
    )

  histogram.name |> should.equal("request_duration_ms")
  histogram.sum |> should.equal(0.0)
  histogram.count |> should.equal(0)
  histogram.buckets |> list.length() |> should.be_greater_than(0)
  metrics.metrics_count(updated) |> should.equal(1)
}

pub fn test_metrics_observe_histogram() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_histogram(
      registry,
      "query_time_ms",
      "Query time",
      types.DefaultBuckets,
    )
  let reg2 = metrics.observe_histogram(reg1, "query_time_ms", 45.0)
  let reg3 = metrics.observe_histogram(reg2, "query_time_ms", 55.0)

  let histogram = case metrics.find_metric(reg3, "query_time_ms") {
    Some(metrics.HistogramMetric(h)) -> h
    _ -> panic
  }

  histogram.count |> should.equal(2)
  histogram.sum |> should.equal(100.0)
}

pub fn test_metrics_histogram_bucket_distribution() {
  let registry = metrics.new_registry()
  let buckets = types.CustomBuckets([10.0, 50.0, 100.0, 500.0])
  let #(reg1, _) =
    metrics.get_or_create_histogram(
      registry,
      "timing",
      "Timing histogram",
      buckets,
    )

  // Record values that fall into different buckets
  let reg2 = metrics.observe_histogram(reg1, "timing", 5.0)
  // Less than 10
  let reg3 = metrics.observe_histogram(reg2, "timing", 25.0)
  // Between 10 and 50
  let reg4 = metrics.observe_histogram(reg3, "timing", 75.0)
  // Between 50 and 100
  let reg5 = metrics.observe_histogram(reg4, "timing", 200.0)
  // Between 100 and 500

  let histogram = case metrics.find_metric(reg5, "timing") {
    Some(metrics.HistogramMetric(h)) -> h
    _ -> panic
  }

  // All 4 observations should be counted across buckets
  histogram.count |> should.equal(4)
  histogram.sum |> should.equal(305.0)

  // Each bucket should have cumulative count
  let bucket_10 = case
    list.find(histogram.buckets, fn(b) { b.boundary == 10.0 })
  {
    Ok(b) -> b
    Error(_) -> panic
  }
  bucket_10.count |> should.equal(1)
  // Only 5.0 falls in <= 10.0
}

pub fn test_metrics_histogram_with_labels() {
  let registry = metrics.new_registry()
  let labels = [
    types.label("endpoint", "/api/search"),
    types.label("method", "GET"),
  ]
  let #(updated, _) =
    metrics.get_or_create_histogram_with_labels(
      registry,
      "http_request_duration_ms",
      "HTTP request duration",
      types.DefaultBuckets,
      labels,
    )

  metrics.metrics_count(updated) |> should.equal(1)
}

// ============================================================================
// Registry Operations
// ============================================================================

pub fn test_metrics_find_metric_by_name() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_counter(registry, "test_counter", "Test")
  let #(reg2, _) = metrics.get_or_create_gauge(reg1, "test_gauge", "Test")

  let found = metrics.find_metric(reg2, "test_counter")
  case found {
    Some(metrics.CounterMetric(c)) -> c.name |> should.equal("test_counter")
    _ -> should.fail()
  }
}

pub fn test_metrics_find_metrics_by_prefix() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_counter(
      registry,
      "http_requests_total",
      "HTTP requests",
    )
  let #(reg2, _) =
    metrics.get_or_create_counter(reg1, "http_errors_total", "HTTP errors")
  let #(reg3, _) =
    metrics.get_or_create_counter(reg2, "db_queries_total", "DB queries")

  let http_metrics = metrics.find_metrics_by_prefix(reg3, "http_")
  http_metrics |> list.length() |> should.equal(2)
}

pub fn test_metrics_clear_registry() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_counter(registry, "test_counter", "Test")
  let #(reg2, _) = metrics.get_or_create_gauge(reg1, "test_gauge", "Test")

  metrics.metrics_count(reg2) |> should.equal(2)

  let cleared = metrics.clear_registry()
  metrics.metrics_count(cleared) |> should.equal(0)
}

// ============================================================================
// Prometheus Export Tests
// ============================================================================

pub fn test_prometheus_format_counter() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_counter(
      registry,
      "requests_total",
      "HTTP requests processed",
    )
  let reg2 = metrics.increment_counter(reg1, "requests_total", 42)

  let output = metrics.export_prometheus(reg2)

  output
  |> string.contains("# HELP requests_total HTTP requests processed")
  |> should.equal(True)
  output
  |> string.contains("# TYPE requests_total counter")
  |> should.equal(True)
  output |> string.contains("requests_total 42") |> should.equal(True)
}

pub fn test_prometheus_format_gauge() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_gauge(
      registry,
      "active_connections",
      "Active connections",
    )
  let reg2 = metrics.set_gauge(reg1, "active_connections", 15.0)

  let output = metrics.export_prometheus(reg2)

  output
  |> string.contains("# HELP active_connections Active connections")
  |> should.equal(True)
  output
  |> string.contains("# TYPE active_connections gauge")
  |> should.equal(True)
  output |> string.contains("active_connections 15") |> should.equal(True)
}

pub fn test_prometheus_format_histogram() {
  let registry = metrics.new_registry()
  let buckets = types.CustomBuckets([10.0, 100.0, 1000.0])
  let #(reg1, _) =
    metrics.get_or_create_histogram(
      registry,
      "request_duration_ms",
      "Request duration in milliseconds",
      buckets,
    )
  let reg2 = metrics.observe_histogram(reg1, "request_duration_ms", 50.0)
  let reg3 = metrics.observe_histogram(reg2, "request_duration_ms", 150.0)

  let output = metrics.export_prometheus(reg3)

  output
  |> string.contains(
    "# HELP request_duration_ms Request duration in milliseconds",
  )
  |> should.equal(True)
  output
  |> string.contains("# TYPE request_duration_ms histogram")
  |> should.equal(True)
  output |> string.contains("request_duration_ms_bucket") |> should.equal(True)
  output |> string.contains("request_duration_ms_sum") |> should.equal(True)
  output |> string.contains("request_duration_ms_count") |> should.equal(True)
}

pub fn test_prometheus_format_with_labels() {
  let registry = metrics.new_registry()
  let labels = [
    types.label("service", "storage"),
    types.label("operation", "query"),
  ]
  let #(reg1, _) =
    metrics.get_or_create_counter_with_labels(
      registry,
      "operations_total",
      "Total operations",
      labels,
    )
  let reg2 =
    metrics.increment_counter_with_labels(reg1, "operations_total", labels, 25)

  let output = metrics.export_prometheus(reg2)

  output |> string.contains("operations_total{") |> should.equal(True)
  output |> string.contains("service=\"storage\"") |> should.equal(True)
  output |> string.contains("operation=\"query\"") |> should.equal(True)
}

pub fn test_prometheus_format_empty_registry() {
  let registry = metrics.new_registry()
  let output = metrics.export_prometheus(registry)

  output |> should.equal("\n")
}

pub fn test_prometheus_format_multiple_metrics() {
  let registry = metrics.new_registry()
  let #(reg1, _) =
    metrics.get_or_create_counter(registry, "requests_total", "Requests")
  let reg2 = metrics.increment_counter(reg1, "requests_total", 100)
  let #(reg3, _) =
    metrics.get_or_create_gauge(reg2, "active_connections", "Connections")
  let reg4 = metrics.set_gauge(reg3, "active_connections", 42.0)

  let output = metrics.export_prometheus(reg4)

  // Should contain both metrics
  output |> string.contains("requests_total") |> should.equal(True)
  output |> string.contains("active_connections") |> should.equal(True)
  output |> string.contains("100") |> should.equal(True)
  output |> string.contains("42") |> should.equal(True)
}

// ============================================================================
// Integration Tests
// ============================================================================

pub fn test_metrics_realistic_monitoring_scenario() {
  // Simulate a realistic monitoring scenario
  let registry = metrics.new_registry()

  // Create storage query metrics
  let #(reg1, _) =
    metrics.get_or_create_histogram(
      registry,
      "storage_query_duration_ms",
      "Storage query execution time",
      types.DefaultBuckets,
    )

  // Record some query times
  let reg2 = metrics.observe_histogram(reg1, "storage_query_duration_ms", 12.0)
  let reg3 = metrics.observe_histogram(reg2, "storage_query_duration_ms", 45.0)
  let reg4 = metrics.observe_histogram(reg3, "storage_query_duration_ms", 8.0)

  // Create API error counter
  let #(reg5, _) =
    metrics.get_or_create_counter(reg4, "api_errors_total", "Total API errors")
  let reg6 = metrics.increment_counter(reg5, "api_errors_total", 3)

  // Create active requests gauge
  let #(reg7, _) =
    metrics.get_or_create_gauge(reg6, "active_requests", "Active requests")
  let reg8 = metrics.set_gauge(reg7, "active_requests", 15.0)

  // Export and verify
  let output = metrics.export_prometheus(reg8)

  output |> string.contains("storage_query_duration_ms") |> should.equal(True)
  output |> string.contains("api_errors_total 3") |> should.equal(True)
  output |> string.contains("active_requests 15") |> should.equal(True)

  // Verify metrics count
  metrics.metrics_count(reg8) |> should.equal(3)
}

// ============================================================================
// Type Tests
// ============================================================================

pub fn test_label_sorting() {
  let labels = [
    types.label("z_key", "value"),
    types.label("a_key", "value"),
    types.label("m_key", "value"),
  ]

  let sorted = types.sort_labels(labels)
  let names = list.map(sorted, fn(l) { l.key })

  names |> should.equal(["a_key", "m_key", "z_key"])
}

pub fn test_find_label() {
  let labels = [
    types.label("service", "storage"),
    types.label("operation", "query"),
  ]

  let found = types.find_label(labels, "service")
  case found {
    option.Some(value) -> value |> should.equal("storage")
    option.None -> should.fail()
  }

  let not_found = types.find_label(labels, "missing")
  case not_found {
    option.Some(_) -> should.fail()
    option.None -> True |> should.equal(True)
  }
}
