# Meal Planner - Make commands
# Run with: make <target>

.PHONY: test test-all test-live test-properties build fmt check run clean \
        cli-build cli-test cli-format cli-run cli-clean \
        ci-all lint pre-commit-install pre-commit-run

.DEFAULT_GOAL := test

# ===============================================
# Core Build & Test Targets
# ===============================================

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

# ===============================================
# CLI-Specific Targets
# ===============================================

# Build CLI binary
cli-build: clean
	gleam build --target erlang
	@echo "CLI build successful"

# Run CLI tests (fast + properties)
cli-test: build
	gleam run -m test_runner/fast
	gleam run -m test_runner/properties
	@echo "CLI tests passed"

# Format and validate all code
cli-format: fmt check
	@echo "Code formatting validated"

# Run the CLI application
cli-run: build
	gleam run

# Clean CLI artifacts
cli-clean:
	rm -rf build ebin priv
	find . -name "*.beam" -delete
	find . -name "*.erl" -delete
	@echo "CLI artifacts cleaned"

# ===============================================
# CI/CD Pipeline Targets
# ===============================================

# Run complete CI pipeline (used in GitHub Actions)
ci-all: build check test cli-test
	@echo "✓ All CI checks passed"

# Lint and validate code quality
lint: check build
	@echo "✓ Linting passed"

# ===============================================
# Git Hooks
# ===============================================

# Install pre-commit hooks
pre-commit-install:
	@mkdir -p .git/hooks
	@echo "Installing pre-commit hooks..."
	@cat > .git/hooks/pre-commit << 'EOF'
#!/bin/sh
# Pre-commit hook: format check and fast tests
set -e

echo "Running pre-commit checks..."

# Check formatting
echo "  • Checking code formatting..."
gleam format --check

# Build check
echo "  • Building project..."
gleam build

# Fast tests
echo "  • Running fast tests..."
gleam run -m test_runner/fast

echo "✓ Pre-commit checks passed"
EOF
	@chmod +x .git/hooks/pre-commit
	@echo "Pre-commit hooks installed"

# Run pre-commit checks manually
pre-commit-run: check build test
	@echo "✓ Pre-commit checks passed"

# ===============================================
# Development Helpers
# ===============================================

# Watch mode (requires entr or similar)
watch:
	@if command -v entr > /dev/null; then \
		find src test -name "*.gleam" | entr -r make test; \
	else \
		echo "Install 'entr' for watch mode: brew install entr"; \
	fi

# Full development check
dev-check: cli-format lint test
	@echo "✓ Development checks passed"
