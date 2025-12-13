/// Metrics type definitions for Prometheus-compatible monitoring
/// 
/// Supports three metric types: Counter, Histogram, and Gauge
/// All metrics can have optional labels for multi-dimensional analysis
///
import gleam/list
import gleam/option.{type Option}
import gleam/string

// ============================================================================
// Core Metric Types
// ============================================================================

/// A metric label (tag) for multi-dimensional filtering
/// Example: {"service": "storage", "operation": "query"}
pub type Label {
  Label(key: String, value: String)
}

/// Ordered list of labels for consistent serialization
pub type Labels =
  List(Label)

/// Counter: Monotonically increasing metric (only goes up)
pub type Counter {
  Counter(name: String, description: String, value: Int, labels: Labels)
}

/// Histogram bucket boundary and count
pub type HistogramBucket {
  HistogramBucket(boundary: Float, count: Int)
}

/// Histogram: Distribution of values
pub type Histogram {
  Histogram(
    name: String,
    description: String,
    buckets: List(HistogramBucket),
    sum: Float,
    count: Int,
    labels: Labels,
  )
}

/// Gauge: Current point-in-time value
pub type Gauge {
  Gauge(name: String, description: String, value: Float, labels: Labels)
}

/// Any registered metric (Counter | Histogram | Gauge)
pub type Metric {
  CounterMetric(Counter)
  HistogramMetric(Histogram)
  GaugeMetric(Gauge)
}

// ============================================================================
// Metric Registry
// ============================================================================

/// Central registry for all metrics
pub type MetricRegistry {
  MetricRegistry(metrics: List(Metric))
}

// ============================================================================
// Metric Configuration
// ============================================================================

/// Histogram bucket configuration
pub type HistogramBuckets {
  DefaultBuckets
  CustomBuckets(boundaries: List(Float))
}

/// Default histogram buckets (milliseconds)
/// Covers 1ms to 60+ seconds
pub fn default_histogram_buckets() -> List(Float) {
  [
    1.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0, 1000.0, 2500.0, 5000.0,
    10_000.0,
  ]
}

/// Extract bucket boundaries from HistogramBuckets config
pub fn get_histogram_buckets(config: HistogramBuckets) -> List(Float) {
  case config {
    DefaultBuckets -> default_histogram_buckets()
    CustomBuckets(boundaries) -> boundaries
  }
}

// ============================================================================
// Metric Creation Helpers
// ============================================================================

/// Create a new counter metric
pub fn new_counter(name: String, description: String) -> Counter {
  Counter(name: name, description: description, value: 0, labels: [])
}

/// Create a new counter with labels
pub fn new_counter_with_labels(
  name: String,
  description: String,
  labels: Labels,
) -> Counter {
  Counter(name: name, description: description, value: 0, labels: labels)
}

/// Create a new histogram metric
pub fn new_histogram(
  name: String,
  description: String,
  buckets: HistogramBuckets,
) -> Histogram {
  let bucket_boundaries = get_histogram_buckets(buckets)
  let buckets_list =
    list.map(bucket_boundaries, fn(boundary) {
      HistogramBucket(boundary: boundary, count: 0)
    })

  Histogram(
    name: name,
    description: description,
    buckets: buckets_list,
    sum: 0.0,
    count: 0,
    labels: [],
  )
}

/// Create a new histogram with labels
pub fn new_histogram_with_labels(
  name: String,
  description: String,
  buckets: HistogramBuckets,
  labels: Labels,
) -> Histogram {
  let bucket_boundaries = get_histogram_buckets(buckets)
  let buckets_list =
    list.map(bucket_boundaries, fn(boundary) {
      HistogramBucket(boundary: boundary, count: 0)
    })

  Histogram(
    name: name,
    description: description,
    buckets: buckets_list,
    sum: 0.0,
    count: 0,
    labels: labels,
  )
}

/// Create a new gauge metric
pub fn new_gauge(name: String, description: String) -> Gauge {
  Gauge(name: name, description: description, value: 0.0, labels: [])
}

/// Create a new gauge with labels
pub fn new_gauge_with_labels(
  name: String,
  description: String,
  labels: Labels,
) -> Gauge {
  Gauge(name: name, description: description, value: 0.0, labels: labels)
}

// ============================================================================
// Metric Updates
// ============================================================================

/// Increment a counter by a value
pub fn increment_counter(counter: Counter, by: Int) -> Counter {
  Counter(..counter, value: counter.value + by)
}

/// Record an observation in a histogram
pub fn observe_histogram(histogram: Histogram, value: Float) -> Histogram {
  let updated_buckets =
    list.map(histogram.buckets, fn(bucket) {
      case value <=. bucket.boundary {
        True -> HistogramBucket(..bucket, count: bucket.count + 1)
        False -> bucket
      }
    })

  Histogram(
    ..histogram,
    buckets: updated_buckets,
    sum: histogram.sum +. value,
    count: histogram.count + 1,
  )
}

/// Set a gauge to a specific value
pub fn set_gauge(gauge: Gauge, value: Float) -> Gauge {
  Gauge(..gauge, value: value)
}

/// Increment a gauge by a value
pub fn add_gauge(gauge: Gauge, value: Float) -> Gauge {
  Gauge(..gauge, value: gauge.value +. value)
}

// ============================================================================
// Metric Queries
// ============================================================================

/// Get metric name
pub fn metric_name(metric: Metric) -> String {
  case metric {
    CounterMetric(c) -> c.name
    HistogramMetric(h) -> h.name
    GaugeMetric(g) -> g.name
  }
}

/// Get metric description
pub fn metric_description(metric: Metric) -> String {
  case metric {
    CounterMetric(c) -> c.description
    HistogramMetric(h) -> h.description
    GaugeMetric(g) -> g.description
  }
}

/// Get metric labels
pub fn metric_labels(metric: Metric) -> Labels {
  case metric {
    CounterMetric(c) -> c.labels
    HistogramMetric(h) -> h.labels
    GaugeMetric(g) -> g.labels
  }
}

/// Get counter value (or 0 if not a counter)
pub fn counter_value(metric: Metric) -> Int {
  case metric {
    CounterMetric(c) -> c.value
    _ -> 0
  }
}

/// Get gauge value (or 0.0 if not a gauge)
pub fn gauge_value(metric: Metric) -> Float {
  case metric {
    GaugeMetric(g) -> g.value
    _ -> 0.0
  }
}

/// Get histogram sum (or 0.0 if not a histogram)
pub fn histogram_sum(metric: Metric) -> Float {
  case metric {
    HistogramMetric(h) -> h.sum
    _ -> 0.0
  }
}

/// Get histogram count (or 0 if not a histogram)
pub fn histogram_count(metric: Metric) -> Int {
  case metric {
    HistogramMetric(h) -> h.count
    _ -> 0
  }
}

// ============================================================================
// Label Helpers
// ============================================================================

/// Create a label
pub fn label(key: String, value: String) -> Label {
  Label(key: key, value: value)
}

/// Find a label value by key
pub fn find_label(labels: Labels, key: String) -> Option(String) {
  case list.find(labels, fn(l) { l.key == key }) {
    Ok(found) -> option.Some(found.value)
    Error(_) -> option.None
  }
}

/// Sort labels alphabetically by key (for consistent serialization)
pub fn sort_labels(labels: Labels) -> Labels {
  list.sort(labels, fn(a, b) { string.compare(a.key, b.key) })
}
