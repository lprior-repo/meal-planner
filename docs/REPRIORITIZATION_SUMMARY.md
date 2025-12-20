# MEAL-PLANNER IMPLEMENTATION ROADMAP - FINAL
## Status: Reprioritized for Feature-First Development

### Executive Summary
- **Total Active Tasks**: 45 (down from 57)
- **Status**: ALL READY - 0 blockers
- **Workflow**: ARCHITECT → CODER (2-phase instead of 4-phase)
- **Estimated Timeline**: 4-6 weeks for complete MVP
- **Strategy**: Parallelizable, acceptance of technical debt for speed

---

## PRIORITY LEVELS & BREAKDOWN

### P1 - CRITICAL FOUNDATION (11 tasks)
Handler implementations for complete API coverage

**Tandoor Handlers** (6 tasks)
- Types: Recipes, Foods/Ingredients, Shopping Lists
- Implementation: Each handler ~100-150 lines

**FatSecret Handlers** (4 tasks)
- Types: Food Brands (missing endpoint)
- Implementation: Brands handler ~80 lines

### P2 - CORE FEATURES (28 tasks)
CLI commands, automation, database schemas

**CLI Commands** (14 tasks)
- Tandoor: sync, categories, update fix
- FatSecret: ingredients
- Plan: generate, sync
- Nutrition: report, trends, compliance, goals
- Scheduler: list, status, trigger, executions

**Automation Layer** (12 tasks)
- Scheduler daemon & HTTP routes
- Email infrastructure (receiver/sender/executor)
- Sync logic (FatSecret matching)
- Generation algorithm (meal planning)

**Database** (2 tasks)
- 3 new schemas (user preferences, sync metadata, upload queue)
- Migration application

### P3 - POLISH (6 tasks)
TUI screens for user interface

- Food Search Popup component
- FatSecret Diary screen
- Recipe Browser
- Meal Plan Generator
- Nutrition Dashboard
- Weight Tracker
- Shopping List

---

## DEFERRED WORK (12 tasks - Closed)

### Testing (5 tasks)
- ✗ Unit tests for all handlers
- ✗ RED phase tests (removed from workflow)

### Refactoring (4 tasks)
- ✗ Code optimization
- ✗ Gleam idiom improvements
- ✗ BLUE phase optimization

### Monitoring (3 tasks)
- ✗ Integration testing
- ✗ Logging infrastructure

**Recovery Plan**: Phases 5-8 post-MVP will implement all deferred work

---

## PRESERVED CRITICAL WORK

✅ ARCHITECT tasks (all 7)
   - Define types & contracts
   - Ensure integration points

✅ Error handling in CODER phase
   - Result/Option patterns
   - Basic error propagation

✅ Database schemas
   - User preferences
   - Sync tracking
   - Offline queueing

✅ HTTP routes
   - Scheduler API
   - Daemon coordination

---

## PARALLELIZATION STRATEGY

### Track A: Handlers (2 weeks)
1. All ARCHITECT tasks in parallel
2. All CODER tasks in parallel
3. No dependencies between tasks

### Track B: Automation & Database (3-4 weeks)
1. Database schemas (independent)
2. Automation layer (depends on scheduler types)
3. CLI commands (depends on handlers)

### Track C: TUI Screens (2-3 weeks)
1. Food Search component (blocks others)
2. 6 screens in parallel (after component)

**Total: 4-6 weeks for MVP**

---

## TECHNICAL DEBT DECISION

### Why Accept Debt?
- MVP requires 100% API coverage + CLI/TUI
- Testing/refactoring don't accelerate feature delivery
- Type system prevents many classes of bugs
- Recovery plan documented (Phases 5-8)

### What's Accepted?
- ❌ No unit tests initially
- ❌ No integration tests
- ❌ No code optimization
- ❌ No monitoring infrastructure

### What's Preserved?
- ✅ Type definitions (ARCHITECT phase)
- ✅ Error handling (CODER phase)
- ✅ Database schemas
- ✅ Core architecture
- ✅ Git history (reversible)

---

## SUCCESS METRICS

### API Coverage
- Tandoor: 40% → 100%
- FatSecret: 84% → 100%

### CLI Implementation
- 16/16 commands working
- 0 stubs remaining

### TUI Implementation
- 6/6 screens functional
- 0 placeholder screens

### Automation
- Scheduler running
- Email feedback loop
- FatSecret sync working
- Meal generation working

### Quality Gates
- `gleam build` ✅
- `make test` ✅
- `gleam format --check` ✅
- Git history preserved ✅

---

## NEXT STEPS

1. **Claim P1 handler tasks** → Start ARCHITECT definitions
2. **Complete ARCHITECT phase** → All types compiled
3. **Implement CODER phase** → Minimal implementations
4. **Integrate with CLI** → Connect to existing structure
5. **Build automation** → Scheduler, sync, generation
6. **Build TUI screens** → User interface

---

## RECOVERY PLAN (Post-MVP)

**Phase 5**: Comprehensive test coverage (100+ tests)
**Phase 6**: Code refactoring for idiom
**Phase 7**: Integration testing (15+20 tests)
**Phase 8**: Monitoring & logging infrastructure

---

## Key Dates & Milestones

- **Week 1**: All handler ARCHITECT tasks complete
- **Week 2**: All handler CODER tasks complete
- **Week 3**: CLI commands foundation working
- **Week 4**: Automation layer operational
- **Week 5-6**: TUI screens complete

