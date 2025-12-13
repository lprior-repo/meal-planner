# Metrics Specification

## ADDED Requirements

### Requirement: Metric Types
The system SHALL support three metric types for performance monitoring:
- **Counter**: Monotonically increasing values (request counts, errors)
- **Histogram**: Distribution of values (query times, response sizes)
- **Gauge**: Current value snapshots (active connections, cache size)

Each metric SHALL have:
- Name (string identifier, follows `[a-z_][a-z0-9_]*` pattern)
- Description (human-readable explanation)
- Unit (optional: seconds, bytes, requests, etc.)
- Labels (optional: tags for multi-dimensional filtering like service, operation)

#### Scenario: Create counter metric
- **WHEN** a counter metric is created with name "requests_total"
- **THEN** the metric is registered in the registry
- **AND** the counter can be incremented by integer values
- **AND** the current value is retrievable

#### Scenario: Create histogram metric
- **WHEN** a histogram metric is created with buckets [10, 50, 100, 500, 1000]
- **THEN** observed values are distributed across buckets
- **AND** sum and count statistics are automatically maintained
- **AND** percentile calculations (p50, p95, p99) are available

#### Scenario: Create gauge metric
- **WHEN** a gauge metric is created with name "active_requests"
- **THEN** the gauge can be set to arbitrary float values
- **AND** the current value reflects the most recent set operation

### Requirement: Label Support
The system SHALL support labels (tags) for multi-dimensional metric analysis.

Labels SHALL:
- Be key-value pairs (e.g., "service"="storage", "operation"="query")
- Support up to 10 labels per metric to prevent cardinality explosion
- Be immutable once a metric is registered
- Appear in Prometheus exposition format

#### Scenario: Metric with labels
- **WHEN** a histogram is created with labels {"service": "tandoor", "endpoint": "/recipes"}
- **THEN** observed values contribute to that specific label combination
- **AND** different label combinations are tracked separately

### Requirement: Prometheus Text Format Export
The system SHALL export all metrics in Prometheus text exposition format (OPENMETRICS 1.0.0).

Export SHALL:
- Include metric comments (# HELP, # TYPE) before each metric
- Use correct types (counter, gauge, histogram, summary)
- Serialize labels as {key="value",key="value"}
- Format timestamps in milliseconds (optional)
- Be parseable by standard Prometheus scrape clients

#### Scenario: Export counters to Prometheus format
- **WHEN** a counter "http_requests_total" with value 42 is exported
- **THEN** the output includes:
  ```
  # HELP http_requests_total HTTP requests processed
  # TYPE http_requests_total counter
  http_requests_total 42
  ```

#### Scenario: Export histogram with labels to Prometheus format
- **WHEN** a histogram "query_duration_ms" with buckets and labels is exported
- **THEN** the output includes:
  ```
  # HELP query_duration_ms Query execution time in milliseconds
  # TYPE query_duration_ms histogram
  query_duration_ms_bucket{le="100",service="storage"} 5
  query_duration_ms_bucket{le="500",service="storage"} 8
  query_duration_ms_bucket{le="+Inf",service="storage"} 10
  query_duration_ms_sum{service="storage"} 1200
  query_duration_ms_count{service="storage"} 10
  ```

### Requirement: Thread-Safe Metric Collection
The system SHALL maintain thread-safe metric registries for concurrent updates.

Thread safety SHALL:
- Allow multiple processes to increment counters simultaneously
- Support histogram observations from concurrent requests
- Prevent data corruption under high concurrency
- Use Erlang/OTP process patterns (gen_server or atomic operations)

#### Scenario: Concurrent counter increments
- **WHEN** 100 processes increment a counter simultaneously
- **THEN** the final value equals the sum of all increments
- **AND** no data corruption occurs

### Requirement: Metrics HTTP Endpoint
The system SHALL expose metrics via GET /metrics endpoint.

The endpoint SHALL:
- Return status 200 OK with Prometheus text format body
- Set Content-Type to "text/plain; charset=utf-8; version=0.0.4"
- Aggregate metrics from all sources
- Respond in <100ms even with 1000+ metrics

#### Scenario: Scrape metrics endpoint
- **WHEN** a Prometheus scraper issues GET /metrics
- **THEN** response status is 200
- **AND** body contains all registered metrics in Prometheus format
- **AND** response time is <100ms

#### Scenario: Empty metrics endpoint
- **WHEN** no metrics have been recorded
- **THEN** GET /metrics returns empty Prometheus format
- **AND** no errors occur

### Requirement: Critical Path Instrumentation
The system SHALL measure performance of critical operations.

Instrumentation targets:
- **Storage layer**: Query execution times per query type
- **Tandoor integration**: API call duration, status codes, retry attempts
- **NCP calculations**: Macro calculation time, error rates
- **Meal generation**: Plan generation time, recipe evaluation count

Metrics names (pattern `operation_metric_unit`):
- storage_query_duration_ms (histogram)
- storage_query_count_total (counter, by query_type)
- tandoor_api_request_duration_ms (histogram, by endpoint)
- tandoor_api_errors_total (counter, by endpoint, status_code)
- ncp_macro_calculation_duration_ms (histogram)
- generator_meal_plan_duration_ms (histogram)

#### Scenario: Storage query monitoring
- **WHEN** a food search query executes in 45ms
- **THEN** storage_query_duration_ms histogram records 45
- **AND** storage_query_count_total[query_type="foods"] increments

#### Scenario: Tandoor API monitoring
- **WHEN** GET /api/recipes/ completes in 250ms with status 200
- **THEN** tandoor_api_request_duration_ms records 250
- **AND** tandoor_api_errors_total is not incremented

#### Scenario: Meal generation monitoring
- **WHEN** 7-day meal plan generation completes in 1800ms
- **THEN** generator_meal_plan_duration_ms histogram records 1800
- **AND** generator_meal_plan_duration_ms_count increments

### Requirement: Metric Cardinality Protection
The system SHALL prevent unbounded metric cardinality.

Protection mechanisms:
- Maximum 10 labels per metric (enforced)
- Maximum 1000 unique label combinations per metric (monitored)
- Error logging when cardinality limit approached
- Reject new label combinations exceeding limit

#### Scenario: Cardinality limit enforcement
- **WHEN** attempting to create metric with 11 labels
- **THEN** an error is returned
- **AND** the metric is not created

### Requirement: Performance Overhead
The system SHALL impose minimal overhead on normal operations.

Performance constraints:
- Metric collection overhead <1% of request latency (p99)
- No blocking on metric collection
- Aggregation on-demand during export
- No memory leaks from metric retention

#### Scenario: Low-overhead metric collection
- **WHEN** 1000 concurrent requests each record metrics
- **THEN** request latency increase is <1% (p99)
- **AND** memory usage remains stable

### Requirement: Metric Naming Convention
The system SHALL follow Prometheus naming conventions.

Naming rules:
- Use snake_case for metric names
- Include unit as suffix: `_seconds`, `_bytes`, `_total`, `_count`
- Avoid redundancy: not `request_duration_seconds_total`
- Use standardized operation names: storage, tandoor, ncp, generator

#### Scenario: Follow naming convention
- **WHEN** naming a counter for request completion
- **THEN** use `http_requests_total` (not `http_request_count`)
- **AND** use `query_duration_seconds` (not `query_time_ms`)
