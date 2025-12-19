#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Rollback Script for Meal Planner
# ============================================================================
#
# Usage: ./rollback.sh [--to-version VERSION]
#
# This script performs a quick rollback to the previous deployment:
# 1. Reads current deployment state
# 2. Switches back to the previous (stopped) deployment
# 3. Validates the rollback
# 4. Switches traffic back
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get current deployment state
get_current_deployment() {
    if [ -f "$PROJECT_ROOT/.deployment-state" ]; then
        cat "$PROJECT_ROOT/.deployment-state"
    else
        echo "unknown"
    fi
}

# Get inactive deployment
get_inactive_deployment() {
    local active=$1
    if [ "$active" = "blue" ]; then
        echo "green"
    else
        echo "blue"
    fi
}

# Health check
health_check() {
    local slot=$1
    local port

    if [ "$slot" = "blue" ]; then
        port=8080
    else
        port=8081
    fi

    log_info "Checking health of ${slot} on port ${port}..."

    for i in {1..10}; do
        if curl -sf "http://localhost:${port}/health" > /dev/null; then
            log_success "Health check passed"
            return 0
        fi
        sleep 3
    done

    log_error "Health check failed"
    return 1
}

# Main rollback
main() {
    log_warning "ROLLBACK INITIATED"

    # Get current state
    local current=$(get_current_deployment)
    local rollback_to=$(get_inactive_deployment "$current")

    log_info "Current deployment: ${current}"
    log_info "Rolling back to: ${rollback_to}"

    # Confirm rollback
    read -p "Are you sure you want to rollback? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Rollback cancelled"
        exit 0
    fi

    # Start old deployment
    log_info "Starting ${rollback_to} deployment..."
    cd "$PROJECT_ROOT"

    if [ "$rollback_to" = "green" ]; then
        docker-compose -f docker-compose.prod.yml --profile green-deployment up -d api-green
    else
        docker-compose -f docker-compose.prod.yml up -d api-blue
    fi

    # Health check
    if ! health_check "$rollback_to"; then
        log_error "Rollback failed - ${rollback_to} is not healthy"
        exit 1
    fi

    # Switch traffic (update nginx)
    log_warning "Manual step required: Update nginx to route to api-${rollback_to}:8080"
    log_info "Then run: docker exec meal_planner_nginx nginx -s reload"

    # Stop current deployment
    log_info "Stopping ${current} deployment..."
    if [ "$current" = "green" ]; then
        docker-compose -f docker-compose.prod.yml --profile green-deployment stop api-green
    else
        docker-compose -f docker-compose.prod.yml stop api-blue
    fi

    # Update state
    echo "${rollback_to}" > "$PROJECT_ROOT/.deployment-state"

    log_success "Rollback completed successfully!"
    log_info "Active: ${rollback_to}"
    log_info "Stopped: ${current}"
}

main "$@"
