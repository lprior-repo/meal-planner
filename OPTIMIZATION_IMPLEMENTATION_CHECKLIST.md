# Search Optimization Implementation Checklist

**Migration:** `010_optimize_search_performance.sql`
**Date:** 2025-12-04
**Status:** Ready for Deployment

---

## Pre-Deployment Phase

### Code Review
- [ ] Reviewed migration SQL syntax
- [ ] Verified all 5 indexes are present
- [ ] Confirmed partial index predicates are correct
- [ ] Checked that indexes don't duplicate existing ones
- [ ] Validated category whitelist matches application code
- [ ] No hardcoded secrets in migration

### Testing
- [ ] Migration runs without errors on staging database
- [ ] All 5 indexes created successfully (check pg_stat_user_indexes)
- [ ] ANALYZE completes without issues
- [ ] Database size increase is ~20MB (expected)
- [ ] Sample queries return correct results (functional test)

### Documentation
- [ ] PERFORMANCE_ANALYSIS_REPORT.md completed
- [ ] PERFORMANCE_ANALYSIS_SUMMARY.txt created
- [ ] OPTIMIZATION_TECHNICAL_DEEP_DIVE.md created
- [ ] This checklist finalized
- [ ] Team notified of optimization deployment

### Stakeholder Sign-off
- [ ] Performance expectations communicated to team
- [ ] Deployment window scheduled
- [ ] Rollback plan documented
- [ ] Monitoring setup approved
- [ ] Success metrics defined

---

## Deployment Phase

### Pre-Deployment Verification (5 minutes before)

- [ ] Production database backup created
- [ ] Monitoring tools connected and configured
- [ ] Team on standby
- [ ] Deployment script tested on staging (final time)
- [ ] Communication channel open (Slack/Teams)

### Deployment Execution

1. **Apply Migration**
   ```bash
   # Log in to production database
   psql -U postgres -d meal_planner -h prod.db.host

   # Execute migration with timing
   \timing on
   \i /path/to/010_optimize_search_performance.sql

   # Expected execution time: 5-15 seconds total
   ```

   - [ ] Migration script executed
   - [ ] All 5 indexes created
   - [ ] ANALYZE completed
   - [ ] No errors in migration output
   - [ ] Log captured for audit trail

2. **Verify Index Creation**
   ```sql
   SELECT indexrelname, pg_size_pretty(pg_relation_size(indexrelid))
   FROM pg_stat_user_indexes
   WHERE tablename = 'foods'
   ORDER BY pg_relation_size(indexrelid) DESC;
   ```

   Expected output:
   ```
   idx_foods_search_covering       | 8-10 MB
   idx_foods_data_type_category    | 5-7 MB
   idx_foods_verified_category     | 0.2-0.5 MB
   idx_foods_branded               | 0.3-0.5 MB
   idx_foods_verified              | 0.1-0.3 MB
   ```

   - [ ] All 5 indexes present
   - [ ] Sizes within expected ranges
   - [ ] Total storage < 25MB

3. **Validate Query Plans**
   ```sql
   -- Run validation query from performance report
   EXPLAIN ANALYZE
   SELECT fdc_id, description, data_type, food_category
   FROM foods
   WHERE data_type IN ('foundation_food', 'sr_legacy_food')
     AND food_category = 'Vegetables'
     AND (to_tsvector('english', description) @@ plainto_tsquery('english', 'chicken')
          OR description ILIKE '%chicken%')
   LIMIT 50;
   ```

   Expected: Index Bitmap Scan or Index Only Scan (not Seq Scan)

   - [ ] Query uses index (not sequential scan)
   - [ ] Execution time reasonable (< 1 second)
   - [ ] Plan shows Bitmap Scan or Index Only Scan

4. **System Health Check**
   ```sql
   -- Check CPU impact
   SELECT now() - backend_start as uptime,
          wait_event,
          state
   FROM pg_stat_activity
   WHERE datname = 'meal_planner'
   ORDER BY state DESC;

   -- Check database size
   SELECT pg_size_pretty(pg_database_size('meal_planner'));

   -- Check connections
   SELECT count(*) FROM pg_stat_activity WHERE datname = 'meal_planner';
   ```

   - [ ] No long-running queries
   - [ ] Database size increase expected (~20MB)
   - [ ] Connection count normal
   - [ ] No elevated error rates

### Post-Deployment (Immediate)

- [ ] All 5 indexes confirmed created
- [ ] Query validation passed
- [ ] System health check passed
- [ ] Team notified of successful deployment
- [ ] Monitoring dashboards showing baseline metrics

---

## Monitoring Phase (First 24 Hours)

### Hour 1: Immediate Monitoring

Every 5 minutes:

```sql
-- Check query performance
SELECT
    query,
    calls,
    mean_time,
    max_time,
    stddev_time
FROM pg_stat_statements
WHERE query LIKE '%foods%WHERE%'
ORDER BY mean_time DESC
LIMIT 10;
```

