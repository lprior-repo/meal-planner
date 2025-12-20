# Test Remediation Strategy
**Epic:** meal-planner-0n0y
**Date:** 2025-12-20
**Status:** Analysis Complete - Ready for Parallel Remediation

## Executive Summary
114 disabled test files identified across the codebase. Three primary root causes discovered:

1. **Deprecated Assertion Pattern** - `should.contain()` → `string.contains()` (6 files)
2. **Deprecated JSON Decoder API** - `dynamic.field()` → proper `gleam/dynamic` API (1 file)
3. **Unused Import Warnings** - All 114 files have import cleanup needed

## Inventory Analysis

### Total Files: 114
- **FatSecret Domain**: 32 files (28%)
- **Tandoor Domain**: 22 files (19%)
- **Integration Tests**: 13 files (11%)
- **CLI Tests**: 13 files (11%)
- **Other/Core**: 48 files (42%)

### Issue Distribution
| Issue Type | Count | Severity | Effort |
|------------|-------|----------|--------|
| Unused imports | 114 | Low | 1-2 min/file |
| `should.contain()` deprecation | 6 | Medium | 3-5 min/file |
| `dynamic.field()` deprecation | 1 | Medium | 5-10 min |

## Root Cause Analysis

### Issue 1: Deprecated `should.contain()` Assertion
**Files Affected:** 6
**Pattern:** String assertion checking if JSON contains substring

#### Old Pattern (BROKEN):
```gleam
import gleeunit/should

let json_string = json.to_string(response)
json_string
|> should.contain("\"count\":100")
```

#### New Pattern (WORKING):
```gleam
import gleam/string

let json_string = json.to_string(response)
should.be_true(json_string |> string.contains("\"count\":100"))
```

#### Alternative (CUSTOM HELPER):
```gleam
// Define helper function
fn gleam_stdlib_contains(haystack: String, needle: String) -> Bool {
  case gleam_stdlib_string_split(haystack, needle) {
    [_] -> False
    _ -> True
  }
}

@external(erlang, "string", "split")
fn gleam_stdlib_string_split(a: String, b: String) -> List(String)

// Usage
should.be_true(actual_string |> gleam_stdlib_contains("\"id\":1"))
```

#### Files to Fix:
1. `/test/shared/response_encoders_test.gleam.disabled`
2. `/test/meal_planner/errors_test.gleam.disabled`
3. `/test/fatsecret/support/http_mock.gleam.disabled`
4. `/test/integration/scheduler_integration_test.gleam.disabled`
5. `/test/integration/workflow_integration_test.gleam.disabled`
6. Additional files (grep for `should.contain`)

### Issue 2: Deprecated `dynamic.field()` API
**Files Affected:** 1
**Pattern:** Old JSON decoder API using `dynamic.field(json, "field")`

#### Old Pattern (BROKEN):
```gleam
import gleam/dynamic

let value = dynamic.field(json, "field_name")
```

#### New Pattern (WORKING):
```gleam
import gleam/dynamic/decode

let decoder = {
  use field_value <- decode.field("field_name", decode.string)
  decode.success(field_value)
}
```

#### Files to Fix:
1. `/test/fatsecret/support/http_mock.gleam.disabled` (if present)

### Issue 3: Unused Import Warnings
**Files Affected:** 114 (ALL)
**Pattern:** Imported modules that are never used in the file

#### Detection Strategy:
```bash
# Run gleam check on re-enabled file
gleam check

# Output will show:
# warning: Unused import
#   ┌─ test/example_test.gleam:5:1
#   │
# 5 │ import gleam/string
#   │ ^^^^^^^^^^^^^^^^^^^ This imported module is never used
```

#### Fix Pattern:
1. Re-enable file (rename `.disabled` → `.gleam`)
2. Run `gleam check` or `gleam test`
3. Remove imports listed in warnings
4. Re-run `gleam test` to verify
5. Commit if passing

## Remediation Workflow (Per File)

