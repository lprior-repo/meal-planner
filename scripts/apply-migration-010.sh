#!/usr/bin/env bash
# Apply migration 010_optimize_search_performance.sql
# This adds 5 indexes for 56% performance improvement on filtered food search

set -e

echo "==================================================================="
echo "  Migration 010: Optimize Search Performance"
echo "==================================================================="
echo ""
echo "This migration adds:"
echo "  - 5 composite and partial indexes"
echo "  - Expected 50-70% performance improvement for filtered queries"
echo "  - ~15-20MB additional storage"
echo ""

# Change to migrations directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_DIR="$SCRIPT_DIR/../gleam/migrations_pg"
MIGRATION_FILE="$MIGRATION_DIR/010_optimize_search_performance.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "📍 Step 1: Check if migration already applied"
echo ""

# Check schema_migrations table
ALREADY_APPLIED=$(psql -d meal_planner -t -c "SELECT COUNT(*) FROM schema_migrations WHERE version = 10;" 2>/dev/null || echo "0")

if [ "$ALREADY_APPLIED" != "0" ] && [ "$ALREADY_APPLIED" != " 0" ]; then
    echo "✓ Migration 010 already recorded in schema_migrations table"
    echo ""
    echo "Checking if indexes exist..."

    INDEX_COUNT=$(psql -d meal_planner -t -c "
        SELECT COUNT(*) FROM pg_indexes
        WHERE tablename = 'foods'
        AND indexname IN (
            'idx_foods_data_type_category',
            'idx_foods_search_covering',
            'idx_foods_verified',
            'idx_foods_verified_category',
            'idx_foods_branded'
        );" 2>/dev/null || echo "0")

    if [ "$INDEX_COUNT" = "5" ] || [ "$INDEX_COUNT" = " 5" ]; then
        echo "✓ All 5 indexes are present"
        echo ""
        echo "📊 Index sizes:"
        psql -d meal_planner -c "
            SELECT
                indexrelname as index_name,
                pg_size_pretty(pg_relation_size(indexrelid)) as size
            FROM pg_stat_user_indexes
            WHERE tablename = 'foods'
            AND indexrelname LIKE 'idx_foods_%'
            ORDER BY pg_relation_size(indexrelid) DESC;"

        echo ""
        echo "🎉 Migration 010 is already fully applied!"
        exit 0
    else
        echo "⚠️  Migration recorded but only $INDEX_COUNT/5 indexes found"
        echo "    Re-applying migration..."
    fi
else
    echo "Migration 010 not yet applied"
fi

echo ""
echo "📍 Step 2: Apply migration"
echo ""

# Apply the migration
if psql -d meal_planner -f "$MIGRATION_FILE"; then
    echo ""
    echo "✓ Migration SQL executed successfully"
else
    echo ""
    echo "❌ Migration failed"
    exit 1
fi

echo ""
echo "📍 Step 3: Record migration in schema_migrations"
echo ""

# Record in schema_migrations table (idempotent)
psql -d meal_planner -c "
    INSERT INTO schema_migrations (version, name, applied_at)
    VALUES (10, 'optimize_search_performance', NOW())
    ON CONFLICT (version) DO UPDATE
    SET applied_at = NOW()
    RETURNING version, name, applied_at;"

echo ""
echo "📍 Step 4: Verify indexes were created"
echo ""

# Verify all indexes exist
FINAL_INDEX_COUNT=$(psql -d meal_planner -t -c "
    SELECT COUNT(*) FROM pg_indexes
    WHERE tablename = 'foods'
    AND indexname IN (
        'idx_foods_data_type_category',
        'idx_foods_search_covering',
        'idx_foods_verified',
        'idx_foods_verified_category',
        'idx_foods_branded'
    );")

if [ "$FINAL_INDEX_COUNT" = "5" ] || [ "$FINAL_INDEX_COUNT" = " 5" ]; then
    echo "✓ All 5 indexes created successfully"
    echo ""

    echo "📊 Index details:"
    psql -d meal_planner -c "
        SELECT
            indexrelname as index_name,
            pg_size_pretty(pg_relation_size(indexrelid)) as size,
            idx_scan as times_used
        FROM pg_stat_user_indexes
        WHERE tablename = 'foods'
        AND indexrelname IN (
            'idx_foods_data_type_category',
            'idx_foods_search_covering',
            'idx_foods_verified',
            'idx_foods_verified_category',
            'idx_foods_branded'
        )
        ORDER BY pg_relation_size(indexrelid) DESC;"

    echo ""
    echo "🎉 Migration 010 applied successfully!"
    echo ""
    echo "Expected performance improvements:"
    echo "  • Verified-only queries: 50-70% faster"
    echo "  • Category-only queries: 30-40% faster"
    echo "  • Combined filters: 50-70% faster"
    echo ""
    echo "Next steps:"
    echo "  • Run application queries to warm up indexes"
    echo "  • Monitor index usage with: SELECT * FROM pg_stat_user_indexes WHERE tablename = 'foods';"
    echo "  • Verify query plans with: EXPLAIN ANALYZE <your query>"
else
    echo "❌ Expected 5 indexes but found $FINAL_INDEX_COUNT"
    echo ""
    echo "Existing indexes:"
    psql -d meal_planner -c "
        SELECT indexrelname
        FROM pg_stat_user_indexes
        WHERE tablename = 'foods'
        ORDER BY indexrelname;"
    exit 1
fi
