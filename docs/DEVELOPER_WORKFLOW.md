# Developer Workflow Improvements

## Overview

This document outlines optimized developer workflows for the Meal Planner project, designed to maximize productivity and minimize friction.

## Quick Start

### First-Time Setup

```bash
# Clone repository
git clone git@github.com:lprior-repo/meal-planner.git
cd meal-planner

# Install dependencies
gleam deps download

# Build project
make build

# Run fast tests
make test

# Install pre-commit hooks (recommended)
make pre-commit-install
```

**Time to First Success**: <2 minutes

---

## Development Workflows

### 1. TDD Fast Cycle (Recommended)

**Goal**: Sub-second feedback loop for unit testing

**Setup** (once):
```bash
# Terminal 1: Watch mode
make watch
```

**Workflow**:
```
Edit code → Save → Auto-run tests (0.7s) → Repeat
```

**Benefits**:
- Immediate feedback (0.7s)
- No manual commands
- Catches issues early
- Flow state preservation

**Requirements**:
- Install `entr`: `sudo pacman -S entr` (Arch) or `brew install entr` (macOS)

---

### 2. Manual TDD Cycle

**Goal**: Explicit control over test execution

**Workflow**:
```bash
# 1. Write failing test
vim test/my_module_test.gleam

# 2. Run fast tests (0.7s)
make test

# 3. Implement feature
vim src/my_module.gleam

# 4. Run fast tests (0.7s)
make test

# 5. Refactor
vim src/my_module.gleam

# 6. Run fast tests (0.7s)
make test

# 7. Full test suite before commit (5.2s)
make test-all

# 8. Format and commit
make fmt
git add .
git commit -m "Add feature X"
```

**Benefits**:
- Explicit test execution
- Clear feedback points
- Controlled pacing

---

### 3. Integration Test Workflow

**Goal**: Test with real database

**Setup** (once):
```bash
# Start PostgreSQL (if not running)
sudo systemctl start postgresql

# Create test database
createdb meal_planner_test

# Set environment variable
export DATABASE_URL="postgresql://localhost/meal_planner_test"
```

**Workflow**:
```bash
# Run all tests including integration (5.2s)
make test-all

# Or run only integration tests
gleam test --filter integration
```

---

### 4. Property-Based Testing Workflow

**Goal**: Discover edge cases with generated inputs

**Workflow**:
```bash
# Run property tests (qcheck, 100 iterations)
make test-properties

# Adjust iterations in test file:
# qcheck.run(config: qcheck.default_config() |> qcheck.iterations(1000), ...)
```

**Best Practices**:
- Start with 100 iterations
- Increase for critical code paths
- Use shrinking to find minimal failing case

---

## Pre-Commit Workflow

### Automatic (Recommended)

**Setup** (once):
```bash
make pre-commit-install
```

**Workflow**:
```bash
git add .
git commit -m "Your message"
# Automatically runs:
#   1. Format check (0.1s)
#   2. Build check (0.15s)
#   3. Fast tests (0.7s)
# Total: ~1s
```

**Benefits**:
- Catches issues before CI
- Fast enough not to disrupt flow
- Enforces code quality

**Bypass** (emergency only):
```bash
git commit --no-verify -m "Emergency fix"
```

---

### Manual

**Workflow**:
```bash
# Run pre-commit checks manually
make pre-commit-run

# Or step-by-step:
make check      # Format check (0.1s)
make build      # Type check (0.15s)
make test       # Fast tests (0.7s)
```

---

## Code Quality Workflow

### Formatting

**Auto-format** (recommended):
```bash
make fmt
```

**Check only** (CI mode):
```bash
make check
```

**Gleam Style**:
- Automatic formatting enforced
- No configuration needed
- Consistent across team

---

### Linting

**Run lint checks**:
```bash
make lint
```

**Includes**:
- Format validation
- Type checking
- Build verification

---

## Performance Optimization Workflow

### Benchmarking

**Run benchmarks**:
```bash
make benchmark
```

**Output**:
```
===== Build System Benchmarks =====

1. Build Performance (3 runs):
  Run 1: real 0m0.110s
  ...

2. Fast Test Performance (3 runs):
  ...

3. Full Test Performance (1 run):
  ...

4. Build Artifact Size:
  27M build/
```

**Use Cases**:
- Detect performance regressions
- Validate optimization efforts
- Compare before/after refactoring

---

