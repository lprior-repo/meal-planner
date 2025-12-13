# Performance Metrics System

This document explains how to use the integrated performance monitoring system for the meal-planner application.

## Overview

The metrics system collects timing data from critical application paths:
- **Storage Queries**: Food searches, custom food operations, nutrient lookups
- **API Calls**: Tandoor API requests (GET, POST, PUT, PATCH, DELETE)
- **Calculations**: Macro calculations, meal selection, meal generation
- **Business Logic**: Any custom computation needing performance visibility

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Web Handlers / Controllers                  │
└─────────────────┬───────────────────────────────────────────┘
                  │
       ┌──────────┴──────────┐
       ▼                     ▼
┌──────────────────┐  ┌──────────────────┐
│   Storage Ops    │  │   API Calls      │
│  (foods, logs)   │  │  (Tandoor)       │
└────────┬─────────┘  └────────┬─────────┘
         │                     │
         └──────────┬──────────┘
                    ▼
         ┌─────────────────────┐
         │  MetricsRegistry    │
         │  (Collects timing)  │
         └──────────┬──────────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
    Prometheus   JSON Export  Console
     (.prom)     (.json)      Report
```

## Core Components

### 1. `metrics/mod.gleam` - Core Infrastructure
- **MetricsRegistry**: Main container for all metrics
- **QueryMetric**: Individual timing measurement
- **MetricSnapshot**: Aggregated statistics
- **OperationType**: Classification (StorageQuery, ApiCall, Calculation)

### 2. `metrics/prometheus.gleam` - Export & Reporting
- **export_prometheus()**: Prometheus 1.0 format
- **export_json()**: REST API friendly format
- **generate_report()**: Human-readable report

### 3. Instrumentation Modules
- **storage_instrumentation.gleam**: Wrappers for food operations
- **api_instrumentation.gleam**: Wrappers for external API calls
- **calculation_instrumentation.gleam**: Wrappers for business logic
- **storage.gleam**: Low-level query timing utilities
- **api.gleam**: Low-level API call timing utilities
- **calculations.gleam**: Low-level calculation timing utilities

### 4. `metrics/context.gleam` - Application Integration
- Registry initialization
- Metrics export
- Reporting functions

## Usage Examples

### Example 1: Food Search with Metrics

```gleam
import meal_planner/metrics/mod.{new_registry}
import meal_planner/metrics/storage_instrumentation as metrics

// Initialize registry at app startup
let registry = new_registry()

// Perform instrumented food search
let #(result, updated_registry) = metrics.search_foods(
  registry,
  db_connection,
  "chicken",
  limit: 20,
)

case result {
  Ok(foods) -> {
    // Use foods...
    // Metrics are automatically collected and stored in updated_registry
    io.println("Found " <> int.to_string(list.length(foods)) <> " foods")
  }
  Error(e) -> {
    // Error handling - still recorded in metrics with success=false
    io.println("Search failed: " <> error_to_string(e))
  }
}
```

### Example 2: API Call with Metrics

```gleam
import meal_planner/metrics/api_instrumentation as api_metrics

// Time a Tandoor GET request
let #(result, updated_registry) = api_metrics.time_tandoor_get(
  registry,
  "/api/recipes/123/",
  fn() { tandoor_client.get_recipe(client, 123) }
)

// Metrics are collected with operation: "Tandoor GET /api/recipes/123/"
```

### Example 3: Macro Calculation with Metrics

```gleam
import meal_planner/metrics/calculation_instrumentation as calc_metrics

// Time a meal macro calculation
let #(macros, updated_registry) = calc_metrics.meal_macros(registry, meal)

// Metrics recorded: operation="meal_macros"
```

### Example 4: Exporting Metrics

```gleam
import meal_planner/metrics/context
import meal_planner/metrics/prometheus

// Generate Prometheus format output
let prometheus_output = context.export_prometheus(registry)
// Returns OpenMetrics 1.0 format suitable for scraping

// Generate JSON output
let json_output = context.export_json(registry)
// Returns JSON with all metrics for API responses

