#!/usr/bin/env bash
# Agent Mail Server Starter with Live Monitor
# Starts server and shows real-time activity

set -euo pipefail

INSTALL_DIR="$HOME/.local/mcp_agent_mail"
MAILBOX_DIR="$HOME/.mcp_agent_mail_git_mailbox_repo"
ENV_FILE="$MAILBOX_DIR/.env"
PORT=8765

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Monitor functions (defined first)
show_header() {
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║           Agent Mail Live Monitor - Press Ctrl+C to exit      ║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${DIM}Monitoring: $MAILBOX_DIR${RESET}"
    echo -e "${DIM}Web UI: http://127.0.0.1:$PORT/mail${RESET}"
    echo -e "${DIM}Watching for changes in real-time...${RESET}"
    echo ""
}

show_agents() {
    echo -e "${BOLD}${CYAN}═══ Active Agents ═══${RESET}"

    if [ ! -d "$MAILBOX_DIR/agents" ]; then
        echo -e "${DIM}No agents registered${RESET}"
        echo ""
        return
    fi

    find "$MAILBOX_DIR/agents" -type f -name "profile.json" 2>/dev/null | while read -r file; do
        agent_dir=$(dirname "$file")
        agent_name=$(basename "$agent_dir")

        program=$(jq -r '.program // "Unknown"' "$file" 2>/dev/null || echo "Unknown")
        model=$(jq -r '.model // "Unknown"' "$file" 2>/dev/null || echo "Unknown")
        task=$(jq -r '.task_description // ""' "$file" 2>/dev/null || echo "")
        last_active=$(jq -r '.last_active_ts // ""' "$file" 2>/dev/null || echo "")

        echo -e "${GREEN}🤖 ${agent_name}${RESET}"
        echo -e "   ${DIM}Program: $program | Model: $model${RESET}"
        [ -n "$task" ] && echo -e "   ${DIM}Task: $task${RESET}"
        [ -n "$last_active" ] && echo -e "   ${DIM}Last active: $last_active${RESET}"
    done
    echo ""
}

show_messages() {
    echo -e "${BOLD}${BLUE}═══ Recent Messages (Last 10) ═══${RESET}"

    if [ ! -d "$MAILBOX_DIR/messages" ]; then
        echo -e "${DIM}No messages yet${RESET}"
        echo ""
        return
    fi

    # Find latest 10 message files
    find "$MAILBOX_DIR/messages" -type f -name "*.md" -printf '%T@ %p\n' 2>/dev/null | \
        sort -rn | head -10 | while read -r timestamp file; do

        filename=$(basename "$file")
        subject=$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //' || echo "No subject")
        from=$(grep "^**From:**" "$file" 2>/dev/null | sed 's/^**From:** //' || echo "Unknown")
        to=$(grep "^**To:**" "$file" 2>/dev/null | sed 's/^**To:** //' || echo "Unknown")
        date=$(stat -c %y "$file" | cut -d'.' -f1)

        echo -e "${GREEN}📧 ${filename}${RESET}"
        echo -e "   ${BOLD}Subject:${RESET} $subject"
        echo -e "   ${DIM}From: $from → To: $to${RESET}"
        echo -e "   ${DIM}Time: $date${RESET}"
        echo ""
    done
}

show_reservations() {
    echo -e "${BOLD}${YELLOW}═══ Active File Reservations ═══${RESET}"

    if [ ! -d "$MAILBOX_DIR/file_reservations" ]; then
        echo -e "${DIM}No reservations${RESET}"
        echo ""
        return
    fi

    local count=0
    find "$MAILBOX_DIR/file_reservations" -type f -name "*.json" 2>/dev/null | while read -r file; do
        if grep -q '"released_ts": null' "$file" 2>/dev/null; then
            agent=$(jq -r '.agent_name // "Unknown"' "$file" 2>/dev/null || echo "Unknown")
            path=$(jq -r '.path_pattern // "Unknown"' "$file" 2>/dev/null || echo "Unknown")
            reason=$(jq -r '.reason // ""' "$file" 2>/dev/null || echo "")
            exclusive=$(jq -r '.exclusive // false' "$file" 2>/dev/null || echo "false")

            lock_icon="🔒"
            [ "$exclusive" = "true" ] && lock_icon="🔐"

            echo -e "${YELLOW}$lock_icon ${agent}${RESET} → ${CYAN}${path}${RESET}"
            [ -n "$reason" ] && echo -e "   ${DIM}Reason: $reason${RESET}"
            count=$((count + 1))
        fi
    done

    active_count=$(find "$MAILBOX_DIR/file_reservations" -type f -name "*.json" -exec grep -l '"released_ts": null' {} \; 2>/dev/null | wc -l)
    echo -e "${DIM}Total active: $active_count${RESET}"
    echo ""
}

