/// Health check handler with integrated metrics endpoint
///
/// This module provides enhanced health check functionality that includes
/// performance metrics and SLA status. It serves as an example of metrics
/// integration into web handlers.
import gleam/http
import gleam/json
import gleam/list
import meal_planner/logger
import meal_planner/metrics/context
import meal_planner/metrics/mod.{
  type MetricSnapshot, type MetricsRegistry, ApiCall, Calculation, StorageQuery,
  get_all_snapshots,
}
import wisp

// ============================================================================
// Health Check with Metrics
// ============================================================================

/// Health check endpoint that includes metrics
/// GET /health or /metrics/health
pub fn handle_with_metrics(
  req: wisp.Request,
  registry: MetricsRegistry,
) -> #(wisp.Response, MetricsRegistry) {
  use <- wisp.require_method(req, http.Get)

  let status_code = 200
  let health_data = get_health_status(registry)

  let body =
    json.object(health_data)
    |> json.to_string

  #(wisp.json_response(body, status_code), registry)
}

/// Get health status with metrics snapshot
fn get_health_status(registry: MetricsRegistry) -> List(#(String, json.Json)) {
  let storage_snapshots = get_all_snapshots(registry, StorageQuery)
  let api_snapshots = get_all_snapshots(registry, ApiCall)
  let calc_snapshots = get_all_snapshots(registry, Calculation)

  let storage_json = format_snapshots_json(storage_snapshots)
  let api_json = format_snapshots_json(api_snapshots)
  let calc_json = format_snapshots_json(calc_snapshots)

  [
    #("status", json.string("healthy")),
    #("service", json.string("meal-planner")),
    #("version", json.string("1.0.0")),
    #(
      "metrics",
      json.object([
        #("storage_queries", storage_json),
        #("api_calls", api_json),
        #("calculations", calc_json),
      ]),
    ),
  ]
}

/// Format metric snapshots as JSON array
fn format_snapshots_json(snapshots: List(MetricSnapshot)) -> json.Json {
  snapshots
  |> list.map(fn(snapshot) {
    json.object([
      #("name", json.string(snapshot.name)),
      #("count", json.int(snapshot.count)),
      #("total_ms", json.float(snapshot.total_ms)),
      #("avg_ms", json.float(snapshot.avg_ms)),
      #("min_ms", json.float(snapshot.min_ms)),
      #("max_ms", json.float(snapshot.max_ms)),
      #("error_count", json.int(snapshot.error_count)),
      #("success_rate", json.float(snapshot.success_rate)),
    ])
  })
  |> json.array()
}

// ============================================================================
// Prometheus Metrics Endpoint
// ============================================================================

/// Prometheus metrics export endpoint
/// GET /metrics
pub fn handle_prometheus(
  req: wisp.Request,
  registry: MetricsRegistry,
) -> #(wisp.Response, MetricsRegistry) {
  use <- wisp.require_method(req, http.Get)

  let prometheus_text = context.export_prometheus(registry)

  // Prometheus metrics are returned as plain text
  let response =
    wisp.response(200)
    |> wisp.string_body(prometheus_text)
    |> wisp.set_header(
      "content-type",
      "text/plain; version=1.0.0; charset=utf-8",
    )

  #(response, registry)
}

// ============================================================================
// JSON Metrics Endpoint
// ============================================================================

/// JSON metrics export endpoint
/// GET /metrics/json
pub fn handle_json(
  req: wisp.Request,
  registry: MetricsRegistry,
) -> #(wisp.Response, MetricsRegistry) {
  use <- wisp.require_method(req, http.Get)

  let json_output = context.get_summary(registry)

  #(wisp.json_response(json_output, 200), registry)
}

// ============================================================================
// Metrics Report Endpoint
// ============================================================================

/// Human-readable metrics report endpoint
/// GET /metrics/report
pub fn handle_report(
  req: wisp.Request,
  registry: MetricsRegistry,
) -> #(wisp.Response, MetricsRegistry) {
  use <- wisp.require_method(req, http.Get)

  let report_text = context.generate_report(registry)

  let response =
    wisp.response(200)
    |> wisp.string_body(report_text)
    |> wisp.set_header("content-type", "text/plain; charset=utf-8")

  #(response, registry)
}

// ============================================================================
// Metrics Reset Endpoint (admin only)
// ============================================================================

/// Reset metrics (for testing or admin purposes)
/// POST /metrics/reset (requires authorization)
pub fn handle_reset(
  req: wisp.Request,
  _registry: MetricsRegistry,
) -> #(wisp.Response, MetricsRegistry) {
  use <- wisp.require_method(req, http.Post)

  // TODO: Add authorization check
  // For now, just create a new empty registry
  let new_registry = mod.new_registry()

  logger.info("Metrics reset requested")

  let body =
    json.object([
      #("status", json.string("reset")),
      #("message", json.string("Metrics registry has been reset")),
    ])
    |> json.to_string

  #(wisp.json_response(body, 200), new_registry)
}
