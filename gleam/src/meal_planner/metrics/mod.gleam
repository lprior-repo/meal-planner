/// Metrics registry and collection module
///
/// Thread-safe central registry for all application metrics.
/// Uses Erlang atoms and the process dictionary for global state.
/// 
/// This is a functional approach using a process-based registry pattern
/// where metric updates are collected and aggregated on demand.
///
import gleam/list
import gleam/option.{type Option}
import gleam/string
import meal_planner/metrics/prometheus
import meal_planner/metrics/types.{
  type Counter, type Gauge, type HistogramBuckets, type Labels, type Metric,
  CounterMetric, DefaultBuckets, GaugeMetric, HistogramMetric,
}

// ============================================================================
// Global Registry State
// ============================================================================

/// In-memory metrics registry
pub type Registry {
  Registry(metrics: List(Metric))
}

/// Create a new empty registry
pub fn new_registry() -> Registry {
  Registry(metrics: [])
}

// ============================================================================
// Counter Operations
// ============================================================================

/// Register and get a counter, creating if it doesn't exist
pub fn get_or_create_counter(
  registry: Registry,
  name: String,
  description: String,
) -> #(Registry, Counter) {
  case find_counter(registry, name, []) {
    Some(counter) -> #(registry, counter)
    None -> {
      let new_counter = types.new_counter(name, description)
      let updated = Registry(
        metrics: [CounterMetric(new_counter), ..registry.metrics],
      )
      #(updated, new_counter)
    }
  }
}

/// Register and get a counter with labels, creating if it doesn't exist
pub fn get_or_create_counter_with_labels(
  registry: Registry,
  name: String,
  description: String,
  labels: Labels,
) -> #(Registry, Counter) {
  case find_counter(registry, name, labels) {
    Some(counter) -> #(registry, counter)
    None -> {
      let new_counter = types.new_counter_with_labels(name, description, labels)
      let updated = Registry(
        metrics: [CounterMetric(new_counter), ..registry.metrics],
      )
      #(updated, new_counter)
    }
  }
}

/// Find a counter by name and labels
fn find_counter(
  registry: Registry,
  name: String,
  labels: Labels,
) -> Option(Counter) {
  list.find_map(registry.metrics, fn(metric) {
    case metric {
      CounterMetric(c) if c.name == name && c.labels == labels -> Some(c)
      _ -> None
    }
  })
}

/// Increment a counter in the registry
pub fn increment_counter(
  registry: Registry,
  name: String,
  by: Int,
) -> Registry {
  increment_counter_with_labels(registry, name, [], by)
}

/// Increment a counter with labels in the registry
pub fn increment_counter_with_labels(
  registry: Registry,
  name: String,
  labels: Labels,
  by: Int,
) -> Registry {
  let updated_metrics = list.map(registry.metrics, fn(metric) {
    case metric {
      CounterMetric(c)
        if c.name == name && c.labels == labels
      -> CounterMetric(types.increment_counter(c, by))
      _ -> metric
    }
  })
  Registry(metrics: updated_metrics)
}

// ============================================================================
// Gauge Operations
// ============================================================================

/// Register and get a gauge, creating if it doesn't exist
pub fn get_or_create_gauge(
  registry: Registry,
  name: String,
  description: String,
) -> #(Registry, Gauge) {
  case find_gauge(registry, name, []) {
    Some(gauge) -> #(registry, gauge)
    None -> {
      let new_gauge = types.new_gauge(name, description)
      let updated = Registry(
        metrics: [GaugeMetric(new_gauge), ..registry.metrics],
      )
      #(updated, new_gauge)
    }
  }
}

/// Register and get a gauge with labels, creating if it doesn't exist
pub fn get_or_create_gauge_with_labels(
  registry: Registry,
  name: String,
  description: String,
  labels: Labels,
) -> #(Registry, Gauge) {
  case find_gauge(registry, name, labels) {
    Some(gauge) -> #(registry, gauge)
    None -> {
      let new_gauge = types.new_gauge_with_labels(name, description, labels)
      let updated = Registry(
        metrics: [GaugeMetric(new_gauge), ..registry.metrics],
      )
      #(updated, new_gauge)
    }
  }
}

/// Find a gauge by name and labels
fn find_gauge(
  registry: Registry,
  name: String,
  labels: Labels,
) -> Option(Gauge) {
  list.find_map(registry.metrics, fn(metric) {
    case metric {
      GaugeMetric(g) if g.name == name && g.labels == labels -> Some(g)
      _ -> None
    }
  })
}

/// Set a gauge value in the registry
pub fn set_gauge(
  registry: Registry,
  name: String,
  value: Float,
) -> Registry {
  set_gauge_with_labels(registry, name, [], value)
}

