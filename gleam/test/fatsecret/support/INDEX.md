# FatSecret SDK Test Infrastructure - Index

Welcome to the FatSecret SDK test infrastructure! This directory contains everything you need to write comprehensive tests for the FatSecret API integration.

## 📚 Documentation

Start here based on your needs:

### 🚀 Quick Start (5 minutes)
**[QUICK_START.md](QUICK_START.md)** - Get up and running fast
- Basic examples
- Common scenarios
- Fixture reference table
- Testing checklist

### 📖 Full Documentation
**[README.md](README.md)** - Complete API reference
- Detailed component overview
- All function signatures
- Common patterns
- Best practices
- Edge cases

### 🏗️ Architecture
**[ARCHITECTURE.md](ARCHITECTURE.md)** - System design
- Component diagram
- Data flow
- Module responsibilities
- Extension points
- Dependencies

## 🧩 Components

### Core Modules

| File | Purpose | Lines | Key Features |
|------|---------|-------|--------------|
| **http_mock.gleam** | Mock HTTP client | 269 | URL matching, call recording, verification |
| **fixtures.gleam** | API responses | 457 | 15+ realistic fixtures, all endpoints |
| **test_helpers.gleam** | Test utilities | 543 | Builders, assertions, validators |

### Examples & Docs

| File | Purpose | Lines | Content |
|------|---------|-------|---------|
| **integration_example_test.gleam** | Working examples | 312 | 12+ complete test examples |
| **README.md** | Full docs | 511 | Complete API reference |
| **QUICK_START.md** | Quick start | 208 | 5-minute tutorial |
| **ARCHITECTURE.md** | Architecture | 298 | System design |

## 🎯 Use Cases

### "I want to write my first test"
→ Start with **[QUICK_START.md](QUICK_START.md)**

### "I need to mock an API call"
→ See **http_mock.gleam** + **[README.md](README.md)** Mock section

### "I need realistic API responses"
→ See **fixtures.gleam** + **[README.md](README.md)** Fixtures section

### "I need to assert on complex types"
→ See **test_helpers.gleam** + **[README.md](README.md)** Helpers section

### "I want to see working examples"
→ See **integration_example_test.gleam**

### "I want to understand the architecture"
→ See **[ARCHITECTURE.md](ARCHITECTURE.md)**

## 📦 What's Included

### HTTP Mock System
- Pattern-based URL matching
- Call recording and verification
- JSON/error/network error helpers
- Default response handling
- No network calls needed

### Realistic Fixtures
- Food API (food.get.v5)
- Search API (foods.search.v3)
- Recipe API (recipe.get.v2)
- OAuth API
- Profile API
- Food Diary API
- Error responses

### Test Helpers
- Configuration builders
- Data builders (nutrition, serving, food)
- Complex assertions
- Parameter builders
- Business logic validators

### Complete Examples
- Basic mock usage
- Error handling
- Fixture usage
- Helper usage
- Integration tests

## 🎓 Learning Path

### Beginner
1. Read [QUICK_START.md](QUICK_START.md) (5 min)
2. Copy an example from integration_example_test.gleam
3. Modify for your use case
4. Run your test

### Intermediate
1. Review [README.md](README.md) (15 min)
2. Understand http_mock API
3. Explore available fixtures
4. Use test_helpers for assertions

### Advanced
1. Study [ARCHITECTURE.md](ARCHITECTURE.md)
2. Add new fixtures for edge cases
3. Create custom helpers
4. Extend mock patterns

## 🔧 Common Tasks

### Mock an API Call
```gleam
import fatsecret/support/http_mock
import fatsecret/support/fixtures

let client = http_mock.new()
  |> http_mock.expect("foods.search",
     http_mock.json_response(200, fixtures.food_search_response()))
```

### Use a Fixture
```gleam
import fatsecret/support/fixtures

let json = fixtures.food_response()
case json.parse(json, using: decoder) {
  Ok(food) -> // test food
  Error(_) -> should.fail()
}
```

