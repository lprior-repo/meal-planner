# Feature: Achieve 90% Test Coverage in Gleam

## Bead ID: meal-planner-vs2

## Dependencies
- meal-planner-386: Port property tests to Gleam qcheck

## Feature Description
Achieve comprehensive 90% code coverage across all Gleam modules using gleeunit for unit tests and qcheck for property-based tests.

## Capabilities

### Capability 1: Identify Coverage Gaps
**Behaviors:**
- GIVEN all Gleam source files WHEN analyzing THEN identify untested functions
- GIVEN gleam/src/meal_planner/*.gleam WHEN scanning THEN list functions without test coverage
- GIVEN server/src/server/*.gleam WHEN scanning THEN list functions without test coverage

### Capability 2: Add Missing Unit Tests
**Behaviors:**
- GIVEN untested function WHEN writing test THEN follow AAA pattern (Arrange, Act, Assert)
- GIVEN edge case scenario WHEN writing test THEN include boundary conditions
- GIVEN error path WHEN writing test THEN verify error handling

### Capability 3: Add Property-Based Tests
**Behaviors:**
- GIVEN Macros type WHEN property testing THEN verify macros_add is commutative
- GIVEN Macros type WHEN property testing THEN verify macros_scale with factor 1.0 returns same
- GIVEN Recipe scoring WHEN property testing THEN verify scores are in [0.0, 1.0] range

### Capability 4: Integration Test Coverage
**Behaviors:**
- GIVEN storage module WHEN testing THEN verify CRUD operations round-trip
- GIVEN web routes WHEN testing THEN verify response codes and content types
- GIVEN NCP reconciliation WHEN testing THEN verify end-to-end flow

## Acceptance Criteria
- [ ] 90% line coverage achieved
- [ ] All public functions have at least one test
- [ ] Property tests cover algebraic properties
- [ ] Edge cases documented and tested
- [ ] CI runs all tests on each commit

## Test Criteria (BDD)
```gherkin
Scenario: Verify Macros addition is commutative
  Given arbitrary Macros a and b from qcheck generator
  When calculating macros_add(a, b)
  And calculating macros_add(b, a)
  Then both results are equal

Scenario: Verify recipe scoring bounds
  Given arbitrary Recipe and Deviation from qcheck generators
  When scoring recipe against deviation
  Then score is >= 0.0
  And score is <= 1.0
```
