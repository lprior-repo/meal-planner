#!/bin/bash
# Integration Test Infrastructure Setup Script
# Ensures all services are running BEFORE executing tests

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GLEAM_DIR="$PROJECT_ROOT/gleam"
COMPOSE_FILE="$GLEAM_DIR/docker-compose.test.yml"
ENV_TEST_FILE="$GLEAM_DIR/.env.test"
TANDOOR_URL="http://localhost:8100"
TANDOOR_USER="admin"
TANDOOR_PASS="admin"
MAX_WAIT=120  # Maximum wait time in seconds

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    local missing_deps=()

    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing_deps+=("docker-compose")
    fi

    if ! command -v gleam &> /dev/null; then
        missing_deps+=("gleam")
    fi

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_error "Please install the missing dependencies and try again."
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker and try again."
        exit 1
    fi

    print_success "All prerequisites satisfied"
}

# Function to detect docker-compose command
get_docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        echo "docker-compose"
    else
        echo "docker compose"
    fi
}

# Function to check if services are already running
check_existing_services() {
    print_info "Checking for existing services..."

    local compose_cmd=$(get_docker_compose_cmd)

    if [ -f "$COMPOSE_FILE" ]; then
        cd "$GLEAM_DIR"
        local running=$($compose_cmd -f docker-compose.test.yml ps -q 2>/dev/null | wc -l)

        if [ "$running" -gt 0 ]; then
            print_warning "Found $running running service(s)"
            return 0
        fi
    fi

    return 1
}

# Function to start Docker services
start_services() {
    print_info "Starting Docker services..."

    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi

    cd "$GLEAM_DIR"
    local compose_cmd=$(get_docker_compose_cmd)

    print_info "Using compose file: $COMPOSE_FILE"
    $compose_cmd -f docker-compose.test.yml up -d

    print_success "Docker services started"
}

# Function to wait for service health
wait_for_service() {
    local service_name=$1
    local health_check=$2
    local wait_seconds=${3:-$MAX_WAIT}

    print_info "Waiting for $service_name to be healthy (max ${wait_seconds}s)..."

    local elapsed=0
    local interval=2

    while [ $elapsed -lt $wait_seconds ]; do
        if eval "$health_check" &> /dev/null; then
            print_success "$service_name is healthy"
            return 0
        fi

        echo -n "."
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    echo ""
    print_error "$service_name failed to become healthy within ${wait_seconds}s"
    return 1
}

# Function to wait for PostgreSQL
wait_for_postgres() {
    wait_for_service "PostgreSQL" \
        "docker exec tandoor_test_db pg_isready -U tandoor" \
        30
}

# Function to wait for Tandoor
wait_for_tandoor() {
    wait_for_service "Tandoor Recipe Manager" \
        "curl -sf $TANDOOR_URL/ > /dev/null" \
        $MAX_WAIT
}

# Function to get or create API token
get_api_token() {
    print_info "Obtaining Tandoor API token..."

    # Wait a bit more for API to be fully ready
    sleep 5

    # Try to get token via API
    local response=$(curl -s -X POST "$TANDOOR_URL/api-token-auth/" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$TANDOOR_USER\",\"password\":\"$TANDOOR_PASS\"}" 2>/dev/null)

    local token=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

    if [ -n "$token" ]; then
        print_success "API token obtained successfully"
        echo "$token"
        return 0
    else
        print_warning "Could not obtain API token automatically"
        print_warning "Response: $response"
        print_info "Please obtain token manually from: $TANDOOR_URL"
        print_info "1. Login with username: $TANDOOR_USER, password: $TANDOOR_PASS"
        print_info "2. Go to Settings → API → Generate Token"
        print_info "3. Copy the token and set it in $ENV_TEST_FILE"
        return 1
    fi
}

# Function to create .env.test file
create_env_file() {
    local token=$1

    print_info "Creating $ENV_TEST_FILE..."

    cat > "$ENV_TEST_FILE" <<EOF
# Tandoor Test Configuration
# Auto-generated by setup-integration-tests.sh
# Generated: $(date)

TANDOOR_TEST_URL=$TANDOOR_URL
TANDOOR_TEST_USER=$TANDOOR_USER
TANDOOR_TEST_PASS=$TANDOOR_PASS
EOF

    if [ -n "$token" ]; then
        echo "TANDOOR_TEST_TOKEN=$token" >> "$ENV_TEST_FILE"
        echo "" >> "$ENV_TEST_FILE"
        echo "# Alternative configuration for Bearer auth" >> "$ENV_TEST_FILE"
        echo "TANDOOR_URL=$TANDOOR_URL" >> "$ENV_TEST_FILE"
        echo "TANDOOR_TOKEN=$token" >> "$ENV_TEST_FILE"
    else
        echo "# TANDOOR_TEST_TOKEN=<manually-add-token-here>" >> "$ENV_TEST_FILE"
        echo "" >> "$ENV_TEST_FILE"
        echo "# Alternative configuration for Bearer auth" >> "$ENV_TEST_FILE"
        echo "# TANDOOR_URL=$TANDOOR_URL" >> "$ENV_TEST_FILE"
        echo "# TANDOOR_TOKEN=<manually-add-token-here>" >> "$ENV_TEST_FILE"
    fi

    print_success "Environment file created: $ENV_TEST_FILE"
}

