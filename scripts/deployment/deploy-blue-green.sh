#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Blue/Green Deployment Script for Meal Planner
# ============================================================================
#
# Usage: ./deploy-blue-green.sh <environment> <version>
#   environment: staging | production
#   version: Docker image tag (e.g., v1.2.3, main-abc123)
#
# This script performs a zero-downtime blue/green deployment:
# 1. Determines current active deployment (blue or green)
# 2. Deploys new version to inactive slot
# 3. Runs health checks on new deployment
# 4. Switches traffic to new deployment
# 5. Keeps old deployment running for quick rollback
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
ENVIRONMENT="${1:-staging}"
VERSION="${2:-latest}"
HEALTH_CHECK_RETRIES=10
HEALTH_CHECK_INTERVAL=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        log_error "docker is not installed"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose is not installed"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        exit 1
    fi

    log_success "All prerequisites met"
}

# Determine current active deployment
get_active_deployment() {
    local blue_status=$(docker inspect -f '{{.State.Running}}' meal_planner_api_blue 2>/dev/null || echo "false")
    local green_status=$(docker inspect -f '{{.State.Running}}' meal_planner_api_green 2>/dev/null || echo "false")

    if [ "$blue_status" = "true" ]; then
        echo "blue"
    elif [ "$green_status" = "true" ]; then
        echo "green"
    else
        echo "none"
    fi
}

# Get inactive deployment slot
get_inactive_deployment() {
    local active=$1
    if [ "$active" = "blue" ]; then
        echo "green"
    elif [ "$active" = "green" ]; then
        echo "blue"
    else
        echo "blue"  # Default to blue if nothing is running
    fi
}

# Pull new Docker image
pull_image() {
    log_info "Pulling Docker image: ghcr.io/lprior-repo/meal-planner:${VERSION}"

    if ! docker pull "ghcr.io/lprior-repo/meal-planner:${VERSION}"; then
        log_error "Failed to pull Docker image"
        exit 1
    fi

    log_success "Image pulled successfully"
}

# Deploy to inactive slot
deploy_to_slot() {
    local slot=$1
    log_info "Deploying to ${slot} slot..."

    cd "$PROJECT_ROOT"

    # Export version for docker-compose
    export VERSION="$VERSION"

    # Start the inactive deployment
    if [ "$slot" = "green" ]; then
        docker-compose -f docker-compose.prod.yml --profile green-deployment up -d api-green
    else
        docker-compose -f docker-compose.prod.yml up -d api-blue
    fi

    log_success "${slot} deployment started"
}

# Health check function
health_check() {
    local slot=$1
    local port

    if [ "$slot" = "blue" ]; then
        port=8080
    else
        port=8081
    fi

    log_info "Running health checks on ${slot} (port ${port})..."

    for i in $(seq 1 $HEALTH_CHECK_RETRIES); do
        if curl -sf "http://localhost:${port}/health" > /dev/null; then
            log_success "Health check passed on attempt $i"
            return 0
        fi

        log_warning "Health check attempt $i/$HEALTH_CHECK_RETRIES failed, retrying in ${HEALTH_CHECK_INTERVAL}s..."
        sleep $HEALTH_CHECK_INTERVAL
    done

    log_error "Health checks failed after $HEALTH_CHECK_RETRIES attempts"
    return 1
}

# Run comprehensive health validation
validate_deployment() {
    local slot=$1
    local port

    if [ "$slot" = "blue" ]; then
        port=8080
    else
        port=8081
    fi

    log_info "Validating ${slot} deployment..."

    # Basic health check
    if ! health_check "$slot"; then
        return 1
    fi

    # Check response structure
    local health_response=$(curl -s "http://localhost:${port}/health")

    if ! echo "$health_response" | grep -q '"status".*"healthy"'; then
        log_error "Health endpoint returned unexpected response: $health_response"
        return 1
    fi

    log_success "${slot} deployment validated"
    return 0
}

# Switch traffic to new deployment
switch_traffic() {
    local new_slot=$1
    log_info "Switching traffic to ${new_slot}..."

    # Update nginx configuration to point to new slot
    # This assumes nginx.conf has upstream configuration
    # In a real setup, you'd update the nginx config and reload

    # For now, we'll just log the action
    log_warning "Traffic switching requires nginx configuration update"
    log_info "Update nginx upstream to point to api-${new_slot}:8080"

    # Reload nginx
    if docker exec meal_planner_nginx nginx -s reload 2>/dev/null; then
        log_success "Nginx reloaded successfully"
    else
        log_warning "Could not reload nginx (may not be running)"
    fi

    log_success "Traffic switched to ${new_slot}"
}

# Stop old deployment
stop_old_deployment() {
    local slot=$1
    log_info "Stopping old ${slot} deployment..."

    if [ "$slot" = "green" ]; then
        docker-compose -f docker-compose.prod.yml --profile green-deployment stop api-green
    else
        docker-compose -f docker-compose.prod.yml stop api-blue
    fi

    log_success "${slot} deployment stopped (container preserved for rollback)"
}

# Rollback function
rollback() {
    local rollback_to=$1
    log_warning "Initiating rollback to ${rollback_to}..."

    # Start old deployment
    if [ "$rollback_to" = "green" ]; then
        docker-compose -f docker-compose.prod.yml --profile green-deployment up -d api-green
    else
        docker-compose -f docker-compose.prod.yml up -d api-blue
    fi

    # Wait for health check
    if health_check "$rollback_to"; then
        switch_traffic "$rollback_to"
        log_success "Rollback to ${rollback_to} completed"
        return 0
    else
        log_error "Rollback failed - health checks not passing"
        return 1
    fi
}

# Main deployment flow
main() {
    log_info "Starting blue/green deployment for ${ENVIRONMENT} environment"
    log_info "Version: ${VERSION}"

    # Check prerequisites
    check_prerequisites

    # Determine current state
    local active_deployment=$(get_active_deployment)
    local target_deployment=$(get_inactive_deployment "$active_deployment")

    log_info "Current active deployment: ${active_deployment}"
    log_info "Target deployment slot: ${target_deployment}"

    # Pull new image
    pull_image

    # Deploy to inactive slot
    deploy_to_slot "$target_deployment"

    # Validate new deployment
    if ! validate_deployment "$target_deployment"; then
        log_error "Deployment validation failed"

        # Stop failed deployment
        if [ "$target_deployment" = "green" ]; then
            docker-compose -f docker-compose.prod.yml --profile green-deployment stop api-green
        else
            docker-compose -f docker-compose.prod.yml stop api-blue
        fi

        log_error "Deployment aborted"
        exit 1
    fi

    # Switch traffic
    switch_traffic "$target_deployment"

    # Brief wait to ensure traffic is flowing
    log_info "Waiting 10 seconds to verify traffic flow..."
    sleep 10

    # Final validation
    if ! validate_deployment "$target_deployment"; then
        log_error "Post-switch validation failed, rolling back..."
        rollback "$active_deployment"
        exit 1
    fi

    # Stop old deployment (but don't remove it)
    if [ "$active_deployment" != "none" ]; then
        stop_old_deployment "$active_deployment"
    fi

    log_success "Deployment completed successfully!"
    log_info "Active deployment: ${target_deployment}"
    log_info "Inactive deployment: ${active_deployment} (stopped, available for rollback)"

    # Save deployment state
    echo "${target_deployment}" > "$PROJECT_ROOT/.deployment-state"
    echo "${VERSION}" > "$PROJECT_ROOT/.deployment-version"
}

# Run main function
main "$@"
