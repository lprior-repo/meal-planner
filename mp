#!/bin/bash
# Meal Planner - Unified Binary Wrapper
#
# This script:
# - Ensures .env is loaded
# - Runs startup checks
# - Launches the meal planner (TUI, CLI, or Web mode)

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Build if not already built
if [ ! -f "build/dev/erlang/meal_planner/ebin/cli.beam" ]; then
    echo "🔨 Building meal planner..."
    gleam build
fi

# Run with startup checks and configuration validation
exec gleam run -- "$@"