### Profiling Tests

**Identify slow tests**:
```bash
gleam test --verbose
```

**Profile specific module**:
```bash
gleam run -m test_runner/fast --verbose 2>&1 | grep -E "module|done in"
```

---

## Dependency Management

### Update Dependencies

**Update to latest compatible versions**:
```bash
make deps-update
```

**Verify compatibility**:
```bash
make build
make test-all
```

**Review changes**:
```bash
git diff manifest.toml
```

---

### Audit Dependencies

**List all dependencies**:
```bash
gleam deps list
```

**Check for unused dependencies**:
```bash
# Manual review of gleam.toml
# Remove unused packages
# Run: make build test-all
```

---

### Clean Build

**Clean all caches**:
```bash
make cache-clean
```

**Rebuild from scratch**:
```bash
make cache-clean
gleam deps download
make build
make test-all
```

---

## CLI Development Workflow

### Build CLI

```bash
make cli-build
```

**Output**: `build/dev/erlang/meal_planner/_gleam_artefacts/mp.erl`

---

### Run CLI

```bash
make cli-run
# Or directly:
./build/dev/erlang/meal_planner/_gleam_artefacts/mp --help
```

---

### Test CLI

```bash
make cli-test
```

**Includes**:
- Fast unit tests
- Property-based tests
- CLI argument parsing tests

---

## Git Workflow

### Branch Strategy

**Main Branches**:
- `main` - Production-ready code
- `develop` - Integration branch (if using)

**Feature Branches**:
```
feature/BD-XXX-short-description
bugfix/BD-XXX-short-description
refactor/BD-XXX-short-description
```

**Workflow**:
```bash
# Create feature branch
git checkout -b feature/BD-123-add-recipe-export

# Make changes
vim src/...

# Commit (triggers pre-commit hooks)
git commit -m "GREEN: Implement recipe export"

# Push and create PR
git push -u origin feature/BD-123-add-recipe-export
```

---

### Commit Message Guidelines

**Format**:
```
<TYPE>: <Description>

<Optional body>
```

**Types**:
- `RED`: Failing test (TDD red phase)
- `GREEN`: Implementation (TDD green phase)
- `BLUE`: Refactor (TDD blue phase)
- `FIX`: Bug fix
- `ADD`: New feature
- `UPDATE`: Modify existing feature
- `REMOVE`: Delete code/feature
- `DOCS`: Documentation only

**Examples**:
```
RED: Add test for recipe export to JSON

GREEN: Implement recipe export to JSON format

BLUE: Extract JSON encoding into separate module

FIX: Handle null values in recipe ingredients
```

---

## Troubleshooting Workflows

### Build Failures

**Symptom**: `gleam build` fails

**Diagnosis**:
```bash
# Clean build
make cache-clean
gleam deps download
gleam build --verbose
```

**Common Causes**:
- Stale cache
- Dependency version conflict
- Missing type annotations

---

### Test Failures

**Symptom**: Tests fail locally

**Diagnosis**:
```bash
# Run specific test module
gleam test --filter my_module

# Run with verbose output
gleam test --verbose

# Check for environment issues
env | grep -E "(DATABASE|TEST)"
```

**Common Causes**:
- Database not running
- Environment variables not set
- Test isolation issues

---

### Slow Build/Tests

**Symptom**: Build/tests take longer than expected

**Diagnosis**:
```bash
# Benchmark current performance
make benchmark

# Check for slow tests
gleam test --verbose | grep -E "done in [0-9]+\.[5-9]"
```

**Solutions**:
- Clean caches: `make cache-clean`
- Review slow tests for optimization
- Check system resources (CPU, RAM)

---

## IDE Integration

### VS Code

**Extensions**:
- Gleam Extension (official)
- Erlang Extension (for BEAM support)

**Settings** (`.vscode/settings.json`):
```json
{
  "gleam.enableFormatOnSave": true,
  "gleam.enableDiagnostics": true
}
```

**Tasks** (`.vscode/tasks.json`):
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Fast Tests",
      "type": "shell",
      "command": "make test",
      "group": {
        "kind": "test",
        "isDefault": true
      }
    }
  ]
}
```

---

### Vim/Neovim

**Plugins**:
- `vim-gleam` (syntax highlighting)
- `ale` or `coc.nvim` (LSP support)

**Key Bindings** (`.vimrc`):
```vim
" Run fast tests
nnoremap <leader>t :!make test<CR>

