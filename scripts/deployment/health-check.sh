#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Health Check Validation Script
# ============================================================================
#
# Usage: ./health-check.sh <endpoint> [timeout]
#   endpoint: URL to check (e.g., http://localhost:8080)
#   timeout: Max time to wait in seconds (default: 60)
#
# Exit codes:
#   0 - All health checks passed
#   1 - Health check failed
#   2 - Invalid arguments
# ============================================================================

ENDPOINT="${1:-}"
TIMEOUT="${2:-60}"
INTERVAL=5

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "[INFO] $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

if [ -z "$ENDPOINT" ]; then
    echo "Usage: $0 <endpoint> [timeout]"
    exit 2
fi

# Basic health check
check_health() {
    local url="${ENDPOINT}/health"
    log_info "Checking basic health: $url"

    local response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null || echo "000")
    local body=$(echo "$response" | head -n -1)
    local status=$(echo "$response" | tail -n 1)

    if [ "$status" = "200" ]; then
        if echo "$body" | grep -q '"status".*"healthy"'; then
            log_success "Health check passed"
            echo "$body" | jq '.' 2>/dev/null || echo "$body"
            return 0
        else
            log_error "Unexpected health response: $body"
            return 1
        fi
    else
        log_error "Health check failed with status $status"
        return 1
    fi
}

# Readiness check
check_readiness() {
    local url="${ENDPOINT}/ready"
    log_info "Checking readiness: $url"

    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

    if [ "$status" = "200" ]; then
        log_success "Readiness check passed"
        return 0
    else
        log_error "Readiness check failed with status $status"
        return 1
    fi
}

# Liveness check
check_liveness() {
    local url="${ENDPOINT}/live"
    log_info "Checking liveness: $url"

    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")

    if [ "$status" = "200" ]; then
        log_success "Liveness check passed"
        return 0
    else
        log_error "Liveness check failed with status $status"
        return 1
    fi
}

# Wait for service to be ready
wait_for_ready() {
    log_info "Waiting up to ${TIMEOUT}s for service to be ready..."

    local elapsed=0
    while [ $elapsed -lt $TIMEOUT ]; do
        if check_health; then
            return 0
        fi

        sleep $INTERVAL
        elapsed=$((elapsed + INTERVAL))
        log_info "Retrying... (${elapsed}/${TIMEOUT}s)"
    done

    log_error "Service did not become ready within ${TIMEOUT}s"
    return 1
}

# Main execution
main() {
    log_info "Starting health check validation for: $ENDPOINT"

    # Wait for basic health
    if ! wait_for_ready; then
        exit 1
    fi

    # Run all checks
    local failed=0

    check_health || failed=$((failed + 1))
    check_readiness || failed=$((failed + 1))
    check_liveness || failed=$((failed + 1))

    if [ $failed -eq 0 ]; then
        echo ""
        log_success "All health checks passed!"
        exit 0
    else
        echo ""
        log_error "$failed health check(s) failed"
        exit 1
    fi
}

main "$@"
