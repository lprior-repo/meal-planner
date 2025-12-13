# Implementation Tasks: Add Prometheus Metrics Export

## 1. Metrics Core Package

- [ ] 1.1 Create `metrics/mod.gleam` - Main registry and aggregation
- [ ] 1.2 Create `metrics/types.gleam` - Metric types (Counter, Histogram, Gauge)
- [ ] 1.3 Create `metrics/prometheus.gleam` - Prometheus text format export
- [ ] 1.4 Create `metrics/labels.gleam` - Tag/label handling
- [ ] 1.5 Test metric creation, updates, and aggregation

## 2. HTTP Integration

- [ ] 2.1 Create `web/handlers/metrics.gleam` - /metrics endpoint handler
- [ ] 2.2 Update `web/handlers.gleam` - Add metrics handler export
- [ ] 2.3 Update `web.gleam` - Route GET /metrics to handler
- [ ] 2.4 Test /metrics endpoint returns valid Prometheus format

## 3. Storage Layer Monitoring

- [ ] 3.1 Wire metrics into `storage/mod.gleam` - Record query execution times
- [ ] 3.2 Track query types: foods, nutrients, recipes, logs, profiles
- [ ] 3.3 Record cache hit/miss rates
- [ ] 3.4 Test metrics appear in /metrics output

## 4. Tandoor Integration Monitoring

- [ ] 4.1 Wire metrics into `tandoor/client.gleam` - API call latencies
- [ ] 4.2 Track endpoint types: recipes, ingredients, users
- [ ] 4.3 Record HTTP status codes and failure rates
- [ ] 4.4 Test Tandoor metrics exported

## 5. NCP Calculation Monitoring

- [ ] 5.1 Wire metrics into `ncp_metrics.gleam` - Calculation time
- [ ] 5.2 Track calculation types: macros, nutrients, compliance
- [ ] 5.3 Record error counts and failure reasons
- [ ] 5.4 Test NCP metrics exported

## 6. Meal Generation Monitoring

- [ ] 6.1 Wire metrics into `generator.gleam` - Generation time
- [ ] 6.2 Track generation parameters: meal_count, recipes_evaluated
- [ ] 6.3 Record success/failure rates
- [ ] 6.4 Test generation metrics exported

## 7. Testing & Validation

- [ ] 7.1 Write unit tests for metrics collection
- [ ] 7.2 Write integration tests for /metrics endpoint
- [ ] 7.3 Verify Prometheus format compliance (OPENMETRICS 1.0.0)
- [ ] 7.4 Test metric cardinality limits and label combinations
- [ ] 7.5 Benchmark metrics collection overhead (<1%)
- [ ] 7.6 Run gleam test and verify all tests pass

## 8. Documentation & Finalization

- [ ] 8.1 Document metric names and meanings in README
- [ ] 8.2 Add Prometheus config example for scraping
- [ ] 8.3 Update CLAUDE.md if needed
- [ ] 8.4 Verify no regressions in existing endpoints
- [ ] 8.5 Final commit and push
