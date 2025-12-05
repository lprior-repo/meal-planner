#!/bin/bash
# Reset database connections for meal planner
# Terminates all connections except the current one

echo "Terminating all database connections..."

psql -h localhost -U postgres -d postgres << 'EOF'
-- Terminate connections to meal_planner
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'meal_planner'
  AND pid <> pg_backend_pid();

-- Terminate connections to meal_planner_test
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'meal_planner_test'
  AND pid <> pg_backend_pid();

-- Terminate connections to test databases (test_meal_planner_*)
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname LIKE 'test_meal_planner_%'
  AND pid <> pg_backend_pid();

-- Show remaining connections
SELECT datname, count(*) as connections
FROM pg_stat_activity
WHERE datname IS NOT NULL
GROUP BY datname
ORDER BY datname;
EOF

echo "Done! Connections reset."
