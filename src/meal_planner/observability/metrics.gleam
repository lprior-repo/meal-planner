//// Metrics collection framework
//// Supports counters, gauges, histograms following OpenTelemetry/Prometheus patterns

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/observability/types.{
  type Metric, Counter, Gauge, Histogram, Summary,
}

/// Create a counter metric
pub fn counter(
  name name: String,
  value value: Int,
  labels labels: Dict(String, String),
) -> Metric {
  Counter(name: name, value: value, labels: labels)
}

/// Create a gauge metric
pub fn gauge(
  name name: String,
  value value: Float,
  labels labels: Dict(String, String),
) -> Metric {
  Gauge(name: name, value: value, labels: labels)
}

/// Create a histogram metric
pub fn histogram(
  name name: String,
  value value: Float,
  buckets buckets: List(Float),
  labels labels: Dict(String, String),
) -> Metric {
  Histogram(name: name, value: value, buckets: buckets, labels: labels)
}

/// Create a summary metric
pub fn summary(
  name name: String,
  value value: Float,
  quantiles quantiles: List(Float),
  labels labels: Dict(String, String),
) -> Metric {
  Summary(name: name, value: value, quantiles: quantiles, labels: labels)
}

/// Increment a counter by a given amount
pub fn increment_counter(metric: Metric, increment: Int) -> Metric {
  case metric {
    Counter(name, value, labels) ->
      Counter(name: name, value: value + increment, labels: labels)
    _ -> metric
  }
}

/// Update a gauge value
pub fn update_gauge(metric: Metric, new_value: Float) -> Metric {
  case metric {
    Gauge(name, _value, labels) ->
      Gauge(name: name, value: new_value, labels: labels)
    _ -> metric
  }
}

/// Format metric in Prometheus text format
pub fn format_prometheus(metric: Metric) -> String {
  case metric {
    Counter(name, value, labels) -> {
      let labels_str = format_labels(labels)
      name <> labels_str <> " " <> int.to_string(value)
    }

    Gauge(name, value, labels) -> {
      let labels_str = format_labels(labels)
      name <> labels_str <> " " <> float.to_string(value)
    }

    Histogram(name, value, _buckets, labels) -> {
      let labels_str = format_labels(labels)
      name <> labels_str <> " " <> float.to_string(value)
    }

    Summary(name, value, _quantiles, labels) -> {
      let labels_str = format_labels(labels)
      name <> labels_str <> " " <> float.to_string(value)
    }
  }
}

/// Collect multiple metrics into a list
pub fn collect(metrics: List(Metric)) -> List(Metric) {
  metrics
}

/// Export metrics in Prometheus format
pub fn export_prometheus(metrics: List(Metric)) -> String {
  metrics
  |> list.map(format_prometheus)
  |> string.join("\n")
}

/// Get metric name
pub fn metric_name(metric: Metric) -> String {
  case metric {
    Counter(name, _, _) -> name
    Gauge(name, _, _) -> name
    Histogram(name, _, _, _) -> name
    Summary(name, _, _, _) -> name
  }
}

/// Get metric value as float
pub fn metric_value(metric: Metric) -> Float {
  case metric {
    Counter(_, value, _) -> int.to_float(value)
    Gauge(_, value, _) -> value
    Histogram(_, value, _, _) -> value
    Summary(_, value, _, _) -> value
  }
}

// Helper: Format labels for Prometheus
fn format_labels(labels: Dict(String, String)) -> String {
  let pairs = dict.to_list(labels)

  case pairs {
    [] -> ""
    _ -> {
      let formatted =
        pairs
        |> list.map(fn(pair) {
          let #(key, value) = pair
          key <> "=\"" <> value <> "\""
        })
        |> string.join(",")

      "{" <> formatted <> "}"
    }
  }
}
