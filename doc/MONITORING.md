# Production Monitoring and Observability Strategy

**Task**: meal-planner-aejt Phase 3
**System**: Autonomous Nutritional Control Plane
**Date**: 2025-12-19
**Status**: Production Readiness

---

## Executive Summary

This document defines the monitoring, observability, and alerting strategy for the meal-planner production system. The system consists of:

1. **Generation Engine** - Weekly meal plan creation (Friday 6 AM)
2. **Scheduler Executor** - Job orchestration and retry management
3. **External APIs** - FatSecret (nutrition), Tandoor (recipes)
4. **Database** - PostgreSQL (job state, meal plans)
5. **Email Delivery** - SMTP (weekly plans, advisor emails)

**Target SLA**: 99.5% availability, <1s generation latency, 100% weekly generation success

---

## 1. Metrics Definition

### 1.1 Generation Engine Metrics

#### `generation_execution_time_seconds`
**Type**: Histogram
**Description**: Time to execute weekly meal plan generation (end-to-end)
**Labels**: `user_id`, `week_of`
**Unit**: seconds
**Thresholds**:
- p50 < 0.5s (target: 0.3s with parallel APIs)
- p95 < 1.0s
- p99 < 2.0s

**Query (Prometheus)**:
```promql
# p95 latency over last 1 hour
histogram_quantile(0.95,
  rate(generation_execution_time_seconds_bucket[1h])
)

# Slow generations (>2s)
generation_execution_time_seconds_bucket{le="2.0"}
  - generation_execution_time_seconds_bucket{le="+Inf"}
```

**Alert Rule**:
```yaml
- alert: GenerationEngineSlow
  expr: histogram_quantile(0.99, rate(generation_execution_time_seconds_bucket[5m])) > 2.0
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Generation engine p99 latency >2s"
    description: "p99 latency: {{ $value }}s (threshold: 2s)"
```

---

#### `generation_success_total`
**Type**: Counter
**Description**: Total successful weekly generations
**Labels**: `user_id`
**Unit**: count

**Query**:
```promql
# Success rate over last 24 hours
rate(generation_success_total[24h])
  / rate(generation_attempts_total[24h])

# Failures in last hour
increase(generation_failures_total[1h])
```

**Alert Rule**:
```yaml
- alert: GenerationSuccessRateLow
  expr: |
    rate(generation_success_total[1h])
      / rate(generation_attempts_total[1h]) < 0.95
  for: 30m
  labels:
    severity: critical
  annotations:
    summary: "Generation success rate <95%"
    description: "Success rate: {{ $value | humanizePercentage }}"
```

---

#### `generation_failures_total`
**Type**: Counter
**Description**: Total failed weekly generations
**Labels**: `user_id`, `error_type` (NoRecipesAvailable, TandoorError, FatSecretError, etc.)
**Unit**: count

**Query**:
```promql
# Failures by error type (last 24h)
sum by (error_type) (
  increase(generation_failures_total[24h])
)

# Top failing users
topk(5, sum by (user_id) (
  increase(generation_failures_total[7d])
))
```

---

#### `generation_recipe_selection_conflicts_total`
**Type**: Counter
**Description**: Count of recipe selection conflicts requiring retries
**Labels**: `conflict_type` (DuplicateRecipe, MacroImbalance, ConstraintViolation)
**Unit**: count

**Query**:
```promql
# Conflict rate as % of generations
rate(generation_recipe_selection_conflicts_total[1h])
  / rate(generation_attempts_total[1h])
```

**Threshold**: <5% conflict rate (retry rate should be rare)

---

#### `generation_macro_balance_success_rate`
**Type**: Gauge
**Description**: Percentage of generations achieving macro balance (±10%)
**Labels**: `user_id`
**Unit**: percentage (0.0 - 1.0)

**Query**:
```promql
# Weekly macro balance success rate
avg_over_time(generation_macro_balance_success_rate[7d])
```

**Alert Rule**:
```yaml
- alert: MacroBalanceRateLow
  expr: generation_macro_balance_success_rate < 0.90
  for: 2h
  labels:
    severity: warning
  annotations:
    summary: "Macro balance success <90%"
    description: "Balance rate: {{ $value | humanizePercentage }} (threshold: 90%)"
```

---

#### `generation_component_duration_seconds`
**Type**: Histogram
**Description**: Breakdown of generation execution by component
**Labels**: `component` (recipe_fetch, profile_fetch, generation_algorithm, macro_validation, grocery_consolidation, email_render)
**Unit**: seconds

**Query**:
```promql
# Component bottleneck analysis
topk(3,
  histogram_quantile(0.95,
    rate(generation_component_duration_seconds_bucket[1h])
  ) by (component)
)
```

**Expected Baseline** (from PERFORMANCE_BENCHMARKS.md):
- `recipe_fetch`: 150-450ms (sequential), 150ms (parallel)
- `profile_fetch`: 100-300ms
- `generation_algorithm`: <50ms
- `macro_validation`: <10ms
- `grocery_consolidation`: <100ms
- `email_render`: <50ms

---

### 1.2 Scheduler Executor Metrics

#### `scheduler_job_queue_depth`
**Type**: Gauge
**Description**: Number of pending jobs awaiting execution
**Labels**: `job_type` (WeeklyGeneration, AutoSync, DailyAdvisor, WeeklyTrends)
**Unit**: count

