# Pre-Commit Hook Documentation

## Overview

The enhanced pre-commit hook (`scripts/pre-commit.sh`) provides comprehensive CI checks before allowing commits.

## Features

### 1. Format Check
- Runs `gleam format --check` (non-destructive)
- Fails if code is not properly formatted
- Provides helpful command to fix: `cd gleam && gleam format`

### 2. Type Check
- Runs `gleam check` for type validation
- Shows warning count but doesn't fail on warnings
- Fails on type errors

### 3. Test Suite
- Runs all tests with `gleam test`
- Shows test breakdown (unit vs integration/E2E)
- Displays last 20 lines of test output for quick feedback

### 4. Performance Timing
- Times each step individually (milliseconds)
- Shows total execution time (seconds + milliseconds)
- Helps identify slow steps

### 5. Colored Output
- Blue: Step headers and info
- Green: Success messages
- Yellow: Warnings and timings
- Red: Errors and failure messages
- Bold: Important information

### 6. Bypass Mechanism
```bash
# Skip all pre-commit checks
SKIP_HOOKS=1 git commit -m "WIP: experimental changes"
```

## Usage

### Normal Commit (with checks)
```bash
git add .
git commit -m "feat: add new feature"
# Hook runs automatically
```

### Skip Checks (emergency use)
```bash
SKIP_HOOKS=1 git commit -m "WIP: debugging"
```

### Manual Run (test the hook)
```bash
./scripts/pre-commit.sh
```

## Installation

The hook is already installed at `.git/hooks/pre-commit` and delegates to `scripts/pre-commit.sh`.

If you need to reinstall:
```bash
cp scripts/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Example Output

```
🚀 Running pre-commit checks...

▶ 1. Checking code formatting...
✓ Passed (108ms)

▶ 2. Running type checker...
  ⚠ 5 warning(s) found
✓ Passed (2341ms)

▶ 3. Running tests...
  Running 75 tests (70 unit, 5 integration/E2E)
  Note: E2E tests may take longer...
✓ Passed (15234ms)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ All checks passed!
Total time: 17.68s (17683ms)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Handling

When a check fails, the hook:
1. Shows which step failed
2. Displays relevant error output
3. Suggests the bypass command
4. Exits with code 1 (prevents commit)

Example failure:
```
✗ Failed: Format check

To bypass this check, use: SKIP_HOOKS=1 git commit
```

## CI Integration

This hook ensures that all commits pass the same checks that CI will run, preventing:
- Failed CI builds due to formatting
- Type errors in production
- Broken tests merged to main

## Performance

Expected execution times:
- Format check: 100-200ms
- Type check: 2-3s
- Tests: 10-20s (depending on test count)
- **Total: ~15-25s**

If tests are too slow, consider:
1. Using `SKIP_HOOKS=1` for WIP commits
2. Optimizing slow tests
3. Splitting integration tests into separate CI job

## Troubleshooting

### Hook not running
```bash
# Check if hook is executable
ls -la .git/hooks/pre-commit

# Make it executable
chmod +x .git/hooks/pre-commit
```

### BC command not found
The hook uses `bc` for decimal calculations. Install it:
```bash
# Arch Linux
sudo pacman -S bc

# Ubuntu/Debian
sudo apt-get install bc
```

### Tests failing
Run manually to see full output:
```bash
cd gleam
gleam test
```

## Maintenance

The hook script is version-controlled at `scripts/pre-commit.sh`, making it:
- Easy to update for all developers
- Trackable in git history
- Shareable across team

The `.git/hooks/pre-commit` file is minimal and just delegates to the script.
