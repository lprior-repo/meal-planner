# Pre-Commit Hook - Quick Reference Guide

## What It Does

The pre-commit hook automatically runs quality checks before every `git commit`:

```
git commit → Hook Runs → Format Check → Type Check → Tests → Commit Success
```

## Normal Workflow

```bash
# Make your changes
git add .

# Try to commit (hook runs automatically)
git commit -m "feat: implement search filters"

# If hook passes: commit succeeds
# If hook fails: commit blocked, fix issues and try again
```

## Hook Checks (3-6 seconds)

| Check | Command | What It Does | Pass/Fail |
|-------|---------|-------------|-----------|
| Format | `gleam format --check` | Validates code style | Blocks if issues |
| Types | `gleam check` | Type safety, imports | Blocks if errors |
| Tests | `gleam test` | Runs fast tests only | Blocks if failure |

## Emergency Bypass

**Only for critical hotfixes** (not normal use):

```bash
# Skip checks and commit immediately
SKIP_HOOKS=1 git commit -m "Hotfix: production issue"

# THEN immediately run full checks
./scripts/pre-commit.sh
```

## If Hook Fails

### Format Issues
```bash
cd gleam
gleam format  # Auto-fixes
git add .
git commit    # Try again
```

### Type/Import Issues
```bash
cd gleam
gleam check   # Shows detailed errors
# Fix imports or type issues manually
git add .
git commit    # Try again
```

### Test Failures
```bash
cd gleam
gleam test    # See which tests fail
# Fix the code
git add .
git commit    # Try again
```

## Files Involved

| File | Purpose | Edit? |
|------|---------|-------|
| `/scripts/pre-commit.sh` | Hook logic | Yes (commit to repo) |
| `/.git/hooks/pre-commit` | Git hook | No (auto-generated) |
| `/README.md` | Documentation | Yes (already done) |

## Before Each Commit

Optional (but recommended):

```bash
# Test locally first to see what will happen
./scripts/pre-commit.sh
```

## Configuration

No configuration needed. The hook is already installed and active.

Hook location: `/home/lewis/src/meal-planner/.git/hooks/pre-commit`
Hook script: `/home/lewis/src/meal-planner/scripts/pre-commit.sh`

## Troubleshooting

### "format check failed"
```bash
cd gleam && gleam format
```

### "gleam check failed"
Look at the error message and fix the imports/types in the file.

### "tests failed"
Run `gleam test` to see which tests are failing, then fix the code.

### Hook not running
```bash
# Verify it's executable
ls -la .git/hooks/pre-commit  # Should show x permissions
```

### Want to temporarily disable?
```bash
# Use SKIP_HOOKS for critical situations only
SKIP_HOOKS=1 git commit -m "..."
```

## Best Practices

1. **Run checks locally first**: `./scripts/pre-commit.sh`
2. **Fix issues before committing**: Don't rely on bypass
3. **Keep commits focused**: Easier to fix when tests fail
4. **Read error messages**: They explain what to fix
5. **Emergency bypass only**: For critical production issues

## Key Files & Line Numbers

**Hook script**: `/home/lewis/src/meal-planner/scripts/pre-commit.sh`
- Format check: Line 50-57
- Type check: Line 60-67
- Test execution: Line 70-102
- SKIP_HOOKS bypass: Line 17-20

**Hook delegation**: `/home/lewis/src/meal-planner/.git/hooks/pre-commit`
- Delegates to: `scripts/pre-commit.sh` (line 8)

**Documentation**: `/home/lewis/src/meal-planner/README.md`
- Pre-commit section: Search for "pre-commit"

## Performance

Typical hook execution: 3-6 seconds
- Format check: 100-200ms (fast)
- Type check: 500-800ms (quick)
- Tests: 2-5s (fast tests only, E2E excluded)

## Summary

- Hook is **always active** on every commit
- Runs **format → types → tests**
- Colored output shows progress and results
- Bypass with `SKIP_HOOKS=1` only for emergencies
- Fix issues locally before committing for best experience
