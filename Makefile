# Meal Planner - Make commands
# Run with: make <target>

.PHONY: test test-all test-live test-properties build fmt check run clean

.DEFAULT_GOAL := test

# Fast parallel tests (0.8s) - filters out slow integration tests
test:
	gleam run -m test_runner/fast

# All tests including slow integration tests
test-all:
	gleam test

# Live integration tests - requires valid FatSecret credentials in environment
# Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET before running
# Tests will skip gracefully if credentials are not configured
test-live:
	gleam test

# Property-based tests only (qcheck generators, 100 iterations each)
test-properties:
	gleam run -m test_runner/properties

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
