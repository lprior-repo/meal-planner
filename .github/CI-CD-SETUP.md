# CI/CD Pipeline & Dev Tools Setup

Complete guide to the Meal Planner CI/CD infrastructure and development tools.

## Overview

This project implements a comprehensive CI/CD pipeline using GitHub Actions with the following components:

- **GitHub Actions Workflows** - Automated testing and deployment
- **Makefile Targets** - Local development commands
- **Pre-commit Hooks** - Enforce quality before commits
- **Environment Configuration** - Centralized .env management
- **Smoke Tests** - Quick validation scripts

---

## Files Created

### GitHub Actions Workflows (`.github/workflows/`)

1. **cli-test.yml** - Main test pipeline
   - Runs on: Push to main/develop, PR to main/develop
   - Jobs:
     - Test (gleam build, format check, tests)
     - Code Quality (type checking, formatting)
   - Duration: ~30 minutes
   - Requirements: PostgreSQL service

2. **release.yml** - Release/deployment pipeline
   - Runs on: Push to main, tagged releases
   - Jobs:
     - Test (full test suite)
     - Build (release artifacts)
     - Publish (GitHub Releases)
   - Creates versioned artifacts

3. **dependabot.yml** - Dependency updates
   - Weekly checks for updates
   - Gleam, GitHub Actions, Docker
   - Auto-creates PRs for newer versions

### Configuration Files

1. **.pre-commit-config.yaml** - Git hooks configuration
   - Gleam formatting, type checking, fast tests
   - YAML/JSON validation
   - Conventional commit enforcement

2. **.env.example** - Environment template
   - Database configuration
   - API credentials
   - Service URLs
   - Development settings

3. **Makefile** - Build and test automation
   - CLI build/test/format targets
   - CI/CD pipeline targets
   - Pre-commit hook installation

### Documentation

1. **DEVELOPMENT.md** - Development guide
   - Setup instructions
   - Make command reference
   - Testing guide
   - Troubleshooting

2. **TESTING.md** - Testing strategy
   - Test categories (unit, integration, property)
   - Writing tests
   - Test fixtures
   - Coverage expectations

3. **CI-CD-SETUP.md** - This file

### Scripts

1. **scripts/cli-smoke-tests.sh** - Quick validation
   - Build verification
   - Format checking
   - Basic tests
   - File structure checks

---

## Quick Start

### 1. Initial Setup

```bash
cd /home/lewis/src/meal-planner

# Copy env template
cp .env.example .env

# Edit for your environment
nano .env

# Install pre-commit hooks
make pre-commit-install

# Verify everything works
make dev-check
```

### 2. Daily Development

```bash
# Before work
git pull origin main

# Make changes and test
make test          # Fast tests
make dev-check    # Full check (format + lint + test)

# Commit (pre-commit hooks run automatically)
git commit -m "feat: your feature"

# Push (triggers GitHub Actions)
git push origin feature-branch
```

### 3. Before Pull Request

```bash
# Ensure everything passes
make ci-all

# View results
git log --oneline | head -5
```

---

## Make Commands Reference

### Build

```bash
make build              # Build project
make cli-build          # Clean build for CLI
make clean              # Remove all artifacts
```

### Testing

```bash
make test               # Fast unit tests (~0.8s)
make test-all          # All tests including integration
make test-properties   # Property-based tests
make cli-test          # All CLI tests
```

### Code Quality

```bash
make fmt               # Format code
make check             # Check formatting
make lint              # Format + build check
make dev-check         # Complete development check
```

### Running

```bash
make run               # Start development server
make cli-run           # Run CLI application
make watch             # Watch mode (requires entr)
```

### Git Hooks

```bash
make pre-commit-install    # Install hooks
make pre-commit-run        # Run checks manually
```

### CI/CD

```bash
make ci-all            # Run complete CI pipeline
```

---

## GitHub Actions Workflows

### cli-test.yml (Main Pipeline)

**Triggers**:
- Push to `main` or `develop`
- Pull request to `main` or `develop`

**Jobs**:

1. **Test Job** (timeout: 30min)
   ```
   PostgreSQL Service (port 5432)
   ↓
   Setup Gleam 1.4.0 + Erlang 27
   ↓
   Cache dependencies
   ↓
   gleam build
   ↓
   gleam format --check
   ↓
   gleam test
   ↓
   CLI smoke tests
   ```