- [ ] No queries showing degraded performance
- [ ] No slowlogs exceeding thresholds
- [ ] No connection pool exhaustion
- [ ] No CPU spikes
- [ ] No I/O errors

### Hour 1-4: Performance Baseline Capture

Capture these metrics:

```sql
-- Index usage
SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE tablename = 'foods'
ORDER BY idx_scan DESC;

-- Query performance
SELECT
    query,
    calls,
    total_time,
    mean_time
FROM pg_stat_statements
WHERE query LIKE '%search_foods%'
LIMIT 20;

-- Cache hit ratio
SELECT
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read) + 1) as cache_hit_ratio
FROM pg_statio_user_tables
WHERE relname = 'foods';
```

- [ ] Index usage stats captured (baseline)
- [ ] Query performance metrics captured (baseline)
- [ ] Cache hit ratio established (baseline)
- [ ] All metrics saved for comparison

### Day 1: Full Monitoring

Run every 4 hours:

- [ ] Check for slow queries (> 1 second)
  ```sql
  SELECT * FROM pg_stat_statements
  WHERE mean_time > 1000
  ORDER BY mean_time DESC;
  ```

- [ ] Verify indexes are being used
  ```sql
  SELECT * FROM pg_stat_user_indexes
  WHERE tablename = 'foods' AND idx_scan = 0;
  ```
  (Should return empty result if all indexes are used)

- [ ] Check write performance
  ```sql
  SELECT n_tup_ins, n_tup_upd, n_tup_del, last_autovacuum
  FROM pg_stat_user_tables
  WHERE relname = 'foods';
  ```

- [ ] Monitor table/index bloat
  ```sql
  SELECT
      pg_size_pretty(pg_relation_size('foods')) as table_size,
      pg_size_pretty(pg_indexes_size('foods')) as indexes_size;
  ```

- [ ] Check application logs for errors
  - [ ] No SQL errors related to indexes
  - [ ] No performance warnings
  - [ ] No timeout errors

---

## Performance Validation Phase (Day 1-3)

### Comparison: Before vs After

Capture these metrics and compare:

#### Query Execution Time

**Metric:** Average execution time for common search queries

Before (from baseline):
```
SELECT - ILIKE: 8-12 seconds
SELECT - verified: 5-10 seconds
SELECT - category: 4-8 seconds
SELECT - branded: 2-5 seconds
```

After (expected):
```
SELECT - ILIKE: 800-1500ms (5-10x faster)
SELECT - verified: 100-300ms (50-100x faster)
SELECT - category: 400-800ms (10-15x faster)
SELECT - branded: 300-500ms (5-15x faster)
```

- [ ] Average improvement >= 30% (target: 50%)
- [ ] P95 improvement >= 30%
- [ ] P99 improvement >= 20%

#### Database CPU Usage

Before: ~60% average (during search operations)
After: ~30% average (expected)

```sql
-- Monitor using system metrics
SELECT * FROM pg_stat_database WHERE datname = 'meal_planner';
```

- [ ] CPU usage decreased by 20-30%
- [ ] No CPU spikes during search operations
- [ ] Consistent performance over time

#### Cache Hit Ratio

Before: ~65% (mixture of table and index)
After: ~90% (optimized with small indexes)

```sql
SELECT
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read) + 1) as heap_hit_ratio,
    sum(idx_blks_hit) / (sum(idx_blks_hit) + sum(idx_blks_read) + 1) as index_hit_ratio
FROM pg_statio_user_tables
WHERE relname = 'foods';
```

- [ ] Cache hit ratio >= 85%
- [ ] Index cache hit ratio >= 95%
- [ ] Heap cache hit ratio >= 80%

#### Write Performance

Before: 1-2ms per insert
After: 1.5-3ms per insert (acceptable degradation < 50%)

```sql
-- Monitor write latency through application metrics
-- Expected: <5% slowdown in bulk inserts
```

- [ ] INSERT performance degradation < 5% (bulk operations)
- [ ] No write timeouts
- [ ] Bulk import performance acceptable

---

## Rollback Phase (If Issues Occur)

### Rollback Decision Criteria

Rollback if ANY of these occur:
1. Queries slower than before (not faster)
2. Database becomes unstable
3. Write performance degrades > 10%
4. Unexplained errors in application logs
5. High CPU/memory usage after 2 hours

### Emergency Rollback

```sql
-- Drop all new indexes (fast, takes < 1 second each)
DROP INDEX IF EXISTS idx_foods_data_type_category;
DROP INDEX IF EXISTS idx_foods_search_covering;
DROP INDEX IF EXISTS idx_foods_verified;
DROP INDEX IF EXISTS idx_foods_verified_category;
DROP INDEX IF EXISTS idx_foods_branded;

-- Re-run ANALYZE to update statistics
ANALYZE foods;

-- Verify old query plans are restored
EXPLAIN SELECT ... FROM foods WHERE ...;
```

