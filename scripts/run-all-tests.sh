#!/bin/bash
# Complete Test Runner - Sets up infrastructure then runs tests
# This ensures everything is stood up BEFORE running integration tests

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GLEAM_DIR="$PROJECT_ROOT/gleam"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Setup infrastructure
print_info "Step 1/3: Setting up integration test infrastructure..."
echo ""

if ! "$SCRIPT_DIR/setup-integration-tests.sh" setup; then
    print_error "Infrastructure setup failed"
    exit 1
fi

echo ""
print_success "Infrastructure is ready"
echo ""

# Step 2: Source environment
print_info "Step 2/3: Loading test environment..."

if [ -f "$GLEAM_DIR/.env.test" ]; then
    set -a
    source "$GLEAM_DIR/.env.test"
    set +a
    print_success "Environment loaded from .env.test"
else
    print_error ".env.test not found"
    print_error "Run: $SCRIPT_DIR/setup-integration-tests.sh setup"
    exit 1
fi

echo ""

# Step 3: Run tests
print_info "Step 3/3: Running integration tests..."
echo ""

cd "$GLEAM_DIR"

# Determine what tests to run
TEST_TARGET="${1:-all}"

case "$TEST_TARGET" in
    all)
        print_info "Running all tests..."
        gleam test --target erlang
        ;;
    integration)
        print_info "Running integration tests only..."
        gleam test --target erlang -- --module tandoor/integration
        ;;
    keyword)
        print_info "Running keyword integration tests..."
        gleam test --target erlang meal_planner/tandoor/integration/keyword_integration_test
        ;;
    recipe)
        print_info "Running recipe integration tests..."
        gleam test --target erlang meal_planner/tandoor/integration/recipes_integration_test
        ;;
    supermarket)
        print_info "Running supermarket integration tests..."
        gleam test --target erlang meal_planner/tandoor/integration/supermarket_test
        gleam test --target erlang meal_planner/tandoor/integration/supermarket_category_test
        ;;
    unit)
        print_info "Running unit tests only..."
        gleam test --target erlang -- --exclude integration
        ;;
    *)
        print_info "Running tests matching: $TEST_TARGET"
        gleam test --target erlang "$TEST_TARGET"
        ;;
esac

TEST_EXIT_CODE=$?

echo ""

if [ $TEST_EXIT_CODE -eq 0 ]; then
    print_success "All tests passed!"
    echo ""
    print_info "Services are still running. To stop them:"
    echo "  $SCRIPT_DIR/setup-integration-tests.sh stop"
else
    print_error "Tests failed with exit code $TEST_EXIT_CODE"
    echo ""
    print_info "Check logs with:"
    echo "  $SCRIPT_DIR/setup-integration-tests.sh logs"
    exit $TEST_EXIT_CODE
fi
