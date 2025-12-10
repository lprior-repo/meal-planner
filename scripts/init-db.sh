#!/bin/bash
set -e

# PostgreSQL initialization script for meal-planner
# Creates both databases: mealie (for Mealie) and meal_planner (for Gleam backend)

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create mealie database for Mealie recipe manager
    CREATE DATABASE mealie;
    GRANT ALL PRIVILEGES ON DATABASE mealie TO $POSTGRES_USER;

    -- Create meal_planner database for Gleam backend
    CREATE DATABASE meal_planner;
    GRANT ALL PRIVILEGES ON DATABASE meal_planner TO $POSTGRES_USER;

    -- List all databases for verification
    \l
EOSQL

echo "✓ Databases created successfully: mealie, meal_planner"