**Query**:
```promql
# Queue depth by job type
scheduler_job_queue_depth by (job_type)

# Queue backlog (jobs older than 5 minutes)
scheduler_job_queue_depth{age_minutes=">5"}
```

**Alert Rule**:
```yaml
- alert: SchedulerQueueBacklog
  expr: scheduler_job_queue_depth > 10
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "Scheduler queue backlog >10 jobs"
    description: "Queue depth: {{ $value }} (threshold: 10)"
```

---

#### `scheduler_job_execution_latency_seconds`
**Type**: Histogram
**Description**: Time from job scheduled_for to execution start
**Labels**: `job_type`, `priority` (Low, Medium, High, Critical)
**Unit**: seconds

**Query**:
```promql
# Execution latency by priority
histogram_quantile(0.95,
  rate(scheduler_job_execution_latency_seconds_bucket[1h])
) by (priority)

# Delayed jobs (latency >60s)
scheduler_job_execution_latency_seconds_bucket{le="+Inf"}
  - scheduler_job_execution_latency_seconds_bucket{le="60"}
```

**Thresholds**:
- Critical priority: p95 < 5s
- High priority: p95 < 30s
- Medium priority: p95 < 60s
- Low priority: p95 < 300s

---

#### `scheduler_job_retry_rate`
**Type**: Gauge
**Description**: Percentage of jobs retried after failure
**Labels**: `job_type`
**Unit**: percentage (0.0 - 1.0)

**Query**:
```promql
# Retry rate by job type (last 24h)
sum by (job_type) (
  increase(scheduler_job_retries_total[24h])
) / sum by (job_type) (
  increase(scheduler_job_executions_total[24h])
)
```

**Alert Rule**:
```yaml
- alert: SchedulerRetryRateHigh
  expr: scheduler_job_retry_rate > 0.20
  for: 1h
  labels:
    severity: warning
  annotations:
    summary: "Job retry rate >20%"
    description: "Retry rate: {{ $value | humanizePercentage }} for {{ $labels.job_type }}"
```

---

#### `scheduler_job_error_rate`
**Type**: Gauge
**Description**: Percentage of jobs failing (exhausted retries)
**Labels**: `job_type`, `error_type`
**Unit**: percentage (0.0 - 1.0)

**Query**:
```promql
# Error rate by job type
rate(scheduler_job_failures_total[1h])
  / rate(scheduler_job_executions_total[1h])

# Errors by type
sum by (error_type) (
  increase(scheduler_job_failures_total[24h])
)
```

**Alert Rule**:
```yaml
- alert: SchedulerJobFailureRateHigh
  expr: scheduler_job_error_rate > 0.05
  for: 30m
  labels:
    severity: critical
  annotations:
    summary: "Job failure rate >5%"
    description: "Failure rate: {{ $value | humanizePercentage }} for {{ $labels.job_type }}"
```

---

#### `scheduler_concurrent_jobs`
**Type**: Gauge
**Description**: Number of jobs currently executing
**Labels**: `job_type`
**Unit**: count

**Query**:
```promql
# Current concurrent jobs
scheduler_concurrent_jobs

# Max concurrency reached (saturated)
scheduler_concurrent_jobs >= 5
```

**Alert Rule**:
```yaml
- alert: SchedulerConcurrencySaturated
  expr: scheduler_concurrent_jobs >= 5
  for: 10m
  labels:
    severity: info
  annotations:
    summary: "Scheduler at max concurrency (5 jobs)"
    description: "Consider scaling executor capacity"
```

---

### 1.3 System Health Metrics

#### `api_availability`
**Type**: Gauge
**Description**: API availability status (0 = down, 1 = up)
**Labels**: `api` (fatsecret, tandoor)
**Unit**: boolean (0 or 1)

**Query**:
```promql
# Uptime over last 24 hours
avg_over_time(api_availability{api="fatsecret"}[24h])

# Downtime incidents (last 7 days)
changes(api_availability{api="tandoor"}[7d])
```

**Alert Rule**:
```yaml
- alert: ExternalAPIDown
  expr: api_availability == 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "External API {{ $labels.api }} is down"
    description: "API unavailable for >5 minutes"
```

---

#### `api_request_duration_seconds`
**Type**: Histogram
**Description**: External API request latency
**Labels**: `api` (fatsecret, tandoor), `endpoint` (profile, recipes, etc.)
**Unit**: seconds

**Query**:
```promql
# p95 latency by API
histogram_quantile(0.95,
  rate(api_request_duration_seconds_bucket[5m])
) by (api)

# Slow requests (>1s)
api_request_duration_seconds_bucket{le="+Inf"}
  - api_request_duration_seconds_bucket{le="1.0"}
```

**Thresholds**:
- FatSecret API: p95 < 500ms
- Tandoor API: p95 < 300ms

---

#### `api_request_total`
**Type**: Counter
**Description**: Total API requests made
**Labels**: `api`, `endpoint`, `status_code`
**Unit**: count

**Query**:
```promql
# Request rate (requests/sec)
rate(api_request_total[5m])

# 4xx/5xx error rate
sum(rate(api_request_total{status_code=~"4..|5.."}[5m])) by (api)
  / sum(rate(api_request_total[5m])) by (api)
```