" Format buffer
nnoremap <leader>f :!gleam format %<CR>:e<CR>

" Build project
nnoremap <leader>b :!make build<CR>
```

---

## Continuous Learning

### Performance Monitoring

**Track metrics over time**:
```bash
# Baseline
git checkout main
make benchmark > baseline.txt

# After changes
git checkout feature-branch
make benchmark > feature.txt

# Compare
diff baseline.txt feature.txt
```

**Set up alerts**:
- Build time >0.5s
- Fast tests >2s
- Full tests >10s

---

### Code Review Workflow

**Before Creating PR**:
```bash
make dev-check
# Runs: format, lint, test
```

**After Receiving Feedback**:
```bash
# Make changes
vim src/...

# Re-run checks
make dev-check

# Push updates
git push
```

---

## Advanced Workflows

### Parallel Development

**Scenario**: Multiple features in parallel

**Workflow**:
```bash
# Feature 1
git checkout -b feature/BD-123-export
# Work on feature 1

# Feature 2 (without committing feature 1)
git stash
git checkout -b feature/BD-124-import
# Work on feature 2

# Back to feature 1
git checkout feature/BD-123-export
git stash pop
```

**Best Practice**: Use Beads issue tracking to coordinate parallel work

---

### Debugging Integration Tests

**Scenario**: Integration test fails sporadically

**Workflow**:
```bash
# Run test 10 times
for i in {1..10}; do
  echo "Run $i:"
  make test-all || break
done

# Check for race conditions
# Review test isolation
# Add logging
```

---

### Performance Regression Analysis

**Scenario**: CI slower than expected

**Workflow**:
```bash
# Local benchmark
make benchmark > local.txt

# CI benchmark (from artifacts)
# Download benchmark-results.txt

# Compare
diff local.txt benchmark-results.txt
```

---

## Productivity Tips

### 1. Alias Common Commands

Add to `.bashrc` or `.zshrc`:
```bash
alias gt='make test'
alias gta='make test-all'
alias gb='make build'
alias gf='make fmt'
alias gc='make check'
```

---

### 2. Use Terminal Multiplexer

**tmux/screen layout**:
```
┌─────────────┬─────────────┐
│             │             │
│   Editor    │  Test Watch │
│             │             │
├─────────────┴─────────────┤
│      Git/Commands         │
└───────────────────────────┘
```

---

### 3. Customize Watch Mode

**Filter specific tests**:
```bash
find src test -name "*.gleam" | entr -r gleam test --filter my_module
```

---

### 4. Use Make Help

**Forget a command?**
```bash
make help
# Displays all available targets with descriptions
```

---

## Appendix: Keyboard Shortcuts

### VS Code

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+B` | Run build task |
| `Ctrl+Shift+T` | Run test task |
| `Shift+Alt+F` | Format document |
| `F12` | Go to definition |

---

### Vim/Neovim

| Shortcut | Action |
|----------|--------|
| `<leader>t` | Run fast tests |
| `<leader>f` | Format buffer |
| `<leader>b` | Build project |
| `gd` | Go to definition (LSP) |

---

## Appendix: Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `DATABASE_URL` | PostgreSQL connection | `postgresql://localhost/meal_planner` |
| `TEST_DATABASE_URL` | Test database | `postgresql://localhost/meal_planner_test` |
| `TANDOOR_URL` | Tandoor API endpoint | `https://tandoor.example.com` |
| `TANDOOR_API_TOKEN` | Tandoor auth token | `Token abc123...` |
| `FATSECRET_CONSUMER_KEY` | FatSecret API key | `your-key` |
| `FATSECRET_CONSUMER_SECRET` | FatSecret API secret | `your-secret` |

---

## Appendix: Common Errors

### Error: "TANDOOR_URL not set"

**Solution**:
```bash
export TANDOOR_URL="https://your-tandoor.com"
export TANDOOR_API_TOKEN="Token your-token"
```

---

### Error: "Connection refused" (PostgreSQL)

**Solution**:
```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Create database
createdb meal_planner_test
```

---

### Error: "Module not found"

**Solution**:
```bash
# Clean and rebuild
make cache-clean
gleam deps download
make build
```

---

## References

- [Gleam Documentation](https://gleam.run/)
- [Make Manual](https://www.gnu.org/software/make/manual/)
- [Git Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows)
- [TDD Best Practices](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