2. **Code Quality Job** (timeout: 15min)
   ```
   Setup Gleam 1.4.0 + Erlang 27
   ↓
   gleam build (type checking)
   ↓
   gleam format --check (formatting)
   ```

**Environment**:
- Ubuntu latest
- PostgreSQL 15 Alpine
- OTP 27, Gleam 1.4.0, Elixir 1.17

**Success Criteria**:
- Build succeeds ✓
- All tests pass ✓
- Code formatted correctly ✓
- No type errors ✓

### release.yml (Release Pipeline)

**Triggers**:
- Push to `main`
- Tag push `v*`
- Manual workflow dispatch

**Jobs**:

1. **Test** - Runs full test suite
2. **Build** - Creates release artifacts
3. **Publish** - Creates GitHub Release with artifacts

**Artifacts**:
- Build directory with compiled code
- VERSION file with git describe output
- 30-day retention

---

## Pre-commit Hooks

### Installation

```bash
# Automatic via Make
make pre-commit-install

# Manual with pre-commit framework
pip install pre-commit
pre-commit install

# Manual git hook
# Creates .git/hooks/pre-commit (created by make)
```

### What Runs Before Each Commit

1. **Code Formatting**
   ```bash
   gleam format --check
   ```

2. **Type Checking**
   ```bash
   gleam build
   ```

3. **Fast Tests**
   ```bash
   gleam run -m test_runner/fast
   ```

4. **File Validation**
   - YAML syntax
   - JSON syntax
   - No trailing whitespace
   - No private keys

5. **Conventional Commits**
   - Enforce commit message format
   - Example: `feat: add feature` or `fix: resolve issue`

### Bypass (Emergency Only)

```bash
git commit --no-verify
```

### Manual Execution

```bash
# Run all pre-commit checks
make pre-commit-run

# Run specific hook
bash .git/hooks/pre-commit
```

---

## Environment Configuration

### Location

- **Template**: `.env.example` (checked into git)
- **Local**: `.env` (NOT checked in, personal config)

### Key Sections

1. **Core Settings**
   - `ENVIRONMENT` - development/staging/production
   - `PORT` - HTTP port (default 8080)
   - `LOG_LEVEL` - debug/info/warn/error

2. **Database**
   - `DATABASE_*` - Connection details
   - `TEST_DATABASE_URL` - Test database

3. **Tandoor Integration**
   - `TANDOOR_BASE_URL` - Recipe API endpoint
   - `TANDOOR_API_TOKEN` - API credentials

4. **FatSecret Integration**
   - `FATSECRET_CONSUMER_KEY` - OAuth key
   - `FATSECRET_CONSUMER_SECRET` - OAuth secret
   - `OAUTH_ENCRYPTION_KEY` - Token encryption

5. **Optional Services**
   - `TODOIST_API_KEY` - Task management
   - `USDA_API_KEY` - Food database
   - `OPENAI_API_KEY` - AI features

### Setup Instructions

```bash
# Copy template
cp .env.example .env

# Edit with your credentials
# Database: localhost (development)
# APIs: Get credentials from each service
nano .env

# Source before running
source .env
make run
```

---

## Smoke Tests

### Purpose

Quick validation that project builds and runs correctly.

### Location

`scripts/cli-smoke-tests.sh`

### What It Tests

- ✓ `gleam build` succeeds
- ✓ `gleam format --check` passes
- ✓ Fast test suite passes
- ✓ Key files exist
- ✓ Dependencies can be downloaded
- ✓ CLI entry point exists
- ✓ Test files compile

### Running Manually

```bash
bash scripts/cli-smoke-tests.sh
```

### Output

```
==================================
CLI Smoke Tests
==================================

=== Build Tests ===
Testing: gleam build... ✓ PASS

=== Code Quality Tests ===
Testing: gleam format --check... ✓ PASS

=== Unit Tests ===
Testing: fast test suite... ✓ PASS

=== File Structure Tests ===
Testing: gleam.toml exists... ✓ PASS
Testing: Makefile exists... ✓ PASS
...

==================================
Test Summary
==================================
Passed: 15
Failed: 0

✓ All smoke tests passed!
```

---

## Troubleshooting

### GitHub Actions Failures

#### Problem: Tests fail in CI but pass locally

