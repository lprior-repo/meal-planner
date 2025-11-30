#!/bin/bash
# Background Beads monitor - shows ready work and in-progress items
# Usage: ./scripts/beads-monitor.sh [interval_seconds]

set -e

cd "$(dirname "$0")/.."

INTERVAL=${1:-30}

echo "Monitoring Beads every ${INTERVAL}s..."
echo "Press Ctrl+C to stop"

while true; do
    clear
    echo "=== Beads Status at $(date) ==="
    echo ""
    echo "--- Ready Work ---"
    bd ready --json 2>/dev/null | jq -r '.[] | "[\(.priority)] \(.id): \(.title)"' 2>/dev/null || echo "No ready items"
    echo ""
    echo "--- In Progress ---"
    bd list --status in_progress --json 2>/dev/null | jq -r '.[] | "\(.id): \(.title)"' 2>/dev/null || echo "None in progress"
    echo ""
    sleep "$INTERVAL"
done