**Alert Rule**:
```yaml
- alert: APIErrorRateHigh
  expr: |
    sum(rate(api_request_total{status_code=~"5.."}[5m])) by (api)
      / sum(rate(api_request_total[5m])) by (api) > 0.05
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "API 5xx error rate >5% for {{ $labels.api }}"
    description: "Error rate: {{ $value | humanizePercentage }}"
```

---

#### `database_connection_pool_usage`
**Type**: Gauge
**Description**: Active database connections / max pool size
**Labels**: `pool` (scheduler, api)
**Unit**: percentage (0.0 - 1.0)

**Query**:
```promql
# Connection pool saturation
database_connection_pool_usage

# Pool exhaustion (>90% usage)
database_connection_pool_usage > 0.90
```

**Alert Rule**:
```yaml
- alert: DatabaseConnectionPoolSaturated
  expr: database_connection_pool_usage > 0.90
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "DB connection pool >90% full"
    description: "Pool usage: {{ $value | humanizePercentage }}"
```

---

#### `database_query_duration_seconds`
**Type**: Histogram
**Description**: Database query execution time
**Labels**: `query` (get_next_pending_job, insert_meal_plan, etc.)
**Unit**: seconds

**Query**:
```promql
# Slow queries (p95 >50ms)
histogram_quantile(0.95,
  rate(database_query_duration_seconds_bucket[5m])
) > 0.050
```

**Alert Rule**:
```yaml
- alert: DatabaseQuerySlow
  expr: |
    histogram_quantile(0.95,
      rate(database_query_duration_seconds_bucket[5m])
    ) > 0.100
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Slow database query (p95 >100ms)"
    description: "Query {{ $labels.query }}: {{ $value }}s"
```

---

#### `email_delivery_success_rate`
**Type**: Gauge
**Description**: Percentage of emails delivered successfully
**Labels**: `email_type` (weekly_plan, daily_advisor, weekly_trends)
**Unit**: percentage (0.0 - 1.0)

**Query**:
```promql
# Delivery rate by email type
rate(email_delivery_success_total[1h])
  / rate(email_delivery_attempts_total[1h])

# Failed deliveries
increase(email_delivery_failures_total[1h])
```

**Alert Rule**:
```yaml
- alert: EmailDeliveryRateLow
  expr: email_delivery_success_rate < 0.95
  for: 30m
  labels:
    severity: warning
  annotations:
    summary: "Email delivery rate <95%"
    description: "Delivery rate: {{ $value | humanizePercentage }}"
```

---

#### `email_delivery_latency_seconds`
**Type**: Histogram
**Description**: Time from job completion to email sent
**Labels**: `email_type`
**Unit**: seconds

**Query**:
```promql
# p95 email latency
histogram_quantile(0.95,
  rate(email_delivery_latency_seconds_bucket[1h])
)
```

**Threshold**: p95 < 10s

---

#### `job_processing_throughput`
**Type**: Gauge
**Description**: Jobs processed per hour
**Labels**: `job_type`
**Unit**: jobs/hour

**Query**:
```promql
# Throughput trend (last 24h)
rate(scheduler_job_completions_total[1h]) * 3600
```

**Expected Baseline**:
- WeeklyGeneration: ~1 job/week (Friday 6 AM)
- AutoSync: ~8 jobs/day (every 2-4 hours)
- DailyAdvisor: 1 job/day (8 PM)
- WeeklyTrends: 1 job/week (Thursday 8 PM)

---

### 1.4 Business Metrics

#### `weekly_generation_success_all_users`
**Type**: Gauge
**Description**: Boolean indicating if ALL users received weekly plans
**Labels**: `week_of`
**Unit**: boolean (0 or 1)

**Query**:
```promql
# Success streak (consecutive weeks)
count_over_time(weekly_generation_success_all_users{week_of=~".*"}[4w])
```

**Alert Rule**:
```yaml
- alert: WeeklyGenerationIncomplete
  expr: weekly_generation_success_all_users == 0
  for: 6h
  labels:
    severity: critical
  annotations:
    summary: "Weekly generation failed for some users"
    description: "Week {{ $labels.week_of }} - investigate failures"
```

---

#### `email_engagement_rate`
**Type**: Gauge
**Description**: Percentage of emails opened/clicked
**Labels**: `email_type`
**Unit**: percentage (0.0 - 1.0)

**Query**:
```promql
# Open rate by email type
email_opens_total / email_delivery_success_total

# Click-through rate
email_clicks_total / email_opens_total
```

**Baseline Targets**:
- Weekly plan emails: 70% open rate
- Advisor emails: 50% open rate

---

#### `command_execution_rate`
**Type**: Counter
**Description**: Email commands executed (LOCK, UNLOCK, REGENERATE, etc.)
**Labels**: `command_type`
**Unit**: count

**Query**:
```promql
# Most used commands (last 30 days)
topk(5, sum by (command_type) (
  increase(command_execution_rate[30d])
))
```

---

#### `cost_metrics_api_calls`
**Type**: Counter
**Description**: Total API calls (for cost tracking)
**Labels**: `api` (fatsecret, tandoor)
**Unit**: count

**Query**:
```promql
# Monthly API call volume
increase(cost_metrics_api_calls[30d])

# Daily API cost estimate (assumes $0.001/call)
rate(cost_metrics_api_calls[1d]) * 86400 * 0.001
```

---