**Solution**:
```bash
# Verify you're on same Gleam version
gleam --version  # Should be 1.4.0+

# Update dependencies
gleam deps download

# Run all tests locally
make test-all

# Check environment variables
env | grep DATABASE
```

#### Problem: PostgreSQL connection timeout

**Solution**:
- Check `TEST_DATABASE_URL` environment variable
- Verify PostgreSQL is running: `psql --version`
- Check database exists: `createdb meal_planner_test`

#### Problem: Code formatting failed in CI

**Solution**:
```bash
# Auto-fix locally
make fmt

# Verify
make check

# Commit with formatting changes
git add .
git commit -m "style: format code"
```

### Local Development Issues

#### Pre-commit hooks not running

```bash
# Reinstall
make pre-commit-install

# Verify hook exists
ls -la .git/hooks/pre-commit

# Run manually
bash .git/hooks/pre-commit
```

#### Build fails with module errors

```bash
# Clean and rebuild
make clean
make build

# Download fresh dependencies
gleam deps download
gleam deps list
```

#### Tests hang or timeout

```bash
# Run with timeout
timeout 30 gleam test

# Run specific test
gleam test test/specific_test.gleam --verbose

# Check for infinite loops or blocking operations
```

---

## Development Workflow

### Standard Feature Development

```
1. Get ready task
   bd ready --json

2. Create feature branch
   git checkout -b feature/task-name

3. Implement with TDD
   - Write test first
   - Make implementation
   - Refactor for clarity

4. Verify locally
   make dev-check

5. Commit with hooks
   git commit -m "feat: description"

6. Push and create PR
   git push origin feature/task-name
   # GitHub Actions runs automatically

7. Review and merge
   # Checks must pass
   git merge feature/task-name

8. Close task
   bd close bd-xxxx --reason "Completed"
```

### Emergency Hotfix

```bash
# Create hotfix branch
git checkout -b hotfix/issue-name

# Make minimal change
# Test thoroughly
make test-all

# Commit
git commit -m "fix: description"

# Push and PR
git push origin hotfix/issue-name

# After merge, create patch release
git tag v1.0.1
git push origin v1.0.1
```

---

## Performance Optimization

### Faster Local Testing

```bash
# Use fast tests during development
make test  # 0.8s vs 5s+ for all tests

# Run specific test file only
gleam test test/specific_test.gleam

# Use watch mode to avoid rebuilds
make watch
```

### Faster CI Pipeline

The pipeline uses:
- Caching for dependencies (saves ~10s)
- Parallel job execution where possible
- PostgreSQL service for fast DB tests
- Separate code quality job for better resource use

---

## Security Considerations

### Secrets Management

1. **Never commit secrets** (enforced by pre-commit)
   ```bash
   # Will fail if you try to commit:
   OAUTH_ENCRYPTION_KEY=actual_secret_value
   ```

2. **Use GitHub Secrets for CI/CD**
   - Store in repo Settings > Secrets
   - Reference as `${{ secrets.SECRET_NAME }}`

3. **Local Development**
   - Keep `.env` in `.gitignore` ✓
   - Never share `.env` file
   - Rotate API keys regularly

### Dependency Security

Dependabot automatically:
- Checks for vulnerable packages
- Creates PRs for updates
- Includes security advisories

Review dependabot PRs carefully before merging.

---

## Monitoring & Metrics

### GitHub Actions Dashboard

View at: https://github.com/lprior-repo/meal-planner/actions

Shows:
- Build status
- Test results
- Execution time trends
- Artifact downloads

### Local Metrics

```bash
# Test coverage (if implemented)
gleam test --coverage
open coverage/index.html

# Build time
time gleam build

# Test execution time
time gleam test
```

---

## Next Steps

1. **Verify Setup**
   ```bash
   make ci-all
   ```

2. **Install Hooks**
   ```bash
   make pre-commit-install
   ```

3. **Read Documentation**
   - DEVELOPMENT.md - Day-to-day guide
   - TESTING.md - Testing strategy
   - This file - CI/CD details

4. **Start Development**
   ```bash
   git checkout -b feature/your-feature
   make test
   make dev-check
   ```

---

## Support & Resources

- **Gleam Documentation**: https://gleam.run/
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Project Issues**: https://github.com/lprior-repo/meal-planner/issues
- **Community**: https://gleam.run/news/

---

**Last Updated**: 2025-12-19
**Gleam Version**: 1.4.0+
**Status**: ✓ Ready for Production
