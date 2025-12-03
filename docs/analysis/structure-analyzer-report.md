# Directory Structure Analysis Report

**Agent**: structure-analyzer
**Thread**: CLEANUP-2025-001
**Project**: /home/lewis/src/meal-planner
**Timestamp**: 2025-12-03T11:56:00Z
**Status**: ✅ COMPLETE

---

## Executive Summary

Comprehensive analysis of the meal-planner project directory structure reveals **10 organizational issues** with **2 CRITICAL** problems requiring immediate attention.

### Key Metrics
- **Total directories scanned**: 25+
- **Total files identified**: 1,500+
- **Repository size**: ~324MB
- **Potential size reduction**: 208MB (64%)
- **Estimated cleanup time**: 4-6 hours

---

## Critical Issues (Immediate Action Required)

### 1. 🔴 Database Files in Git Repository (CRITICAL)

**Problem**: Multiple SQLite database files are tracked or modified in git:
- `.beads/beads.db` + WAL files
- `.hive-mind/hive.db`
- `.swarm/memory.db` + WAL files (72KB, currently modified)

**Impact**:
- Repository pollution
- Potential data leaks
- Merge conflicts on binary files
- Bloated git history

**Action Required**:
```bash
# Update .gitignore
echo "*.db" >> .gitignore
echo "*.db-shm" >> .gitignore
echo "*.db-wal" >> .gitignore
echo ".swarm/" >> .gitignore
echo ".hive-mind/" >> .gitignore
echo ".beads/beads.db*" >> .gitignore

# Remove from git tracking
git rm --cached .beads/beads.db*
git rm --cached .hive-mind/hive.db
git rm --cached .swarm/memory.db*
```

**Time Estimate**: 15 minutes

---

### 2. 🔴 Oversized db_export/ Directory (CRITICAL)

**Problem**: Database export directory consuming 208MB (64% of repository)

**Impact**:
- Massive repository bloat
- Slow clone/pull operations
- Storage waste
- Likely doesn't belong in version control

**Options**:
1. **Move to external storage** (Recommended)
   - Upload to cloud storage (S3, Google Drive, etc.)
   - Update documentation with location
   - Add to .gitignore

2. **Add to .gitignore only**
   - Keep local copy
   - Prevent future commits

3. **Archive and delete**
   - Create compressed backup
   - Remove from repository

**Action Required**:
```bash
# Option 1: Add to .gitignore
echo "db_export/" >> .gitignore
git rm -r --cached db_export/

# Option 2: Move to external location
mv db_export/ ~/backups/meal-planner-db-export-$(date +%Y%m%d)
echo "db_export/" >> .gitignore
```

**Time Estimate**: 15-30 minutes

---

## High Priority Issues

### 3. 🟡 Root-Level Scripts (HIGH)

**Problem**: Utility scripts in root directory instead of organized location

**Misplaced Files**:
- `debug-browser.mjs` (1.5KB) → should be in `scripts/debug/`
- `claude-flow` (1.1KB) → should be in `scripts/tools/`

**Action Required**:
```bash
mkdir -p scripts/debug scripts/tools
mv debug-browser.mjs scripts/debug/
mv claude-flow scripts/tools/
git add scripts/
git commit -m "refactor: organize root scripts into subdirectories"
```

**Time Estimate**: 20 minutes

---

## Medium Priority Issues

### 4. ⚠️ Duplicate Metrics Directories

**Problem**: Metrics stored in two locations:
- `.claude-flow/metrics/` (476KB, 4 files)
- `gleam/.claude-flow/metrics/` (2 files)

**Bloated File**: `system-metrics.json` (475KB)

**Action Required**:
1. Determine if gleam metrics are needed separately
2. If not, remove `gleam/.claude-flow/metrics/`
3. Implement metrics rotation for large files
4. Consider adding `*.json` files in metrics to .gitignore

**Time Estimate**: 15 minutes

---

### 5. ⚠️ Large Files Exceeding Guidelines (>500 lines)

**Critical Files Needing Refactoring**:

| File | Lines | Status | Recommendation |
|------|-------|--------|----------------|
| `gleam/src/meal_planner/web.gleam` | 1,522 | 🔴 CRITICAL | Split into routes/, handlers/, middleware/ |
| `gleam/src/meal_planner/storage.gleam` | 1,384 | 🔴 CRITICAL | Split into storage/queries.gleam, storage/models.gleam |
| `gleam/test/ncp_test.gleam` | 1,475 | 🟡 WARNING | Consider splitting test suites |
| `gleam/src/meal_planner/ncp.gleam` | 835 | 🟡 WARNING | Monitor, may need refactoring soon |
| `gleam/test/save_food_to_log_test.gleam` | 602 | 🟡 WARNING | Acceptable for comprehensive tests |
| `gleam/src/meal_planner/vertical_diet_recipes.gleam` | 595 | 🟡 WARNING | Extract recipe data to separate file |

**Impact**:
- Reduced maintainability
- Harder code reviews
- Increased cognitive load
- Violates project guidelines (500 line limit)

**Time Estimate**: 4-5 hours for major refactoring

---

### 6. ⚠️ Documentation Organization

**Problem**: 50+ markdown files scattered in `docs/` root

