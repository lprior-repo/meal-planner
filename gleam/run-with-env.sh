#!/bin/bash
# Wrapper to run gleam with .env file loaded

cd "$(dirname "$0")"

# Load .env if it exists
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

# Run gleam with all environment variables and pass through arguments
exec gleam run "$@"
