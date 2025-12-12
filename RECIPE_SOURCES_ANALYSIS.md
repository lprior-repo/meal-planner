# Recipe Sources Table - Comprehensive Usage Analysis

**Task:** meal-planner-6md9
**Date:** 2025-12-12
**Status:** Completed

## Executive Summary

The `recipe_sources` table is a PostgreSQL table created in migration 009 designed to track the configuration of recipe sources for the auto meal planner feature. The table stores metadata about where recipes come from (database, API, or user-provided) and their associated configurations.

**Current Status:** The table exists and is actively used by the auto meal planner feature, but the associated audit logging infrastructure was completely removed in migration 021.

---

## Table Schema

### Location
- **File:** `/home/lewis/src/meal-planner/gleam/migrations_pg/009_auto_meal_planner.sql`
- **Line:** 5-13

### Structure
```sql
CREATE TABLE IF NOT EXISTS recipe_sources (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL CHECK(type IN ('api', 'scraper', 'manual')),
    config JSONB, -- JSON config for API keys, endpoints, etc.
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Columns
| Column | Type | Constraints | Purpose |
|--------|------|-----------|---------|
| `id` | SERIAL | PRIMARY KEY | Unique identifier |
| `name` | TEXT | NOT NULL, UNIQUE | Source name (e.g., "USDA API", "Local Database") |
| `type` | TEXT | NOT NULL, CHECK ('api', 'scraper', 'manual') | Type of recipe source |
| `config` | JSONB | Optional | JSON configuration (API keys, endpoints, etc.) |
| `enabled` | BOOLEAN | NOT NULL, DEFAULT true | Whether source is active |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Last update timestamp |

### Indexes
```sql
CREATE INDEX idx_recipe_sources_type ON recipe_sources(type);
CREATE INDEX idx_recipe_sources_enabled ON recipe_sources(enabled);
CREATE INDEX idx_recipe_sources_config ON recipe_sources USING GIN (config);
```

---

## Audit Infrastructure (Removed in Migration 021)

### What Was Removed
Migration 021 (`/home/lewis/src/meal-planner/gleam/migrations_pg/021_drop_recipe_sources_audit.sql`) completely removed:

1. **Audit Table:** `recipe_sources_audit`
2. **Triggers:**
   - `recipe_sources_audit_insert_trigger`
   - `recipe_sources_audit_update_trigger`
   - `recipe_sources_audit_delete_trigger`
3. **Trigger Functions:**
   - `audit_recipe_sources_insert()`
   - `audit_recipe_sources_update()`
   - `audit_recipe_sources_delete()`
4. **View:** `recipe_sources_audit_changes`

### Why It Was Removed
Based on the migration comments and task history, the audit infrastructure was removed as part of the Mealie-to-Tandoor migration cleanup. The infrastructure was no longer needed for this functionality.

### Audit Code (Now Obsolete)
The Gleam code for audit operations exists in:
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage/audit.gleam` (200+ lines)

This module is now **non-functional** since the underlying audit tables no longer exist in the database.

---

## Active Usage Points

### 1. Type Definitions
**Files:**
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/auto_planner/types.gleam` (lines 48-66)
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/auto_planner/ncp_auto_planner/types.gleam` (duplicate)

**Defined Types:**
```gleam
pub type RecipeSourceType {
  Database
  Api
  UserProvided
}

pub type RecipeSource {
  RecipeSource(
    id: String,
    name: String,
    source_type: RecipeSourceType,
    config: Option(String),
  )
}
```

### 2. Storage Operations
**Primary File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/auto_planner/storage.gleam` (lines 157-223)

**Functions:**

#### `save_recipe_source(conn, source) -> Result(Nil, StorageError)`
- **Lines:** 162-190
- **SQL:** `INSERT INTO recipe_sources (id, name, type, config) ... ON CONFLICT (id) DO UPDATE`
- **Purpose:** Save or update a recipe source in the database
- **Parameters:** Connection and RecipeSource record
- **Returns:** Result indicating success or error

**Code Example:**
```gleam
pub fn save_recipe_source(
  conn: pog.Connection,
  source: auto_types.RecipeSource,
) -> Result(Nil, StorageError) {
  let sql =
    "INSERT INTO recipe_sources (id, name, type, config)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       type = EXCLUDED.type,
       config = EXCLUDED.config"
  // ... execution code
}
```

#### `get_recipe_sources(conn) -> Result(List(RecipeSource), StorageError)`
- **Lines:** 192-223
- **SQL:** `SELECT id, name, type, config FROM recipe_sources ORDER BY name`
- **Purpose:** Retrieve all recipe sources from database
- **Parameters:** Connection only
- **Returns:** Result containing list of RecipeSource records

**Code Example:**
```gleam
pub fn get_recipe_sources(
  conn: pog.Connection,
) -> Result(List(auto_types.RecipeSource), StorageError) {
  let sql = "SELECT id, name, type, config FROM recipe_sources ORDER BY name"
  // ... decoder and execution code
}
```

### 3. Duplicate Storage Implementation
**File:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/auto_planner/ncp_auto_planner/storage.gleam`
- **Status:** Appears to be a duplicate of the main storage file
- **Lines:** 152-218 (same functions, identical implementation)

