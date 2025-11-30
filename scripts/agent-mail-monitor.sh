#!/bin/bash
# Background Agent Mail monitor - watches inbox for new messages
# Usage: ./scripts/agent-mail-monitor.sh <agent_name> [interval_seconds]

set -e

cd "$(dirname "$0")/.."

AGENT_NAME=${1:-"OrangeLake"}
INTERVAL=${2:-15}
PROJECT_KEY=$(pwd)

echo "Monitoring Agent Mail inbox for ${AGENT_NAME}..."
echo "Project: ${PROJECT_KEY}"
echo "Interval: ${INTERVAL}s"
echo "Press Ctrl+C to stop"

LAST_COUNT=0

while true; do
    # This would need MCP client access - placeholder for integration
    echo ""
    echo "=== Inbox Check at $(date) ==="
    echo "Agent: ${AGENT_NAME}"
    echo "(Use fetch_inbox via MCP to check messages)"
    echo ""
    sleep "$INTERVAL"
done
