/// Global metrics context and management
///
/// This module manages the application-wide metrics registry and provides
/// initialization and management functions for performance monitoring.
import gleam/bool
import gleam/io
import meal_planner/logger
import meal_planner/metrics/mod.{type MetricsRegistry, new_registry}
import meal_planner/metrics/prometheus

// ============================================================================
// Global Metrics State
// ============================================================================

/// Initialize a new metrics registry for the application
pub fn init_registry() -> MetricsRegistry {
  new_registry()
}

// ============================================================================
// Metrics Export and Reporting
// ============================================================================

/// Export metrics to Prometheus format
pub fn export_prometheus(registry: MetricsRegistry) -> String {
  prometheus.export_prometheus(registry)
}

/// Export metrics as JSON
pub fn export_json(registry: MetricsRegistry) -> String {
  prometheus.export_json(registry)
}

/// Generate human-readable report
pub fn generate_report(registry: MetricsRegistry) -> String {
  prometheus.generate_report(registry)
}

/// Log current metrics status to console
pub fn log_metrics(registry: MetricsRegistry) -> Nil {
  let report = prometheus.generate_report(registry)
  logger.info("Metrics Report")
  io.println(report)
}

// ============================================================================
// Metrics Collection Control
// ============================================================================

/// Whether metrics collection is enabled
/// Can be configured via environment variable METRICS_ENABLED
pub fn is_enabled() -> Bool {
  // In production, read from config
  // For now, default to enabled
  True
}

/// Get summary of all metrics collected so far
pub fn get_summary(registry: MetricsRegistry) -> String {
  let json = export_json(registry)
  json
}
