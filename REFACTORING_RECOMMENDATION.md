# Fix Compilation Errors in Tandoor Client

## Root Cause

Type duplication across multiple modules causes type mismatches:

1. **types/base.gleam** defines:
   - `ClientConfig`
   - `TandoorError`
   - `AuthMethod`
   - `ApiResponse`

2. **client.gleam** ALSO defines these types (duplicate):
   - Lines 45-107: Type definitions for `HttpMethod`, `TandoorError`, `AuthMethod`, `ClientConfig`, `ApiResponse`
   - Lines 110-231: Config functions and session helpers

3. **recipe.gleam** imports from `types/base.gleam`:
   - `import ... types/base.{type ClientConfig, type TandoorError}`

4. **CLI domain** imports from `client.gleam`:
   - `import meal_planner/tandoor/client`

5. **Result**: Type mismatch when CLI passes `client.ClientConfig` to recipe functions expecting `base.ClientConfig`

## Current Build Errors

```
error: Type mismatch
   Expected type: base.ClientConfig
   Found type: client.ClientConfig
```

This occurs in:
- `src/meal_planner/cli/domains/tandoor.gleam` lines 327, 365, 398
- `src/meal_planner/tandoor/api/crud_helpers.gleam` (similar pattern)

## Solution Options

### Option A: Quick Fix - Update CLI Imports (Minimal Change)

Change `src/meal_planner/cli/domains/tandoor.gleam` line 19:

**Before:**
```gleam
import meal_planner/tandoor/client
```

**After:**
```gleam
import meal_planner/tandoor/types/base.{
  type ClientConfig,
  type TandoorError,
}
```

Also update error handling calls:
- `client.error_to_string(e)` → `base.error_to_string(e)` (if function exists in base)
- Or keep client import and import error handling separately

**Impact:** 
- ✅ Minimal change (1 file)
- ✅ Fixes immediate compilation errors
- ⚠️  Doesn't address type duplication (technical debt)

### Option B: Complete Fix - Remove Duplicates from client.gleam (Recommended)

**File: `src/meal_planner/tandoor/client.gleam`**

**Remove (lines 40-231, ~192 lines total):**
1. Type definitions:
   - `pub type HttpMethod` (lines 45-51)
   - `pub type TandoorError` (lines 54-73)
   - `pub type AuthMethod` (lines 76-87)
   - `pub type ClientConfig` (lines 90-103)
   - `pub type ApiResponse` (lines 106-108)

2. Config functions (now in types/base.gleam):
   - `session_config`
   - `bearer_config`
   - `default_config`
   - `with_timeout`
   - `with_retry_config`

3. Session helper (still needed in client):
   - `with_session` (internal function used by login flow)

**Add import to line ~39:**
```gleam
import meal_planner/tandoor/types/base.{
  type AuthMethod,
  type ClientConfig,
  type TandoorError,
  type ApiResponse,
  AuthenticationError,
  AuthorizationError,
  BadRequestError,
  BearerAuth,
  NetworkError,
  NotFoundError,
  ParseError,
  ServerError,
  SessionAuth,
  TimeoutError,
  UnknownError,
}
```

**Impact:**
- ✅ Eliminates type duplication
- ✅ Single source of truth for types
- ✅ Better long-term architecture
- ⚠️ Larger change (client.gleam)

### Option C: Make recipe module import from client (Alternative)

Instead of removing duplicates, change recipe.gleam to import from client:

**Change `src/meal_planner/tandoor/recipe.gleam` imports:**
```gleam
# Remove:
import meal_planner/tandoor/types/base.{
  type ClientConfig, type TandoorError,
}

# Add:
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError,
}
```

**Impact:**
- ✅ Minimal change (recipe.gleam)
- ✅ Keeps client.gleam as main source of types
- ⚠️ Client still has duplicates (technical debt)

## Recommendation

**For Immediate Fix:** Use **Option A** (Quick Fix)
- Change CLI imports to use `types/base`
- Run `gleam build` to verify
- Run `gleam test` to ensure no regressions

**For Long-term:** Implement **Option B** (Complete Fix)  
- Remove duplicate type definitions from `client.gleam`
- Run comprehensive tests
- Update all dependent modules

## Implementation Steps

### For Option A (Quick Fix):

1. Edit `src/meal_planner/cli/domains/tandoor.gleam`:
   ```bash
   # Line 19 - replace import
   sed -i 's/import meal_planner\/tandoor\/client$/import meal_planner\/tandoor\/types\/base.{$/' src/meal_planner/cli/domains/tandoor.gleam
   sed -i '19a\  type ClientConfig,$/  type ClientConfig,\n  type TandoorError,/' src/meal_planner/cli/domains/tandoor.gleam
   sed -i '20a\}/' src/meal_planner/cli/domains/tandoor.gleam
   ```

2. Fix error handling calls (if needed):
   - Either keep `import meal_planner/tandoor/client`
   - Or import `error_to_string` from client

3. Verify build:
   ```bash
   gleam build
   ```

4. Run tests:
   ```bash
   gleam test
   ```

### For Option B (Complete Fix):

1. Backup `client.gleam`:
   ```bash
   cp src/meal_planner/tandoor/client.gleam src/meal_planner/tandoor/client.gleam.bak
   ```

2. Remove duplicate definitions:
   ```bash
   sed -i '40,231d' src/meal_planner/tandoor/client.gleam
   ```

3. Add imports from types/base:
   ```bash
   # After line 39, add:
   sed -i '39a\import meal_planner\/tandoor\/types\/base.{$/' src/meal_planner/tandoor/client.gleam
   ```

4. Verify and fix:
   ```bash
   gleam build
   gleam test
   ```

5. Commit changes:
   ```bash
   git add src/meal_planner/tandoor/client.gleam
   git commit -m "refactor: Remove duplicate type definitions from client.gleam

   - Remove duplicate ClientConfig, TandoorError, AuthMethod, ApiResponse
   - Import from types/base.gleam as single source of truth
   - Fixes type mismatches across tandoor modules"
   ```

