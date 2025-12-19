//// Tests for metrics collection framework
//// RED phase - these tests should fail until implementation is complete

import gleam/dict
import gleeunit
import gleeunit/should
import meal_planner/observability/metrics
import meal_planner/observability/types.{Counter, Gauge, Histogram, MetricConfig}

pub fn main() {
  gleeunit.main()
}

pub fn create_counter_test() {
  let labels =
    dict.new()
    |> dict.insert("method", "GET")
    |> dict.insert("endpoint", "/api/recipes")

  let counter =
    metrics.counter(name: "http_requests_total", value: 42, labels: labels)

  case counter {
    Counter(name, value, _labels) -> {
      name
      |> should.equal("http_requests_total")

      value
      |> should.equal(42)
    }
    _ -> should.fail()
  }
}

pub fn create_gauge_test() {
  let labels = dict.new()

  let gauge =
    metrics.gauge(name: "memory_usage_bytes", value: 1024.5, labels: labels)

  case gauge {
    Gauge(name, value, _labels) -> {
      name
      |> should.equal("memory_usage_bytes")

      value
      |> should.equal(1024.5)
    }
    _ -> should.fail()
  }
}

pub fn increment_counter_test() {
  let labels =
    dict.new()
    |> dict.insert("status", "200")

  // Create counter with value 10
  let counter = metrics.counter(name: "requests", value: 10, labels: labels)

  // Increment by 5
  let updated = metrics.increment_counter(counter, 5)

  case updated {
    Counter(_name, value, _labels) -> {
      value
      |> should.equal(15)
    }
    _ -> should.fail()
  }
}

pub fn record_gauge_test() {
  let labels = dict.new()

  let gauge = metrics.gauge(name: "cpu_usage", value: 50.0, labels: labels)

  // Update gauge value
  let updated = metrics.update_gauge(gauge, 75.5)

  case updated {
    Gauge(_name, value, _labels) -> {
      value
      |> should.equal(75.5)
    }
    _ -> should.fail()
  }
}

pub fn create_histogram_test() {
  let labels =
    dict.new()
    |> dict.insert("handler", "recipe_fetch")

  let buckets = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0]

  let histogram =
    metrics.histogram(
      name: "request_duration_seconds",
      value: 0.042,
      buckets: buckets,
      labels: labels,
    )

  case histogram {
    Histogram(name, value, _buckets, _labels) -> {
      name
      |> should.equal("request_duration_seconds")

      value
      |> should.equal(0.042)
    }
    _ -> should.fail()
  }
}

pub fn format_metric_for_prometheus_test() {
  let labels =
    dict.new()
    |> dict.insert("method", "POST")
    |> dict.insert("status", "201")

  let counter =
    metrics.counter(name: "api_requests_total", value: 123, labels: labels)

  let formatted = metrics.format_prometheus(counter)

  // Should contain metric name and labels
  formatted
  |> should.not_equal("")
}

pub fn metric_config_test() {
  let config =
    MetricConfig(
      namespace: "meal_planner",
      subsystem: "api",
      enabled: True,
      export_interval_ms: 10_000,
    )

  config.namespace
  |> should.equal("meal_planner")

  config.subsystem
  |> should.equal("api")

  config.enabled
  |> should.equal(True)

  config.export_interval_ms
  |> should.equal(10_000)
}

pub fn collect_metrics_test() {
  // Should be able to collect multiple metrics
  let counter1 = metrics.counter(name: "metric1", value: 10, labels: dict.new())

  let counter2 = metrics.counter(name: "metric2", value: 20, labels: dict.new())

  let collected = metrics.collect([counter1, counter2])

  collected
  |> should.not_equal([])
}