### Build Test Data
```gleam
import fatsecret/support/test_helpers

let config = test_helpers.test_config()
let nutrition = test_helpers.test_nutrition(
  calories: 95.0, carbs: 25.13, protein: 0.47, fat: 0.31)
```

### Assert on Results
```gleam
import fatsecret/support/test_helpers

food
|> test_helpers.assert_food(
  id: "33691", name: "Apple", food_type: "Generic", serving_count: 1)
```

## 📊 Coverage

### API Endpoints Covered
- ✅ food.get.v5 (single/multiple servings, branded)
- ✅ foods.search.v3 (single/multiple results, empty)
- ✅ recipe.get.v2 (complete recipes)
- ✅ OAuth (request/access tokens)
- ✅ profile.get (user profiles)
- ✅ food_entries.get.v2 (diary entries)

### Edge Cases Covered
- ✅ Single vs array results
- ✅ Numeric strings ("95.0" vs 95.0)
- ✅ Optional nutrition fields
- ✅ Branded vs generic foods
- ✅ Empty results
- ✅ API errors (101, 102, 108, 110)
- ✅ Network errors (500, timeout)

## 🚦 Quick Reference

### Import These Modules
```gleam
import fatsecret/support/fixtures
import fatsecret/support/http_mock
import fatsecret/support/test_helpers
```

### Basic Test Template
```gleam
pub fn my_test() {
  // 1. Setup mock
  let client = http_mock.new()
    |> http_mock.expect("endpoint",
       http_mock.json_response(200, fixtures.response()))

  // 2. Setup config
  let config = test_helpers.test_config()

  // 3. Execute
  let result = api_call(config, params)

  // 4. Verify response
  result |> should.be_ok()

  // 5. Verify HTTP calls
  client |> http_mock.assert_called("POST", "endpoint")
    |> should.be_true()
}
```

## 🎯 Key Features

### No Network Calls
All tests run instantly without hitting real APIs.

### Realistic Data
Fixtures based on actual FatSecret API responses.

### Type Safe
Full Gleam type checking, no runtime surprises.

### Well Documented
README + Quick Start + Architecture + Examples.

### Easy to Extend
Add fixtures, helpers, and patterns easily.

## 📈 Statistics

- **Total Lines**: 2,598 (code + docs)
- **Test Code**: 1,581 lines
- **Documentation**: 1,017 lines
- **Fixtures**: 15+ realistic responses
- **Examples**: 12+ complete tests
- **Helpers**: 30+ utility functions

## 🤝 Contributing

### Adding a Fixture
1. Get actual API response (curl, Postman)
2. Add to fixtures.gleam
3. Document edge cases
4. Add example usage

### Adding a Helper
1. Identify common pattern
2. Add to test_helpers.gleam
3. Add doc comment with example
4. Update README

### Adding an Example
1. Write working test
2. Add to integration_example_test.gleam
3. Add comments explaining each step

## ✅ Quality Checklist

Before submitting tests:
- [ ] Use fixtures (not hand-crafted JSON)
- [ ] Test edge cases (single vs array, etc.)
- [ ] Verify HTTP calls
- [ ] Use test_helpers for assertions
- [ ] Add comments explaining what you're testing
- [ ] Run tests to ensure they pass

## 🆘 Getting Help

### Can't find what you need?
1. Check [QUICK_START.md](QUICK_START.md)
2. Search [README.md](README.md)
3. Look at integration_example_test.gleam
4. Review existing tests in ../

### Found a bug?
File an issue with:
- What you tried
- Expected vs actual behavior
- Minimal reproduction

## 📞 Contact

- **Thread**: fatsecret-sdk-coordination
- **Coordinator**: RedLake

---

**Ready to write tests?** → Start with [QUICK_START.md](QUICK_START.md)!