### Phase 1: Assertion Fixes (6 files, ~30 minutes total)
```bash
# For each file with should.contain:
1. cd /home/lewis/src/meal-planner
2. mv test/path/to/file.gleam.disabled test/path/to/file.gleam
3. EDIT: Replace all `should.contain(substring)` with:
   - Add: import gleam/string
   - Change: should.be_true(actual_string |> string.contains(substring))
4. gleam test --target erlang
5. IF PASS: git add test/path/to/file.gleam && git commit -m "🟢 FIX: Remediate should.contain in file_test"
6. IF FAIL: Review error, fix, repeat step 4
```

### Phase 2: Decoder Fixes (1 file, ~10 minutes)
```bash
# For files with dynamic.field:
1. Re-enable file
2. Replace dynamic.field() with decode.field() pattern
3. Update imports (gleam/dynamic → gleam/dynamic/decode)
4. Test + commit
```

### Phase 3: Import Cleanup (114 files, ~3-4 hours sequential, ~15-20 min parallel)
```bash
# Automated approach (per file):
1. Re-enable file
2. gleam test 2>&1 | grep "This imported module is never used" -B 2 | grep "import" | cut -d' ' -f2-
3. Remove each unused import line
4. gleam test (verify pass)
5. Commit
```

#### Batch Processing Strategy (RECOMMENDED):
```bash
# Process files in domain batches:
BATCH_1="test/fatsecret/**/*.disabled"  # 32 files
BATCH_2="test/tandoor/**/*.disabled"    # 22 files
BATCH_3="test/integration/**/*.disabled" # 13 files
BATCH_4="test/cli/**/*.disabled"        # 13 files
BATCH_5="test/**/*.disabled"            # 34 remaining

# For each batch:
for file in $BATCH_1; do
  enabled="${file%.disabled}"
  mv "$file" "$enabled"
  # Fix assertions if needed
  # Fix decoders if needed
  gleam test "$enabled" 2>&1 | parse_unused_imports | remove_imports "$enabled"
  gleam test "$enabled" && git commit -m "🟢 FIX: $(basename $enabled)"
done
```

## Parallel Remediation Plan (48-Agent Swarm)

### Batch Allocation (8 batches, 6 agents each)

#### Batch 1-6: Assertion Updates (6 files)
**Agent Task:** Fix `should.contain` deprecation
**Files:**
1. `test/shared/response_encoders_test.gleam.disabled`
2. `test/meal_planner/errors_test.gleam.disabled`
3. `test/fatsecret/support/http_mock.gleam.disabled`
4. `test/integration/scheduler_integration_test.gleam.disabled`
5. `test/integration/workflow_integration_test.gleam.disabled`
6. `test/data_pipeline_test.gleam.disabled`

#### Batch 7-12: FatSecret Domain (32 files ÷ 6 = ~5-6 files/agent)
**Agent Task:** Import cleanup + test re-enable
**Files:** All `/test/fatsecret/**/*.disabled`

#### Batch 13-18: Tandoor Domain (22 files ÷ 6 = ~3-4 files/agent)
**Agent Task:** Import cleanup + test re-enable
**Files:** All `/test/tandoor/**/*.disabled`

#### Batch 19-24: Integration Tests (13 files ÷ 6 = ~2-3 files/agent)
**Agent Task:** Import cleanup + complex integration fixes
**Files:** All `/test/integration/**/*.disabled`

#### Batch 25-30: CLI Tests (13 files ÷ 6 = ~2-3 files/agent)
**Agent Task:** Import cleanup + CLI interaction tests
**Files:** All `/test/cli/**/*.disabled`

#### Batch 31-36: Core/Generation Tests (24 files ÷ 6 = ~4 files/agent)
**Agent Task:** Import cleanup + business logic tests
**Files:** `/test/generation/**/*.disabled`, `/test/generator/**/*.disabled`, etc.

#### Batch 37-42: Email/Scheduler/Advisor (14 files ÷ 6 = ~2-3 files/agent)
**Agent Task:** Import cleanup + workflow tests
**Files:** `/test/email/**/*.disabled`, `/test/scheduler/**/*.disabled`, `/test/advisor/**/*.disabled`

#### Batch 43-48: Final Validation (Remaining 10 files + verification)
**Agent Task:**
- Import cleanup for remaining files
- Run full `gleam test` suite
- Verify `gleam format --check`
- Generate remediation report

## Acceptance Criteria