monitor_activity() {
    # Handle Ctrl+C gracefully
    trap 'echo -e "\n${GREEN}Monitor stopped${RESET}"; exit 0' INT

    show_header

    # Check if inotifywait is available
    if ! command -v inotifywait &> /dev/null; then
        echo -e "${YELLOW}⚠ inotifywait not found - install for real-time monitoring${RESET}"
        echo -e "${DIM}Install: sudo pacman -S inotify-tools${RESET}"
        echo -e "${DIM}Falling back to periodic polling...${RESET}"
        echo ""

        # Periodic polling fallback
        local last_check=$(date +%s)
        while true; do
            sleep 2
            local now=$(date +%s)
            echo -e "${DIM}[$(date '+%H:%M:%S')] Still monitoring... (${now}s)${RESET}"

            # Show periodic summary every 30 seconds
            if [ $((now - last_check)) -ge 30 ]; then
                clear
                show_header
                show_agents
                show_messages
                show_reservations
                last_check=$now
            fi
        done
        return
    fi

    echo -e "${GREEN}✓ Real-time file system monitoring active${RESET}"
    echo ""

    # Show current state before watching for changes
    show_agents
    show_messages
    show_reservations

    echo -e "${BOLD}${MAGENTA}═══ Live Events ═══${RESET}"
    echo ""

    # Stream inotifywait events with continuous processing
    cd "$MAILBOX_DIR"
    inotifywait -m -r -e create,modify,delete,moved_to \
        --timefmt '%H:%M:%S' --format '%T|%e|%w|%f' \
        agents/ messages/ file_reservations/ 2>/dev/null | \
    while IFS='|' read -r timestamp event dir file; do
        local full_path="${dir}${file}"
        local event_type="${event}"

        # Determine what changed
        if [[ "$full_path" == *"/agents/"* ]] && [[ "$file" == "profile.json" ]]; then
            agent_name=$(basename "$(dirname "$full_path")")
            if [[ "$event_type" == *"CREATE"* ]]; then
                echo -e "${GREEN}[${timestamp}] 🤖 New agent registered: ${agent_name}${RESET}"
            elif [[ "$event_type" == *"MODIFY"* ]]; then
                echo -e "${CYAN}[${timestamp}] 🔄 Agent updated: ${agent_name}${RESET}"
            elif [[ "$event_type" == *"DELETE"* ]]; then
                echo -e "${RED}[${timestamp}] 👋 Agent removed: ${agent_name}${RESET}"
            fi

        elif [[ "$full_path" == *"/messages/"* ]] && [[ "$file" == *.md ]]; then
            if [[ "$event_type" == *"CREATE"* ]] || [[ "$event_type" == *"MOVED_TO"* ]]; then
                # Parse message details
                if [ -f "$full_path" ]; then
                    subject=$(grep "^# " "$full_path" 2>/dev/null | head -1 | sed 's/^# //' || echo "No subject")
                    from=$(grep "^**From:**" "$full_path" 2>/dev/null | sed 's/^**From:** //' || echo "Unknown")
                    to=$(grep "^**To:**" "$full_path" 2>/dev/null | sed 's/^**To:** //' || echo "Unknown")
                    echo -e "${BLUE}[${timestamp}] 📧 New message: ${subject}${RESET}"
                    echo -e "   ${DIM}From: ${from} → To: ${to}${RESET}"
                fi
            fi

        elif [[ "$full_path" == *"/file_reservations/"* ]] && [[ "$file" == *.json ]]; then
            if [ -f "$full_path" ]; then
                agent=$(jq -r '.agent_name // "Unknown"' "$full_path" 2>/dev/null || echo "Unknown")
                path=$(jq -r '.path_pattern // "Unknown"' "$full_path" 2>/dev/null || echo "Unknown")
                released=$(jq -r '.released_ts // "null"' "$full_path" 2>/dev/null || echo "null")

                if [[ "$event_type" == *"CREATE"* ]] && [[ "$released" == "null" ]]; then
                    echo -e "${YELLOW}[${timestamp}] 🔒 File reservation: ${agent} → ${path}${RESET}"
                elif [[ "$event_type" == *"MODIFY"* ]] && [[ "$released" != "null" ]]; then
                    echo -e "${GREEN}[${timestamp}] 🔓 File released: ${agent} → ${path}${RESET}"
                fi
            fi
        fi

        # Send heartbeat every event to keep process active
        echo -e "${DIM}[${timestamp}] Event processed${RESET}"
    done
}

