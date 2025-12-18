# Meal Planner - Make commands
# Run with: make <target>

.PHONY: test test-all build fmt check run clean

.DEFAULT_GOAL := test

# Fast parallel tests (0.8s) - filters out slow integration tests
test:
	gleam run -m test_runner/fast

# All tests including slow integration tests
test-all:
	gleam test

# Build the project
build:
	gleam build

# Format code
fmt:
	gleam format

# Check formatting without changing
check:
	gleam format --check

# Start the web server
run:
	gleam run

# Clean build artifacts
clean:
	rm -rf build