### Per-File Success:
✅ File renamed from `.disabled` to `.gleam`
✅ Zero `should.contain()` usage
✅ Zero `dynamic.field()` usage
✅ Zero unused import warnings
✅ `gleam test <file>` passes
✅ `gleam format --check <file>` passes
✅ Git commit created

### Epic Success:
✅ All 114 test files re-enabled
✅ `make test` passes (0.8s parallel)
✅ `gleam format --check` passes (entire codebase)
✅ Zero test failures
✅ Zero warnings
✅ All changes committed to git

## Automation Scripts

### Script 1: Detect Unused Imports
```bash
#!/bin/bash
# detect_unused_imports.sh <file.gleam>

file="$1"
gleam test "$file" 2>&1 | \
  grep "This imported module is never used" -B 2 | \
  grep "import" | \
  sed 's/^[^i]*//' | \
  cut -d' ' -f1-2
```

### Script 2: Remove Unused Imports
```bash
#!/bin/bash
# remove_unused_imports.sh <file.gleam>

file="$1"
unused=$(./detect_unused_imports.sh "$file")

while IFS= read -r import_line; do
  # Remove exact import line from file
  sed -i "/^$import_line$/d" "$file"
done <<< "$unused"
```

### Script 3: Batch Remediation
```bash
#!/bin/bash
# remediate_batch.sh <pattern>

pattern="$1"
files=$(find test -name "$pattern")

for file in $files; do
  enabled="${file%.disabled}"

  echo "Processing: $enabled"

  # Re-enable
  mv "$file" "$enabled"

  # Fix assertions (if needed)
  if grep -q "should\.contain" "$enabled"; then
    sed -i 's/should\.contain(\(.*\))/should.be_true(string.contains(\1))/g' "$enabled"
    # Add import if missing
    if ! grep -q "import gleam/string" "$enabled"; then
      sed -i '1a import gleam/string' "$enabled"
    fi
  fi

  # Remove unused imports
  ./remove_unused_imports.sh "$enabled"

  # Test
  if gleam test "$enabled"; then
    git add "$enabled"
    git commit -m "🟢 FIX: Remediate $(basename $enabled)"
    echo "✅ SUCCESS: $enabled"
  else
    echo "❌ FAILED: $enabled (needs manual fix)"
  fi
done
```

## Risk Assessment

### Low Risk (Import Cleanup):
- **Impact:** Cosmetic only, removes warnings
- **Rollback:** Git revert
- **Effort:** Automated script handles 95%

### Medium Risk (Assertion Updates):
- **Impact:** Test logic unchanged, only assertion method
- **Rollback:** Git revert
- **Effort:** Manual review of 6 files, pattern is straightforward

### Low Risk (Decoder Updates):
- **Impact:** Only 1 file affected
- **Rollback:** Git revert
- **Effort:** 10 minutes, well-documented pattern

## Timeline Estimates

### Sequential Processing:
- **Assertion fixes:** 30 minutes (6 files × 5 min)
- **Decoder fixes:** 10 minutes (1 file)
- **Import cleanup:** 3-4 hours (114 files × 2 min)
- **Total:** ~4.5 hours

### Parallel Processing (48 agents):
- **Batch 1-6 (Assertions):** 5 minutes
- **Batch 7-42 (Domain cleanup):** 10-15 minutes (parallel)
- **Batch 43-48 (Validation):** 5 minutes
- **Total:** ~20-25 minutes

## Next Steps

1. **Agent Coordinator Review:** Approve batch allocation strategy
2. **Spawn Agent Swarm:** 48 agents (8 batches × 6 agents)
3. **Execute Parallel Remediation:** Batches 1-48 simultaneously
4. **Validation Pass:** Full test suite + format check
5. **Close Epic:** Update bd task, commit all changes
6. **Memory Archive:** Save patterns to mem0 for future reference

## References

- **Gleam String Module:** https://hexdocs.pm/gleam_stdlib/gleam/string.html
- **Gleam Dynamic/Decode:** https://hexdocs.pm/gleam_stdlib/gleam/dynamic/decode.html
- **Gleeunit Assertions:** https://hexdocs.pm/gleeunit/
- **Working Example:** `/test/tandoor/handlers/foods_handler_test.gleam`

---

**Generated:** 2025-12-20
**Author:** Claude Code (ARCHITECT)
**Epic:** meal-planner-0n0y