#### `cost_metrics_bandwidth_bytes`
**Type**: Counter
**Description**: Total bandwidth used (email attachments, API responses)
**Labels**: `source` (email, api)
**Unit**: bytes

**Query**:
```promql
# Monthly bandwidth (GB)
increase(cost_metrics_bandwidth_bytes[30d]) / 1e9
```

---

## 2. Dashboard Design

### 2.1 Generation Engine Dashboard

**Purpose**: Monitor weekly meal plan generation performance

**Panels**:

1. **Generation Latency (Timeseries)**
   ```promql
   histogram_quantile(0.50, rate(generation_execution_time_seconds_bucket[5m]))
   histogram_quantile(0.95, rate(generation_execution_time_seconds_bucket[5m]))
   histogram_quantile(0.99, rate(generation_execution_time_seconds_bucket[5m]))
   ```
   - 3 lines: p50 (green), p95 (yellow), p99 (red)
   - Horizontal line at 1s (target)

2. **Success vs Failure Rate (Bar gauge)**
   ```promql
   rate(generation_success_total[1h])
   rate(generation_failures_total[1h])
   ```
   - 2 bars: Success (green), Failures (red)
   - Target: >95% success

3. **Component Breakdown (Heatmap)**
   ```promql
   histogram_quantile(0.95,
     rate(generation_component_duration_seconds_bucket[5m])
   ) by (component)
   ```
   - Heatmap: component (x-axis), time (y-axis), latency (color)
   - Identifies bottlenecks

4. **Error Distribution (Pie chart)**
   ```promql
   sum by (error_type) (increase(generation_failures_total[24h]))
   ```
   - Pie slices: NoRecipesAvailable, TandoorError, FatSecretError, etc.

5. **Macro Balance Success (Single stat)**
   ```promql
   avg(generation_macro_balance_success_rate)
   ```
   - Large number with sparkline
   - Green if >90%, yellow if 80-90%, red if <80%

---

### 2.2 Scheduler Dashboard

**Purpose**: Monitor job orchestration and retry management

**Panels**:

1. **Job Queue Depth (Timeseries)**
   ```promql
   scheduler_job_queue_depth by (job_type)
   ```
   - Stacked area: 4 layers (WeeklyGeneration, AutoSync, DailyAdvisor, WeeklyTrends)
   - Alert line at 10 jobs

2. **Execution Latency by Priority (Table)**
   ```promql
   histogram_quantile(0.95,
     rate(scheduler_job_execution_latency_seconds_bucket[1h])
   ) by (priority)
   ```
   - Columns: Priority, p50, p95, p99, Threshold
   - Color-coded: Green (within threshold), Red (exceeds)

3. **Retry and Failure Rates (Graph)**
   ```promql
   scheduler_job_retry_rate by (job_type)
   scheduler_job_error_rate by (job_type)
   ```
   - 2 lines per job type: Retry (dashed), Failure (solid)
   - Target lines: Retry <20%, Failure <5%

4. **Concurrent Job Execution (Gauge)**
   ```promql
   scheduler_concurrent_jobs
   ```
   - Gauge: 0-5 (max concurrency)
   - Red zone: 4-5 (saturated)

5. **Job Execution History (Table)**
   - Recent executions (last 100)
   - Columns: Job ID, Type, Started, Duration, Status, Retries
   - Sortable, filterable

---

### 2.3 System Health Dashboard

**Purpose**: Monitor external dependencies and infrastructure

**Panels**:

1. **API Availability (Status history)**
   ```promql
   api_availability by (api)
   ```
   - 2 rows: FatSecret (green/red), Tandoor (green/red)
   - Timeline: last 24 hours

2. **API Latency (Timeseries)**
   ```promql
   histogram_quantile(0.95,
     rate(api_request_duration_seconds_bucket[5m])
   ) by (api)
   ```
   - 2 lines: FatSecret (blue), Tandoor (orange)
   - Target lines: FatSecret 500ms, Tandoor 300ms

3. **Database Connection Pool (Gauge)**
   ```promql
   database_connection_pool_usage by (pool)
   ```
   - 2 gauges: Scheduler pool, API pool
   - Yellow zone: >70%, Red zone: >90%

4. **Database Query Performance (Table)**
   ```promql
   topk(10,
     histogram_quantile(0.95,
       rate(database_query_duration_seconds_bucket[5m])
     ) by (query)
   )
   ```
   - Columns: Query, p95 latency, Calls/sec
   - Sorted by latency (slowest first)

5. **Email Delivery Metrics (Stat panels)**
   ```promql
   email_delivery_success_rate
   email_delivery_latency_seconds
   ```
   - 2 stats: Success rate (%), p95 latency (seconds)

6. **API Error Rate (Graph)**
   ```promql
   sum(rate(api_request_total{status_code=~"4.."}[5m])) by (api)
   sum(rate(api_request_total{status_code=~"5.."}[5m])) by (api)
   ```
   - Stacked bars: 4xx (yellow), 5xx (red)
   - Per API: FatSecret, Tandoor

---

### 2.4 Business Metrics Dashboard

**Purpose**: Track SLA compliance and user engagement

**Panels**:

1. **Weekly Generation Success Streak (Stat)**
   ```promql
   count_over_time(weekly_generation_success_all_users[8w])
   ```
   - Large number: "8 consecutive weeks"
   - Green if >4 weeks

