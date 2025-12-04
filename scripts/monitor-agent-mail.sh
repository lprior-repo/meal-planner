#!/usr/bin/env bash
# Agent Mail Live Monitor
# Shows real-time activity from Agent Mail server
# Usage: ./monitor-agent-mail.sh

set -euo pipefail

MAILBOX_DIR="$HOME/.mcp_agent_mail_git_mailbox_repo"
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

# Check if server is running
if ! pgrep -f "mcp_agent_mail" > /dev/null 2>&1; then
    echo -e "${RED}✗ Agent Mail server is not running${RESET}"
    echo "Start it first with: ./scripts/start-agent-mail.sh"
    exit 1
fi

# Verify server is responding
if ! curl -s -f "http://127.0.0.1:$PORT/health/liveness" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ Server process found but not responding${RESET}"
    echo "Check logs: $MAILBOX_DIR/server.log"
    exit 1
fi

# Check if mailbox directory exists
if [ ! -d "$MAILBOX_DIR" ]; then
    echo -e "${RED}✗ Mailbox directory not found: $MAILBOX_DIR${RESET}"
    exit 1
fi

show_header() {
    echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║    📬 Agent Mail Live Monitor - Press Ctrl+C to exit 📬       ║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${DIM}📁 Monitoring: $MAILBOX_DIR${RESET}"
    echo -e "${DIM}🌐 Web UI: ${BOLD}http://127.0.0.1:$PORT/mail${RESET}"
    echo -e "${DIM}👁  Watching for changes in real-time...${RESET}"
    echo ""
}

