#!/usr/bin/env bash
# init-local-database.sh
#
# LOCAL DEVELOPMENT INITIALIZATION SCRIPT
# Purpose: Set up the meal-planner database for local development
#
# This script:
# 1. Starts the system PostgreSQL service (via systemctl)
# 2. Waits for PostgreSQL to be ready
# 3. Runs Gleam migrations to initialize the meal_planner database
# 4. Provides next steps for development
#
# Usage: ./scripts/init-local-database.sh
# Note: Requires sudo access to start PostgreSQL service
#
# NOT used in Docker environments - see init-docker-database.sh instead

set -e

echo "🐘 Initializing PostgreSQL database..."
echo ""

# Step 1: Start PostgreSQL
echo "📍 Step 1: Starting PostgreSQL service"
if systemctl is-active --quiet postgresql; then
    echo "   ✓ PostgreSQL is already running"
else
    echo "   Starting PostgreSQL..."
    sudo systemctl start postgresql

    # Wait for PostgreSQL to be ready
    echo "   ⏳ Waiting for PostgreSQL to be ready..."
    for i in {1..10}; do
        if pg_isready -q 2>/dev/null; then
            echo "   ✓ PostgreSQL is ready"
            break
        fi
        if [ $i -eq 10 ]; then
            echo "   ✗ PostgreSQL failed to start"
            exit 1
        fi
        sleep 1
    done
fi

echo ""

# Step 2: Create database and run migrations
echo "📍 Step 2: Creating meal_planner database and running migrations"
cd "$(dirname "$0")/../gleam"

if gleam run -m scripts/init_pg; then
    echo "   ✓ Database initialized successfully"
else
    echo "   ✗ Database initialization failed"
    exit 1
fi

echo ""
echo "🎉 Database setup complete!"
echo ""
echo "Next steps:"
echo "  • Import recipes: gleam run -m scripts/import_recipes"
echo "  • Run tests: gleam test"
echo "  • Start server: gleam run"