2. **Email Engagement Funnel (Funnel chart)**
   ```promql
   email_delivery_success_total
   email_opens_total
   email_clicks_total
   command_execution_rate
   ```
   - 4 stages: Delivered → Opened → Clicked → Command Executed

3. **Command Usage Heatmap (Table)**
   ```promql
   sum by (command_type, week_of) (
     increase(command_execution_rate[7d])
   )
   ```
   - Rows: Commands (LOCK, UNLOCK, etc.)
   - Columns: Weeks
   - Cell color: Usage count

4. **Cost Metrics (Timeseries)**
   ```promql
   rate(cost_metrics_api_calls[1d]) * 86400 * 0.001
   increase(cost_metrics_bandwidth_bytes[1d]) / 1e9
   ```
   - 2 lines: API costs (USD), Bandwidth (GB)
   - Monthly projection overlay

5. **SLA Compliance (Single stat)**
   ```promql
   # Availability SLA (target: 99.5%)
   avg_over_time(api_availability[30d])
   ```
   - Large percentage with uptime/downtime breakdown

---

## 3. Logging Strategy

### 3.1 Structured Logging Format

**Standard**: JSON logs with consistent fields

**Base Fields** (all log entries):
```json
{
  "timestamp": "2025-12-19T06:00:00.123Z",
  "level": "info",
  "component": "generation_scheduler",
  "message": "Weekly generation started",
  "trace_id": "gen_2025w51_u123",
  "user_id": "user_lewis",
  "job_id": "job_weekly_generation_2025w51"
}
```

**Error Fields** (level=error):
```json
{
  "level": "error",
  "message": "Generation failed: Tandoor API timeout",
  "error_type": "TandoorError",
  "error_message": "Connection timeout after 500ms",
  "stack_trace": "...",
  "retry_attempt": 2,
  "retry_scheduled_for": "2025-12-19T06:05:00Z"
}
```

**Performance Fields** (level=debug):
```json
{
  "level": "debug",
  "message": "Generation completed",
  "duration_ms": 487,
  "component_timings": {
    "recipe_fetch": 152,
    "profile_fetch": 201,
    "generation_algorithm": 45,
    "macro_validation": 8,
    "grocery_consolidation": 62,
    "email_render": 19
  }
}
```

---

### 3.2 Log Levels and Sampling

**Log Levels**:
- `ERROR`: Failures requiring investigation (always logged)
- `WARN`: Degraded performance or retries (always logged)
- `INFO`: Normal operations (sampled at 10% in production)
- `DEBUG`: Detailed diagnostics (disabled in production, enabled on-demand)

**Sampling Strategy**:
```gleam
// Pseudo-code for log sampling
pub fn should_log(level: LogLevel, trace_id: String) -> Bool {
  case level {
    Error | Warn -> True  // Always log errors/warnings
    Info -> hash(trace_id) % 10 == 0  // 10% sampling
    Debug -> False  // Disabled by default
  }
}
```

**Dynamic Sampling** (on-demand):
- Set `LOG_LEVEL=debug` for specific user_id
- Set `TRACE_REQUESTS=true` for 100% sampling (debugging)

---

### 3.3 Query Examples

#### Find Slow Generations (>2s)
```
level:info component:generation_scheduler duration_ms:>2000
| sort -timestamp
| table timestamp, user_id, duration_ms, component_timings.recipe_fetch
```

#### Failed Jobs with Context
```
level:error component:scheduler
| stats count by error_type, job_id
| sort -count
```

#### Tandoor API Timeouts
```
level:error error_type:TandoorError message:*timeout*
| timechart span=1h count
```

#### Database Slow Queries
```
level:warn component:database duration_ms:>100
| table timestamp, query, duration_ms, connection_pool_usage
```

#### User-Specific Issues
```
user_id:user_lewis level:error
| sort -timestamp
| head 50
```

#### Retry Pattern Analysis
```
retry_attempt:>0
| stats avg(duration_ms) by retry_attempt
| table retry_attempt, avg_duration_ms
```

---

### 3.4 Log Retention

**Retention Policy**:
- ERROR/WARN logs: 90 days (hot storage), 1 year (cold storage)
- INFO logs: 30 days (hot), 90 days (cold)
- DEBUG logs: 7 days (hot), purged after

**Storage Estimates**:
- ERROR/WARN: ~100 MB/month (low volume)
- INFO (10% sampled): ~500 MB/month
- Total: ~600 MB/month (~7 GB/year)

**Indexing**:
- Full-text index on `message` field
- Field indexes: `level`, `component`, `error_type`, `user_id`, `job_id`
- Time-partitioned by week (for efficient queries)

---

## 4. Alerting

### 4.1 Alert Rules

#### Critical Alerts (Page On-Call Immediately)

1. **WeeklyGenerationIncomplete**
   - Condition: `weekly_generation_success_all_users == 0` for 6h
   - Escalation: Immediate page
   - Runbook: `/runbook/generation-failed`

2. **ExternalAPIDown**
   - Condition: `api_availability == 0` for 5m
   - Escalation: Immediate page
   - Runbook: `/runbook/api-down`

3. **SchedulerJobFailureRateHigh**
   - Condition: `scheduler_job_error_rate > 0.05` for 30m
   - Escalation: Page after 30m
   - Runbook: `/runbook/job-failures`

