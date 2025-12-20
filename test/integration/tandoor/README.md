# Tandoor Integration Tests

This directory contains comprehensive integration tests for Tandoor handlers.

## Test Files

### 1. recipes_handler_test.gleam (31 tests)
Tests for Recipe CRUD operations:
- List recipes with pagination
- Get single recipe with full details
- Create recipes with validation
- Update recipes (partial and full updates)
- Delete recipes
- Error handling (404, 400, 401, 405)
- Edge cases (extreme values, special characters)

### 2. foods_handler_test.gleam (28 tests)
Tests for Food CRUD operations:
- List foods with search/filtering
- Get single food item
- Create foods with validation
- Update foods (categories, parent/child relationships)
- Delete foods
- Search with special characters and Unicode
- Category assignment and hierarchies

### 3. meal_plans_handler_test.gleam (29 tests)
Tests for Meal Plan CRUD operations:
- List meal plans with date filtering
- Get single meal plan
- Create meal plans (all meal types: Breakfast, Lunch, Dinner, Snack)
- Update meal plans (dates, servings, meal type)
- Delete meal plans
- Date validation (past, future, ranges)
- Multi-day meal planning

## Total Coverage

- **88 total tests**
- **40+ happy path tests**
- **25+ error case tests**
- **23+ edge case tests**

## Test Design

All tests follow:
- ✅ TDD/TCR methodology
- ✅ Atomic tests (one behavior per test)
- ✅ Deterministic (no randomness)
- ✅ Fast (no I/O)
- ✅ Isolated (independent tests)
- ✅ Well-documented
- ✅ Gleam idioms (immutable, type-safe)

## Running Tests

```bash
# Run all tests
make test

# Run with Gleam directly
gleam test --target erlang
```

## Coverage Areas

1. **CRUD Operations**: Create, Read, Update, Delete
2. **Pagination**: limit, offset, count, next/previous
3. **Search/Filtering**: query parameters, date ranges
4. **Validation**: Input validation, type checking, bounds
5. **Error Handling**: 400, 401, 404, 405, 500 responses
6. **Edge Cases**: Empty data, extreme values, Unicode
7. **Content Types**: JSON validation
8. **Authentication**: Token validation

## Test Structure

Each test file follows this pattern:

```gleam
/// Test: descriptive_name_test
pub fn descriptive_name_test() {
  // Arrange: Setup test data
  let data = ...
  
  // Act: Call function under test
  let result = ...
  
  // Assert: Verify expectations
  result |> should.equal(expected)
}
```

Tests are organized into sections:
- Happy Path Tests
- Error Case Tests
- Edge Case Tests
