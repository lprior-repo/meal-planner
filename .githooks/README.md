# Git Hooks - Quality Gates

This project uses multiple git hooks to enforce code quality and prevent broken code from reaching main.

## Hook Chain

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│ pre-commit  │ ───> │ post-commit  │ ───> │  pre-push   │
│ (can skip)  │      │  (warning)   │      │ (enforced!) │
└─────────────┘      └──────────────┘      └─────────────┘
       │                    │                      │
       ▼                    ▼                      ▼
  Build check         Detect errors         BLOCK push
  Format check        Warn if used          if errors
  Beads sync          --no-verify           exist
```

## Hooks Explained

### 1. `pre-commit` (Can be bypassed)
**Location**: `.git/hooks/pre-commit`

Runs BEFORE commit is created. Checks:
- ✓ Beads sync
- ✓ Code formatting
- ✓ Build compilation
- ✓ (Truth score - if enabled)

Can be bypassed with: `git commit --no-verify`

**Purpose**: Catch issues early during development.

### 2. `post-commit` (Always runs)
**Location**: `.git/hooks/post-commit`

Runs AFTER commit is created. Checks:
- ⚠ Detects if code has compilation errors
- ⚠ Warns if you likely used `--no-verify`
- ⚠ Reminds to fix before pushing

**Cannot be bypassed** - always runs after commit.

**Purpose**: Remind you if you bypassed pre-commit checks.

### 3. `pre-push` (ENFORCED - Final Gate)
**Location**: `.git/hooks/pre-push`

Runs BEFORE pushing to remote. Checks:
- ✗ **BLOCKS push if compilation errors**
- ✗ **BLOCKS direct push to main**
- ⚠ Warns about TODOs
- ⚠ Warns about warnings

**This is the FINAL DEFENSE** - if you used `--no-verify` on commit, this hook will catch it!

**Purpose**: Ensure only working code reaches remote/main.

### 4. `prepare-commit-msg` (Helper)
**Location**: `.git/hooks/prepare-commit-msg`

Runs when preparing commit message. Adds:
- ⚠ Warning comments if build fails
- 📝 Reminder to fix before pushing

**Purpose**: Visual reminder in commit message.

## Why This Design?

### Problem
Developers sometimes use `git commit --no-verify` to skip pre-commit hooks when:
- In a hurry
- Want to commit WIP
- Pre-commit is slow
- Want to "fix it later"

### Solution: Defense in Depth

1. **Pre-commit** (First line of defense)
   - Catches most issues
   - Fast feedback
   - Can be bypassed for WIP commits

2. **Post-commit** (Immediate warning)
   - Runs even if pre-commit was bypassed
   - Warns immediately after commit
   - Gives instructions to fix

3. **Pre-push** (Final enforcement)
   - **CANNOT BE BYPASSED SAFELY**
   - Blocks push if errors exist
   - Protects main branch
   - Prevents broken code on remote

## Usage Patterns

### Normal workflow (recommended)
```bash
# Make changes
vim gleam/src/my_file.gleam

# Commit (pre-commit runs)
git commit -m "Add feature"
✓ Pre-commit checks pass

# Push (pre-push runs)
git push
✓ Pre-push checks pass
```

### WIP workflow (using --no-verify)
```bash
# Make changes (code doesn't compile yet)
vim gleam/src/my_file.gleam

# Commit WIP (bypass pre-commit)
git commit --no-verify -m "WIP: partial implementation"
⚠ Post-commit warns: "Code has compilation errors!"

# Continue working...
vim gleam/src/my_file.gleam

# Fix compilation errors
gleam build
✓ Build passes

# Commit fix
git commit -am "Complete implementation"
✓ Pre-commit passes

# Push (pre-push runs)
git push
✓ Pre-push checks pass - all good!
```

### What happens if you try to push broken code?
```bash
# Committed with --no-verify, code doesn't compile
git commit --no-verify -m "Broken code"
⚠ Post-commit: "WARNING: COMMIT HAS COMPILATION ERRORS"

# Try to push
git push
✗ PRE-PUSH BLOCKED!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✗ PUSH BLOCKED - COMPILATION ERRORS DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You CANNOT push code that doesn't compile!

CRITICAL REMINDER:
  If you used 'git commit --no-verify' to bypass the pre-commit hook,
  you MUST fix the compilation errors BEFORE pushing!

  This is a HARD REQUIREMENT before merging to main.

To fix:
  1. Read the errors above
  2. Fix the compilation issues
  3. Run: gleam build
  4. Commit the fixes
  5. Try pushing again

Push rejected. Fix errors and try again.
```

## Branch Protection

### Integration Branch
- Pre-push checks enforced
- Compilation must pass
- Warnings allowed (but flagged)
- TODOs allowed (but flagged)

### Main Branch
- **DIRECT PUSHES BLOCKED**
- Must go through integration first
- All checks must pass
- No TODOs allowed
- No warnings recommended

## Bypassing Hooks (Emergency Only)

### Pre-commit
```bash
git commit --no-verify -m "Message"
```
✓ Allowed for WIP commits
⚠ Must fix before pushing

### Pre-push
```bash
git push --no-verify
```
❌ **NOT RECOMMENDED** - defeats the purpose
⚠ Will break remote if code doesn't compile
⚠ Will block merges to main

## Installation

Hooks are already installed in `.git/hooks/`. They're not tracked by git (security).

To reinstall:
```bash
cp .githooks/pre-push .git/hooks/
cp .githooks/post-commit .git/hooks/
cp .githooks/prepare-commit-msg .git/hooks/
chmod +x .git/hooks/*
```

## Customization

Edit hooks in `.git/hooks/` to customize behavior:

**Make hooks stricter**:
```bash
# In pre-push, also block warnings
if echo "$build_output" | grep -q "^warning:"; then
    echo "PUSH BLOCKED - No warnings allowed!"
    exit 1
fi
```

**Make hooks more lenient**:
```bash
# In pre-push, allow errors on non-main branches
if [[ "$current_branch" != "integration" ]]; then
    echo "Allowing push on feature branch"
    exit 0
fi
```

## Testing Hooks

### Test pre-commit
```bash
# Break the build
echo "invalid gleam" >> gleam/src/meal_planner/web.gleam

# Try to commit
git commit -m "Test"
# Should fail

# Fix it
git restore gleam/src/meal_planner/web.gleam
```

### Test post-commit
```bash
# Commit broken code with --no-verify
git commit --no-verify --allow-empty -m "Test"
# Should show warning
```

### Test pre-push
```bash
# Make broken commit
git commit --no-verify --allow-empty -m "Broken"

# Try to push
git push
# Should be BLOCKED
```

## Troubleshooting

### "Hook not running"
```bash
# Check if executable
ls -la .git/hooks/pre-push
# Should have 'x' permission

# Make executable
chmod +x .git/hooks/pre-push
```

### "Hook running but not blocking"
Check exit codes:
- `exit 0` = success (allow)
- `exit 1` = failure (block)

### "Want to disable temporarily"
```bash
# Rename to disable
mv .git/hooks/pre-push .git/hooks/pre-push.disabled

# Re-enable
mv .git/hooks/pre-push.disabled .git/hooks/pre-push
```

## Summary

**Key Points**:
1. ✅ Pre-commit can be bypassed for WIP
2. ⚠️ Post-commit always warns if broken
3. ❌ Pre-push BLOCKS broken code from remote
4. 🔒 Main branch requires clean code

**Bottom Line**:
Use `--no-verify` for WIP commits if needed, but you MUST fix errors before pushing. The pre-push hook ensures this!
