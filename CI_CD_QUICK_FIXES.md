# CI/CD Critical Fixes - Quick Reference

## Summary
3 CRITICAL issues blocking test execution. Estimated fix time: **50 minutes**

---

## Issue 1: Type Mismatch in swap.gleam (5 minutes)

**File**: `gleam/src/meal_planner/web/handlers/swap.gleam`
**Line**: 127
**Current Error**: Type mismatch - element.Element cannot be passed to wisp.Text

### Problem
```gleam
|> wisp.set_body(wisp.Text(html))  // ❌ html is Element, not String
```

### Solution
```gleam
|> wisp.set_body(wisp.Text(element.to_string(html)))  // ✓ Convert to string
```

### Verification
```bash
cd gleam && gleam check
# Should report no errors in swap.gleam
```

---

## Issue 2: Invalid Gleeunit Assertions (15 minutes)

**File**: `gleam/test/meal_planner/integrations/todoist_client_test.gleam`
**Problem**: Using non-existent gleeunit assertion methods

### Affected Assertions (23 instances)

1. `should.have_length(n)` → Use `list.length |> should.equal(n)`
2. `should.contain(value)` → Use `list.contains(_, value) |> should.equal(True)`

### Example Fixes

**Before**:
```gleam
users
  |> should.have_length(2)

result
  |> should.contain("API Error")
```

**After**:
```gleam
users
  |> list.length
  |> should.equal(2)

result
  |> string.contains("API Error")
  |> should.be_true()
```

### Affected Lines
- 233, 237, 241, 245: `should.have_length`
- 256, 259, 266, 269, 276, 279, 286, 289, 304, 307: `should.contain`

### Verification
```bash
cd gleam && gleam test
# Should compile without "Unknown module value" errors
```

---

## Issue 3: Compilation Warnings Cleanup (30 minutes)

**File**: Multiple files
**Problem**: 22 compiler warnings make error output noisy

### Quick Fixes by Category

#### A. Unused Imports
Search for these patterns and remove:

**Pattern 1**: Imported but never used
```gleam
import gleam/result      // Line 9 in test_db.gleam
import gleam/list        // Line 6 in query_cache.gleam
```

Run this to find all:
```bash
cd gleam && gleam check 2>&1 | grep "This imported"
```

#### B. Unused Function Arguments
Add underscore prefix:

**Before**:
```gleam
pub fn generate_checklist(file: String) -> List(CheckItem) {
  // file is never used
}
```

**After**:
```gleam
pub fn generate_checklist(_file: String) -> List(CheckItem) {
  // file prefixed with _ to suppress warning
}
```

Affected files:
- fractal_quality_harness_test.gleam:72 (`file`)
- query_cache.gleam:305-307 (`cache_hit`, `query_name`, `execution_time_ms`)
- storage_optimized.gleam:7 (`Option` type)

#### C. Unused Values
Remove or assign to variable:

**Before**:
```gleam
query_cache.record_metric(True, "search_foods", 0.5)
// Value is computed but not used
```

**After**:
```gleam
let _metric = query_cache.record_metric(True, "search_foods", 0.5)
// Now warning is suppressed with _metric
```

Affected lines in storage_optimized.gleam: 50, 64, 155, 167

#### D. Deprecated API Usage
Replace deprecated functions:

**Before**:
```gleam
|> result.then(fn(_) {  // ❌ deprecated
```

**After**:
```gleam
|> result.try(fn(_) {   // ✓ correct
```

File: generator.gleam:161

### Verification
```bash
cd gleam && gleam check 2>&1 | grep -c "warning:"
# Should return 0 after fixes
```

---

## Testing & Verification

### Step 1: Verify All Issues Fixed
```bash
cd gleam

# Check 1: No type errors
gleam check
# Expected: "✓ No warnings or errors!"

# Check 2: No compilation warnings
gleam build 2>&1 | grep -c "warning:"
# Expected: 0

# Check 3: Tests compile
gleam test --no-run
# Expected: "Compiled successfully"

# Check 4: Tests pass
gleam test
# Expected: All tests pass with no compilation errors
```

### Step 2: Verify Pre-commit Hook Works
```bash
# Make sure you're in the repo root
cd /home/lewis/src/meal-planner

# Run pre-commit checks
./scripts/pre-commit.sh
# Expected output:
# ✓ Checking code formatting... (Xms)
# ✓ Running type checker... (Xms)
# ✓ Running fast tests... (Xms)
# ✓ All checks passed!
```

### Step 3: Verify GitHub Actions Ready
```bash
# Manually trigger the workflow by pushing to a branch
git add .
git commit -m "[ci-fix] Fix compilation errors"
git push origin your-branch

# Check GitHub Actions tab
# Expected: Green checkmark on all status checks
```

