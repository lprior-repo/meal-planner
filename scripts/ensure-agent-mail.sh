#!/usr/bin/env bash

################################################################################
# Ensure Agent Mail - Startup and Health Monitor
#
# Runs in dedicated Zellij pane to:
# 1. Start agent-mail server
# 2. Verify health checks
# 3. Maintain connection
# 4. Alert on failures
#
# If this fails, ALL agents will fail
################################################################################

set -euo pipefail

AGENT_MAIL_URL="${AGENT_MAIL_URL:-http://127.0.0.1:8765}"
AGENT_MAIL_SERVER="${AGENT_MAIL_SERVER:-/home/lewis/mcp_agent_mail/scripts/run_server_with_token.sh}"
MAX_STARTUP_WAIT=30
HEALTH_CHECK_INTERVAL=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[AGENT-MAIL]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*" >&2
}

fatal() {
    echo -e "${RED}✗ FATAL:${NC} $*" >&2
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${RED}AGENT MAIL SERVER FAILED - ALL AGENTS WILL FAIL${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
}

################################################################################
# Health Check
################################################################################

check_health() {
    local endpoint="$AGENT_MAIL_URL/health/liveness"
    local response
    
    if response=$(curl -s -m 5 "$endpoint" 2>/dev/null); then
        if echo "$response" | grep -q '"status":"alive"'; then
            return 0
        fi
    fi
    return 1
}

wait_for_health() {
    local elapsed=0
    
    log "Waiting for agent-mail to be healthy..."
    
    while [[ $elapsed -lt $MAX_STARTUP_WAIT ]]; do
        if check_health; then
            success "Agent Mail is healthy"
            echo ""
            return 0
        fi
        
        echo -ne "\r  Waiting... ${elapsed}s"
        sleep 1
        ((elapsed++))
    done
    
    echo ""
    fatal "Agent Mail did not become healthy within ${MAX_STARTUP_WAIT}s"
}

################################################################################
# Server Management
################################################################################

start_server() {
    log "Starting agent-mail server..."
    
    if [[ ! -x "$AGENT_MAIL_SERVER" ]]; then
        fatal "Agent Mail server script not found: $AGENT_MAIL_SERVER"
    fi
    
    # Start the server in the background and capture output
    if "$AGENT_MAIL_SERVER" 2>&1 | tee -a /tmp/agent-mail.log; then
        success "Server started"
    else
        fatal "Failed to start agent-mail server"
    fi
}

################################################################################
# Registration Check
################################################################################

check_registration() {
    log "Verifying MCP registration..."
    
    # Check that the server responds to MCP protocol
    local response
    if response=$(curl -s -m 5 "$AGENT_MAIL_URL/mcp/" 2>/dev/null); then
        success "MCP endpoint is accessible"
        return 0
    else
        fatal "MCP endpoint not accessible at $AGENT_MAIL_URL/mcp/"
    fi
}

################################################################################
# Web UI Check
################################################################################

check_web_ui() {
    log "Verifying web UI..."
    
    local ui_url="$AGENT_MAIL_URL/mail"
    local response
    
    if response=$(curl -s -m 5 -I "$ui_url" 2>/dev/null | head -1); then
        if echo "$response" | grep -q "200\|301\|302"; then
            success "Web UI accessible at $ui_url"
            return 0
        fi
    fi
    
    warn "Web UI not fully accessible yet (may be normal)"
    return 0
}

################################################################################
# Server Info
################################################################################

display_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${MAGENTA}Agent Mail Server Ready${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Endpoint: ${BLUE}$AGENT_MAIL_URL${NC}"
    echo "  MCP:      ${BLUE}$AGENT_MAIL_URL/mcp/${NC}"
    echo "  Web UI:   ${BLUE}$AGENT_MAIL_URL/mail${NC}"
    echo ""
    echo "Status: ${GREEN}RUNNING${NC}"
    echo "All agents can now proceed with file reservations and messaging."
    echo ""
}

################################################################################
# Continuous Monitoring
################################################################################

monitor_server() {
    log "Monitoring agent-mail server..."
    echo ""
    
    local failure_count=0
    local max_failures=3
    
    while true; do
        sleep $HEALTH_CHECK_INTERVAL
        
        if check_health; then
            # Reset failure count on success
            if [[ $failure_count -gt 0 ]]; then
                failure_count=0
                success "Agent Mail recovered"
            fi
        else
            ((failure_count++))
            warn "Health check failed ($failure_count/$max_failures)"
            
            if [[ $failure_count -ge $max_failures ]]; then
                error "Agent Mail has failed too many times"
                fatal "Agent Mail server is unresponsive"
            fi
        fi
    done
}

################################################################################
# Main Flow
################################################################################

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${MAGENTA}MCP Agent Mail Startup${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Start the server
    start_server
    
    # Wait for it to be healthy
    wait_for_health
    
    # Verify registrations
    check_registration
    
    # Check web UI
    check_web_ui
    
    # Display info
    display_info
    
    # Monitor continuously
    monitor_server
}

# Trap signals
trap 'log "Shutdown signal received"; exit 0' SIGTERM SIGINT

# Run main
main "$@"
