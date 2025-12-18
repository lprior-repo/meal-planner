#!/usr/bin/env bash
# Integration Test Setup Script
#
# This script helps set up and run Tandoor SDK integration tests.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_COMPOSE_FILE="docker-compose.test.yml"
TANDOOR_URL="http://localhost:8100"
ENV_FILE=".env.test"

# Helper functions
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
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    if ! command -v gleam &> /dev/null; then
        log_error "Gleam is not installed. Please install Gleam first."
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Start Tandoor test instance
start_tandoor() {
    log_info "Starting Tandoor test instance..."
    
    docker-compose -f "$DOCKER_COMPOSE_FILE" up -d
    
    log_info "Waiting for services to be healthy..."
    
    # Wait for database
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T db_tandoor_test pg_isready -U tandoor &> /dev/null; then
            log_success "Database is ready"
            break
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log_error "Database failed to start"
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs db_tandoor_test
        exit 1
    fi
    
    # Wait for Tandoor
    log_info "Waiting for Tandoor to be ready..."
    attempt=0
    max_attempts=60
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -f -s "${TANDOOR_URL}/api/" &> /dev/null; then
            log_success "Tandoor is ready at ${TANDOOR_URL}"
            break
        fi
        
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    if [ $attempt -eq $max_attempts ]; then
        log_error "Tandoor failed to start"
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs tandoor_test
        exit 1
    fi
}

# Stop Tandoor test instance
stop_tandoor() {
    log_info "Stopping Tandoor test instance..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down
    log_success "Tandoor stopped"
}

# Clean up (remove volumes)
cleanup_tandoor() {
    log_info "Cleaning up Tandoor test instance (removing volumes)..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" down -v
    log_success "Cleanup complete"
}

# Get API token
get_api_token() {
    log_info "Getting API token..."
    
    # Wait a bit for Tandoor to fully initialize
    sleep 5
    
    # Try to get token via API
    local response
    response=$(curl -s -X POST "${TANDOOR_URL}/api-token-auth/" \
        -H "Content-Type: application/json" \
        -d '{"username":"admin","password":"admin"}' || echo "{}")
    
    local token
    token=$(echo "$response" | grep -o '"token":"[^"]*' | sed 's/"token":"//')
    
    if [ -n "$token" ] && [ "$token" != "{}" ]; then
        log_success "API token obtained"
        echo "$token"
    else
        log_warning "Could not obtain API token automatically"
        log_info "Please:"
        log_info "1. Visit ${TANDOOR_URL}"
        log_info "2. Login with admin/admin"
        log_info "3. Go to Settings → API → Generate Token"
        log_info "4. Add token to ${ENV_FILE}"
        echo ""
    fi
}

# Create .env.test file
create_env_file() {
    if [ -f "$ENV_FILE" ]; then
        log_warning "${ENV_FILE} already exists, skipping creation"
        return
    fi
    
    log_info "Creating ${ENV_FILE}..."
    
    local token
    token=$(get_api_token)
    
    cat > "$ENV_FILE" <<EOF
# Tandoor Test Instance Configuration
TANDOOR_TEST_URL=${TANDOOR_URL}
TANDOOR_TEST_TOKEN=${token}

# Session auth credentials
TANDOOR_TEST_USER=admin
TANDOOR_TEST_PASS=admin
EOF
    
    log_success "Created ${ENV_FILE}"
    
    if [ -z "$token" ]; then
        log_warning "Please update TANDOOR_TEST_TOKEN in ${ENV_FILE} manually"
    fi
}

# Run integration tests
run_tests() {
    local test_module="${1:-tandoor/integration}"
    
    log_info "Running integration tests: ${test_module}..."
    
    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        export $(cat "$ENV_FILE" | grep -v '^#' | xargs)
    else
        log_warning "${ENV_FILE} not found, tests may fail"
    fi
    
    # Run tests
    if gleam test --target erlang -- --module "$test_module"; then
        log_success "Tests passed!"
    else
        log_error "Tests failed"
        exit 1
    fi
}

# Show status
show_status() {
    log_info "Tandoor Test Instance Status:"
    echo ""
    docker-compose -f "$DOCKER_COMPOSE_FILE" ps
    echo ""
    
    if [ -f "$ENV_FILE" ]; then
        log_info "Environment file: ${ENV_FILE} exists"
    else
        log_warning "Environment file: ${ENV_FILE} not found"
    fi
    
    log_info "Tandoor URL: ${TANDOOR_URL}"
}

# Show logs
show_logs() {
    docker-compose -f "$DOCKER_COMPOSE_FILE" logs -f
}

# Main menu
show_usage() {
    cat <<EOF
Tandoor SDK Integration Test Helper

Usage: $0 [command]

Commands:
    setup       - Start Tandoor and create .env.test file
    start       - Start Tandoor test instance
    stop        - Stop Tandoor test instance
    cleanup     - Stop Tandoor and remove volumes
    test        - Run all integration tests
    test:recipe - Run recipe integration tests
    test:food   - Run food integration tests
    test:unit   - Run unit integration tests
    test:shopping - Run shopping integration tests
    test:supermarket - Run supermarket integration tests
    status      - Show Tandoor instance status
    logs        - Show Tandoor logs (follow mode)
    token       - Get API token
    help        - Show this help message

Examples:
    $0 setup              # First-time setup
    $0 test               # Run all tests
    $0 test:recipe        # Run only recipe tests
    $0 logs               # View logs

EOF
}

# Main script
main() {
    local command="${1:-help}"
    
    case "$command" in
        setup)
            check_prerequisites
            start_tandoor
            create_env_file
            log_success "Setup complete! Run '$0 test' to run tests"
            ;;
        start)
            check_prerequisites
            start_tandoor
            ;;
        stop)
            stop_tandoor
            ;;
        cleanup)
            cleanup_tandoor
            ;;
        test)
            run_tests "tandoor/integration"
            ;;
        test:recipe)
            run_tests "tandoor/integration/recipe_integration_test"
            ;;
        test:food)
            run_tests "tandoor/integration/food_integration_test"
            ;;
        test:unit)
            run_tests "tandoor/integration/unit_integration_test"
            ;;
        test:shopping)
            run_tests "tandoor/integration/shopping_integration_test"
            ;;
        test:supermarket)
            run_tests "tandoor/integration/supermarket_integration_test"
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        token)
            get_api_token
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
