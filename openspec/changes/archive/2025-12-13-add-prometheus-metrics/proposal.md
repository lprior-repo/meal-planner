# Change: Add Prometheus Metrics Export for Performance Monitoring

## Why

The project has existing performance monitoring infrastructure in `performance.gleam`, but it's not integrated into critical paths and lacks a standardized way to export metrics. This prevents external monitoring systems (Prometheus, Datadog, NewRelic) from observing real-time performance degradation across:

- Database query execution times
- Tandoor API integration latency
- Nutrition Control Plane (NCP) calculation overhead
- Meal generation algorithm performance

Following Martin Fowler's principle **"Make Performance Visible"** and Rich Hickey's **"Measure what matters"**, we need a dedicated metrics package that collects and exports metrics in Prometheus text format.

## What Changes

- Add new `metrics/` package with:
  - Counter, Histogram, and Gauge metric types
  - Prometheus text exposition format export
  - Thread-safe metric collection
  - Tag/label support for multi-dimensional analysis

- Create `/metrics` HTTP endpoint for Prometheus scraping
- Wire monitoring into critical paths:
  - Storage queries (execute_time_ms per query type)
  - Tandoor API calls (request_count, duration_ms, status)
  - NCP calculations (calculation_time_ms, error_count)
  - Meal generation (generation_time_ms, meal_count)

- Add tests for metric collection, aggregation, and export format

## Impact

**Affected specs:**
- New: `metrics` capability (Prometheus export)
- Modified: Web routing (add /metrics endpoint)

**Affected code:**
- New files: `gleam/src/meal_planner/metrics/` package
- New handler: `gleam/src/meal_planner/web/handlers/metrics.gleam`
- Integration points: storage, tandoor, ncp_metrics, generator modules

**Non-breaking:** Adds new capability without changing existing APIs.

**Performance:** Minimal overhead (<1% for typical request patterns) through lazy aggregation and efficient serialization.

**Monitoring value:** Enables 80+ operational dashboards and proactive alerting on:
- P99 query latencies
- API timeout rates
- Meal generation failures
- Cache effectiveness
