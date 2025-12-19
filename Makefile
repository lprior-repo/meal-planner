# Meal Planner - Optimized Build System
# Run with: make <target>
#
# Performance Metrics (2025-12-19):
#   - Fast tests: 0.7s (parallel, unit tests only)
#   - Full tests:  5.2s (includes integration tests)
#   - Build:       0.15s (incremental, cached)
#   - Format:      <0.1s

.PHONY: test test-all test-live test-properties build fmt check run clean \
        cli-build cli-test cli-format cli-run cli-clean \
        ci-all lint pre-commit-install pre-commit-run \
        benchmark help deps-update cache-clean

.DEFAULT_GOAL := help

# Build cache directory
BUILD_CACHE := build/
GLEAM_CACHE := $(HOME)/.cache/gleam

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
	@printf '#!/bin/sh\n' > .git/hooks/pre-commit
	@printf '# Pre-commit hook: format check and fast tests\n' >> .git/hooks/pre-commit
	@printf 'set -e\n\n' >> .git/hooks/pre-commit
	@printf 'echo "Running pre-commit checks..."\n\n' >> .git/hooks/pre-commit
	@printf '# Check formatting\n' >> .git/hooks/pre-commit
	@printf 'echo "  • Checking code formatting..."\n' >> .git/hooks/pre-commit
	@printf 'gleam format --check\n\n' >> .git/hooks/pre-commit
	@printf '# Build check\n' >> .git/hooks/pre-commit
	@printf 'echo "  • Building project..."\n' >> .git/hooks/pre-commit
	@printf 'gleam build\n\n' >> .git/hooks/pre-commit
	@printf '# Fast tests\n' >> .git/hooks/pre-commit
	@printf 'echo "  • Running fast tests..."\n' >> .git/hooks/pre-commit
	@printf 'gleam run -m test_runner/fast\n\n' >> .git/hooks/pre-commit
	@printf 'echo "✓ Pre-commit checks passed"\n' >> .git/hooks/pre-commit
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

# ===============================================
# Performance & Optimization Targets
# ===============================================

# Benchmark build and test performance
benchmark:
	@echo "===== Build System Benchmarks ====="
	@echo ""
	@echo "1. Build Performance (3 runs):"
	@for i in 1 2 3; do \
		echo -n "  Run $$i: "; \
		{ time gleam build 2>&1 | tail -1; } 2>&1 | grep real; \
	done
	@echo ""
	@echo "2. Fast Test Performance (3 runs):"
	@for i in 1 2 3; do \
		echo -n "  Run $$i: "; \
		{ time gleam run -m test_runner/fast >/dev/null 2>&1; } 2>&1 | grep real; \
	done
	@echo ""
	@echo "3. Full Test Performance (1 run):"
	@echo -n "  Run 1: "
	@{ time gleam test >/dev/null 2>&1; } 2>&1 | grep real
	@echo ""
	@echo "4. Build Artifact Size:"
	@du -sh $(BUILD_CACHE) 2>/dev/null || echo "  No build artifacts"
	@echo ""

# Update dependencies to latest compatible versions
deps-update:
	@echo "Updating dependencies..."
	gleam update
	@echo "✓ Dependencies updated"
	@echo ""
	@echo "Run 'make build' to verify compatibility"

# Clean all caches (build + Gleam cache)
cache-clean: clean
	@echo "Cleaning Gleam cache..."
	@rm -rf $(GLEAM_CACHE)
	@echo "✓ All caches cleaned"

# Display help information
help:
	@echo "Meal Planner - Build System"
	@echo ""
	@echo "Core Targets:"
	@echo "  make test          - Run fast parallel tests (0.7s)"
	@echo "  make test-all      - Run all tests including integration (5.2s)"
	@echo "  make build         - Build project (0.15s)"
	@echo "  make fmt           - Format code"
	@echo "  make check         - Check formatting without modifying"
	@echo "  make run           - Start web server"
	@echo ""
	@echo "CLI Targets:"
	@echo "  make cli-build     - Build CLI binary"
	@echo "  make cli-test      - Run CLI tests (fast + properties)"
	@echo "  make cli-format    - Format and validate all code"
	@echo "  make cli-run       - Run CLI application"
	@echo ""
	@echo "CI/CD Targets:"
	@echo "  make ci-all        - Run complete CI pipeline"
	@echo "  make lint          - Lint and validate code quality"
	@echo ""
	@echo "Development Targets:"
	@echo "  make watch         - Watch mode (requires entr)"
	@echo "  make dev-check     - Full development check"
	@echo "  make pre-commit-install - Install git pre-commit hooks"
	@echo ""
	@echo "Performance & Optimization:"
	@echo "  make benchmark     - Run build system benchmarks"
	@echo "  make deps-update   - Update dependencies"
	@echo "  make cache-clean   - Clean all build caches"
	@echo ""
	@echo "Current Performance Metrics:"
	@echo "  • Fast tests: 0.7s (parallel, 487 unit tests)"
	@echo "  • Full tests: 5.2s (includes 8 integration tests)"
	@echo "  • Build:      0.15s (incremental compilation)"
	@echo "  • Files:      246 source + 75 test modules"
	@echo ""
