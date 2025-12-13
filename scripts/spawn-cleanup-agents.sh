#!/bin/bash
# Spawn 16 parallel agents to work on cleanup tasks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Spawning 16 agents for cleanup-redundancy tasks..."

# Get all cleanup-redundancy beads
BEADS=$(bd ready --label cleanup-redundancy --json)
TOTAL_BEADS=$(echo "$BEADS" | jq 'length')

echo "📋 Found $TOTAL_BEADS cleanup tasks"

if [ "$TOTAL_BEADS" -eq 0 ]; then
    echo "❌ No cleanup tasks found with label 'cleanup-redundancy'"
    exit 1
fi

# Extract bead IDs
BEAD_IDS=$(echo "$BEADS" | jq -r '.[].id')

echo "🤖 Launching 16 Claude Code agents in parallel..."
echo ""

# Function to spawn a single agent
spawn_agent() {
    local BEAD_ID=$1
    local AGENT_NUM=$2
    local BEAD_INFO=$(echo "$BEADS" | jq -r ".[] | select(.id == \"$BEAD_ID\") | .title")

    echo "Agent $AGENT_NUM → [$BEAD_ID] $BEAD_INFO"

    # Spawn Claude Code in background to work on this bead
    (
        cd "$PROJECT_ROOT"

        # Create a prompt for the agent
        PROMPT="Work on bead $BEAD_ID: $BEAD_INFO

1. Update bead status to in_progress: bd update $BEAD_ID --status in_progress
2. Complete the task as described
3. Test that your changes work
4. Update bead status to done: bd close $BEAD_ID
5. Sync beads: bd sync
6. Commit changes: git add . && git commit -m '[$BEAD_ID] $BEAD_INFO'
7. Push: git push

CRITICAL: Use file reservations via Agent Mail to prevent conflicts with other agents."

        # Log file for this agent
        LOG_FILE="/tmp/cleanup-agent-$AGENT_NUM-$BEAD_ID.log"

        # Run claude-code with the prompt
        echo "$PROMPT" | claude --dangerously-skip-permissions 2>&1 | tee "$LOG_FILE"

    ) &

    # Store the PID
    echo $! >> /tmp/cleanup-agent-pids.txt
}

# Clear PID file
rm -f /tmp/cleanup-agent-pids.txt

# Spawn agents (max 16)
AGENT_NUM=1
for BEAD_ID in $BEAD_IDS; do
    if [ $AGENT_NUM -gt 16 ]; then
        echo "⚠️  More than 16 tasks - spawning only first 16 agents"
        break
    fi

    spawn_agent "$BEAD_ID" $AGENT_NUM
    AGENT_NUM=$((AGENT_NUM + 1))

    # Small delay to avoid thundering herd
    sleep 0.5
done

echo ""
echo "✅ Spawned $((AGENT_NUM - 1)) agents working in parallel"
echo ""
echo "📊 Monitor progress:"
echo "   bd ready --label cleanup-redundancy"
echo "   watch -n 5 'bd ready --label cleanup-redundancy --json | jq -r \".[] | [.id, .status, .title] | @tsv\"'"
echo ""
echo "🛑 To kill all agents:"
echo "   cat /tmp/cleanup-agent-pids.txt | xargs kill"
echo ""
echo "📋 View agent logs:"
echo "   tail -f /tmp/cleanup-agent-*.log"