// Generate human-readable report
let report = context.generate_report(registry)
io.println(report)
// Output:
// ╔════════════════════════════════════════════════════════════╗
// ║           Performance Metrics Report                        ║
// ╠════════════════════════════════════════════════════════════╣
// ║
// ## Storage Queries
//
//   search_foods
//     Calls: 42 | Avg: 3.21ms | Min: 1.05ms | Max: 8.73ms
//     Success Rate: 100% | Errors: 0
//   ...
```

## Integration Points

### Web Handlers Integration
Handlers should:
1. Create/receive metrics registry
2. Call instrumented functions instead of raw functions
3. Pass registry through the call chain
4. Return updated registry alongside response

```gleam
pub fn search_handler(req, registry) {
  let query = get_query_param(req, "q")
  let #(result, updated_registry) = storage_instrumentation.search_foods(
    registry, conn, query, 20
  )

  let response = case result {
    Ok(foods) -> format_foods_response(foods)
    Error(e) -> format_error_response(e)
  }

  #(response, updated_registry)
}
```

### Request Context Propagation
For web frameworks, metrics registry should be part of request context:

```gleam
pub type RequestContext {
  RequestContext(
    user_id: String,
    db_conn: pog.Connection,
    metrics_registry: MetricsRegistry,
  )
}

// Handlers receive context and return updated context
pub fn my_handler(ctx: RequestContext) -> #(Response, RequestContext) {
  // Use ctx.metrics_registry
  // Return updated context with modified registry
}
```

## Metrics Collection Points

### Storage Layer
- `search_foods` - USDA food text search
- `search_foods_paginated` - Paginated food search
- `get_food_by_id` - Direct food lookup
- `get_food_nutrients` - Nutrient data lookup
- `search_custom_foods` - User custom food search
- `create_custom_food` - Custom food creation
- `update_custom_food` - Custom food updates
- `delete_custom_food` - Custom food deletion

### API Layer (Tandoor)
- `GET /api/recipes/` - List recipes
- `GET /api/recipes/{id}/` - Get recipe
- `POST /api/recipes/` - Create recipe
- `PATCH /api/recipes/{id}/` - Update recipe
- `DELETE /api/recipes/{id}/` - Delete recipe

### Calculation Layer
- `meal_macros` - Calculate meal nutrition
- `daily_plan_macros` - Calculate daily totals
- `weekly_plan_macros` - Calculate weekly totals
- `get_meal_category` - Categorize meal
- `analyze_distribution` - Analyze vertical diet compliance

## Performance Targets (SLAs)

Based on `performance.gleam` SLA definitions:
- Dashboard load: < 20ms
- Search latency: < 5ms
- Cache hit rate: > 80%

The metrics system tracks actual vs. target performance for alerting.

## Exporting Metrics

### Prometheus Format
The `export_prometheus()` function returns OpenMetrics 1.0 format:

```
# HELP storage_query_duration_ms Storage query execution time
# TYPE storage_query_duration_ms summary
storage_query_duration_ms{operation="search_foods",quantile="0.5"} 3.21
storage_query_duration_ms{operation="search_foods",quantile="0.9"} 8.73
storage_query_duration_ms_count{operation="search_foods"} 42
storage_query_duration_ms_sum{operation="search_foods"} 134.82
storage_query_duration_ms_errors{operation="search_foods"} 0
```

### JSON Format
The `export_json()` function returns machine-readable JSON:

```json
{
  "storage_queries": [
    {
      "name": "search_foods",
      "count": 42,
      "total_ms": 134.82,
      "avg_ms": 3.21,
      "min_ms": 1.05,
      "max_ms": 8.73,
      "error_count": 0,
      "success_rate": 100.0
    }
  ],
  "api_calls": [...],
  "calculations": [...]
}
```

## Best Practices

1. **Initialize Early**: Create registry at application startup
2. **Use Instrumentation Modules**: Use `*_instrumentation.gleam` modules instead of direct metrics calls for consistency
3. **Propagate Registry**: Pass registry through function chains to collect complete trace
4. **Export Regularly**: Export metrics periodically (e.g., on health check endpoint)
5. **Monitor Critical Paths**: Focus instrumentation on high-impact operations
6. **Document Custom Metrics**: If adding custom timing, document in this file

## Performance Impact

- Metrics collection adds ~0.1-0.2ms per operation
- Minimal memory overhead (in-memory registry only)
- No network calls unless explicitly exporting
- Suitable for production use with high-volume operations

## Future Enhancements

- [ ] Persistent metrics storage (time-series DB)
- [ ] Alerting on SLA violations
- [ ] Per-user performance tracking
- [ ] Cache hit rate monitoring
- [ ] Database query plan analysis
- [ ] Distributed tracing support
