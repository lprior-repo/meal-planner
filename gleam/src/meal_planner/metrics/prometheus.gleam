/// Prometheus text exposition format (version 0.0.4) export
///
/// Converts internal metrics to Prometheus format suitable for scraping
/// Reference: https://prometheus.io/docs/instrumenting/exposition_formats/
///
import gleam/float
import gleam/list
import gleam/string
import meal_planner/metrics/types.{
  type Gauge, type Histogram, type HistogramBucket, type Label, type Metric,
  CounterMetric, GaugeMetric, HistogramMetric,
}

// ============================================================================
// Format Functions
// ============================================================================

/// Convert all metrics to Prometheus text format
pub fn format_metrics(metrics: List(Metric)) -> String {
  // Group metrics by base name
  let grouped = group_metrics_by_name(metrics)

  // Format each metric group
  let formatted =
    list.map(grouped, fn(group) {
      let #(base_name, metric_list) = group
      format_metric_group(base_name, metric_list)
    })

  // Join with newlines and ensure trailing newline
  string.join(formatted, "\n") <> "\n"
}

/// Group metrics by their base name (handling _total, _bucket, etc.)
fn group_metrics_by_name(metrics: List(Metric)) -> List(#(String, List(Metric))) {
  // Create a map of base names to metrics
  list.fold(metrics, [], fn(acc, metric) {
    let name = types.metric_name(metric)
    let base_name = extract_base_name(name)

    case
      list.find(acc, fn(group) {
        let #(group_name, _) = group
        group_name == base_name
      })
    {
      Ok(group) -> {
        let #(_, existing) = group
        list.filter(acc, fn(g) { g.0 != base_name })
        |> list.append([#(base_name, [metric, ..existing])])
      }
      Error(_) -> list.append(acc, [#(base_name, [metric])])
    }
  })
}

/// Extract base metric name (removes _total, _bucket, _sum, _count suffixes)
fn extract_base_name(name: String) -> String {
  case string.ends_with(name, "_total") {
    True -> string.drop_end(name, 6)
    False ->
      case string.ends_with(name, "_bucket") {
        True -> string.drop_end(name, 7)
        False ->
          case string.ends_with(name, "_sum") {
            True -> string.drop_end(name, 4)
            False ->
              case string.ends_with(name, "_count") {
                True -> string.drop_end(name, 6)
                False -> name
              }
          }
      }
  }
}

/// Format a group of metrics with shared base name
fn format_metric_group(base_name: String, metrics: List(Metric)) -> String {
  // Get first metric for description (they should all have same description for same base name)
  case metrics {
    [] -> ""
    [first, ..] -> {
      let description = types.metric_description(first)
      let metric_type = get_metric_type(first)

      let help_line = "# HELP " <> base_name <> " " <> description
      let type_line = "# TYPE " <> base_name <> " " <> metric_type
      let metric_lines = list.map(metrics, format_single_metric)

      string.join([help_line, type_line, ..metric_lines], "\n")
    }
  }
}

/// Get Prometheus type string for a metric
fn get_metric_type(metric: Metric) -> String {
  case metric {
    CounterMetric(_) -> "counter"
    GaugeMetric(_) -> "gauge"
    HistogramMetric(_) -> "histogram"
  }
}

/// Format a single metric line
fn format_single_metric(metric: Metric) -> String {
  case metric {
    CounterMetric(c) -> format_counter(c)
    GaugeMetric(g) -> format_gauge(g)
    HistogramMetric(h) -> format_histogram(h)
  }
}

/// Format a counter metric
fn format_counter(counter: types.Counter) -> String {
  let labels_str = format_labels(counter.labels)
  let value_str = int.to_string(counter.value)

  case labels_str {
    "" -> counter.name <> " " <> value_str
    _ -> counter.name <> "{" <> labels_str <> "} " <> value_str
  }
}

/// Format a gauge metric
fn format_gauge(gauge: Gauge) -> String {
  let labels_str = format_labels(gauge.labels)
  let value_str = format_float(gauge.value)

  case labels_str {
    "" -> gauge.name <> " " <> value_str
    _ -> gauge.name <> "{" <> labels_str <> "} " <> value_str
  }
}

/// Format a histogram metric (generates multiple output lines)
fn format_histogram(histogram: Histogram) -> String {
  let base_name = extract_base_name(histogram.name)
  let labels_str = format_labels(histogram.labels)

  // Format bucket lines
  let bucket_lines =
    list.map(histogram.buckets, fn(bucket) {
      format_histogram_bucket(base_name, bucket, labels_str)
    })

  // Format sum and count lines
  let sum_line = format_histogram_sum(base_name, histogram.sum, labels_str)
  let count_line =
    format_histogram_count(base_name, histogram.count, labels_str)

  string.join(list.append(bucket_lines, [sum_line, count_line]), "\n")
}

/// Format a single histogram bucket line
fn format_histogram_bucket(
  base_name: String,
  bucket: HistogramBucket,
  labels_str: String,
) -> String {
  let le_value = case bucket.boundary >=. 1.0e10 {
    True -> "+Inf"
    False -> format_float(bucket.boundary)
  }

  let count_str = int.to_string(bucket.count)
  let bucket_name = base_name <> "_bucket"

  case labels_str {
    "" -> bucket_name <> "{le=\"" <> le_value <> "\"} " <> count_str
    _ ->
      bucket_name
      <> "{le=\""
      <> le_value
      <> "\","
      <> labels_str
      <> "} "
      <> count_str
  }
}

/// Format histogram sum line
fn format_histogram_sum(
  base_name: String,
  sum: Float,
  labels_str: String,
) -> String {
  let sum_name = base_name <> "_sum"
  let sum_str = format_float(sum)

  case labels_str {
    "" -> sum_name <> " " <> sum_str
    _ -> sum_name <> "{" <> labels_str <> "} " <> sum_str
  }
}

/// Format histogram count line
fn format_histogram_count(
  base_name: String,
  count: Int,
  labels_str: String,
) -> String {
  let count_name = base_name <> "_count"
  let count_str = int.to_string(count)

  case labels_str {
    "" -> count_name <> " " <> count_str
    _ -> count_name <> "{" <> labels_str <> "} " <> count_str
  }
}

// ============================================================================
// Label Formatting
// ============================================================================

/// Format labels as Prometheus {key="value",key="value"} format
fn format_labels(labels: types.Labels) -> String {
  let sorted = types.sort_labels(labels)
  let label_strs = list.map(sorted, format_label_pair)
  string.join(label_strs, ",")
}

/// Format a single label pair
fn format_label_pair(label: Label) -> String {
  label.key <> "=\"" <> escape_label_value(label.value) <> "\""
}

/// Escape special characters in label values
fn escape_label_value(value: String) -> String {
  value
  |> string.replace(each: "\\", with: "\\\\")
  |> string.replace(each: "\"", with: "\\\"")
  |> string.replace(each: "\n", with: "\\n")
}

// ============================================================================
// Number Formatting
// ============================================================================

/// Format a float for Prometheus output
/// Handles special values: NaN → NaN, Inf → +Inf, -Inf → -Inf
fn format_float(value: Float) -> String {
  // For now, just convert to string directly
  // TODO: Handle NaN and Inf when gleam_stdlib adds is_nan/is_infinite functions
  let str = float.to_string(value)
  // Ensure no scientific notation for small numbers
  case string.contains(str, "e") {
    True -> format_float_decimal(value)
    False -> str
  }
}

/// Format float using decimal notation to avoid scientific notation
fn format_float_decimal(value: Float) -> String {
  // For now, use basic float.to_string()
  // A production implementation would handle precision better
  float.to_string(value)
}

// Import statements needed
import gleam/int
