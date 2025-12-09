-- ============================================================================
-- Search Performance Testing Suite
-- ============================================================================
-- Tests search queries BEFORE and AFTER indexes to measure improvement
--
-- Target: 56% performance improvement (62ms → 27ms)
-- ============================================================================

-- Configuration
\timing on
\pset pager off

-- Display current indexes
\echo '============================================================================'
\echo 'CURRENT INDEXES ON foods TABLE'
\echo '============================================================================'
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    idx_scan as scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'foods'
ORDER BY pg_relation_size(indexrelid) DESC;

-- ============================================================================
-- TEST 1: Basic Search with Verified Filter
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'TEST 1: Basic Search with Verified Filter'
\echo 'Query: chicken + verified USDA foods only'
\echo '============================================================================'

EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT fdc_id, description, data_type, food_category
FROM foods
WHERE data_type IN ('foundation_food', 'sr_legacy_food')
  AND (to_tsvector('english', description) @@ plainto_tsquery('english', 'chicken')
       OR description ILIKE '%chicken%')
ORDER BY
  CASE
    WHEN description ILIKE 'chicken%' THEN 0
    WHEN description ILIKE '% chicken%' THEN 1
    ELSE 2
  END,
  description
LIMIT 50;

-- ============================================================================
-- TEST 2: Category Search with Data Type Filter
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'TEST 2: Category Search with Data Type Filter'
\echo 'Query: protein + SR Legacy + Proteins category'
\echo '============================================================================'

EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT fdc_id, description, data_type, food_category
FROM foods
WHERE data_type = 'sr_legacy_food'
  AND food_category = 'Proteins'
  AND (to_tsvector('english', description) @@ plainto_tsquery('english', 'protein')
       OR description ILIKE '%protein%')
ORDER BY
  CASE
    WHEN description ILIKE 'protein%' THEN 0
    WHEN description ILIKE '% protein%' THEN 1
    ELSE 2
  END,
  description
LIMIT 50;

-- ============================================================================
-- TEST 3: Branded Search
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'TEST 3: Branded Search'
\echo 'Query: yogurt + branded foods only'
\echo '============================================================================'

EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT fdc_id, description, data_type, food_category
FROM foods
WHERE data_type = 'branded_food'
  AND (to_tsvector('english', description) @@ plainto_tsquery('english', 'yogurt')
       OR description ILIKE '%yogurt%')
ORDER BY
  CASE
    WHEN description ILIKE 'yogurt%' THEN 0
    WHEN description ILIKE '% yogurt%' THEN 1
    ELSE 2
  END,
  description
LIMIT 50;

-- ============================================================================
-- TEST 4: Combined Filters (Verified + Category)
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'TEST 4: Combined Filters (Verified + Category)'
\echo 'Query: chicken + verified + Poultry category'
\echo '============================================================================'

EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT fdc_id, description, data_type, food_category
FROM foods
WHERE data_type IN ('foundation_food', 'sr_legacy_food')
  AND food_category = 'Poultry Products'
  AND (to_tsvector('english', description) @@ plainto_tsquery('english', 'chicken')
       OR description ILIKE '%chicken%')
ORDER BY
  CASE
    WHEN description ILIKE 'chicken%' THEN 0
    WHEN description ILIKE '% chicken%' THEN 1
    ELSE 2
  END,
  description
LIMIT 50;

-- ============================================================================
-- TEST 5: No Filters (Baseline)
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'TEST 5: No Filters (Baseline)'
\echo 'Query: chicken + no filters'
\echo '============================================================================'

EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT fdc_id, description, data_type, food_category
FROM foods
WHERE to_tsvector('english', description) @@ plainto_tsquery('english', 'chicken')
   OR description ILIKE '%chicken%'
ORDER BY
  CASE
    WHEN description ILIKE 'chicken%' THEN 0
    WHEN description ILIKE '% chicken%' THEN 1
    ELSE 2
  END,
  description
LIMIT 50;

-- ============================================================================
-- TEST 6: Multiple Categories
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'TEST 6: Multiple Categories'
\echo 'Query: dairy + multiple categories'
\echo '============================================================================'

EXPLAIN (ANALYZE, BUFFERS, TIMING, FORMAT TEXT)
SELECT fdc_id, description, data_type, food_category
FROM foods
WHERE data_type IN ('foundation_food', 'sr_legacy_food')
  AND food_category IN ('Dairy and Egg Products', 'Milk and Milk Products')
  AND (to_tsvector('english', description) @@ plainto_tsquery('english', 'milk')
       OR description ILIKE '%milk%')
ORDER BY
  CASE
    WHEN description ILIKE 'milk%' THEN 0
    WHEN description ILIKE '% milk%' THEN 1
    ELSE 2
  END,
  description
LIMIT 50;

-- ============================================================================
-- SUMMARY STATISTICS
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'INDEX USAGE STATISTICS'
\echo '============================================================================'

SELECT
    indexname,
    idx_scan as total_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    CASE
        WHEN idx_scan > 0 THEN round(idx_tup_read::numeric / idx_scan, 2)
        ELSE 0
    END as avg_tuples_per_scan
FROM pg_stat_user_indexes
WHERE tablename = 'foods'
  AND idx_scan > 0
ORDER BY idx_scan DESC;

\echo ''
\echo '============================================================================'
\echo 'INDEX SIZES'
\echo '============================================================================'

SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    pg_relation_size(indexrelid) as bytes
FROM pg_stat_user_indexes
WHERE tablename = 'foods'
ORDER BY pg_relation_size(indexrelid) DESC;

\echo ''
\echo '============================================================================'
\echo 'TABLE STATISTICS'
\echo '============================================================================'

SELECT
    schemaname,
    tablename,
    n_live_tup as live_rows,
    n_dead_tup as dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE tablename = 'foods';

-- ============================================================================
-- Performance Testing Complete
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'PERFORMANCE TEST COMPLETE'
\echo '============================================================================'
\echo 'Review the EXPLAIN ANALYZE output above to compare:'
\echo '  - Planning Time'
\echo '  - Execution Time'
\echo '  - Total Time = Planning + Execution'
\echo '  - Rows Scanned vs Rows Returned'
\echo '  - Index usage (Bitmap Index Scan, Index Only Scan, etc.)'
\echo ''
\echo 'Target: 56% improvement (62ms → 27ms)'
\echo '============================================================================'