show_stats() {
    echo -e "${BOLD}${MAGENTA}═══ 📊 Database Statistics ═══${RESET}"

    # Count active agents
    local agent_count=0
    if [ -d "$MAILBOX_DIR/agents" ]; then
        agent_count=$(find "$MAILBOX_DIR/agents" -type f -name "profile.json" 2>/dev/null | wc -l)
    fi

    # Count total messages
    local message_count=0
    if [ -d "$MAILBOX_DIR/messages" ]; then
        message_count=$(find "$MAILBOX_DIR/messages" -type f -name "*.md" 2>/dev/null | wc -l)
    fi

    # Count active reservations
    local reservation_count=0
    if [ -d "$MAILBOX_DIR/file_reservations" ]; then
        reservation_count=$(find "$MAILBOX_DIR/file_reservations" -type f -name "*.json" -exec grep -l '"released_ts": null' {} \; 2>/dev/null | wc -l)
    fi

    # Count total projects
    local project_count=0
    if [ -d "$MAILBOX_DIR" ]; then
        project_count=$(find "$MAILBOX_DIR" -type d -name ".git" 2>/dev/null | wc -l)
    fi

    echo -e "  ${BOLD}Projects:${RESET} ${GREEN}$project_count${RESET} │ ${BOLD}Agents:${RESET} ${GREEN}$agent_count${RESET} │ ${BOLD}Messages:${RESET} ${BLUE}$message_count${RESET} │ ${BOLD}Reservations:${RESET} ${YELLOW}$reservation_count${RESET}"
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

# Handle Ctrl+C gracefully
trap 'echo -e "\n${GREEN}Monitor stopped${RESET}"; exit 0' INT

show_header
show_stats

# Check if inotifywait is available
if ! command -v inotifywait &> /dev/null; then
    echo -e "${YELLOW}⚠ inotifywait not found - install for real-time monitoring${RESET}"
    echo -e "${DIM}Install: sudo pacman -S inotify-tools  (or apt install inotify-tools)${RESET}"
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
            show_stats
            show_agents
            show_messages
            show_reservations
            last_check=$now
        fi
    done
    exit 0
fi

echo -e "${GREEN}✓ Real-time file system monitoring active${RESET}"
echo ""

# Show current state before watching for changes
show_agents
show_messages
show_reservations

echo -e "${BOLD}${MAGENTA}═══ Live Events ═══${RESET}"
echo ""

# Ensure directories exist
mkdir -p "$MAILBOX_DIR/agents" "$MAILBOX_DIR/messages" "$MAILBOX_DIR/file_reservations"

# Stream inotifywait events with continuous processing
cd "$MAILBOX_DIR"
stdbuf -oL inotifywait -m -r -e create,modify,delete,moved_to \
    --timefmt '%H:%M:%S' --format '%T|%e|%w|%f' \
    agents/ messages/ file_reservations/ | \
while IFS='|' read -r timestamp event dir file; do
    full_path="${dir}${file}"
    event_type="${event}"

    # Determine what changed
    if [[ "$full_path" == *"/agents/"* ]] && [[ "$file" == "profile.json" ]]; then
        agent_name=$(basename "$(dirname "$full_path")")
        if [[ "$event_type" == *"CREATE"* ]]; then
            echo -e "${GREEN}┌─────────────────────────────────────────────────────────────${RESET}"
            echo -e "${GREEN}│ [${timestamp}] 🤖 NEW AGENT REGISTERED${RESET}"
            echo -e "${GREEN}├─────────────────────────────────────────────────────────────${RESET}"
            if [ -f "$full_path" ]; then
                program=$(jq -r '.program // "Unknown"' "$full_path" 2>/dev/null || echo "Unknown")
                model=$(jq -r '.model // "Unknown"' "$full_path" 2>/dev/null || echo "Unknown")
                task=$(jq -r '.task_description // ""' "$full_path" 2>/dev/null || echo "")
                echo -e "${GREEN}│${RESET} ${BOLD}Agent:${RESET} ${GREEN}${agent_name}${RESET}"
                echo -e "${GREEN}│${RESET} ${BOLD}Program:${RESET} ${program}"
                echo -e "${GREEN}│${RESET} ${BOLD}Model:${RESET} ${model}"
                [ -n "$task" ] && echo -e "${GREEN}│${RESET} ${BOLD}Task:${RESET} ${task}"
            else
                echo -e "${GREEN}│${RESET} ${BOLD}Agent:${RESET} ${GREEN}${agent_name}${RESET}"
            fi
            echo -e "${GREEN}└─────────────────────────────────────────────────────────────${RESET}"
        elif [[ "$event_type" == *"MODIFY"* ]]; then
            echo -e "${CYAN}[${timestamp}] 🔄 Agent updated: ${BOLD}${agent_name}${RESET}"
        elif [[ "$event_type" == *"DELETE"* ]]; then
            echo -e "${RED}[${timestamp}] 👋 Agent removed: ${BOLD}${agent_name}${RESET}"
        fi

    elif [[ "$full_path" == *"/messages/"* ]] && [[ "$file" == *.md ]]; then
        if [[ "$event_type" == *"CREATE"* ]] || [[ "$event_type" == *"MOVED_TO"* ]]; then
            # Parse message details
            if [ -f "$full_path" ]; then
                subject=$(grep "^# " "$full_path" 2>/dev/null | head -1 | sed 's/^# //' || echo "No subject")
                from=$(grep "^**From:**" "$full_path" 2>/dev/null | sed 's/^**From:** //' || echo "Unknown")
                to=$(grep "^**To:**" "$full_path" 2>/dev/null | sed 's/^**To:** //' || echo "Unknown")
                thread=$(grep "^**Thread:**" "$full_path" 2>/dev/null | sed 's/^**Thread:** //' || echo "")
                importance=$(grep "^**Importance:**" "$full_path" 2>/dev/null | sed 's/^**Importance:** //' || echo "normal")

                # Choose color based on importance
                color="${BLUE}"
                icon="📧"
                case "$importance" in
                    high|urgent)
                        color="${RED}"
                        icon="🚨"
                        ;;
                    *)
                        color="${BLUE}"
                        icon="📧"
                        ;;
                esac

                echo -e "${color}┌─────────────────────────────────────────────────────────────${RESET}"
                echo -e "${color}│ [${timestamp}] ${icon} NEW MESSAGE${RESET}"
                echo -e "${color}├─────────────────────────────────────────────────────────────${RESET}"
                echo -e "${color}│${RESET} ${BOLD}Subject:${RESET} ${subject}"
                echo -e "${color}│${RESET} ${BOLD}From:${RESET} ${GREEN}${from}${RESET} ${BOLD}→${RESET} ${BOLD}To:${RESET} ${CYAN}${to}${RESET}"
                [ -n "$thread" ] && echo -e "${color}│${RESET} ${BOLD}Thread:${RESET} ${thread}"
                [ "$importance" != "normal" ] && echo -e "${color}│${RESET} ${BOLD}Importance:${RESET} ${RED}${importance}${RESET}"
                echo -e "${color}│${RESET} ${BOLD}File:${RESET} ${DIM}${file}${RESET}"
                echo -e "${color}└─────────────────────────────────────────────────────────────${RESET}"
            fi
        fi

    elif [[ "$full_path" == *"/file_reservations/"* ]] && [[ "$file" == *.json ]]; then
        if [ -f "$full_path" ]; then
            agent=$(jq -r '.agent_name // "Unknown"' "$full_path" 2>/dev/null || echo "Unknown")
            path=$(jq -r '.path_pattern // "Unknown"' "$full_path" 2>/dev/null || echo "Unknown")
            released=$(jq -r '.released_ts // "null"' "$full_path" 2>/dev/null || echo "null")
            exclusive=$(jq -r '.exclusive // false' "$full_path" 2>/dev/null || echo "false")
            reason=$(jq -r '.reason // ""' "$full_path" 2>/dev/null || echo "")

            if [[ "$event_type" == *"CREATE"* ]] && [[ "$released" == "null" ]]; then
                lock_icon="🔒"
                lock_type="SHARED"
                if [ "$exclusive" = "true" ]; then
                    lock_icon="🔐"
                    lock_type="EXCLUSIVE"
                fi
                echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────${RESET}"
                echo -e "${YELLOW}│ [${timestamp}] ${lock_icon} FILE RESERVATION (${lock_type})${RESET}"
                echo -e "${YELLOW}├─────────────────────────────────────────────────────────────${RESET}"
                echo -e "${YELLOW}│${RESET} ${BOLD}Agent:${RESET} ${GREEN}${agent}${RESET}"
                echo -e "${YELLOW}│${RESET} ${BOLD}Path:${RESET} ${CYAN}${path}${RESET}"
                [ -n "$reason" ] && echo -e "${YELLOW}│${RESET} ${BOLD}Reason:${RESET} ${reason}"
                echo -e "${YELLOW}└─────────────────────────────────────────────────────────────${RESET}"
            elif [[ "$event_type" == *"MODIFY"* ]] && [[ "$released" != "null" ]]; then
                echo -e "${GREEN}┌─────────────────────────────────────────────────────────────${RESET}"
                echo -e "${GREEN}│ [${timestamp}] 🔓 FILE RELEASED${RESET}"
                echo -e "${GREEN}├─────────────────────────────────────────────────────────────${RESET}"
                echo -e "${GREEN}│${RESET} ${BOLD}Agent:${RESET} ${GREEN}${agent}${RESET}"
                echo -e "${GREEN}│${RESET} ${BOLD}Path:${RESET} ${CYAN}${path}${RESET}"
                echo -e "${GREEN}└─────────────────────────────────────────────────────────────${RESET}"
            fi
        fi
    fi
done