**Note:** This duplication may be a worktree artifact or leftover from refactoring. Both files contain the same storage operations.

### 4. Documentation References
**Files:**
- `/home/lewis/src/meal-planner/docs/POSTGRES_SETUP.md` (line 81) - Schema documentation
- `/home/lewis/src/meal-planner/MIGRATION_STATUS.md` - Migration tracking
- `/home/lewis/src/meal-planner/openspec/changes/archive/2025-12-12-migrate-mealie-to-tandoor/proposal.md` - Migration context
- `/home/lewis/src/meal-planner/openspec/changes/archive/2025-12-12-migrate-mealie-to-tandoor/tasks.md` - Task 7.6 mentions recipe_sources update

### 5. Test Coverage
**File:** `/home/lewis/src/meal-planner/gleam/test/migration_021_test.gleam` (97 lines)
- Tests the removal of audit infrastructure
- Documents expected drop order: triggers → functions → view → table
- Verifies CASCADE and IF EXISTS usage for safety

---

## Migration History

### Migration 009: Table Creation
**File:** `/home/lewis/src/meal-planner/gleam/migrations_pg/009_auto_meal_planner.sql`
- Created `recipe_sources` table with initial schema
- Created supporting indexes (type, enabled, config GIN)
- Created `update_updated_at_column()` trigger function
- Created `update_recipe_sources_timestamp` trigger

### Migration 014: Audit Infrastructure Added
**File:** `/home/lewis/src/meal-planner/gleam/migrations_pg/014_add_recipe_sources_audit.sql` (marked OBSOLETE)
- Created `recipe_sources_audit` table with comprehensive audit trail
- Created 3 trigger functions (insert, update, delete)
- Created 3 audit triggers
- Created `recipe_sources_audit_changes` view for easy querying
- Marked as OBSOLETE in header comment

### Migration 018: Audit Context Enhancement
**File:** `/home/lewis/src/meal-planner/gleam/migrations_pg/018_update_audit_triggers_context.sql`
- Updated audit triggers to capture context (changed_by, change_reason)
- Enhanced audit functionality with user tracking

### Migration 021: Audit Infrastructure Removed
**File:** `/home/lewis/src/meal-planner/gleam/migrations_pg/021_drop_recipe_sources_audit.sql`
- Removed all audit triggers
- Removed audit view
- Removed trigger functions
- Removed audit table
- Part of Mealie migration cleanup

### Rollback Support
**File:** `/home/lewis/src/meal-planner/gleam/migrations_pg/rollback/021_restore_recipe_sources_audit.sql`
- Restores complete audit infrastructure if needed
- Documented in `/home/lewis/src/meal-planner/gleam/migrations_pg/rollback/README.md`

---

## Data Flow Analysis

### How Recipe Sources Are Used

