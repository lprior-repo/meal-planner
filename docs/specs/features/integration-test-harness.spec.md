# Feature: Create Gleam Integration Test Harness

## Bead ID: meal-planner-eem

## Dependencies
- meal-planner-kz2: Port unit tests to Gleam gleeunit (CLOSED)

## Feature Description
Create a comprehensive integration test harness for end-to-end testing of the meal planner application, including database operations, web server responses, and NCP reconciliation flows.

## Capabilities

### Capability 1: Database Integration Tests
**Behaviors:**
- GIVEN clean database WHEN running init_db THEN all tables are created
- GIVEN recipe data WHEN saving and retrieving THEN data round-trips correctly
- GIVEN user profile WHEN updating THEN changes persist across connections
- GIVEN food log entries WHEN querying by date THEN correct entries returned

### Capability 2: Web Server Integration Tests
**Behaviors:**
- GIVEN running server WHEN GET /api/recipes THEN return JSON array of recipes
- GIVEN running server WHEN GET /api/profile THEN return user profile JSON
- GIVEN running server WHEN POST /api/logs THEN create food log entry
- GIVEN running server WHEN GET /recipes/:id THEN return SSR HTML page

### Capability 3: NCP Flow Integration Tests
**Behaviors:**
- GIVEN nutrition history WHEN running reconciliation THEN produce adjustment plan
- GIVEN deviation from targets WHEN scoring recipes THEN return ranked suggestions
- GIVEN multiple days of logs WHEN averaging THEN calculate correct averages

### Capability 4: Test Fixtures and Helpers
**Behaviors:**
- GIVEN test module WHEN importing THEN have access to sample_recipe() helper
- GIVEN test module WHEN importing THEN have access to sample_profile() helper
- GIVEN test database WHEN test starts THEN use isolated temp database
- GIVEN test database WHEN test ends THEN cleanup temp files

## Acceptance Criteria
- [ ] Integration tests run in CI pipeline
- [ ] Tests use isolated databases (no shared state)
- [ ] Test helpers reduce boilerplate
- [ ] All critical paths have integration tests
- [ ] Tests complete in under 30 seconds

## Test Criteria (BDD)
```gherkin
Scenario: Full recipe CRUD flow
  Given a clean test database
  When creating a new recipe
  And retrieving the recipe by ID
  Then the retrieved recipe matches the created one
  And cleanup removes the test database

Scenario: NCP reconciliation produces suggestions
  Given a user profile with moderate activity
  And 3 days of nutrition logs with protein deficit
  When running reconciliation
  Then adjustment plan contains high-protein recipes
  And suggestions are ranked by relevance
```
