# Deployment and Rollout Strategy
## meal-planner-aejt Phase 3: Production Release

**Document Version:** 1.0
**Last Updated:** 2025-12-19
**Owner:** Operations Team
**Status:** Draft - Pending Review

---

## Executive Summary

This document outlines the deployment strategy for Phase 3 of the meal-planner application, introducing the Weekly Meal Plan Generation Engine and Automation Loop. The strategy employs a **three-phase rollout** over 11 days total:

- **Phase 1:** Canary Deployment (1 day) - 5% beta users
- **Phase 2:** Gradual Rollout (3 days) - 25% → 50% → 100%
- **Phase 3:** Stabilization (1 week) - monitoring and feedback

**Key Features Being Deployed:**
- Weekly meal plan generation engine
- Automated FatSecret synchronization
- Scheduled job execution system
- Email notification system
- Grocery list consolidation

**Risk Level:** MEDIUM - New background job system with external API integrations

---

## Table of Contents

1. [Canary Deployment Plan](#1-canary-deployment-plan)
2. [Gradual Rollout Timeline](#2-gradual-rollout-timeline)
3. [Runbooks](#3-runbooks)
4. [Infrastructure Checklist](#4-infrastructure-checklist)
5. [Monitoring and Observability](#5-monitoring-and-observability)
6. [Rollback Procedures](#6-rollback-procedures)
7. [Risk Assessment](#7-risk-assessment)
8. [Communication Plan](#8-communication-plan)

---

## 1. Canary Deployment Plan

### 1.1 Objectives

Deploy Phase 3 features to a controlled subset of users (5%) to:
- Validate functionality in production environment
- Detect critical bugs before broad rollout
- Measure performance impact on live system
- Gather early user feedback

### 1.2 Canary User Selection

**Target Group:** 5% of user base (~50-100 users, adjust based on actual user count)

**Selection Criteria:**
1. **Beta Testers** - Users who opted into early access program
2. **Active Users** - Daily active users in past 30 days
3. **Diverse Profiles** - Mix of dietary preferences and macro targets
4. **Geographic Distribution** - Different time zones for schedule testing

**Implementation Method:**
```sql
-- Feature flag table (add to schema/032_feature_flags.sql)
CREATE TABLE IF NOT EXISTS feature_flags (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    flag_name TEXT NOT NULL UNIQUE,
    enabled_globally BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_feature_flags (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    flag_name TEXT NOT NULL REFERENCES feature_flags(flag_name) ON DELETE CASCADE,
    enabled BOOLEAN NOT NULL DEFAULT true,
    enrolled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, flag_name)
);

-- Enable canary cohort (run during deployment)
INSERT INTO feature_flags (flag_name, enabled_globally)
VALUES ('phase3_generation_engine', false);

-- Enroll beta testers (5% of users)
WITH beta_users AS (
    SELECT id FROM users
    WHERE email LIKE '%+beta%'  -- Beta opt-in convention
       OR id IN (SELECT user_id FROM beta_program_enrollment)
    LIMIT (SELECT CEIL(COUNT(*) * 0.05) FROM users)
)
INSERT INTO user_feature_flags (user_id, flag_name)
SELECT id, 'phase3_generation_engine' FROM beta_users;
```

**Code Integration:**
```gleam
// src/meal_planner/feature_flags.gleam
pub fn is_feature_enabled(
    db: Connection,
    user_id: UserId,
    flag_name: String
) -> Result(Bool, String) {
    let sql = "
        SELECT
            COALESCE(
                (SELECT enabled FROM user_feature_flags
                 WHERE user_id = $1 AND flag_name = $2),
                (SELECT enabled_globally FROM feature_flags
                 WHERE flag_name = $2),
                false
            ) as enabled
    "
    // Execute query and return result
}
```

### 1.3 Canary Metrics

**Success Criteria (must ALL pass to proceed):**
- ✅ Error rate <1% for generation jobs
- ✅ P99 latency <30 seconds for meal plan generation
- ✅ FatSecret API sync success rate >95%
- ✅ Email delivery success rate >98%
- ✅ Zero database deadlocks or connection pool exhaustion
- ✅ No user-reported critical bugs in 24 hours

**Monitoring Queries:**
```sql
-- Error rate for canary users
SELECT
    COUNT(*) FILTER (WHERE status = 'failed') * 100.0 / COUNT(*) as error_rate_pct,
    COUNT(*) as total_jobs
FROM job_executions
WHERE job_id IN (
    SELECT id FROM scheduled_jobs
    WHERE user_id IN (SELECT user_id FROM user_feature_flags WHERE flag_name = 'phase3_generation_engine')
)
AND started_at > NOW() - INTERVAL '24 hours';

-- P99 latency
SELECT
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms) as p99_latency_ms
FROM job_executions
WHERE started_at > NOW() - INTERVAL '24 hours'
  AND status = 'completed';

-- FatSecret sync success rate
SELECT
    COUNT(*) FILTER (WHERE status = 'completed') * 100.0 / COUNT(*) as success_rate_pct
FROM job_executions
WHERE job_id IN (SELECT id FROM scheduled_jobs WHERE job_type = 'AutoSync')
  AND started_at > NOW() - INTERVAL '24 hours';
```

### 1.4 Canary Duration and Decision Gates

**Duration:** 24 hours minimum

**Decision Gate Checkpoints:**
- **T+1 hour:** Smoke test - verify first scheduled jobs execute successfully
- **T+6 hours:** Early detection - check for crash loops, API failures
- **T+12 hours:** Mid-point review - analyze error patterns, latency trends
- **T+24 hours:** Go/No-Go decision for Phase 2 rollout

**Automated Rollback Triggers:**
- Error rate >5% sustained for 2+ minutes
- P99 latency >60 seconds sustained for 5+ minutes
- Database connection pool exhaustion (>90% utilization)
- FatSecret API rate limit exceeded (429 responses)

**Manual Escalation Triggers:**
- User-reported data corruption
- Incorrect macro calculations in generated plans
- Email spam complaints
- Security vulnerabilities discovered

---

## 2. Gradual Rollout Timeline

### 2.1 Rollout Schedule

**Phase 2: Gradual Expansion (3 days)**

| Day | Percentage | User Count | Checkpoint | Rollback Window |
|-----|------------|------------|------------|-----------------|
| Day 1 (Canary) | 5% | 50-100 | 24h observation | Instant |
| Day 2 | 25% | 250-500 | 12h checkpoint | 6 hours |
| Day 3 | 50% | 500-1000 | 12h checkpoint | 12 hours |
| Day 4 | 100% | All users | Final deployment | 24 hours |

**Rollout Execution:**
```sql
-- Day 2: 25% rollout
UPDATE feature_flags
SET enabled_globally = false
WHERE flag_name = 'phase3_generation_engine';

WITH rollout_users AS (
    SELECT id FROM users
    WHERE id NOT IN (SELECT user_id FROM user_feature_flags WHERE flag_name = 'phase3_generation_engine')
    ORDER BY RANDOM()
    LIMIT (SELECT CEIL(COUNT(*) * 0.20) FROM users)  -- Additional 20% (5% + 20% = 25%)
)
INSERT INTO user_feature_flags (user_id, flag_name)
SELECT id, 'phase3_generation_engine' FROM rollout_users
ON CONFLICT (user_id, flag_name) DO NOTHING;

-- Day 3: 50% rollout
-- Similar query, LIMIT to reach 50% total

-- Day 4: 100% rollout
UPDATE feature_flags
SET enabled_globally = true
WHERE flag_name = 'phase3_generation_engine';
```

### 2.2 Checkpoint Monitoring

**Day 2 Checkpoint (25% rollout):**
- Verify job queue processing rate scales linearly
- Check for database query performance degradation
- Monitor FatSecret API rate limit headroom
- Review user feedback from feedback forms

**Day 3 Checkpoint (50% rollout):**
- Validate load balancing across job workers
- Check for memory leaks in long-running processes
- Verify email delivery scales with user count
- Review database connection pool metrics

**Day 4 Final Deployment:**
- All metrics green across full user base
- No increase in error rate vs Day 3
- User engagement metrics positive (open rates, click-through)

### 2.3 Rollout Communication

**User Notification Timeline:**
```
T-48h: Email to beta users (canary cohort)
  Subject: "You're invited: Early access to AI Meal Planning"
  Content: Feature overview, opt-out instructions, feedback link

T+24h: In-app banner for 25% rollout cohort
  Message: "New: Weekly meal plans generated automatically! View your plan →"

T+72h: Email to all users (100% rollout)
  Subject: "Your personalized meal plans are ready"
  Content: Feature benefits, tutorial link, settings customization

T+1 week: Follow-up survey
  Questions: Satisfaction rating, feature requests, bug reports
```

---

## 3. Runbooks

### 3.1 Pre-Deployment Checklist

**Required approvals (check before proceeding):**
- [ ] Code review approved by 2+ engineers
- [ ] Security audit completed (see `doc/SECURITY_AUDIT.md`)
- [ ] Performance benchmarks passed (see `doc/PERFORMANCE_BENCHMARKS.md`)
- [ ] Integration tests passed (see `doc/TEST_COVERAGE.md`)
- [ ] Database migrations tested on staging
- [ ] Rollback plan reviewed and tested

**Infrastructure readiness:**
- [ ] Feature flag tables created (`schema/032_feature_flags.sql`)
- [ ] Scheduler tables created (`schema/031_scheduler_tables.sql`)
- [ ] Database indexes created and analyzed
- [ ] Connection pool sized for increased load (current: 20, recommend: 30)
- [ ] FatSecret API credentials validated
- [ ] Tandoor API health check passed
- [ ] Email SMTP server configured and tested

**Monitoring setup:**
- [ ] Dashboard created for canary metrics
- [ ] Alert rules configured (error rate, latency, API failures)
- [ ] Log aggregation configured (job execution logs)
- [ ] Incident response team on-call schedule confirmed

**Code quality:**
- [ ] All compilation warnings resolved
- [ ] `gleam format --check` passes
- [ ] No TODO/FIXME in production code paths
- [ ] Test coverage >80% for scheduler modules

**Dependency verification:**
- [ ] All `gleam.toml` dependencies pinned to specific versions
- [ ] No deprecated packages in use
- [ ] Security vulnerabilities scanned (`gleam deps audit`)

### 3.2 Deployment Procedure

**Deployment Steps (estimated 60 minutes):**

#### Step 1: Pre-Deployment Backup (15 minutes)
```bash
# Backup production database
pg_dump -h production-db.example.com -U meal_planner -F c -f meal_planner_backup_$(date +%Y%m%d_%H%M%S).dump meal_planner

# Verify backup integrity
pg_restore --list meal_planner_backup_*.dump | head -20

# Upload to secure storage
aws s3 cp meal_planner_backup_*.dump s3://meal-planner-backups/pre-phase3/
```

#### Step 2: Deploy Database Migrations (10 minutes)
```bash
# Run migrations on production
psql -h production-db.example.com -U meal_planner -d meal_planner <<EOF
\i schema/031_scheduler_tables.sql
\i schema/032_feature_flags.sql
EOF

# Verify migration success
psql -h production-db.example.com -U meal_planner -d meal_planner -c "
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name IN ('scheduled_jobs', 'job_executions', 'feature_flags', 'user_feature_flags');
"

# Expected output: 4 rows (all tables present)
```

#### Step 3: Deploy Application Code (15 minutes)
```bash
# Build production release
gleam build --target erlang

# Run pre-deployment tests
make test

# Deploy to production (adjust for your deployment method)
# Option A: Blue-Green deployment
./deploy.sh blue-green --target production --build build/erlang/meal_planner

# Option B: Rolling deployment
kubectl rollout restart deployment/meal-planner-api

# Option C: Docker container update
docker pull meal-planner:phase3
docker-compose up -d --no-deps --build meal-planner-api
```

#### Step 4: Smoke Tests (10 minutes)
```bash
# Health check endpoint
curl -f https://api.meal-planner.example.com/health || exit 1

# Database connectivity test
curl -f https://api.meal-planner.example.com/health/db || exit 1

# Create test scheduled job
curl -X POST https://api.meal-planner.example.com/api/scheduler/jobs \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "job_type": "WeeklyGeneration",
    "frequency": "weekly",
    "user_id": "test-user-001",
    "enabled": true
  }'

# Verify job created
psql -h production-db.example.com -U meal_planner -d meal_planner -c "
    SELECT id, job_type, status FROM scheduled_jobs WHERE user_id = 'test-user-001';
"
```

#### Step 5: Enable Canary Cohort (5 minutes)
```bash
# Enroll beta users (see Section 1.2 for SQL query)
psql -h production-db.example.com -U meal_planner -d meal_planner -f scripts/deploy/enable_canary_cohort.sql

# Verify enrollment count
psql -h production-db.example.com -U meal_planner -d meal_planner -c "
    SELECT COUNT(*) FROM user_feature_flags WHERE flag_name = 'phase3_generation_engine';
"

# Expected: 5% of total user count
```

#### Step 6: Monitor Initial Execution (10 minutes)
```bash
# Watch job execution logs (first 10 minutes)
tail -f /var/log/meal-planner/scheduler.log | grep "job_execution"

# Monitor metrics dashboard
open https://grafana.example.com/d/phase3-deployment

# Check for errors in first batch
psql -h production-db.example.com -U meal_planner -d meal_planner -c "
    SELECT job_id, status, error_message
    FROM job_executions
    WHERE started_at > NOW() - INTERVAL '10 minutes'
    ORDER BY started_at DESC;
"
```

### 3.3 Post-Deployment Verification

**Verification Checklist (complete within 1 hour of deployment):**

- [ ] Scheduled jobs are being created for canary users
- [ ] Jobs execute successfully (check `job_executions` table)
- [ ] Meal plans are generated with valid structure
- [ ] FatSecret sync completes without errors
- [ ] Emails are sent and delivered (check SMTP logs)
- [ ] No spike in error logs or exceptions
- [ ] Database connection pool utilization <70%
- [ ] API response times within normal range
- [ ] No user-reported critical bugs

**Validation Queries:**
```sql
-- Jobs created in last hour
SELECT job_type, status, COUNT(*) as count
FROM scheduled_jobs
WHERE created_at > NOW() - INTERVAL '1 hour'
GROUP BY job_type, status;

-- Recent executions success rate
SELECT
    status,
    COUNT(*) as count,
    AVG(duration_ms) as avg_duration_ms
FROM job_executions
WHERE started_at > NOW() - INTERVAL '1 hour'
GROUP BY status;

-- Error messages (if any)
SELECT DISTINCT error_message, COUNT(*) as occurrences
FROM job_executions
WHERE status = 'failed'
  AND started_at > NOW() - INTERVAL '1 hour'
GROUP BY error_message;
```

### 3.4 Rollback Procedure

**When to Rollback:**
- Any automated rollback trigger fires (see Section 1.4)
- Critical bug discovered affecting data integrity
- Security vulnerability exploited
- Unable to resolve production incident within 30 minutes
- Stakeholder decision (product owner or CTO approval)

**Rollback Steps (estimated 30 minutes):**

#### Step 1: Disable Feature Flag (IMMEDIATE)
```sql
-- Stop new jobs from being created
UPDATE feature_flags
SET enabled_globally = false
WHERE flag_name = 'phase3_generation_engine';

-- Disable for all users
DELETE FROM user_feature_flags
WHERE flag_name = 'phase3_generation_engine';
```

#### Step 2: Stop In-Flight Jobs (5 minutes)
```sql
-- Mark pending jobs as cancelled
UPDATE scheduled_jobs
SET status = 'cancelled',
    updated_at = NOW()
WHERE status = 'pending'
  AND job_type IN ('WeeklyGeneration', 'AutoSync');

-- Wait for running jobs to complete (max 5 minutes)
-- Monitor: SELECT COUNT(*) FROM scheduled_jobs WHERE status = 'running';
```

#### Step 3: Revert Application Code (10 minutes)
```bash
# Revert to previous version (adjust for your deployment method)
# Option A: Blue-Green - switch traffic back to previous version
./deploy.sh switch-to-previous

# Option B: Kubernetes - rollback deployment
kubectl rollout undo deployment/meal-planner-api

# Option C: Docker - revert to previous image tag
docker-compose down
docker tag meal-planner:phase2 meal-planner:latest
docker-compose up -d
```

#### Step 4: Revert Database Migrations (ONLY if data corruption detected)
```bash
# WARNING: Only run if absolutely necessary (data loss risk)

# Rollback scheduler tables
psql -h production-db.example.com -U meal_planner -d meal_planner <<EOF
DROP TABLE IF EXISTS job_executions CASCADE;
DROP TABLE IF EXISTS scheduled_jobs CASCADE;
DROP TABLE IF EXISTS user_feature_flags CASCADE;
DROP TABLE IF EXISTS feature_flags CASCADE;
EOF

# Restore from backup if needed
pg_restore -h production-db.example.com -U meal_planner -d meal_planner -c meal_planner_backup_*.dump
```

#### Step 5: Verify Rollback Success (10 minutes)
```bash
# Health checks
curl -f https://api.meal-planner.example.com/health
curl -f https://api.meal-planner.example.com/health/db

# Verify no new jobs created
psql -h production-db.example.com -U meal_planner -d meal_planner -c "
    SELECT COUNT(*) FROM scheduled_jobs WHERE created_at > NOW() - INTERVAL '5 minutes';
"
# Expected: 0

# Check application logs for errors
tail -100 /var/log/meal-planner/app.log | grep ERROR
```

#### Step 6: Incident Report and Root Cause Analysis
```
1. Create incident ticket with:
   - Rollback timestamp
   - Trigger event description
   - Impact assessment (users affected, data loss)
   - Rollback verification results

2. Schedule post-mortem meeting within 24 hours

3. Document root cause and corrective actions

4. Update deployment checklist with lessons learned
```

---

## 4. Infrastructure Checklist

### 4.1 Database Configuration

**Schema Migrations:**
- [ ] `031_scheduler_tables.sql` - Scheduled jobs and executions
- [ ] `032_feature_flags.sql` - Feature flag system (NEW)
- [ ] Verify all indexes created: `\di` in psql
- [ ] Analyze tables for query optimization: `ANALYZE scheduled_jobs;`

**Connection Pool Sizing:**
```erlang
% config/prod.exs (or equivalent for Gleam app)
config :meal_planner, MealPlanner.Repo,
  pool_size: 30,  % Increased from 20 for scheduler workload
  queue_target: 50,
  queue_interval: 1000,
  timeout: 30_000,
  pool_timeout: 10_000
```

**Performance Tuning:**
```sql
-- Increase shared_buffers for larger dataset
ALTER SYSTEM SET shared_buffers = '2GB';

-- Enable parallel query execution
ALTER SYSTEM SET max_parallel_workers_per_gather = 4;

-- Increase work_mem for complex queries
ALTER SYSTEM SET work_mem = '64MB';

-- Reload configuration
SELECT pg_reload_conf();
```

### 4.2 Application Configuration

**Environment Variables (production):**
```bash
# Database
DATABASE_URL=postgresql://meal_planner:PASSWORD@production-db.example.com:5432/meal_planner
DATABASE_POOL_SIZE=30

# Scheduler
SCHEDULER_ENABLED=true
SCHEDULER_MAX_CONCURRENT_JOBS=5
SCHEDULER_POLL_INTERVAL_SECONDS=60
SCHEDULER_JOB_TIMEOUT_SECONDS=300

# FatSecret API
FATSECRET_CLIENT_ID=production_client_id
FATSECRET_CLIENT_SECRET=production_secret
FATSECRET_BASE_URL=https://platform.fatsecret.com/rest/server.api

# Tandoor API
TANDOOR_BASE_URL=https://tandoor.example.com
TANDOOR_API_TOKEN=production_api_token

# Email (SMTP)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=production_sendgrid_key
EMAIL_FROM_ADDRESS=noreply@meal-planner.example.com

# Feature Flags
FEATURE_FLAG_DEFAULT_ENABLED=false
CANARY_ROLLOUT_PERCENTAGE=5

# Logging
LOG_LEVEL=info
LOG_FORMAT=json
SENTRY_DSN=https://production_sentry_dsn@sentry.io/project_id
```

**Application Startup:**
```bash
# Start scheduler worker process (separate from web server)
./bin/meal_planner start_scheduler &

# Start web API server
./bin/meal_planner start_web &

# Verify both processes running
ps aux | grep meal_planner
```

### 4.3 Monitoring and Alerting

**Metrics to Track (Grafana Dashboard):**

1. **Job Execution Metrics**
   - Job creation rate (jobs/minute)
   - Job completion rate (jobs/minute)
   - Job success rate (%)
   - Job duration (P50, P95, P99 latency)
   - Active job count (gauge)

2. **API Health Metrics**
   - FatSecret API call count (requests/minute)
   - FatSecret API error rate (%)
   - FatSecret API latency (P99)
   - Tandoor API call count
   - Tandoor API error rate
   - Tandoor API latency

3. **Database Metrics**
   - Connection pool utilization (%)
   - Active connections (gauge)
   - Query duration (P99)
   - Database CPU usage (%)
   - Database memory usage (%)

4. **Application Metrics**
   - HTTP request rate (requests/second)
   - HTTP error rate (5xx %)
   - HTTP latency (P99)
   - Memory usage (MB)
   - CPU usage (%)

**Alert Rules (PagerDuty/Opsgenie):**
```yaml
# alerts.yml
groups:
  - name: phase3_critical
    interval: 1m
    rules:
      - alert: JobExecutionErrorRateHigh
        expr: |
          sum(rate(job_executions_failed_total[5m])) /
          sum(rate(job_executions_total[5m])) > 0.05
        for: 2m
        severity: critical
        annotations:
          summary: "Job execution error rate >5% for 2 minutes"

      - alert: JobExecutionLatencyHigh
        expr: histogram_quantile(0.99, job_execution_duration_seconds) > 30
        for: 5m
        severity: warning
        annotations:
          summary: "P99 job execution latency >30 seconds"

      - alert: FatSecretAPIDown
        expr: sum(rate(fatsecret_api_errors_total[1m])) > 10
        for: 1m
        severity: critical
        annotations:
          summary: "FatSecret API returning errors"

      - alert: DatabaseConnectionPoolExhausted
        expr: db_connection_pool_utilization_percent > 90
        for: 2m
        severity: critical
        annotations:
          summary: "Database connection pool >90% utilized"
```

**Logging Configuration:**
```gleam
// src/meal_planner/scheduler/logger.gleam
pub fn log_job_execution(
    job_id: JobId,
    status: JobStatus,
    duration_ms: Int,
    error: Option(String)
) -> Nil {
    let log_entry = json.object([
        #("timestamp", json.string(timestamp())),
        #("job_id", json.string(job_id)),
        #("status", json.string(status_to_string(status))),
        #("duration_ms", json.int(duration_ms)),
        #("error", case error {
            Some(err) -> json.string(err)
            None -> json.null()
        })
    ])

    // Send to structured logging (Elasticsearch/CloudWatch)
    io.println(json.to_string(log_entry))
}
```

### 4.4 Security Configuration

**API Rate Limiting:**
```nginx
# nginx.conf (rate limiting for scheduler API endpoints)
http {
    limit_req_zone $binary_remote_addr zone=scheduler_api:10m rate=10r/s;

    server {
        location /api/scheduler {
            limit_req zone=scheduler_api burst=20 nodelay;
            proxy_pass http://meal_planner_backend;
        }
    }
}
```

**Secrets Management:**
```bash
# Use environment variables from secrets manager (AWS Secrets Manager, HashiCorp Vault)
# DO NOT hardcode secrets in config files

# Example: AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id meal-planner/production/fatsecret-api | \
    jq -r '.SecretString' | \
    jq -r '.client_id'
```

**Database Connection Encryption:**
```erlang
% Enforce SSL for production database connections
config :meal_planner, MealPlanner.Repo,
  ssl: true,
  ssl_opts: [
    verify: :verify_peer,
    cacertfile: "/etc/ssl/certs/ca-certificates.crt",
    server_name_indication: 'production-db.example.com'
  ]
```

### 4.5 Backup and Disaster Recovery

**Automated Backups:**
```bash
# cron job: daily backups at 2 AM UTC
0 2 * * * /usr/local/bin/backup-meal-planner-db.sh

# /usr/local/bin/backup-meal-planner-db.sh
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="meal_planner_backup_${TIMESTAMP}.dump"

# Backup database
pg_dump -h production-db.example.com -U meal_planner -F c -f "/tmp/${BACKUP_FILE}" meal_planner

# Upload to S3 with 30-day retention
aws s3 cp "/tmp/${BACKUP_FILE}" "s3://meal-planner-backups/daily/" --storage-class GLACIER

# Delete backups older than 30 days
aws s3 ls s3://meal-planner-backups/daily/ | \
    awk '{if ($1 < "'$(date -d '30 days ago' +%Y-%m-%d)'") print $4}' | \
    xargs -I {} aws s3 rm "s3://meal-planner-backups/daily/{}"

# Cleanup local backup
rm "/tmp/${BACKUP_FILE}"
```

**Recovery Time Objective (RTO): 30 minutes**
**Recovery Point Objective (RPO): 24 hours**

---

## 5. Monitoring and Observability

### 5.1 Metrics Collection

**Prometheus Metrics (exported by application):**
```gleam
// src/meal_planner/metrics.gleam
pub fn record_job_execution(
    job_type: String,
    status: String,
    duration_ms: Int
) -> Nil {
    // Increment job counter
    prometheus.counter_inc("job_executions_total", [
        #("job_type", job_type),
        #("status", status)
    ])

    // Record duration histogram
    prometheus.histogram_observe("job_execution_duration_seconds",
        int.to_float(duration_ms) /. 1000.0,
        [#("job_type", job_type)]
    )
}
```

**Custom Metrics:**
- `meal_plan_generation_duration_seconds` - Time to generate meal plan
- `fatsecret_api_call_duration_seconds` - FatSecret API latency
- `tandoor_api_call_duration_seconds` - Tandoor API latency
- `active_scheduled_jobs` - Gauge of currently scheduled jobs
- `failed_job_retry_count` - Count of job retries

### 5.2 Dashboard Configuration

**Grafana Dashboard Panels (see `grafana/phase3_dashboard.json`):**

1. **Overview Panel**
   - Total jobs executed (counter)
   - Current success rate (gauge)
   - Active jobs (gauge)

2. **Latency Panel**
   - P50, P95, P99 latency (line chart)
   - Latency breakdown by job type (stacked area)

3. **Error Rate Panel**
   - Error rate over time (line chart)
   - Error breakdown by type (pie chart)

4. **API Health Panel**
   - FatSecret API call count (bar chart)
   - Tandoor API call count (bar chart)
   - API error rates (line chart)

5. **Database Panel**
   - Connection pool utilization (gauge)
   - Query duration (heatmap)
   - Active connections (line chart)

### 5.3 Log Aggregation

**Structured Logging (JSON format):**
```json
{
  "timestamp": "2025-12-19T15:30:45Z",
  "level": "info",
  "service": "meal-planner-scheduler",
  "job_id": "job-12345",
  "job_type": "WeeklyGeneration",
  "user_id": "user-67890",
  "status": "completed",
  "duration_ms": 1234,
  "message": "Weekly meal plan generated successfully"
}
```

**Log Retention Policy:**
- **ERROR logs:** 90 days
- **WARN logs:** 30 days
- **INFO logs:** 7 days
- **DEBUG logs:** 1 day (disabled in production)

### 5.4 Tracing (Distributed Tracing)

**OpenTelemetry Integration:**
```gleam
// src/meal_planner/tracing.gleam
pub fn trace_job_execution(
    job_id: JobId,
    job_type: JobType,
    operation: fn() -> Result(a, b)
) -> Result(a, b) {
    let span = otel.start_span("job_execution", [
        #("job.id", job_id),
        #("job.type", job_type_to_string(job_type))
    ])

    let result = operation()

    case result {
        Ok(_) -> otel.set_span_status(span, "ok")
        Error(err) -> {
            otel.set_span_status(span, "error")
            otel.add_span_event(span, "error", [#("error", err)])
        }
    }

    otel.end_span(span)
    result
}
```

---

## 6. Rollback Procedures

### 6.1 Automatic Rollback Triggers

**System monitors the following metrics and automatically rolls back if thresholds exceeded:**

| Metric | Threshold | Duration | Action |
|--------|-----------|----------|--------|
| Job error rate | >5% | 2 minutes | Disable feature flag |
| P99 latency | >60 seconds | 5 minutes | Disable feature flag |
| Database connection pool | >90% | 2 minutes | Stop scheduler, alert ops |
| FatSecret API errors | >20 errors/min | 1 minute | Disable AutoSync jobs |
| Memory usage | >90% | 3 minutes | Restart service, alert ops |

**Automatic Rollback Script:**
```bash
#!/bin/bash
# /usr/local/bin/auto-rollback-phase3.sh

# Triggered by monitoring alert webhook

METRIC=$1
VALUE=$2

echo "Auto-rollback triggered: ${METRIC} = ${VALUE}"

# Disable feature flag immediately
psql -h production-db.example.com -U meal_planner -d meal_planner <<EOF
UPDATE feature_flags
SET enabled_globally = false
WHERE flag_name = 'phase3_generation_engine';
EOF

# Create incident ticket
curl -X POST https://api.pagerduty.com/incidents \
    -H "Authorization: Token $PAGERDUTY_TOKEN" \
    -d "{
        \"incident\": {
            \"type\": \"incident\",
            \"title\": \"Auto-rollback triggered: ${METRIC}\",
            \"service\": {\"id\": \"PXXXXXX\", \"type\": \"service_reference\"},
            \"urgency\": \"high\",
            \"body\": {
                \"type\": \"incident_body\",
                \"details\": \"Metric ${METRIC} exceeded threshold with value ${VALUE}\"
            }
        }
    }"

# Alert on-call engineer
echo "Rollback complete. Incident created."
```

### 6.2 Manual Rollback Decision Tree

```
[Critical Bug Detected]
    ├─> Data corruption?
    │   ├─> YES: IMMEDIATE ROLLBACK + Database restore
    │   └─> NO: Continue assessment
    │
    ├─> Security vulnerability?
    │   ├─> YES: IMMEDIATE ROLLBACK + Security patch
    │   └─> NO: Continue assessment
    │
    ├─> Can fix be deployed within 30 minutes?
    │   ├─> YES: Deploy hotfix, monitor for 1 hour
    │   └─> NO: ROLLBACK
    │
    └─> Impact >10% of users?
        ├─> YES: ROLLBACK
        └─> NO: Disable for affected users, investigate
```

### 6.3 Post-Rollback Actions

**Immediate Actions (T+0 to T+2 hours):**
1. Confirm rollback successful (run verification queries)
2. Create incident post-mortem document (template below)
3. Notify stakeholders (email to product, engineering, support)
4. Analyze logs and metrics to identify root cause
5. Create bug tickets for issues discovered

**Short-term Actions (T+2 hours to T+24 hours):**
1. Schedule post-mortem meeting (within 24 hours)
2. Develop fix and test in staging environment
3. Update deployment checklist with new safeguards
4. Plan re-deployment timeline (minimum 48 hours after rollback)

**Post-Mortem Template:**
```markdown
# Incident Post-Mortem: Phase 3 Rollback

**Date:** YYYY-MM-DD
**Incident Duration:** X hours
**Impact:** X users affected

## Timeline
- T+0: Deployment started
- T+X: Issue detected (describe symptom)
- T+X: Rollback initiated
- T+X: Rollback completed

## Root Cause
[Detailed analysis of what went wrong]

## Impact Assessment
- Users affected: X (X%)
- Data loss: YES/NO (describe if yes)
- Downtime: X minutes

## Corrective Actions
1. [Action item 1] - Owner: [Name] - Due: [Date]
2. [Action item 2] - Owner: [Name] - Due: [Date]

## Lessons Learned
- [Lesson 1]
- [Lesson 2]

## Action Items for Next Deployment
- [ ] [Checklist item 1]
- [ ] [Checklist item 2]
```

---

## 7. Risk Assessment

### 7.1 Risk Matrix

| Risk | Severity | Likelihood | Impact | Mitigation | Owner |
|------|----------|------------|--------|------------|-------|
| **Scheduler jobs overwhelm database** | HIGH | MEDIUM | Service degradation | Connection pool limits, job concurrency limits | DevOps |
| **FatSecret API rate limits exceeded** | MEDIUM | HIGH | Sync failures | Backoff retry logic, API call throttling | Backend |
| **Email spam complaints** | MEDIUM | LOW | IP blacklisting | Opt-out mechanism, send rate limits | Backend |
| **Meal plan algorithm produces unbalanced macros** | LOW | MEDIUM | User dissatisfaction | Validation tests, manual QA review | Product |
| **Database migration failure** | HIGH | LOW | Deployment blocked | Test migrations on staging, backup before deploy | DevOps |
| **Concurrent job execution causes race conditions** | MEDIUM | MEDIUM | Duplicate work | Database locks (FOR UPDATE SKIP LOCKED) | Backend |
| **Memory leak in long-running scheduler process** | MEDIUM | LOW | Service crash | Memory monitoring, automatic restarts | DevOps |
| **Incorrect macro calculations** | MEDIUM | MEDIUM | User safety risk | Extensive unit tests, QA validation | QA/Backend |

### 7.2 Risk Mitigation Strategies

**Technical Mitigations:**
- **Database Overload:**
  - Implement job queue with max concurrency (5 concurrent jobs)
  - Use database connection pooling with limits
  - Monitor query performance and add indexes as needed

- **API Rate Limits:**
  - Implement exponential backoff for failed API calls
  - Cache FatSecret profile data (30-minute TTL)
  - Throttle API calls to stay within rate limits

- **Data Integrity:**
  - Extensive unit tests for macro calculations
  - Integration tests with real API responses
  - Manual QA review of generated meal plans

**Process Mitigations:**
- Canary deployment to detect issues early
- Automated rollback on critical metrics
- On-call engineer during deployment window
- Post-mortem process for learning from incidents

---

## 8. Communication Plan

### 8.1 Internal Communication

**Stakeholder Notification Timeline:**

**T-1 week:** Deployment announcement
- **Audience:** Engineering, Product, Support, QA
- **Channel:** Email + Slack announcement
- **Content:** Deployment date, features overview, testing status

**T-48 hours:** Pre-deployment briefing
- **Audience:** On-call engineers, support team
- **Channel:** Zoom meeting
- **Content:** Runbook review, rollback procedures, escalation paths

**T-0 (Deployment Day):** Real-time updates
- **Audience:** Engineering leadership, on-call team
- **Channel:** Slack #deployments channel
- **Frequency:** Every 30 minutes during deployment window

**T+24 hours:** Canary results summary
- **Audience:** Product, Engineering, Support
- **Channel:** Email summary
- **Content:** Metrics review, decision to proceed with Phase 2

**T+1 week:** Post-deployment retrospective
- **Audience:** Full engineering team
- **Channel:** All-hands meeting
- **Content:** Lessons learned, metrics review, next steps

### 8.2 User Communication

**Beta User Email (T-48 hours):**
```
Subject: You're invited: Early access to AI Meal Planning

Hi [First Name],

As a valued beta tester, you're getting early access to our new AI-powered meal planning feature!

**What's New:**
✨ Weekly meal plans generated automatically every Friday
✨ Personalized to your macros and dietary preferences
✨ Grocery lists and prep instructions included
✨ Seamless sync with FatSecret

**How It Works:**
1. Your first meal plan will be generated this Friday
2. Check your email for a notification
3. Review your plan in the app (Settings > Meal Plans)

**We Need Your Feedback:**
This is a beta feature - your feedback helps us improve! Report bugs or suggestions:
[Feedback Form Link]

**Opt-Out:**
Not ready for automated planning? You can disable this in Settings > Preferences.

Thanks for being an early adopter!

The Meal Planner Team
```

**Full Rollout Email (T+72 hours):**
```
Subject: Your personalized meal plans are ready 🍽️

Hi [First Name],

Great news! Your weekly meal plans are now generated automatically.

**What You'll Get:**
• 7-day meal plan every Friday
• Balanced to your macro targets
• Shopping list for the week
• Step-by-step prep instructions

**First Steps:**
1. Check your inbox on Friday for your first plan
2. Customize your preferences (Settings > Meal Plans)
3. Sync with FatSecret to track your meals

**Need Help?**
• [Tutorial Video]
• [FAQ]
• [Contact Support]

Happy meal planning!

The Meal Planner Team
```

### 8.3 Escalation Paths

**Incident Severity Levels:**

**SEV-1 (Critical):**
- **Definition:** Service down, data loss, security breach
- **Response Time:** Immediate (<5 minutes)
- **Escalation:** Page on-call engineer + CTO
- **Communication:** Slack #incidents + email to leadership

**SEV-2 (High):**
- **Definition:** Degraded performance, affecting >25% users
- **Response Time:** <15 minutes
- **Escalation:** On-call engineer + engineering manager
- **Communication:** Slack #incidents

**SEV-3 (Medium):**
- **Definition:** Non-critical bug, affecting <10% users
- **Response Time:** <1 hour
- **Escalation:** On-call engineer
- **Communication:** Bug ticket + Slack notification

**SEV-4 (Low):**
- **Definition:** Minor issue, no user impact
- **Response Time:** Next business day
- **Escalation:** Bug ticket assigned to team
- **Communication:** Ticket only

**On-Call Rotation:**
- **Primary:** On-call engineer (24/7 availability)
- **Secondary:** Engineering manager (backup escalation)
- **Tertiary:** CTO (critical escalation only)

**Contact Directory:**
```
Primary On-Call: [Name] - [Phone] - [Email]
Secondary On-Call: [Name] - [Phone] - [Email]
Engineering Manager: [Name] - [Phone] - [Email]
CTO: [Name] - [Phone] - [Email]
Product Owner: [Name] - [Phone] - [Email]

PagerDuty: https://meal-planner.pagerduty.com
Slack Incidents: #incidents
Grafana Dashboard: https://grafana.example.com/d/phase3
Sentry Errors: https://sentry.io/meal-planner
```

---

## Appendix A: Migration Scripts

### A.1 Feature Flag Migration

**File:** `schema/032_feature_flags.sql`

```sql
-- Feature flag system for gradual rollouts
-- Run this BEFORE deploying application code

CREATE TABLE IF NOT EXISTS feature_flags (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    flag_name TEXT NOT NULL UNIQUE,
    enabled_globally BOOLEAN NOT NULL DEFAULT false,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_feature_flags (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    flag_name TEXT NOT NULL REFERENCES feature_flags(flag_name) ON DELETE CASCADE,
    enabled BOOLEAN NOT NULL DEFAULT true,
    enrolled_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, flag_name)
);

-- Indexes for fast lookups
CREATE INDEX idx_user_feature_flags_user_id ON user_feature_flags(user_id);
CREATE INDEX idx_user_feature_flags_flag_name ON user_feature_flags(flag_name);

-- Insert Phase 3 feature flag (disabled by default)
INSERT INTO feature_flags (flag_name, enabled_globally, description)
VALUES (
    'phase3_generation_engine',
    false,
    'Weekly meal plan generation and automation loop'
) ON CONFLICT (flag_name) DO NOTHING;

-- Audit log
COMMENT ON TABLE feature_flags IS 'Feature flags for gradual rollouts and A/B testing';
COMMENT ON TABLE user_feature_flags IS 'Per-user feature flag enrollments';
```

### A.2 Canary Enrollment Script

**File:** `scripts/deploy/enable_canary_cohort.sql`

```sql
-- Enroll 5% of users in canary cohort (beta testers)
-- Run this AFTER deploying application code and feature flag migration

BEGIN;

-- Calculate 5% of user base
WITH cohort_size AS (
    SELECT CEIL(COUNT(*) * 0.05)::INTEGER as target_count
    FROM users
    WHERE deleted_at IS NULL  -- Exclude soft-deleted users
),
beta_users AS (
    -- Priority 1: Users who explicitly opted into beta program
    SELECT id FROM users
    WHERE email LIKE '%+beta%'
       OR id IN (SELECT user_id FROM beta_program_enrollment)
       OR tags @> ARRAY['beta_tester']
    UNION
    -- Priority 2: Active users (daily login in past 30 days)
    SELECT user_id as id FROM user_activity
    WHERE last_login > NOW() - INTERVAL '30 days'
    ORDER BY last_login DESC
    LIMIT (SELECT target_count FROM cohort_size)
),
canary_enrollment AS (
    INSERT INTO user_feature_flags (user_id, flag_name, enabled)
    SELECT id, 'phase3_generation_engine', true
    FROM beta_users
    ON CONFLICT (user_id, flag_name) DO UPDATE
    SET enabled = true, enrolled_at = NOW()
    RETURNING user_id
)
SELECT
    COUNT(*) as enrolled_count,
    (SELECT target_count FROM cohort_size) as target_count,
    ROUND(COUNT(*)::NUMERIC / (SELECT target_count FROM cohort_size)::NUMERIC * 100, 2) as pct_of_target
FROM canary_enrollment;

COMMIT;
```

---

## Appendix B: Monitoring Queries

**Real-time Canary Health Check:**
```sql
-- Run every 5 minutes during canary phase
SELECT
    'Job Execution Health' as metric,
    COUNT(*) as total_executions,
    COUNT(*) FILTER (WHERE status = 'completed') as successful,
    COUNT(*) FILTER (WHERE status = 'failed') as failed,
    ROUND(COUNT(*) FILTER (WHERE status = 'failed')::NUMERIC / NULLIF(COUNT(*), 0)::NUMERIC * 100, 2) as error_rate_pct,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms) as p99_latency_ms
FROM job_executions
WHERE started_at > NOW() - INTERVAL '5 minutes';
```

**Canary User Engagement:**
```sql
-- Track user engagement with generated meal plans
SELECT
    COUNT(DISTINCT ue.user_id) as total_canary_users,
    COUNT(DISTINCT CASE WHEN mp.viewed_at IS NOT NULL THEN ue.user_id END) as users_viewed_plan,
    COUNT(DISTINCT CASE WHEN mp.edited_at IS NOT NULL THEN ue.user_id END) as users_edited_plan,
    ROUND(
        COUNT(DISTINCT CASE WHEN mp.viewed_at IS NOT NULL THEN ue.user_id END)::NUMERIC /
        NULLIF(COUNT(DISTINCT ue.user_id), 0)::NUMERIC * 100,
        2
    ) as view_rate_pct
FROM user_feature_flags ue
LEFT JOIN meal_plans mp ON mp.user_id = ue.user_id AND mp.created_at > NOW() - INTERVAL '24 hours'
WHERE ue.flag_name = 'phase3_generation_engine'
  AND ue.enabled = true;
```

---

## Appendix C: Rollback Verification Checklist

**Post-Rollback Verification (complete all steps):**

- [ ] Feature flag disabled in database (`SELECT * FROM feature_flags WHERE flag_name = 'phase3_generation_engine'`)
- [ ] No new scheduled jobs created in past 5 minutes
- [ ] All in-flight jobs completed or cancelled
- [ ] Application logs show no errors related to scheduler
- [ ] Web API health check passes (`curl /health`)
- [ ] Database health check passes (`curl /health/db`)
- [ ] No spike in error rate for existing features
- [ ] User-facing features unaffected (test login, food search, recipe creation)
- [ ] Incident ticket created with rollback details
- [ ] Post-mortem meeting scheduled

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-19 | Claude Code | Initial deployment strategy created |

---

## Approval Signatures

**Engineering Lead:** __________________ Date: __________
**Product Owner:** __________________ Date: __________
**DevOps Lead:** __________________ Date: __________
**CTO/VP Engineering:** __________________ Date: __________

---

**END OF DOCUMENT**
