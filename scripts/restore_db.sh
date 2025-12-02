#!/bin/bash
# Restore meal_planner database from pg_dump
# Downloads from GitHub Release if not present locally

DUMP_URL="https://github.com/lprior-repo/meal-planner/releases/download/v1.0.0/meal_planner.dump"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DUMP_FILE="$SCRIPT_DIR/../db_export/meal_planner.dump"
DB_NAME="meal_planner"

# Check if dump file exists locally
if [ ! -f "$DUMP_FILE" ]; then
    echo "Downloading database dump from GitHub..."
    mkdir -p "$SCRIPT_DIR/../db_export"
    curl -L -o "$DUMP_FILE" "$DUMP_URL"
fi

echo "Creating database..."
export PGPASSWORD=postgres
psql -h localhost -U postgres -c "DROP DATABASE IF EXISTS $DB_NAME"
psql -h localhost -U postgres -c "CREATE DATABASE $DB_NAME"

echo "Restoring database (this takes a few minutes)..."
pg_restore -h localhost -U postgres -d $DB_NAME -j 4 "$DUMP_FILE"

echo "Done! Database restored."
psql -h localhost -U postgres -d $DB_NAME -c "SELECT 'Foods' as table_name, count(*) FROM foods UNION ALL SELECT 'Nutrients', count(*) FROM nutrients UNION ALL SELECT 'Food Nutrients', count(*) FROM food_nutrients"