# Main script starts here
# Check if server is already running
if pgrep -f "mcp_agent_mail" > /dev/null 2>&1; then
    # Verify it's actually responding
    if curl -s -f "http://127.0.0.1:$PORT/health/liveness" > /dev/null 2>&1; then
        echo "✓ Server is already running and healthy"
        echo ""
        echo "Web UI: http://127.0.0.1:$PORT/mail"
        echo "Logs: $MAILBOX_DIR/server.log"
        echo ""
        echo "Starting live monitor (Ctrl+C to stop)..."
        sleep 1

        # Call the standalone monitor script
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        exec "$SCRIPT_DIR/monitor-agent-mail.sh"
    else
        echo "⚠ Server process found but not responding - will restart"
        pkill -f "mcp_agent_mail" || true
        sleep 1
    fi
fi

# Install if needed
if [ ! -d "$INSTALL_DIR" ] || [ ! -f "$INSTALL_DIR/scripts/run_server_with_token.sh" ]; then
    echo "Installing Agent Mail..."

    # Install uv if needed
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Clone and install
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone https://github.com/Dicklesworthstone/mcp_agent_mail.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    uv venv -p 3.14 || uv venv -p 3.13 || uv venv -p 3.12
    uv sync

    echo "✓ Installation complete"
    echo ""
fi

# Setup config if needed
if [ ! -f "$ENV_FILE" ]; then
    echo "Setting up configuration..."
    mkdir -p "$MAILBOX_DIR"

    # Generate secure token
    cd "$INSTALL_DIR"
    TOKEN=$(uv run python -c "import secrets; print(secrets.token_hex(32))")

    # Create config
    cat > "$ENV_FILE" <<EOF
HTTP_PORT=$PORT
HTTP_HOST=127.0.0.1
HTTP_BEARER_TOKEN=$TOKEN
EOF

    chmod 600 "$ENV_FILE"
    echo "✓ Configuration created"
    echo ""
fi

# Start server
echo "Starting Agent Mail server..."
cd "$INSTALL_DIR"
nohup "$INSTALL_DIR/scripts/run_server_with_token.sh" > "$MAILBOX_DIR/server.log" 2>&1 &

# Wait and verify process started
sleep 2
if ! pgrep -f "mcp_agent_mail" > /dev/null 2>&1; then
    echo "✗ Server process failed to start"
    echo "Check logs: $MAILBOX_DIR/server.log"
    exit 1
fi

# Wait for HTTP server to be ready (max 10 seconds)
echo "Testing server readiness..."
MAX_ATTEMPTS=20
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s -f "http://127.0.0.1:$PORT/health/liveness" > /dev/null 2>&1; then
        echo "✓ Server is ready and responding"
        echo ""
        echo "Web UI: http://127.0.0.1:$PORT/mail"
        echo "Logs: $MAILBOX_DIR/server.log"
        echo ""
        echo "Starting live monitor (Ctrl+C to stop)..."
        sleep 1

        # Call the standalone monitor script
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        exec "$SCRIPT_DIR/monitor-agent-mail.sh"
    fi
    ATTEMPT=$((ATTEMPT + 1))
    sleep 0.5
done

echo "✗ Server started but not responding to HTTP requests"
echo "Check logs: $MAILBOX_DIR/server.log"
exit 1
