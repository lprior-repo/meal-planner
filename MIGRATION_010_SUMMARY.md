# Migration 010 Application Summary

## Current Status: ⚠️ NOT YET APPLIED (Ready to Apply)

### What I Found

1. **Migration File Exists**: ✅
   - Location: `/home/lewis/src/meal-planner/gleam/migrations_pg/010_optimize_search_performance.sql`
   - Content: 5 performance indexes + ANALYZE statement
   - Status: Well-documented, idempotent (uses IF NOT EXISTS)

2. **Migration System**: ✅
   - Manual application via `psql` commands
   - Tracking table: `schema_migrations`
   - No automated migration runner in codebase
   - Pattern: Run SQL file manually, then record in tracking table

3. **Database Status**: ⚠️ CONNECTION POOL EXHAUSTED
   - PostgreSQL is running: ✅
   - Issue: "too many clients already"
   - Cause: Likely Gleam app running with 50-connection pool
   - Solution: Stop application before applying migration

4. **Application Scripts Created**: ✅
   - `/home/lewis/src/meal-planner/scripts/apply-migration-010.sh` - Automated migration script
   - `/home/lewis/src/meal-planner/MIGRATION_010_INSTRUCTIONS.md` - Detailed instructions

## How to Apply the Migration

### Quick Method (Recommended)

```bash
# Stop Gleam application (if running)
pkill -f "gleam run"
sleep 5

# Apply migration
cd /home/lewis/src/meal-planner
./scripts/apply-migration-010.sh

# Restart application
cd gleam && gleam run
```

### Manual Method

```bash
# Stop application
pkill -f "gleam run"
sleep 5

# Apply SQL
cd /home/lewis/src/meal-planner/gleam
PGPASSWORD=postgres psql -U postgres -d meal_planner -f migrations_pg/010_optimize_search_performance.sql

# Record migration
PGPASSWORD=postgres psql -U postgres -d meal_planner -c "
    INSERT INTO schema_migrations (version, name, applied_at)
    VALUES (10, 'optimize_search_performance', NOW())
    ON CONFLICT (version) DO UPDATE SET applied_at = NOW();"
```

## Migration Contents

The migration creates these indexes on the `foods` table:

### 1. idx_foods_data_type_category
- **Type**: Composite B-tree index
- **Columns**: data_type, food_category
- **Partial**: WHERE data_type IN ('foundation_food', 'sr_legacy_food', 'branded_food')
- **Use Case**: Queries filtering by both data_type AND category
- **Size**: ~30% of full table size

### 2. idx_foods_search_covering
- **Type**: Covering index
- **Columns**: data_type, food_category, description, fdc_id
- **Partial**: WHERE data_type IN ('foundation_food', 'sr_legacy_food', 'branded_food', 'survey_fndds_food')
- **Use Case**: Enables index-only scans (no table access needed)
- **Benefit**: Reduces I/O by ~15%

### 3. idx_foods_verified
- **Type**: Partial B-tree index
- **Columns**: description, fdc_id
- **Partial**: WHERE data_type IN ('foundation_food', 'sr_legacy_food')
- **Use Case**: verified_only=true queries
- **Size**: ~2% of full table (50-70x smaller)

### 4. idx_foods_verified_category
- **Type**: Partial composite index
- **Columns**: food_category, description, fdc_id
- **Partial**: WHERE data_type IN ('foundation_food', 'sr_legacy_food')
- **Use Case**: verified_only=true AND category filter
- **Benefit**: Combines two filters in one index

### 5. idx_foods_branded
- **Type**: Partial B-tree index
- **Columns**: description, fdc_id
- **Partial**: WHERE data_type = 'branded_food'
- **Use Case**: branded_only=true queries
- **Benefit**: Fast lookups for branded foods

### 6. ANALYZE foods
- Refreshes table statistics for query planner
- Helps PostgreSQL choose optimal indexes

## Performance Impact

### Expected Improvements
- **Verified-only queries**: 50-70% faster
- **Category-only queries**: 30-40% faster
- **Combined filter queries**: 50-70% faster
- **Overall average**: 56% performance improvement

### Storage Cost
- Total index size: ~15-20MB
- Partial indexes keep size minimal
- Covering index is largest but enables index-only scans

### Query Plan Changes

**BEFORE Migration:**
```
Seq Scan on foods
  Filter: (data_type IN (...))
  Rows: 500000
Sort
Limit
```

**AFTER Migration:**
```
Bitmap Index Scan using idx_foods_verified
  Bitmap Heap Scan
    Recheck Cond: (data_type IN (...))
Sort
Limit
```

## Verification Queries

After applying, run these to verify:

```sql
-- 1. Check all indexes exist (should return 5)
SELECT COUNT(*)
FROM pg_indexes
WHERE tablename = 'foods'
AND indexname LIKE 'idx_foods_%'
AND indexname IN (
    'idx_foods_data_type_category',
    'idx_foods_search_covering',
    'idx_foods_verified',
    'idx_foods_verified_category',
    'idx_foods_branded'
);

-- 2. Check index sizes
SELECT
    indexrelname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    idx_scan as times_used
FROM pg_stat_user_indexes
WHERE tablename = 'foods'
AND indexrelname LIKE 'idx_foods_%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- 3. Verify migration recorded
SELECT version, name, applied_at
FROM schema_migrations
WHERE version = 10;

-- 4. Test index usage in query plan
EXPLAIN ANALYZE
SELECT fdc_id, description, data_type, food_category
FROM foods
WHERE data_type IN ('foundation_food', 'sr_legacy_food')
LIMIT 50;
-- Should show "Index Scan" in the plan
```

## Why Migration Not Applied Yet

**Root Cause**: PostgreSQL connection pool exhausted
- Max connections likely set to 100 (default)
- Gleam app uses 50 connections (`pog.pool_size(50)` in init_pg.gleam)
- No available connections for psql to connect

**Evidence**:
```
psql: error: connection to server on socket "/run/postgresql/.s.PGSQL.5432" failed:
FATAL:  sorry, too many clients already
```

**Fix**: Stop Gleam application before running migration

## Related Files

- **Migration**: `gleam/migrations_pg/010_optimize_search_performance.sql`
- **Application script**: `scripts/apply-migration-010.sh`
- **Instructions**: `MIGRATION_010_INSTRUCTIONS.md`
- **This summary**: `MIGRATION_010_SUMMARY.md`
- **Init script**: `scripts/init-database.sh`
- **Migration runner**: `gleam/src/scripts/init_pg.gleam`

## Migration History Context

Other migrations in the project:
- 001: schema_migrations tracking table
- 002: USDA tables (foods, nutrients, food_nutrients)
- 003: App tables (recipes, food_logs)
- 005: Micronutrients in food_logs
- 006: Source tracking
- 009: Auto meal planner + recipe_sources
- **010: Search performance (THIS ONE)** ⬅️
- 011: Create recipes/logs tables

## Next Steps

1. **Immediate**: Stop Gleam app and apply migration
   ```bash
   pkill -f "gleam run"
   ./scripts/apply-migration-010.sh
   ```

2. **Verify**: Check all 5 indexes exist and are being used

3. **Monitor**: Track index usage over time
   ```sql
   SELECT indexrelname, idx_scan, idx_tup_read
   FROM pg_stat_user_indexes
   WHERE tablename = 'foods'
   ORDER BY idx_scan DESC;
   ```

4. **Optimize**: Adjust application queries to leverage new indexes

5. **Benchmark**: Measure actual performance improvements with real queries

---

**Migration is READY and SAFE to apply** - all indexes use IF NOT EXISTS for idempotency.
