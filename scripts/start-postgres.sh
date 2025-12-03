#!/usr/bin/env bash
# Start PostgreSQL for local development and testing

set -e

echo "🐘 Starting PostgreSQL..."

# Check if PostgreSQL is already running
if systemctl is-active --quiet postgresql; then
    echo "✓ PostgreSQL is already running"
    exit 0
fi

# Start PostgreSQL
sudo systemctl start postgresql

# Wait for it to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
for i in {1..10}; do
    if pg_isready -q; then
        echo "✓ PostgreSQL is ready"
        exit 0
    fi
    sleep 1
done

echo "✗ PostgreSQL failed to start"
exit 1