**Untracked Files**:
- `docs/architecture/save_food_to_log_design.md` (new, untracked)
- `gleam/priv/static/css/recipe-form.css` (new, untracked)
- `gleam/src/meal_planner/auto_planner.gleam` (new, untracked)
- `gleam/src/meal_planner/ui/recipe_form.gleam` (new, untracked)

**Recommended Structure**:
```
docs/
├── architecture/     # Design documents
├── api/             # API documentation
├── guides/          # User guides
├── analysis/        # Analysis reports (newly created)
└── README.md        # Docs index
```

**Action Required**:
1. Create subdirectories
2. Move docs into appropriate folders
3. Add untracked files to git
4. Consider merging `specs/` into `docs/architecture/`

**Time Estimate**: 30-45 minutes

---

### 7. ⚠️ Server Directory Ambiguity

**Problem**: Unclear purpose of separate `server/` directory (268KB) when `gleam/` is the main application

**Questions**:
- Is this legacy code?
- Is it a separate service?
- Should it be merged into gleam/?

**Action Required**:
1. Document purpose in README
2. If obsolete, archive and remove
3. If active, clarify relationship to gleam/

**Time Estimate**: 15-30 minutes (depending on complexity)

---

### 8. ⚠️ Untracked Source Files

**Problem**: New source files not yet in git

**Files**:
- `gleam/src/meal_planner/auto_planner.gleam`
- `gleam/src/meal_planner/ui/recipe_form.gleam`
- `gleam/priv/static/css/recipe-form.css`
- `docs/architecture/save_food_to_log_design.md`

**Action Required**:
```bash
git add gleam/src/meal_planner/auto_planner.gleam
git add gleam/src/meal_planner/ui/recipe_form.gleam
git add gleam/priv/static/css/recipe-form.css
git add docs/architecture/save_food_to_log_design.md
git commit -m "feat: add auto-planner and recipe form modules"
```

**Time Estimate**: 10 minutes

---

## Low Priority Issues

### 9. ℹ️ Empty/Minimal Directories

**Directories**:
- `mcp_agent_mail/` (empty, 0 bytes)
- `memory/` (minimal, 12KB)

**Action Required**: Document purpose or remove if unused

### 10. ℹ️ Build Artifacts

**Issue**: Verify `gleam/build/` is properly gitignored

---

## Deliverables Created

✅ **Comprehensive JSON Reports**:
1. `/home/lewis/src/meal-planner/docs/analysis/directory_map.json`
   - Complete directory tree with metadata
   - File type distribution
   - Size analysis
   - Metrics analysis

2. `/home/lewis/src/meal-planner/docs/analysis/misplaced_files.json`
   - Detailed list of misplaced files
   - Recommended locations
   - Severity classifications
   - Action items

3. `/home/lewis/src/meal-planner/docs/analysis/root_level_issues.json`
   - Root directory analysis
   - Cleanup priorities
   - Large file analysis
   - Impact assessment

---

## Recommended .gitignore Additions

```gitignore
# Database files (CRITICAL)
*.db
*.db-shm
*.db-wal

# Runtime directories
.swarm/
.hive-mind/
.beads/beads.db*

# Large data exports
db_export/

# Metrics (optional - consider rotation instead)
.claude-flow/metrics/*.json
```

---

## Action Plan Priority Matrix

| Priority | Action | Time | Impact |
|----------|--------|------|--------|
| 🔴 P1 | Update .gitignore with database patterns | 5 min | Critical |
| 🔴 P1 | Remove database files from git tracking | 10 min | Critical |
| 🔴 P2 | Handle db_export/ directory | 15 min | High |
| 🟡 P3 | Organize root scripts | 20 min | Medium |
| 🟡 P4 | Consolidate metrics directories | 15 min | Medium |
| 🟡 P5 | Add untracked source files to git | 10 min | Medium |
| 🟡 P6 | Organize documentation | 45 min | Medium |
| ℹ️ P7 | Refactor web.gleam (1522 lines) | 2-3 hrs | Long-term |
| ℹ️ P8 | Refactor storage.gleam (1384 lines) | 2-3 hrs | Long-term |

**Estimated Total Cleanup Time**:
- Quick wins (P1-P6): 1-2 hours
- Complete cleanup: 4-6 hours

---

## Impact Assessment

### Repository Size Impact
- **Current size**: ~324MB
- **Potential reduction**: 208MB (64%)
- **After cleanup**: ~116MB

### Code Quality Impact
- **Files exceeding guidelines**: 11 files over 500 lines
- **Critical refactoring needed**: 2 files (web.gleam, storage.gleam)
- **Test files**: 7 large test files (acceptable)

### Organization Impact
- **Root directory**: 2 misplaced scripts
- **Documentation**: 50+ files need organization
- **Metrics**: Duplicate storage locations

---

## Next Steps for Coordinator

1. **Review findings** in JSON reports
2. **Prioritize actions** based on team bandwidth
3. **Assign cleanup tasks** to appropriate agents:
   - File operations → file-organizer agent
   - Git operations → git-cleanup agent
   - Code refactoring → code-quality agent
4. **Create backup** before major changes
5. **Execute cleanup** in priority order
6. **Verify changes** don't break builds/tests

---

## Status: Analysis Complete ✅

All deliverables created and stored in `/home/lewis/src/meal-planner/docs/analysis/`

**structure-analyzer** ready for next assignment.