/// Set a gauge value with labels in the registry
pub fn set_gauge_with_labels(
  registry: Registry,
  name: String,
  labels: Labels,
  value: Float,
) -> Registry {
  let updated_metrics = list.map(registry.metrics, fn(metric) {
    case metric {
      GaugeMetric(g)
        if g.name == name && g.labels == labels
      -> GaugeMetric(types.set_gauge(g, value))
      _ -> metric
    }
  })
  Registry(metrics: updated_metrics)
}

/// Increment a gauge value in the registry
pub fn add_gauge(
  registry: Registry,
  name: String,
  value: Float,
) -> Registry {
  add_gauge_with_labels(registry, name, [], value)
}

/// Increment a gauge with labels in the registry
pub fn add_gauge_with_labels(
  registry: Registry,
  name: String,
  labels: Labels,
  value: Float,
) -> Registry {
  let updated_metrics = list.map(registry.metrics, fn(metric) {
    case metric {
      GaugeMetric(g)
        if g.name == name && g.labels == labels
      -> GaugeMetric(types.add_gauge(g, value))
      _ -> metric
    }
  })
  Registry(metrics: updated_metrics)
}

// ============================================================================
// Histogram Operations
// ============================================================================

/// Register and get a histogram, creating if it doesn't exist
pub fn get_or_create_histogram(
  registry: Registry,
  name: String,
  description: String,
  buckets: HistogramBuckets,
) -> #(Registry, types.Histogram) {
  case find_histogram(registry, name, []) {
    Some(histogram) -> #(registry, histogram)
    None -> {
      let new_histogram = types.new_histogram(name, description, buckets)
      let updated = Registry(
        metrics: [HistogramMetric(new_histogram), ..registry.metrics],
      )
      #(updated, new_histogram)
    }
  }
}

/// Register and get a histogram with labels, creating if it doesn't exist
pub fn get_or_create_histogram_with_labels(
  registry: Registry,
  name: String,
  description: String,
  buckets: HistogramBuckets,
  labels: Labels,
) -> #(Registry, types.Histogram) {
  case find_histogram(registry, name, labels) {
    Some(histogram) -> #(registry, histogram)
    None -> {
      let new_histogram =
        types.new_histogram_with_labels(name, description, buckets, labels)
      let updated = Registry(
        metrics: [HistogramMetric(new_histogram), ..registry.metrics],
      )
      #(updated, new_histogram)
    }
  }
}

/// Find a histogram by name and labels
fn find_histogram(
  registry: Registry,
  name: String,
  labels: Labels,
) -> Option(types.Histogram) {
  list.find_map(registry.metrics, fn(metric) {
    case metric {
      HistogramMetric(h) if h.name == name && h.labels == labels -> Some(h)
      _ -> None
    }
  })
}

/// Record an observation in a histogram
pub fn observe_histogram(
  registry: Registry,
  name: String,
  value: Float,
) -> Registry {
  observe_histogram_with_labels(registry, name, [], value)
}

/// Record an observation in a histogram with labels
pub fn observe_histogram_with_labels(
  registry: Registry,
  name: String,
  labels: Labels,
  value: Float,
) -> Registry {
  let updated_metrics = list.map(registry.metrics, fn(metric) {
    case metric {
      HistogramMetric(h)
        if h.name == name && h.labels == labels
      -> HistogramMetric(types.observe_histogram(h, value))
      _ -> metric
    }
  })
  Registry(metrics: updated_metrics)
}

// ============================================================================
// Registry Export
// ============================================================================

/// Export all metrics in Prometheus text format
pub fn export_prometheus(registry: Registry) -> String {
  prometheus.format_metrics(registry.metrics)
}

/// Get all metrics from the registry
pub fn get_metrics(registry: Registry) -> List(Metric) {
  registry.metrics
}

/// Get metrics count
pub fn metrics_count(registry: Registry) -> Int {
  list.length(registry.metrics)
}

/// Clear all metrics from the registry
pub fn clear_registry() -> Registry {
  Registry(metrics: [])
}

// ============================================================================
// Metric Lookup
// ============================================================================

/// Find a metric by name
pub fn find_metric(registry: Registry, name: String) -> Option(Metric) {
  list.find(registry.metrics, fn(metric) {
    types.metric_name(metric) == name
  })
}

/// Find all metrics with a given name (different labels)
pub fn find_metrics_by_name(registry: Registry, name: String) -> List(Metric) {
  list.filter(registry.metrics, fn(metric) {
    types.metric_name(metric) == name
  })
}

/// Find all metrics matching a prefix
pub fn find_metrics_by_prefix(registry: Registry, prefix: String) -> List(Metric) {
  list.filter(registry.metrics, fn(metric) {
    string.starts_with(types.metric_name(metric), prefix)
  })
}