---

## Files to Modify (Checklist)

### Critical Fixes
- [ ] `gleam/src/meal_planner/web/handlers/swap.gleam:127` - Type mismatch
- [ ] `gleam/test/meal_planner/integrations/todoist_client_test.gleam` - Assertions (23 lines)

### Cleanup
- [ ] `gleam/test/fixtures/test_db.gleam:9,11` - Unused imports
- [ ] `gleam/test/fractal_quality_harness_test.gleam:72` - Unused argument
- [ ] `gleam/src/meal_planner/query_cache.gleam:6,305-307` - Unused imports/arguments
- [ ] `gleam/src/meal_planner/storage_optimized.gleam:4,6,7,50,64,155,167` - Unused imports/values
- [ ] `gleam/src/meal_planner/web/handlers/food_log.gleam:4,7,11` - Unused imports
- [ ] `gleam/src/meal_planner/generator.gleam:5,161` - Unused import & deprecated API
- [ ] `gleam/src/meal_planner/ui/components/meal_card.gleam:19` - Unused import
- [ ] `gleam/src/meal_planner/web/handlers/generate.gleam:9,12` - Unused imports
- [ ] `gleam/src/meal_planner/web/handlers/profile.gleam:5` - Unused imports
- [ ] `gleam/src/meal_planner/web/handlers/recipe.gleam:12` - Unused imports

---

## Commit Strategy

### Option 1: Fix All at Once (Recommended)
```bash
# Fix all issues in a single commit
# This unblocks CI/CD immediately

git add gleam/
git commit -m "[ci] Fix compilation errors and warnings

- Fix type mismatch in swap.gleam (wisp.Text requires String)
- Replace invalid gleeunit assertions with correct methods
- Clean up unused imports and arguments
- Replace deprecated result.then with result.try

Fixes blocking GitHub Actions test failures."

git push origin main
```

### Option 2: Fix in Stages
```bash
# Stage 1: Fix blockers only (1 commit)
git add gleam/src/meal_planner/web/handlers/swap.gleam
git add gleam/test/meal_planner/integrations/todoist_client_test.gleam
git commit -m "[ci] Fix critical test compilation errors"
git push

# Stage 2: Cleanup warnings (1 commit)
git add gleam/src/ gleam/test/
git commit -m "[cleanup] Remove unused imports and arguments"
git push
```

---

## Expected Results After Fixes

### Pre-commit Hook
```
🚀 Running pre-commit checks...

▶ 1. Checking code formatting...
✓ Passed (45ms)

▶ 2. Running type checker...
✓ Passed (1234ms)

▶ 3. Running fast tests (excluding E2E/integration)...
  Running 19/20 tests (excluding 1 slow tests)
✓ Passed (8923ms)

✓ All checks passed!
Total time: 10202ms
```

### GitHub Actions
```
✓ Checkout code
✓ Set up Gleam (erlef/setup-beam@v1)
✓ Install dependencies
✓ Check format (gleam format --check)
✓ Build (gleam build)
✓ Run tests (gleam test)

All checks passed!
```

### Local Test Suite
```
compiling meal_planner
Building project as an application
Finished in 8.52s

 28 passed in 29ms
```

---

## Prevention for Future

### 1. Enable Pre-commit Locally
Ensure the hook is executable and runs before commits:
```bash
chmod +x .git/hooks/pre-commit
# Should run automatically on `git commit`
```

### 2. Run Checks Before Pushing
```bash
./scripts/pre-commit.sh
# Must pass before pushing any code
```

### 3. Keep Dependencies Updated
```bash
cd gleam
gleam deps upgrade
# Run tests after upgrade to catch API changes
```

---

## Estimated Timeline

| Task | Time | Notes |
|------|------|-------|
| Fix swap.gleam | 5 min | Edit 1 line |
| Fix todoist_client_test.gleam | 15 min | Edit ~23 lines |
| Clean warnings | 30 min | Many small edits |
| Test & verify | 10 min | Run commands |
| Commit & push | 5 min | Git operations |
| **Total** | **~65 min** | All fixes |

---

## Support / Questions

If any fix doesn't work as expected:

1. **Check gleam version**:
   ```bash
   gleam --version
   # Should be >= 1.5.0
   ```

2. **Verify imports are correct**:
   ```bash
   cd gleam && gleam deps download
   # Refresh dependencies
   ```

3. **Clear build cache if needed**:
   ```bash
   cd gleam && rm -rf build && gleam build
   # Fresh rebuild
   ```

4. **Check full error message**:
   ```bash
   gleam check 2>&1 | less
   # Read entire error context
   ```

---

**Last updated**: 2025-12-04
**Status**: Ready for implementation
**Risk level**: Very Low (only fixes, no new features)