4. **DatabaseConnectionPoolSaturated**
   - Condition: `database_connection_pool_usage > 0.90` for 5m
   - Escalation: Immediate page
   - Runbook: `/runbook/db-pool-saturated`

---

#### Warning Alerts (Slack Notification)

5. **GenerationEngineSlow**
   - Condition: `generation_execution_time_seconds{p99} > 2.0` for 10m
   - Escalation: Slack alert, investigate within 1 hour
   - Runbook: `/runbook/generation-slow`

6. **APIErrorRateHigh**
   - Condition: API 5xx rate >5% for 10m
   - Escalation: Slack alert
   - Runbook: `/runbook/api-errors`

7. **SchedulerRetryRateHigh**
   - Condition: `scheduler_job_retry_rate > 0.20` for 1h
   - Escalation: Slack alert
   - Runbook: `/runbook/high-retry-rate`

8. **EmailDeliveryRateLow**
   - Condition: `email_delivery_success_rate < 0.95` for 30m
   - Escalation: Slack alert
   - Runbook: `/runbook/email-delivery-issues`

---

#### Info Alerts (No Action Required)

9. **SchedulerConcurrencySaturated**
   - Condition: `scheduler_concurrent_jobs >= 5` for 10m
   - Escalation: Info log
   - Action: Consider scaling executor capacity

10. **MacroBalanceRateLow**
    - Condition: `generation_macro_balance_success_rate < 0.90` for 2h
    - Escalation: Info log
    - Action: Review recipe nutrition data quality

---

### 4.2 Escalation Policy

**Tier 1: Automated Response** (0-5 minutes)
- Trigger: Alert fires
- Action: Automated retry (if transient error detected)
- Fallback: Escalate to Tier 2 if retry fails

**Tier 2: On-Call Engineer** (5-15 minutes)
- Trigger: Alert persists for 5m OR critical alert
- Action: Page on-call engineer via PagerDuty
- SLA: Acknowledge within 5m, mitigate within 15m

**Tier 3: Engineering Lead** (15-30 minutes)
- Trigger: Issue not resolved in 15m
- Action: Page engineering lead
- SLA: Mitigation plan within 30m

**Tier 4: Incident Response** (30+ minutes)
- Trigger: Issue not resolved in 30m OR multiple systems affected
- Action: Declare incident, assemble war room
- SLA: Full resolution plan within 1 hour

---

### 4.3 Runbook: Generation Engine Slow

**Alert**: `GenerationEngineSlow`
**Condition**: p99 generation latency >2s
**Severity**: Warning

#### Diagnosis Steps

1. **Check Component Breakdown**
   ```
   Query: histogram_quantile(0.95,
     rate(generation_component_duration_seconds_bucket[5m])
   ) by (component)
   ```
   - Identify bottleneck: recipe_fetch, profile_fetch, etc.

2. **Check External API Health**
   ```bash
   # FatSecret API health
   curl -I https://platform.fatsecret.com/rest/server.api

   # Tandoor API health
   curl -I https://tandoor.example.com/api/recipe
   ```
   - Expected: HTTP 200 response in <500ms

3. **Check Database Performance**
   ```sql
   SELECT query, mean_exec_time, calls
   FROM pg_stat_statements
   WHERE mean_exec_time > 100
   ORDER BY mean_exec_time DESC
   LIMIT 10;
   ```
   - Look for slow queries (>100ms)

4. **Check Logs**
   ```
   level:warn component:generation_scheduler duration_ms:>2000
   | table timestamp, user_id, duration_ms, component_timings
   ```
   - Identify patterns (specific users, time of day, etc.)

#### Resolution Steps

**If API is slow:**
- Check API provider status page
- Verify network connectivity (`ping`, `traceroute`)
- Check API rate limit headers
- Implement temporary timeout increase (500ms → 1000ms)
- Enable parallel API execution (if not already enabled)

**If database is slow:**
- Run `VACUUM ANALYZE` on job tables
- Check connection pool usage (`database_connection_pool_usage`)
- Identify and kill long-running queries
- Add missing indexes (see EXPLAIN ANALYZE output)

**If generation algorithm is slow:**
- Check recipe pool size (should be 11 recipes, not 1000+)
- Verify locked meals count (should be 0-3, not 21)
- Profile Gleam code with `:timer.tc/1` wrapper
- Review recent code changes (regression?)

**If email rendering is slow:**
- Check template size (should be <50KB)
- Verify image URLs are reachable
- Profile template rendering logic

#### Mitigation

Temporary workaround if issue persists:
```gleam
// Increase timeout thresholds temporarily
let generation_timeout_ms = 5000  // Was: 2000ms
```

Permanent fix:
- Optimize bottleneck component
- Add caching layer (recipe pool cache, user profile cache)
- Implement parallel API execution

#### Post-Incident

- Document root cause in postmortem
- Add test case to prevent regression
- Update performance benchmarks

---

### 4.4 Runbook: External API Down

**Alert**: `ExternalAPIDown`
**Condition**: `api_availability{api="fatsecret"} == 0` for 5m
**Severity**: Critical

#### Diagnosis Steps

1. **Verify API Status**
   ```bash
   # FatSecret
   curl -I https://platform.fatsecret.com/rest/server.api

   # Tandoor
   curl -I https://tandoor.example.com/api/recipe
   ```
   - Expected: HTTP 200
   - Check HTTP status, latency, response body