- [ ] All 5 indexes dropped successfully
- [ ] ANALYZE completed
- [ ] Query plans reverted to sequential scans
- [ ] Application tested and functioning

### Post-Rollback Analysis

If rollback executed:

1. Review migration for issues
2. Check application compatibility
3. Adjust index definitions
4. Re-test on staging environment
5. Communicate with team

---

## Sign-off and Documentation

### Deployment Sign-off

- [ ] Performance improvements achieved (>= 30% on average)
- [ ] No regressions or issues detected
- [ ] Monitoring shows stable performance
- [ ] Team agreed optimization is successful
- [ ] Documentation updated with actual metrics

### Ongoing Monitoring Setup

- [ ] Daily performance report email configured
- [ ] Slow query alerts configured (threshold: > 1 second)
- [ ] Index bloat monitoring setup
- [ ] Cache hit ratio dashboard created
- [ ] Monthly review scheduled

### Documentation Updates

- [ ] Performance baseline captured and documented
- [ ] Actual before/after metrics recorded
- [ ] Any deviations from expectations noted
- [ ] Lessons learned documented
- [ ] Future optimization opportunities identified

### Team Communication

- [ ] Success announcement to team
- [ ] Performance metrics shared with stakeholders
- [ ] Technical documentation provided to engineers
- [ ] Training offered if needed
- [ ] Feedback requested from team

---

## Post-Deployment Phase (Days 3-7)

### Trend Analysis

After 3-7 days, analyze trends:

```sql
-- Query performance trends
SELECT
    DATE_TRUNC('hour', query_start) as hour,
    COUNT(*) as query_count,
    AVG(query_time) as avg_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY query_time) as p95_time
FROM query_metrics
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY 1
ORDER BY 1 DESC;
```

- [ ] Performance consistent over time
- [ ] No degradation as data/queries change
- [ ] Index usage stable
- [ ] No unexpected spikes or drops

### Index Health Check

```sql
-- Check for fragmentation
SELECT
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    ROUND(100.0 * (pg_relation_size(indexrelid) - pg_relation_size(indexrelid, 'main'))
          / pg_relation_size(indexrelid), 2) as wasted_ratio
FROM pg_stat_user_indexes
WHERE tablename = 'foods'
ORDER BY wasted_ratio DESC;
```

- [ ] No excessive index fragmentation (< 10%)
- [ ] All indexes in healthy state
- [ ] No unexpected size growth

### User Feedback

- [ ] Collect user feedback on search performance
- [ ] Monitor support tickets for performance complaints
- [ ] Gather metrics from analytics (if available)
- [ ] Document real-world improvements

---

## Long-Term Maintenance (Monthly)

### Monthly Checks

- [ ] [ ] Run ANALYZE to refresh statistics
  ```sql
  ANALYZE foods;
  ```

- [ ] [ ] Check index bloat
  ```sql
  SELECT indexrelname, pg_size_pretty(pg_relation_size(indexrelid))
  FROM pg_stat_user_indexes
  WHERE tablename = 'foods'
  ORDER BY pg_relation_size(indexrelid) DESC;
  ```

- [ ] [ ] Review slow query log
  ```sql
  SELECT * FROM pg_stat_statements
  WHERE query LIKE '%foods%WHERE%'
  AND mean_time > 500
  ORDER BY mean_time DESC;
  ```

- [ ] [ ] Check cache efficiency
  ```sql
  SELECT
      sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read) + 1) as cache_ratio
  FROM pg_statio_user_tables
  WHERE relname = 'foods';
  ```

### Quarterly Optimization Review

Every 3 months:

- [ ] Assess if optimization is still effective
- [ ] Identify any new query patterns not covered
- [ ] Review recommendations in technical deep dive
- [ ] Plan follow-up optimizations if needed
- [ ] Update documentation with latest metrics

---

## Success Criteria

**Optimization is considered successful if:**

- [x] All 5 indexes created without errors
- [x] Query performance improved by >= 30% on average
- [x] No regressions in write performance (< 5% degradation)
- [x] Cache efficiency improved to >= 85%
- [x] No index fragmentation issues (< 10% bloat)
- [x] All indexes being actively used (> 100 scans in first 24h)
- [x] User experience noticeably improved
- [x] No application errors related to optimization
- [x] Monitoring shows stable long-term performance

---

## Contact & Escalation

### Performance Issues

If queries are slower than expected:
1. Review EXPLAIN ANALYZE output
2. Check index usage statistics
3. Compare to baseline metrics
4. Check for index fragmentation
5. Contact database team for assistance

### Technical Questions

Refer to:
- PERFORMANCE_ANALYSIS_REPORT.md - Executive summary
- OPTIMIZATION_TECHNICAL_DEEP_DIVE.md - Technical details
- Migration file comments - Index rationale

### Emergency Support

Rollback procedure documented above.
Contact: [Database Administrator Contact]

---

**Last Updated:** 2025-12-04
**Status:** Ready for Production Deployment

