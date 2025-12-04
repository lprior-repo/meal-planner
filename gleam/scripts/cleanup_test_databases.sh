#!/bin/bash
# Clean up orphaned test databases from failed test runs

echo "Terminating connections to test databases..."
psql -U postgres -h localhost -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname LIKE 'test_meal_planner_%';
"

echo "Dropping test databases..."
psql -U postgres -h localhost -c "
SELECT 'DROP DATABASE IF EXISTS ' || quote_ident(datname) || ';'
FROM pg_database
WHERE datname LIKE 'test_meal_planner_%';
" | psql -U postgres -h localhost

echo "Cleanup complete!"