2. **Check DNS Resolution**
   ```bash
   nslookup platform.fatsecret.com
   nslookup tandoor.example.com
   ```
   - Verify DNS resolves correctly

3. **Check Network Connectivity**
   ```bash
   ping platform.fatsecret.com
   traceroute platform.fatsecret.com
   ```
   - Verify routing path, packet loss

4. **Check Firewall/Security Groups**
   - Verify outbound HTTPS (443) allowed
   - Check IP whitelisting (if required)

5. **Check API Provider Status**
   - FatSecret: https://status.fatsecret.com (hypothetical)
   - Tandoor: Check self-hosted instance health

6. **Check Logs**
   ```
   level:error error_type:NetworkError api:fatsecret
   | stats count by error_message
   ```
   - Identify error patterns (timeout, connection refused, etc.)

#### Resolution Steps

**If API provider is down:**
- Check status page for incident updates
- Estimate downtime duration
- Communicate to users via status page
- Implement fallback:
  - Use cached recipe pool (if available)
  - Use default macro targets (if FatSecret unavailable)
  - Skip sync jobs until API recovers

**If network issue:**
- Restart network service
- Flush DNS cache
- Update firewall rules
- Contact network team

**If authentication failure:**
- Verify API credentials (client_id, secret, token)
- Check token expiration
- Re-authenticate using OAuth flow
- Rotate credentials if compromised

**If rate limit exceeded:**
- Check rate limit headers (`X-RateLimit-Remaining`)
- Implement exponential backoff
- Reduce request frequency
- Upgrade API plan (if needed)

#### Mitigation

Temporary fallback:
```gleam
// Use cached data if API unavailable
pub fn fetch_recipes_with_fallback() -> Result(List(Recipe), Error) {
  case fetch_recipes_from_api() {
    Ok(recipes) -> Ok(recipes)
    Error(_) -> fetch_recipes_from_cache()  // Use 1-hour cached data
  }
}
```

#### Post-Incident

- Update API retry policy (max attempts, backoff)
- Implement circuit breaker pattern
- Add API status monitoring
- Document incident timeline

---

### 4.5 Runbook: Job Failures

**Alert**: `SchedulerJobFailureRateHigh`
**Condition**: Job failure rate >5% for 30m
**Severity**: Critical

#### Diagnosis Steps

1. **Identify Failing Job Types**
   ```
   Query: sum by (job_type, error_type) (
     increase(scheduler_job_failures_total[1h])
   )
   ```
   - Determine which jobs are failing

2. **Check Error Distribution**
   ```
   level:error component:scheduler
   | stats count by error_type
   | sort -count
   ```
   - Identify most common error type

3. **Review Recent Job Executions**
   ```sql
   SELECT job_id, job_type, status, error_message, attempt_number
   FROM job_executions
   WHERE status = 'failed'
   ORDER BY started_at DESC
   LIMIT 50;
   ```
   - Look for patterns (specific users, time ranges, etc.)

4. **Check Retry Exhaustion**
   ```
   Query: scheduler_job_retry_exhausted_total by (job_type)
   ```
   - Verify jobs are retrying before failing

#### Resolution Steps

**If transient errors (network, timeout):**
- Increase retry max attempts (3 → 5)
- Increase timeout thresholds
- Implement exponential backoff
- Verify external API health

**If permanent errors (invalid data, constraint violations):**
- Review failing job parameters
- Validate input data (user constraints, recipe IDs, etc.)
- Fix data integrity issues in database
- Update job validation logic

**If database errors:**
- Check database connectivity
- Verify schema migrations applied
- Check for deadlocks (`pg_stat_activity`)
- Review transaction isolation levels

**If resource exhaustion:**
- Check CPU/memory usage
- Scale executor capacity (add workers)
- Reduce concurrent job limit
- Implement job prioritization

#### Mitigation

Pause failing jobs:
```sql
UPDATE scheduled_jobs
SET enabled = FALSE
WHERE job_type = 'AutoSync' AND error_count > 3;
```

Manual retry after fix:
```sql
UPDATE scheduled_jobs
SET status = 'pending', error_count = 0, last_error = NULL
WHERE job_type = 'AutoSync' AND enabled = TRUE;
```

#### Post-Incident

- Add validation tests for job parameters
- Improve error messages for diagnostics
- Document failure scenarios in runbook

---

### 4.6 Runbook: Database Pool Saturated

**Alert**: `DatabaseConnectionPoolSaturated`
**Condition**: Connection pool usage >90% for 5m
**Severity**: Critical

#### Diagnosis Steps

1. **Check Current Pool Usage**
   ```sql
   SELECT count(*) AS active_connections
   FROM pg_stat_activity
   WHERE datname = 'meal_planner';
   ```
   - Compare to pool max_size (default: 20)

2. **Identify Long-Running Queries**
   ```sql
   SELECT pid, usename, query, state, now() - query_start AS duration
   FROM pg_stat_activity
   WHERE state != 'idle' AND now() - query_start > interval '30 seconds'
   ORDER BY duration DESC;
   ```
   - Look for queries running >30s

3. **Check Connection Leaks**
   ```
   Query: database_connection_pool_usage by (pool)
   ```
   - Verify connections are released after use

4. **Check Application Logs**
   ```
   level:error message:*connection pool*
   | table timestamp, component, error_message
   ```
   - Identify connection acquisition failures

