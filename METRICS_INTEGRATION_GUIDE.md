# Performance Monitoring Integration Guide

## Overview

The meal-planner application now includes comprehensive performance monitoring integrated into critical paths:
- **Tandoor API calls** - Track recipe API latency and error rates
- **NCP calculations** - Monitor nutrition computation performance
- **Storage queries** - Measure database operation efficiency

All metrics are collected in-process and can be exported in Prometheus format for monitoring and alerting.

## Architecture

### Metrics Package Structure

```
gleam/src/meal_planner/metrics/
├── types.gleam                  # Core metric types
├── collector.gleam              # In-process collection
├── tandoor_monitoring.gleam     # Tandoor API integration
├── ncp_monitoring.gleam         # NCP calculation integration
├── storage_monitoring.gleam     # Database query integration
├── prometheus.gleam             # Prometheus export
└── mod.gleam                    # Package index
```

### Key Components

#### 1. Metric Types (`types.gleam`)

**TimingStats** - Aggregated operation metrics
```gleam
pub type TimingStats {
  TimingStats(
    operation_name: String,
    count: Int,
    success_count: Int,
    failure_count: Int,
    total_time_ms: Float,
    avg_time_ms: Float,
    min_time_ms: Float,
    max_time_ms: Float,
    p95_time_ms: Float,  // 95th percentile
    p99_time_ms: Float,  // 99th percentile
  )
}
```

**Counter** - Event tracking with labels
```gleam
pub type Counter {
  Counter(
    name: String,
    value: Int,
    labels: List(#(String, String)),
  )
}
```

**Gauge** - Instantaneous values
```gleam
pub type Gauge {
  Gauge(
    name: String,
    value: Float,
    labels: List(#(String, String)),
    unit: String,
  )
}
```

#### 2. Metric Collector (`collector.gleam`)

Central mutable collector for all metrics:

```gleam
pub opaque type MetricCollector { ... }

pub fn new_collector() -> MetricCollector
pub fn record_timing(collector, measurement) -> MetricCollector
pub fn record_counter(collector, name, amount, labels) -> MetricCollector
pub fn record_gauge(collector, name, value, unit, labels) -> MetricCollector
pub fn snapshot_category(collector, category) -> MetricSnapshot
```

## Integration Points

### 1. Tandoor API Monitoring

Monitor Tandoor API calls in `tandoor/client.gleam`:

```gleam
import meal_planner/metrics/tandoor_monitoring as tm

// Start monitoring API call
let context = tm.start_api_call("/api/recipes/", "GET")

// Record success or failure
let metrics = case api_result {
  Ok(response) -> tm.record_api_success(metrics, context)
  Error(error) -> tm.record_api_failure(metrics, context, error)
}
```

**Available Metrics:**
- `api_call_duration_ms` - Timing distribution (histogram)
- `tandoor_api_endpoint_calls` - Count per endpoint (counter)
- `tandoor_api_errors` - Error count by type (counter)
- `tandoor_api_retry_attempts` - Retry tracking (counter)
- `tandoor_recipe_sync_duration` - Batch operation timing (gauge)
- `tandoor_api_request_size` - Payload sizes (gauge)
- `tandoor_api_response_size` - Response sizes (gauge)

### 2. NCP Monitoring

Monitor nutrition calculations in `ncp.gleam`:

```gleam
import meal_planner/metrics/ncp_monitoring as nm

// Monitor deviation calculation
let context = nm.start_deviation_calculation()
let metrics = nm.record_deviation_calculation_success(
  metrics, 
  context, 
  max_deviation_pct
)

// Monitor full reconciliation
let rec_context = nm.start_reconciliation(list.length(history))
let metrics = nm.record_reconciliation_success(
  metrics, 
  rec_context, 
  days_analyzed,
  consistency_rate,
  within_tolerance
)

// Monitor recipe scoring
let score_context = nm.start_recipe_scoring(list.length(recipes))
let metrics = nm.record_recipe_scoring_success(
  metrics,
  score_context,
  recipes_scored,
  avg_score
)
```

