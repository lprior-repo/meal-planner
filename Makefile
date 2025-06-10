# Makefile for meal planner application tests

.PHONY: all test lint test-unit test-integration test-e2e clean build run

# Default target
all: lint test build

# Build the application
build:
	go build -o bin/meal-planner main.go

# Run the application
run: build
	./bin/meal-planner

# Clean build artifacts
clean:
	rm -rf bin/
	go clean

# Run linter (static analysis)
lint:
	@echo "Running linter..."
	golangci-lint run ./...

# Run all tests
test: test-unit test-integration test-e2e

# Run unit tests
test-unit:
	@echo "Running unit tests..."
	go test -v ./tests/unit/...

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	go test -v ./tests/integration/...

# Run end-to-end tests
test-e2e:
	@echo "Running end-to-end tests..."
	go test -v ./tests/e2e/...

# Setup test environment
setup-test:
	@echo "Setting up test environment..."
	go mod tidy
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Create .env file for testing
create-test-env:
	@echo "Creating test .env file..."
	@echo "MAILTRAP_API_TOKEN=test-token" > .env.test
	@echo "SENDER_EMAIL=test@example.com" >> .env.test
	@echo "SENDER_NAME=Test Sender" >> .env.test
	@echo "RECIPIENT_EMAIL=recipient@example.com" >> .env.test

# Help target
help:
	@echo "Available targets:"
	@echo "  all              - Run lint, tests, and build the application"
	@echo "  build            - Build the application"
	@echo "  run              - Run the application"
	@echo "  clean            - Clean build artifacts"
	@echo "  lint             - Run linter (static analysis)"
	@echo "  test             - Run all tests"
	@echo "  test-unit        - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-e2e         - Run end-to-end tests only"
	@echo "  setup-test       - Set up test environment"
	@echo "  create-test-env  - Create test environment file"
	@echo "  help             - Show this help message"