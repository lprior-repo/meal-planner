# Feature: Port Property Tests to Gleam qcheck

## Bead ID: meal-planner-386

## Dependencies
- meal-planner-kz2: Port unit tests to Gleam gleeunit (CLOSED)

## Blocks
- meal-planner-vs2: Achieve 90% test coverage in Gleam

## Feature Description
Implement property-based testing using Gleam's qcheck library to verify algebraic properties, invariants, and edge cases that unit tests might miss.

## Capabilities

### Capability 1: Set Up qcheck Dependency
**Behaviors:**
- GIVEN gleam.toml WHEN adding dependency THEN include qcheck >= 1.0.0
- GIVEN test module WHEN importing THEN access qcheck/qtest and qcheck/generators
- GIVEN property test WHEN running THEN execute 100+ random cases

### Capability 2: Macros Type Properties
**Behaviors:**
- GIVEN macros_add(a, b) WHEN testing THEN verify commutative: add(a,b) == add(b,a)
- GIVEN macros_add(a, b, c) WHEN testing THEN verify associative: add(add(a,b),c) == add(a,add(b,c))
- GIVEN macros_scale(m, 1.0) WHEN testing THEN verify identity: result == m
- GIVEN macros_scale(m, 0.0) WHEN testing THEN verify zero: result == macros_zero()
- GIVEN macros_calories(m) WHEN testing THEN verify non-negative for non-negative inputs

### Capability 3: Recipe Scoring Properties
**Behaviors:**
- GIVEN any recipe and deviation WHEN scoring THEN score in [0.0, 1.0]
- GIVEN zero deviation WHEN scoring THEN all recipes score equally
- GIVEN recipe with exact deficit match WHEN scoring THEN score is maximal

### Capability 4: User Profile Properties
**Behaviors:**
- GIVEN any valid profile WHEN calculating targets THEN protein >= 0
- GIVEN any valid profile WHEN calculating targets THEN fat >= 0
- GIVEN any valid profile WHEN calculating targets THEN carbs >= 0
- GIVEN higher bodyweight WHEN calculating targets THEN higher protein target

## Acceptance Criteria
- [ ] qcheck added to dev-dependencies
- [ ] At least 10 property tests written
- [ ] Properties cover Macros, Recipe scoring, UserProfile
- [ ] Tests pass with 100 iterations
- [ ] Shrinking works to find minimal counterexamples

## Test Criteria (BDD)
```gherkin
Scenario: Macros addition is commutative
  Given qcheck generator for Macros type
  When generating 100 random pairs (a, b)
  Then for all pairs: macros_add(a, b) == macros_add(b, a)

Scenario: Recipe scores are bounded
  Given qcheck generators for Recipe and Deviation
  When scoring 100 random (recipe, deviation) pairs
  Then all scores are >= 0.0 and <= 1.0

Scenario: Higher bodyweight means higher protein target
  Given qcheck generator for valid UserProfile
  When comparing two profiles where only bodyweight differs
  Then higher bodyweight profile has higher protein target
```