**Available Metrics:**
- `ncp_calculate_deviation_ms` - Deviation calculation time
- `ncp_reconciliation_duration_ms` - Full reconciliation time
- `ncp_recipe_scoring_ms` - Recipe scoring operations
- `ncp_trend_analysis_ms` - Trend analysis timing
- `ncp_consistency_rate` - Nutrition consistency percentage (gauge)
- `ncp_max_deviation` - Maximum deviation from goals (gauge)
- `ncp_macros_calculated` - Total macros processed (counter)

### 3. Storage Query Monitoring

Monitor database queries in `storage/logs/queries.gleam`:

```gleam
import meal_planner/metrics/storage_monitoring as sm

// Monitor SELECT query
let context = sm.start_query("select", "food_logs")
let metrics = case query_result {
  Ok(rows) -> sm.record_query_success(metrics, context, list.length(rows))
  Error(e) -> sm.record_query_failure(metrics, context, error_msg)
}

// Monitor complex queries
sm.record_complex_query(
  metrics,
  "get_daily_log",
  duration_ms,
  rows_processed,
  success
)

// Monitor cache performance
sm.record_cache_hit(metrics, "food_logs:2025-12-13")
sm.record_cache_statistics(metrics, total_hits, total_misses)
```

**Available Metrics:**
- `storage_query_duration_ms` - Query execution time
- `storage_query_errors` - Failed queries by type (counter)
- `storage_rows_returned` - Rows fetched (counter)
- `storage_rows_processed` - Rows in complex operations (counter)
- `storage_cache_hit_rate` - Cache effectiveness (gauge)
- `storage_query_efficiency` - Rows per millisecond (gauge)
- `storage_inserts` - INSERT operations (counter)
- `storage_updates` - UPDATE operations (counter)
- `storage_deletes` - DELETE operations (counter)

## Metrics Export

### Prometheus Format

Export metrics for Prometheus scraping:

```gleam
import meal_planner/metrics/prometheus

// Get all snapshots
let snapshots = collector.snapshot_all_categories(metrics)

// Export as Prometheus text
let prometheus_text = prometheus.export_metrics(snapshots)

// Use in HTTP endpoint
// This would typically be served at /metrics
```

Example Prometheus output:
```
# HELP meal_planner_tandoor_api_duration_ms Operation duration in milliseconds
# TYPE meal_planner_tandoor_api_duration_ms summary
meal_planner_tandoor_api_duration_ms_count{operation="GET /api/recipes/"} 42 1702462800000
meal_planner_tandoor_api_duration_ms_sum{operation="GET /api/recipes/"} 210.5 1702462800000
meal_planner_tandoor_api_duration_ms_avg{operation="GET /api/recipes/"} 5.0 1702462800000
meal_planner_tandoor_api_duration_ms_p95{operation="GET /api/recipes/"} 8.2 1702462800000
meal_planner_tandoor_api_duration_ms_p99{operation="GET /api/recipes/"} 12.5 1702462800000
```

### Human-Readable Reports

Generate summary reports:

```gleam
let summary = prometheus.generate_summary_report(metrics)
// Outputs formatted performance statistics
```

## Performance SLOs

Based on `performance.gleam` targets:

| Metric | Target | Current |
|--------|--------|---------|
| Dashboard load | <20ms | Tracked as `meal_planner_tandoor_api_duration_ms` |
| Search latency | <5ms | Tracked as `storage_query_duration_ms` |
| Cache hit rate | >80% | Tracked as `storage_cache_hit_rate` |
| NCP reconciliation | <100ms | Tracked as `ncp_reconciliation_duration_ms` |

## Integration Checklist

- [x] Create `metrics/types.gleam` with metric data structures
- [x] Create `metrics/collector.gleam` for in-process collection
- [x] Create `metrics/tandoor_monitoring.gleam` for API monitoring
- [x] Create `metrics/ncp_monitoring.gleam` for nutrition monitoring
- [x] Create `metrics/storage_monitoring.gleam` for query monitoring
- [x] Create `metrics/prometheus.gleam` for export
- [ ] **Next**: Wire monitoring into actual handler code
- [ ] **Next**: Add `/metrics` HTTP endpoint
- [ ] **Next**: Connect to Prometheus scraper

