#!/bin/bash
# Script to add Vertical Diet recipes to the database

echo "🥩 Vertical Diet Recipe Importer"
echo "================================"
echo ""

# Check if PostgreSQL is running
if ! pg_isready -q; then
    echo "❌ PostgreSQL is not running. Please start it first."
    exit 1
fi

echo "✅ PostgreSQL is running"
echo ""

# Run Gleam test to insert recipes
cd "$(dirname "$0")/.." || exit

echo "📝 Building and running recipe insertion..."
gleam test --target erlang --module vertical_diet_recipes_insertion

echo ""
echo "✨ Done!"
