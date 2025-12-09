#!/usr/bin/env bash
# =============================================================================
# Agent Mail MCP Integration Wrapper
# =============================================================================
# Provides shell functions for calling Agent Mail MCP tools
#
# Usage:
#   source agent-mail-wrapper.sh
#   agent_mail_register "MyAgent" "Working on task"
#   agent_mail_reserve_files "MyAgent" "bd-123" "gleam/src/**/*.gleam"
#   agent_mail_send_message "MyAgent" "OtherAgent" "[bd-123] Status" "Making progress"
#   agent_mail_release_files "bd-123"
# =============================================================================

readonly PROJECT_KEY="/home/lewis/src/meal-planner"

# =============================================================================
# Agent Registration
# =============================================================================

agent_mail_register() {
    local agent_name="$1"
    local task_desc="${2:-Agent work}"

    echo "[Agent Mail] Registering $agent_name..."

    # This would call the MCP server
    # For now, we log the intent
    echo "{\"action\":\"register\",\"agent\":\"$agent_name\",\"task\":\"$task_desc\"}" \
        >> /tmp/agent-mail-calls.jsonl

    echo "✓ Registered: $agent_name"
}

# =============================================================================
# File Reservations
# =============================================================================

agent_mail_reserve_files() {
    local agent_name="$1"
    local reason="$2"  # Usually the beads ID like "bd-123"
    local patterns="$3"

    echo "[Agent Mail] Reserving files for $agent_name ($reason)"
    echo "  Patterns: $patterns"

    # Log the reservation
    local timestamp
    timestamp=$(date -Iseconds)

    cat >> /tmp/agent-mail-calls.jsonl << EOF
{"action":"reserve_files","agent":"$agent_name","reason":"$reason","patterns":"$patterns","timestamp":"$timestamp"}
EOF

    # Store in local tracking
    local res_file="/tmp/file-reservations.json"
    if [[ ! -f "$res_file" ]]; then
        echo '{"reservations":{}}' > "$res_file"
    fi

    local current
    current=$(cat "$res_file")

    current=$(echo "$current" | jq \
        --arg reason "$reason" \
        --arg agent "$agent_name" \
        --arg patterns "$patterns" \
        --arg ts "$timestamp" \
        ".reservations[\"$reason\"] = {
            \"agent\": \$agent,
            \"patterns\": \$patterns,
            \"reserved_at\": \$ts,
            \"ttl_seconds\": 3600
        }")

    echo "$current" > "$res_file"

    echo "✓ Reserved files for $reason"
}

agent_mail_release_files() {
    local reason="$1"

    echo "[Agent Mail] Releasing files for $reason"

    # Log the release
    cat >> /tmp/agent-mail-calls.jsonl << EOF
{"action":"release_files","reason":"$reason","timestamp":"$(date -Iseconds)"}
EOF

    # Remove from local tracking
    local res_file="/tmp/file-reservations.json"
    if [[ -f "$res_file" ]]; then
        local current
        current=$(cat "$res_file")

        current=$(echo "$current" | jq "del(.reservations[\"$reason\"])")
        echo "$current" > "$res_file"
    fi

    echo "✓ Released files for $reason"
}

agent_mail_check_conflicts() {
    local patterns="$1"

    echo "[Agent Mail] Checking for file conflicts..."

    local res_file="/tmp/file-reservations.json"
    if [[ ! -f "$res_file" ]]; then
        echo "No active reservations"
        return 0
    fi

    local current
    current=$(cat "$res_file")

    local conflicts=()

    # Simple pattern matching (in production, Agent Mail would do proper glob matching)
    local reserved_patterns
    reserved_patterns=$(echo "$current" | jq -r '.reservations | to_entries[] | .value.patterns')

    for pattern in $patterns; do
        for reserved in $reserved_patterns; do
            if [[ "$pattern" == "$reserved" ]]; then
                conflicts+=("$pattern")
            fi
        done
    done

    if [[ ${#conflicts[@]} -gt 0 ]]; then
        echo "⚠ Conflicts detected: ${conflicts[*]}"
        return 1
    else
        echo "✓ No conflicts"
        return 0
    fi
}

# =============================================================================
# Messaging
# =============================================================================

agent_mail_send_message() {
    local from_agent="$1"
    local to_agent="$2"
    local subject="$3"
    local body="$4"
    local thread_id="${5:-}"

    echo "[Agent Mail] Message: $from_agent → $to_agent"
    echo "  Subject: $subject"

    # Log the message
    cat >> /tmp/agent-mail-calls.jsonl << EOF
{"action":"send_message","from":"$from_agent","to":"$to_agent","subject":"$subject","body":"$body","thread_id":"$thread_id","timestamp":"$(date -Iseconds)"}
EOF

    echo "✓ Message sent"
}

agent_mail_fetch_inbox() {
    local agent_name="$1"
    local since_ts="${2:-}"

    echo "[Agent Mail] Fetching inbox for $agent_name..."

    # In production, this would call the MCP server
    # For now, filter the message log
    if [[ -f /tmp/agent-mail-calls.jsonl ]]; then
        if [[ -n "$since_ts" ]]; then
            jq -s --arg agent "$agent_name" --arg since "$since_ts" \
                '[.[] | select(.action == "send_message" and .to == $agent and .timestamp > $since)]' \
                /tmp/agent-mail-calls.jsonl
        else
            jq -s --arg agent "$agent_name" \
                '[.[] | select(.action == "send_message" and .to == $agent)]' \
                /tmp/agent-mail-calls.jsonl
        fi
    else
        echo '[]'
    fi
}

# =============================================================================
# Utility Functions
# =============================================================================

agent_mail_show_reservations() {
    local res_file="/tmp/file-reservations.json"

    if [[ ! -f "$res_file" ]]; then
        echo "No active file reservations"
        return 0
    fi

    echo "═══ ACTIVE FILE RESERVATIONS ═══"
    jq -r '.reservations | to_entries[] |
        "\(.key): \(.value.agent) | Patterns: \(.value.patterns) | Reserved: \(.value.reserved_at)"' \
        "$res_file"
}

agent_mail_show_messages() {
    if [[ ! -f /tmp/agent-mail-calls.jsonl ]]; then
        echo "No messages logged"
        return 0
    fi

    echo "═══ RECENT MESSAGES ═══"
    jq -s -r '.[] | select(.action == "send_message") |
        "\(.timestamp) | \(.from) → \(.to): \(.subject)"' \
        /tmp/agent-mail-calls.jsonl | tail -20
}

agent_mail_init() {
    echo "[Agent Mail] Initializing logging..."
    mkdir -p /tmp
    touch /tmp/agent-mail-calls.jsonl
    echo '{"reservations":{}}' > /tmp/file-reservations.json
    echo "✓ Initialized"
}

# Auto-initialize on source
agent_mail_init
