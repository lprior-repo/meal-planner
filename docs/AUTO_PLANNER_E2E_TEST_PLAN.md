# Auto Planner End-to-End Test Plan

**Task**: meal-planner-l5tz - Test auto planner with Mealie recipes end-to-end
**Status**: Planning and Documentation
**Date**: 2025-12-12

## Executive Summary

This document outlines a comprehensive end-to-end testing strategy for the auto meal planner functionality using Tandoor (formerly Mealie) recipes. The tests validate the complete workflow from recipe filtering through meal plan generation.

## Test Objectives

1. **Recipe Integration**: Verify auto planner correctly processes recipes from Tandoor
2. **Diet Filtering**: Validate recipes are filtered by diet principles (Vertical Diet, Tim Ferriss, etc.)
3. **Scoring System**: Test multi-factor scoring (diet compliance, macro match, variety)
4. **Selection Algorithm**: Verify top-N recipe selection with variety consideration
5. **Plan Generation**: End-to-end validation of auto meal plan generation
6. **Error Handling**: Test edge cases and error conditions

## Test Architecture

### Current Project State

The project is undergoing refactoring from Mealie to Tandoor integration:
- `auto_planner.gleam` - Currently disabled (moved to `.skip`)
- `ncp_auto_planner/types.gleam` - Contains core types
- `recipe_scorer.gleam` - Scoring functionality
- `storage.gleam` - Persistence layer

### Test Suite Components

```
Test Pyramid:
         /\
        /E2E\      <- Full workflow tests
       /------\
      /Integr. \   <- Component integration
     /----------\
    /   Unit     \ <- Individual functions
   /--------------\
```

## Test Categories

### 1. Unit Tests (Foundation)

#### Configuration Validation
- [ ] Valid config accepted
- [ ] Recipe count validation (1-20)
- [ ] Variety factor validation (0.0-1.0)
- [ ] Macro targets must be positive
- [ ] Config error messages are descriptive

#### Recipe Filtering
- [ ] Filter by Vertical Diet principle
- [ ] Filter by Tim Ferriss principle
- [ ] Filter by Paleo, Keto, Mediterranean principles
- [ ] Empty principle list returns all recipes
- [ ] Multiple principles use AND logic

#### Scoring Functions
- [ ] Macro match score calculation
  - Perfect match = high score (>0.9)
  - Poor match = low score (<0.2)
  - Exponential decay formula validated

- [ ] Diet compliance scoring
  - Vertical diet + low FODMAP = 1.0
  - Non-compliant = 0.0

- [ ] Variety scoring
  - First recipe = 1.0
  - Duplicate category = 0.4
  - Multiple duplicates = 0.2

- [ ] Overall score weighting
  - Diet: 40%
  - Macros: 35%
  - Variety: 25%

### 2. Integration Tests

#### Recipe Selection
- [ ] Select top N recipes works correctly
- [ ] Variety factor influences selection
- [ ] Selected recipes have proper diversity

#### Macro Calculations
- [ ] Total macros sum correctly
- [ ] Per-recipe macro targets calculated correctly
- [ ] Macro deviations properly scored

#### Type Conversions
- [ ] Diet principles to/from string
- [ ] JSON serialization of plans
- [ ] JSON serialization of recipes

### 3. End-to-End Tests

#### Full Workflow
- [ ] Generate meal plan with 3 recipes
  - Input: 6+ vertical diet recipes
  - Output: 3 selected recipes with totals

- [ ] Error handling: insufficient recipes
  - Request 20 recipes from pool of 6
  - Expect descriptive error

- [ ] Error handling: invalid config
  - recipe_count = 0
  - Expect validation error

- [ ] Different diet principles
  - Tim Ferriss diet workflow
  - Paleo diet workflow

- [ ] Edge cases
  - Empty recipe list
  - Single recipe
  - Timestamp generation
  - Plan ID uniqueness

#### Tandoor Integration Points

1. **Recipe Source**
   - Recipes from Tandoor API
   - FODMAP levels from Tandoor
   - Vertical diet compliance flags
   - Nutrient data from USDA database

2. **Plan Persistence**
   - Auto meal plans stored in DB
   - recipe_json field preserves full recipe data
   - Config saved with plan
   - Timestamps in ISO8601 format

3. **User Context**
   - user_id associated with plans
   - User preferences for diet principles
   - Macro targets per user

## Test Fixtures

### Sample Recipes (Tandoor)

```gleam
// Vertical Diet Compliant (Low FODMAP)
- Grass-fed Beef with Root Vegetables (P:45, F:25, C:15)
- Wild Salmon with Sweet Potato (P:40, F:20, C:18)
- Grass-fed Liver with Onions (P:30, F:8, C:6)
- Beef Heart Steak (P:35, F:10, C:4)

// Non-Compliant (High FODMAP)
- Whole Wheat Pasta (P:12, F:2, C:45)
- Garlic and Onion Soup (P:8, F:5, C:20)
```

### Configuration Examples