```
┌─────────────────────────────────────────────────────────┐
│                  Auto Meal Planner                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  1. get_recipe_sources(conn)                            │
│     └─> SELECT * FROM recipe_sources                    │
│         └─> List(RecipeSource) with Database, Api,      │
│             UserProvided types                          │
│                                                           │
│  2. Filter enabled sources                              │
│     └─> Use source type to determine fetch strategy     │
│                                                           │
│  3. Fetch recipes from source                           │
│     └─> Database → Local query                          │
│     └─> Api → External call using config                │
│     └─> UserProvided → Manual input                     │
│                                                           │
│  4. save_recipe_source(conn, source)                    │
│     └─> INSERT/UPDATE recipe_sources with config       │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

### Data Validation
**Constraints enforced by database:**
- `name` UNIQUE: Only one source per name
- `type` CHECK: Must be 'api', 'scraper', or 'manual'
- `enabled` DEFAULT: Sources are enabled by default

---

## Code Quality Observations

### Strengths
1. **Clear Separation:** Storage operations separated from types
2. **Type Safety:** Strong typing with Gleam types matching DB constraints
3. **Error Handling:** Proper Result types for database operations
4. **Decoder Pattern:** Proper use of Gleam decoder pattern for SQL parsing
5. **Idempotent Operations:** Uses `ON CONFLICT` for safe upserts
6. **Index Coverage:** Appropriate indexes for common queries (type, enabled, config)

### Issues Identified

1. **Duplicate Code (CRITICAL)**
   - File: `/home/lewis/src/meal-planner/gleam/src/meal_planner/auto_planner/ncp_auto_planner/storage.gleam`
   - Issue: Identical implementation to main storage file
   - Impact: Maintenance burden, risk of divergence
   - Recommendation: Remove duplicate or consolidate

2. **Orphaned Audit Code**
   - File: `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage/audit.gleam`
   - Issue: Implements queries against `recipe_sources_audit` table which no longer exists
   - Impact: Will crash if called; dead code
   - Recommendation: Remove or update to reflect current schema

3. **Type Mapping Inconsistency**
   - Storage code: Maps types as "database", "api", "user_provided"
   - Migration SQL: Defines types as "api", "scraper", "manual"
   - Impact: Type constraint violation risk
   - Recommendation: Align both to same set of valid types

4. **Missing Handler Functions**
   - No API endpoints found for recipe source management
   - Uses of get_recipe_sources/save_recipe_source are limited
   - Recommendation: Implement REST API if intended as user-facing feature

---

## Risk Assessment

### High Risk Items
1. **Audit Code Still Exists:** `/gleam/src/meal_planner/storage/audit.gleam` (200+ lines) will fail if called
2. **Type Constraint Mismatch:** Database vs. code type definition inconsistency
3. **Duplicate Storage Code:** Difficult to maintain, risk of divergence

### Medium Risk Items
1. **No Active Web Handlers:** Recipe sources can't be managed via API
2. **Limited Testing:** Only migration test exists, no functional tests

### Low Risk Items
1. **Missing Documentation:** Rollback procedure well documented
2. **Schema Stability:** Table structure unlikely to change

---

## File Reference Index

### Migration Files
| File | Purpose | Status |
|------|---------|--------|
| `009_auto_meal_planner.sql` | Creates recipe_sources table | Active |
| `014_add_recipe_sources_audit.sql` | Adds audit infrastructure | Obsolete |
| `018_update_audit_triggers_context.sql` | Enhances audit context | Superseded |
| `021_drop_recipe_sources_audit.sql` | Removes audit infrastructure | Active |
| `rollback/021_restore_recipe_sources_audit.sql` | Rollback script | Standby |

### Gleam Files
| File | Purpose | Status |
|------|---------|--------|
| `auto_planner/types.gleam` | Type definitions | Active |
| `auto_planner/storage.gleam` | Storage operations | Active |
| `auto_planner/ncp_auto_planner/types.gleam` | Duplicate types | Duplicate |
| `auto_planner/ncp_auto_planner/storage.gleam` | Duplicate storage | Duplicate |
| `storage/audit.gleam` | Audit operations | Orphaned |

### Documentation Files
| File | Purpose |
|------|---------|
| `docs/POSTGRES_SETUP.md` | Schema overview |
| `gleam/migrations_pg/rollback/README.md` | Rollback procedures |
| `MIGRATION_STATUS.md` | Migration tracking |
| `openspec/changes/archive/.../proposal.md` | Context for migration |
| `test/migration_021_test.gleam` | Migration tests |

---

## Recommendations

### Immediate Actions
1. **Remove Orphaned Code**
   - Delete `/gleam/src/meal_planner/storage/audit.gleam` (dead code)
   - It cannot function after migration 021

2. **Fix Type Consistency**
   - Align storage.gleam type mappings with migration 009 constraints
   - Current: "database", "api", "user_provided"
   - Expected: "api", "scraper", "manual"

3. **Remove Duplicate Storage**
   - Consolidate `auto_planner/ncp_auto_planner/storage.gleam` into main storage
   - Update imports in any files using the duplicate

### Short-term Improvements
1. **Add API Handlers** (if recipe sources should be user-configurable)
   - Create GET `/api/recipe-sources` endpoint
   - Create POST/PUT `/api/recipe-sources/{id}` endpoint
   - Create DELETE `/api/recipe-sources/{id}` endpoint

2. **Add Tests**
   - Functional tests for save_recipe_source
   - Functional tests for get_recipe_sources
   - Integration tests with auto meal planner

3. **Update Documentation**
   - Add API documentation for recipe sources
   - Document how sources are selected by auto planner
   - Update POSTGRES_SETUP.md with current schema

### Long-term Strategy
1. **Consider Audit Restoration** (if regulatory requirement)
   - Current code exists only in rollback
   - Could restore migration 021 if needed
   - Would require running: `rollback/021_restore_recipe_sources_audit.sql`

2. **Optimize Query Performance**
   - Monitor GIN index usage on config column
   - Consider caching recipe sources in application memory
   - Add query logging to track usage patterns

3. **Schema Evolution**
   - Add `updated_by` field for tracking changes without triggers
   - Consider renaming `type` to `source_type` for clarity
   - Add `priority` field for source selection ordering

---

## Conclusion

The `recipe_sources` table is a well-designed component of the auto meal planner feature, currently:
- **Active and functional** in the database
- **Properly indexed** for performance
- **Type-safe** in the Gleam implementation
- **Documented** for rollback and recovery

However, **maintenance issues** need attention:
1. Dead code (audit.gleam) should be removed
2. Type inconsistencies should be resolved
3. Duplicate implementations should be consolidated
4. Test coverage should be expanded

The table's purpose is clear: configure and track recipe sources for the auto meal planner feature, supporting three types of sources (API, scraper, manual) with JSON configuration for source-specific settings.
