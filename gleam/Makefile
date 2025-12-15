# Meal Planner Makefile
# Convenient shortcuts for common development tasks

.PHONY: help build test test-integration test-unit setup-test clean lint format check

# Default target
help:
	@echo "Meal Planner Development Commands"
	@echo ""
	@echo "Testing:"
	@echo "  make test              - Run all tests (with infrastructure setup)"
	@echo "  make test-integration  - Run integration tests only"
	@echo "  make test-unit         - Run unit tests only"
	@echo "  make setup-test        - Setup test infrastructure only"
	@echo ""
	@echo "Development:"
	@echo "  make build            - Build the project"
	@echo "  make format           - Format code"
	@echo "  make check            - Type check without building"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make clean-test       - Stop test infrastructure"
	@echo "  make clean-all        - Clean everything (including test volumes)"

# Build the project
build:
	gleam build

# Run all tests with automatic infrastructure setup
test:
	@echo "🚀 Running all tests with infrastructure setup..."
	gleam test --target erlang

# Run integration tests only
test-integration:
	@echo "🚀 Running integration tests..."
	../scripts/run-all-tests.sh integration

# Run unit tests only (skip integration)
test-unit:
	@echo "📝 Running unit tests only..."
	gleam test --target erlang -- --exclude integration

# Setup test infrastructure manually
setup-test:
	@echo "🔧 Setting up test infrastructure..."
	../scripts/setup-integration-tests.sh setup

# Clean build artifacts
clean:
	gleam clean
	rm -rf build/

# Stop test infrastructure
clean-test:
	@echo "🛑 Stopping test infrastructure..."
	../scripts/setup-integration-tests.sh stop

# Full cleanup (including test volumes)
clean-all: clean
	@echo "🧹 Cleaning all test data..."
	../scripts/setup-integration-tests.sh cleanup

# Format code
format:
	gleam format

# Type check
check:
	gleam check

# Show test infrastructure status
status:
	@../scripts/setup-integration-tests.sh status

# Show test logs
logs:
	@../scripts/setup-integration-tests.sh logs