```gleam
// Vertical Diet Config
AutoPlanConfig(
  user_id: "user-123",
  diet_principles: [VerticalDiet],
  macro_targets: Macros(protein: 150.0, fat: 100.0, carbs: 200.0),
  recipe_count: 3,
  variety_factor: 0.8,
)

// Tim Ferriss Config
AutoPlanConfig(
  user_id: "user-456",
  diet_principles: [TimFerriss],
  macro_targets: Macros(protein: 120.0, fat: 80.0, carbs: 150.0),
  recipe_count: 3,
  variety_factor: 0.7,
)
```

## Expected Behaviors

### Success Path
1. User selects diet principle (Vertical Diet)
2. System fetches recipes from Tandoor
3. Auto planner filters recipes by:
   - Diet compliance (vertical_compliant flag)
   - FODMAP level (Low only)
4. Recipes scored on:
   - Diet compliance: 1.0 for compliant
   - Macro match: exponential decay from target
   - Variety: 1.0 for unique, 0.4 for first duplicate, 0.2 for additional
5. Top 3 recipes selected
6. Total macros calculated
7. Plan serialized to JSON
8. Plan saved to database

### Error Paths
- Insufficient compliant recipes → Clear error message
- Invalid configuration → Validation error with details
- Empty recipe list → Error
- Network error fetching Tandoor → Graceful degradation

## Metrics

### Code Coverage Targets
- Statements: >85%
- Branches: >80%
- Functions: >85%
- Lines: >85%

### Performance Expectations
- Recipe filtering: <10ms for 1000 recipes
- Scoring 100 recipes: <50ms
- Plan generation: <100ms
- JSON serialization: <20ms

## Current Blockers

### 1. Compilation Errors
The project has pre-existing syntax errors in `recipe_mappings.gleam` preventing test execution:
- Pattern matching in function parameters needs refactoring
- `pog.Returned` pattern matching syntax issues

**Mitigation**: These are unrelated to auto planner E2E tests and should be fixed in a separate task.

### 2. Module Architecture
The `auto_planner.gleam` module was disabled in commit bb280bc:
- Module moved to `auto_planner.gleam.skip`
- Core types moved to `ncp_auto_planner/types.gleam`
- Tests need to reference correct module paths

**Mitigation**: Tests should import from `ncp_auto_planner` modules.

### 3. Type Compatibility
The existing `auto_planner_save_load_test.gleam` has type mismatches:
- Recipe type fields don't match test expectations
- String operations returning unexpected types

**Mitigation**: Update test fixtures to match current Recipe type definition.

## Test Execution Plan

### Phase 1: Unit Tests (Week 1)
- Create `auto_planner_unit_tests.gleam`
- Test individual scoring functions
- Test filtering logic
- Test configuration validation
- Expected: 30+ unit tests

### Phase 2: Integration Tests (Week 2)
- Create `auto_planner_integration_tests.gleam`
- Test recipe selection algorithm
- Test macro calculations
- Test type conversions
- Expected: 20+ integration tests

### Phase 3: E2E Tests (Week 3)
- Create `auto_planner_e2e_tests.gleam`
- Full workflow tests
- Error condition tests
- Tandoor integration points
- Expected: 15+ E2E tests

### Phase 4: Performance Tests (Week 4)
- Create `auto_planner_performance_tests.gleam`
- Benchmark large recipe sets
- Validate response times
- Memory profiling
- Expected: 10+ performance tests

## Dependencies

```
Test Requirements:
├── gleeunit (test framework)
├── gleam/list (filtering)
├── gleam/float (scoring)
├── gleam/int (configuration)
├── gleam/json (serialization)
└── meal_planner modules
    ├── types (Recipe, Macros)
    ├── auto_planner/ncp_auto_planner/types
    ├── auto_planner/recipe_scorer
    └── auto_planner/storage
```

## Success Criteria

- [ ] All unit tests pass (100% pass rate)
- [ ] All integration tests pass (100% pass rate)
- [ ] All E2E tests pass (100% pass rate)
- [ ] Code coverage >80% for auto_planner modules
- [ ] Performance tests show <100ms for full plan generation
- [ ] Error messages are clear and actionable
- [ ] Tests document expected behavior
- [ ] Tests work with Tandoor recipe format

## Documentation

Each test includes:
1. **Purpose** - What behavior is being tested
2. **Setup** - Test fixtures and preconditions
3. **Action** - The operation being tested
4. **Assertion** - Expected outcomes
5. **Edge Cases** - Related scenarios

## Maintenance

- Tests updated when auto_planner API changes
- Fixtures updated when Tandoor recipe format changes
- Performance baselines reviewed quarterly
- Coverage reports reviewed at each commit

## References

- Auto Planner Architecture: `docs/AUTO_PLANNER.md`
- Tandoor Integration: `docs/TANDOOR_INTEGRATION.md`
- Migration Guide: `docs/migrations/MEALIE_TO_TANDOOR.md`
- Type Definitions: `gleam/src/meal_planner/types.gleam`