# Function to verify setup
verify_setup() {
    print_info "Verifying setup..."

    local errors=0

    # Check if services are running
    cd "$GLEAM_DIR"
    local compose_cmd=$(get_docker_compose_cmd)
    local running=$($compose_cmd -f docker-compose.test.yml ps -q 2>/dev/null | wc -l)

    if [ "$running" -eq 0 ]; then
        print_error "No Docker services are running"
        errors=$((errors + 1))
    else
        print_success "$running Docker service(s) running"
    fi

    # Check if Tandoor is accessible
    if curl -sf "$TANDOOR_URL/" > /dev/null; then
        print_success "Tandoor is accessible at $TANDOOR_URL"
    else
        print_error "Tandoor is not accessible at $TANDOOR_URL"
        errors=$((errors + 1))
    fi

    # Check if .env.test exists
    if [ -f "$ENV_TEST_FILE" ]; then
        print_success "Environment file exists: $ENV_TEST_FILE"

        # Check if token is set
        if grep -q "^TANDOOR_TEST_TOKEN=.*[a-zA-Z0-9]" "$ENV_TEST_FILE"; then
            print_success "API token is configured"
        else
            print_warning "API token is not configured in $ENV_TEST_FILE"
            print_warning "You may need to add it manually"
        fi
    else
        print_error "Environment file not found: $ENV_TEST_FILE"
        errors=$((errors + 1))
    fi

    if [ $errors -eq 0 ]; then
        print_success "Setup verification passed"
        return 0
    else
        print_error "Setup verification failed with $errors error(s)"
        return 1
    fi
}

# Function to show service status
show_status() {
    print_info "Service Status:"
    echo ""

    cd "$GLEAM_DIR"
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd -f docker-compose.test.yml ps

    echo ""
    print_info "Configuration:"
    echo "  Tandoor URL: $TANDOOR_URL"
    echo "  Environment File: $ENV_TEST_FILE"
    echo "  Docker Compose: $COMPOSE_FILE"
}

# Function to show logs
show_logs() {
    local service=$1

    cd "$GLEAM_DIR"
    local compose_cmd=$(get_docker_compose_cmd)

    if [ -n "$service" ]; then
        print_info "Showing logs for $service..."
        $compose_cmd -f docker-compose.test.yml logs -f "$service"
    else
        print_info "Showing logs for all services..."
        $compose_cmd -f docker-compose.test.yml logs -f
    fi
}

# Function to stop services
stop_services() {
    print_info "Stopping Docker services..."

    cd "$GLEAM_DIR"
    local compose_cmd=$(get_docker_compose_cmd)
    $compose_cmd -f docker-compose.test.yml down

    print_success "Services stopped"
}

# Function to cleanup (stop and remove volumes)
cleanup_all() {
    print_warning "This will stop services and remove all data volumes"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning up all services and volumes..."

        cd "$GLEAM_DIR"
        local compose_cmd=$(get_docker_compose_cmd)
        $compose_cmd -f docker-compose.test.yml down -v

        if [ -f "$ENV_TEST_FILE" ]; then
            rm -f "$ENV_TEST_FILE"
            print_info "Removed $ENV_TEST_FILE"
        fi

        print_success "Cleanup complete"
    else
        print_info "Cleanup cancelled"
    fi
}

# Function to run full setup
full_setup() {
    print_info "Starting full integration test setup..."
    echo ""

    check_prerequisites

    if check_existing_services; then
        print_warning "Services are already running"
        read -p "Restart services? (y/N) " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            stop_services
        else
            print_info "Using existing services"
        fi
    fi

    # Ensure services are running
    cd "$GLEAM_DIR"
    local compose_cmd=$(get_docker_compose_cmd)
    local running=$($compose_cmd -f docker-compose.test.yml ps -q 2>/dev/null | wc -l)

    if [ "$running" -eq 0 ]; then
        start_services
    fi

    # Wait for services
    if ! wait_for_postgres; then
        print_error "PostgreSQL failed to start"
        exit 1
    fi

    if ! wait_for_tandoor; then
        print_error "Tandoor failed to start"
        print_info "Check logs with: $0 logs tandoor_test"
        exit 1
    fi

    # Get API token and create env file
    local token=$(get_api_token)
    create_env_file "$token"

    echo ""
    verify_setup

    echo ""
    print_success "Integration test infrastructure is ready!"
    echo ""
    print_info "Next steps:"
    echo "  1. Review configuration in: $ENV_TEST_FILE"
    echo "  2. Run tests with: cd $GLEAM_DIR && gleam test"
    echo "  3. Or use: $GLEAM_DIR/test/tandoor/integration/run-integration-tests.sh test"
    echo ""
    print_info "Useful commands:"
    echo "  Status:  $0 status"
    echo "  Logs:    $0 logs [service]"
    echo "  Stop:    $0 stop"
    echo "  Cleanup: $0 cleanup"
}

# Main command handler
case "${1:-setup}" in
    setup|start)
        full_setup
        ;;
    stop)
        stop_services
        ;;
    cleanup)
        cleanup_all
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    verify)
        verify_setup
        ;;
    token)
        get_api_token
        ;;
    help|--help|-h)
        echo "Integration Test Setup Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  setup      Full setup (default): start services, wait for health, configure env"
        echo "  start      Alias for setup"
        echo "  stop       Stop all services"
        echo "  cleanup    Stop services and remove all volumes"
        echo "  status     Show service status"
        echo "  logs       Show logs (optionally for specific service)"
        echo "  verify     Verify setup is correct"
        echo "  token      Get API token from Tandoor"
        echo "  help       Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 setup              # Full setup"
        echo "  $0 logs tandoor_test  # Show Tandoor logs"
        echo "  $0 status             # Check status"
        echo "  $0 cleanup            # Remove everything"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