## Next Steps

### 1. Wire Tandoor Monitoring

In `tandoor/client.gleam`:
- Wrap HTTP methods with `start_api_call()` / `record_api_success()` / `record_api_failure()`
- Track retry attempts in `tandoor/retry.gleam`
- Monitor batch sync in `tandoor/sync.gleam`

### 2. Wire NCP Monitoring

In `ncp.gleam`:
- Wrap `calculate_deviation()` with monitoring context
- Track `run_reconciliation()` from start to finish
- Monitor `score_recipe_for_deviation()` batch operations
- Track `analyze_nutrition_trends()` duration

### 3. Wire Storage Monitoring

In `storage/logs/queries.gleam`:
- Wrap database queries with start/record success/failure
- Track `get_daily_log()` complex operation
- Monitor batch queries like `get_recent_meals()`
- Track cache hit/miss for frequently used queries

### 4. Create Metrics Endpoint

In `web/handlers.gleam`:
```gleam
pub fn metrics_handler(_req: Request(Connection)) -> Response(String) {
  let snapshots = collector.snapshot_all_categories(global_metrics)
  let text = prometheus.export_metrics(snapshots)
  
  response.new(200)
  |> response.prepend_header("content-type", "text/plain; version=0.0.4")
  |> response.set_body(text)
}
```

### 5. Prometheus Configuration

Configure Prometheus to scrape metrics:
```yaml
scrape_configs:
  - job_name: 'meal-planner'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

## Best Practices

1. **Use descriptive operation names**: "GET /api/recipes/" instead of "api_call"
2. **Include context in labels**: endpoint, table, error_type
3. **Record both success and failure**: Enables SLO tracking
4. **Measure at entry/exit points**: Minimize overhead
5. **Use percentiles for SLO**: p95/p99 better than just avg
6. **Keep cardinality reasonable**: Avoid unbounded label values
7. **Record batch metrics separately**: Distinguish batch from single-item ops

## Example: Complete Flow

```gleam
// 1. Create global metrics collector at app startup
let metrics = collector.new_collector()

// 2. In tandoor/client.gleam GET request:
let context = tandoor_monitoring.start_api_call("/api/recipes/", "GET")
// ... execute HTTP request ...
let metrics = case result {
  Ok(_) -> tandoor_monitoring.record_api_success(metrics, context)
  Error(e) -> tandoor_monitoring.record_api_failure(metrics, context, e)
}

// 3. In ncp.gleam reconciliation:
let ncp_context = ncp_monitoring.start_reconciliation(list.length(history))
// ... run calculations ...
let metrics = ncp_monitoring.record_reconciliation_success(
  metrics, ncp_context, days, consistency, within_tolerance
)

// 4. In storage/logs/queries.gleam:
let query_context = storage_monitoring.start_query("select", "food_logs")
// ... execute query ...
let metrics = storage_monitoring.record_query_success(metrics, query_context, row_count)

// 5. In /metrics endpoint:
let snapshots = collector.snapshot_all_categories(metrics)
let prometheus_text = prometheus.export_metrics(snapshots)
response.new(200)
|> response.set_body(prometheus_text)
```

## Monitoring Infrastructure

The metrics are ready for:
- **Prometheus**: Direct text format export
- **Grafana**: Dashboard visualization
- **Alerting**: SLO violation alerts
- **Trending**: Performance regression detection
- **Reporting**: Period statistics and summaries

## Performance Impact

The monitoring system is designed for low overhead:
- In-process collection (no network calls)
- O(1) timing record operations
- Lazy percentile calculation (on snapshot)
- No blocking operations
- Memory-efficient aggregation

## Further Reading

- `gleam/src/meal_planner/performance.gleam` - Original SLA definitions
- `gleam/src/meal_planner/ncp_metrics.gleam` - NCP-specific metrics
- [Prometheus Metrics Types](https://prometheus.io/docs/concepts/metric_types/)
- [Prometheus Exposition Format](https://prometheus.io/docs/instrumenting/exposition_formats/)