#### Resolution Steps

**If long-running queries:**
- Kill blocking queries:
  ```sql
  SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid = <pid>;
  ```
- Add query timeout:
  ```sql
  SET statement_timeout = '30s';
  ```
- Optimize slow queries (add indexes, rewrite)

**If connection leaks:**
- Restart application (releases connections)
- Review code for missing `pog.disconnect()` calls
- Add connection leak detection logging

**If pool too small:**
- Increase max_connections in PostgreSQL config
- Increase pool max_size in application config
- Scale database (vertical or horizontal)

**If high concurrency:**
- Implement connection pooling middleware (PgBouncer)
- Use read replicas for read-heavy queries
- Reduce concurrent job limit

#### Mitigation

Temporary increase:
```gleam
// Increase pool size temporarily
let pool_config = pog.Config(
  ..default_config,
  max_size: 30  // Was: 20
)
```

#### Post-Incident

- Add connection pool monitoring dashboard
- Set up alerts for pool usage >70%
- Document connection pool tuning guide

---

## 5. Success Metrics

### 5.1 SLA Targets

| Metric | Target | Measurement Window |
|--------|--------|-------------------|
| **Availability** | 99.5% | 30 days |
| **Generation Latency** | p95 < 1s | 24 hours |
| **Weekly Generation Success** | 100% | Per week |
| **Email Delivery Rate** | >95% | 24 hours |
| **Job Failure Rate** | <5% | 24 hours |
| **API Error Rate** | <5% | 1 hour |

### 5.2 Performance Baselines

**From PERFORMANCE_BENCHMARKS.md**:

| Component | Baseline | Target (Optimized) |
|-----------|----------|-------------------|
| Generation algorithm | <50ms | <50ms |
| Recipe fetch (sequential) | 150-450ms | N/A |
| Recipe fetch (parallel) | N/A | <150ms |
| Profile fetch | 100-300ms | <200ms |
| Macro validation | <10ms | <10ms |
| Grocery consolidation | <100ms | <20ms |
| Email render | <50ms | <50ms |
| **Total (sequential)** | <960ms | N/A |
| **Total (parallel)** | N/A | <500ms |

### 5.3 Success Criteria

**Definition of Done**:
- ✅ All metrics implemented in Prometheus
- ✅ All dashboards created in Grafana
- ✅ All alerts configured in AlertManager
- ✅ All runbooks documented and tested
- ✅ On-call rotation established
- ✅ Monitoring validated in staging environment

**Validation Tests**:
1. Trigger test alert (verify PagerDuty integration)
2. Simulate API failure (verify fallback behavior)
3. Load test scheduler (verify concurrency limits)
4. Generate slow query (verify slow query alert)
5. Exhaust connection pool (verify pool saturation alert)

---

## 6. Implementation Plan

### Phase 1: Metrics Instrumentation (Week 1)

**Tasks**:
1. Add Prometheus client to Gleam app
2. Instrument generation engine with metrics
3. Instrument scheduler executor with metrics
4. Instrument API clients with metrics
5. Instrument database layer with metrics

**Deliverable**: All metrics emitting to Prometheus

---

### Phase 2: Dashboard Creation (Week 2)

**Tasks**:
1. Create Generation Engine dashboard
2. Create Scheduler dashboard
3. Create System Health dashboard
4. Create Business Metrics dashboard

**Deliverable**: 4 Grafana dashboards

---

### Phase 3: Alerting Setup (Week 3)

**Tasks**:
1. Configure AlertManager
2. Create alert rules (critical + warning)
3. Set up PagerDuty integration
4. Test alert escalation

**Deliverable**: All alerts operational

---

### Phase 4: Runbook Documentation (Week 4)

**Tasks**:
1. Write runbooks for all critical alerts
2. Document resolution procedures
3. Create troubleshooting flowcharts
4. Train on-call engineers

**Deliverable**: Complete runbook repository

---

### Phase 5: Validation & Launch (Week 5)

**Tasks**:
1. Load test in staging
2. Trigger test alerts
3. Validate metric accuracy
4. Deploy to production

**Deliverable**: Monitoring live in production

---

## 7. Appendix

### 7.1 Tool Stack

- **Metrics**: Prometheus (time-series database)
- **Dashboards**: Grafana (visualization)
- **Alerts**: AlertManager (routing)
- **Paging**: PagerDuty (on-call)
- **Logs**: Loki or Elasticsearch (log aggregation)
- **Tracing**: Jaeger (distributed tracing, optional)

### 7.2 Prometheus Configuration

**prometheus.yml**:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'meal-planner-api'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: /metrics

  - job_name: 'meal-planner-scheduler'
    static_configs:
      - targets: ['localhost:8081']
    metrics_path: /metrics
```

### 7.3 Grafana Datasource

**datasource.yml**:
```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
```

### 7.4 Alert Manager Configuration

**alertmanager.yml**:
```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'pagerduty'
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty'
    - match:
        severity: warning
      receiver: 'slack'

receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: '<pagerduty-integration-key>'
  - name: 'slack'
    slack_configs:
      - api_url: '<slack-webhook-url>'
        channel: '#alerts'
```

---

**Document Version**: 1.0
**Last Updated**: 2025-12-19
**Maintainer**: Lewis (via Claude Code - Monitoring Specialist)
**Review Status**: Ready for implementation
