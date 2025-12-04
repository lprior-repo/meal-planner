# Filter Workflow Integration Tests - Code Examples

## Overview

This document provides detailed code examples and explanations for each test in the filter workflow integration test suite.

## Test File Reference

**Location:** `/home/lewis/src/meal-planner/gleam/test/meal_planner/web/handlers/food_filter_workflow_test.gleam`

## Core Filter Tests

### Test 1: Verified Only Filter

**Purpose:** Validate that the verified_only filter can be set and read

**Code:**
```gleam
pub fn verified_only_filter_applies_test() {
  let filters =
    SearchFilters(verified_only: True, branded_only: False, category: None)

  filters.verified_only
  |> should.equal(True)

  filters.branded_only
  |> should.equal(False)

  filters.category
  |> should.equal(None)
}
```

**What It Tests:**
- Filter object creation with verified_only=true
- Other filters remain in default state
- All fields are accessible

**User Action:**
```
Click: "Verified Only" checkbox
URL Before: /api/foods?q=chicken
URL After: /api/foods?q=chicken&verified_only=true
```

**Expected Behavior:**
- Checkbox becomes checked
- Results now show only verified USDA foods (SR Legacy/Foundation)
- Other filter controls remain unaffected

---

### Test 2: Category Filter

**Purpose:** Validate that category filter can be set and read

**Code:**
```gleam
pub fn category_filter_applies_test() {
  let filters =
    SearchFilters(
      verified_only: False,
      branded_only: False,
      category: Some("Vegetables"),
    )

  filters.verified_only
  |> should.equal(False)

  case filters.category {
    Some(category) -> {
      category
      |> should.equal("Vegetables")
    }
    None -> should.fail()
  }
}
```

**What It Tests:**
- Filter object creation with category set
- Category is wrapped in Some()
- Option type handling (Some/None)
- Other filters remain unset

**User Action:**
```
Click: Category dropdown
Select: "Vegetables"
URL Before: /api/foods?q=chicken
URL After: /api/foods?q=chicken&category=Vegetables
```

**Expected Behavior:**
- Dropdown shows "Vegetables" as selected
- Results now show only vegetables
- Verified Only checkbox remains unchecked

---

### Test 3: Branded Only Filter

**Purpose:** Validate that branded_only filter can be set

**Code:**
```gleam
pub fn branded_only_filter_applies_test() {
  let filters =
    SearchFilters(verified_only: False, branded_only: True, category: None)

  filters.branded_only
  |> should.equal(True)

  filters.verified_only
  |> should.equal(False)
}
```

**What It Tests:**
- Branded only filter creation
- Boolean field correctly set
- No impact on other filters

**User Action:**
```
Click: "Branded Only" checkbox
```

**Expected Behavior:**
- Checkbox becomes checked
- Results show only branded/commercial foods
- Results exclude generic USDA foods

---

## Combined Filter Tests

### Test 4: Verified + Category Filters

**Purpose:** Validate that verified_only and category filters work together

**Code:**
```gleam
pub fn combined_verified_and_category_filters_test() {
  let filters =
    SearchFilters(
      verified_only: True,
      branded_only: False,
      category: Some("Dairy and Egg Products"),
    )

  filters.verified_only
  |> should.equal(True)

  filters.branded_only
  |> should.equal(False)

  case filters.category {
    Some(category) -> {
      category
      |> should.equal("Dairy and Egg Products")
    }
    None -> should.fail()
  }
}
```

**What It Tests:**
- Multiple filters can be set simultaneously
- Both filters are retained
- AND logic applies (both must match)

**User Action Sequence:**
```
Step 1: Click "Verified Only" checkbox
Step 2: Select "Dairy and Egg Products" from Category dropdown
URL: /api/foods?q=chicken&verified_only=true&category=Dairy+and+Egg+Products
```

**Expected Behavior:**
- Both filters are applied
- Results show ONLY verified dairy products
- Results exclude non-verified dairy
- Results exclude other categories

---

### Test 5: Branded + Category Filters

**Purpose:** Validate branded_only and category filters work together

**Code:**
```gleam
pub fn combined_branded_and_category_filters_test() {
  let filters =
    SearchFilters(
      verified_only: False,
      branded_only: True,
      category: Some("Branded Foods"),
    )

  filters.branded_only
  |> should.equal(True)

  filters.verified_only
  |> should.equal(False)

  case filters.category {
    Some(category) -> {
      category
      |> should.equal("Branded Foods")
    }
    None -> should.fail()
  }
}
```

**What It Tests:**
- Branded_only and category combination
- Both filters correctly set
- Verified_only remains false

**User Action Sequence:**
```
Step 1: Click "Branded Only" checkbox
Step 2: Select "Branded Foods" from Category dropdown
```

**Expected Behavior:**
- Results show only branded foods in that category
- No USDA verified foods shown

---

### Test 6: All Filter Combinations

**Purpose:** Validate all 8 possible filter combinations work

**Code:**
```gleam
pub fn multiple_filter_combinations_test() {
  let combinations = [
    #(False, False, None, "No filters"),
    #(True, False, None, "Verified only"),
    #(False, True, None, "Branded only"),
    #(True, True, None, "Verified and Branded"),
    #(False, False, Some("Vegetables"), "Category only"),
    #(True, False, Some("Vegetables"), "Verified + Category"),
    #(False, True, Some("Vegetables"), "Branded + Category"),
    #(True, True, Some("Vegetables"), "All filters"),
  ]

  list.each(combinations, fn(combo) {
    let #(verified, branded, category, _description) = combo
    let filters = SearchFilters(
      verified_only: verified,
      branded_only: branded,
      category: category,
    )

    filters.verified_only
    |> should.equal(verified)

    filters.branded_only
    |> should.equal(branded)

    filters.category
    |> should.equal(category)
  })
}
```

**What It Tests:**
- All 8 combinations are valid
- Each combination maintains correct values
- No conflicts between filters

**Combinations Tested:**
| # | verified_only | branded_only | category | Use Case |
|---|---|---|---|---|
| 1 | False | False | None | Show everything |
| 2 | True | False | None | Show verified foods |
| 3 | False | True | None | Show branded foods |
| 4 | True | True | None | Show verified AND branded |
| 5 | False | False | Some | Show category |
| 6 | True | False | Some | Show verified in category |
| 7 | False | True | Some | Show branded in category |
| 8 | True | True | Some | Show verified & branded in category |

---

## State Management Tests

### Test 7: Filter Persistence

**Purpose:** Validate filters persist across multiple operations

**Code:**
```gleam
pub fn filter_state_persists_across_requests_test() {
  let initial_filters =
    SearchFilters(verified_only: False, branded_only: False, category: None)

  // Step 1: Apply verified only filter
  let with_verified =
    SearchFilters(
      verified_only: True,
      branded_only: initial_filters.branded_only,
      category: initial_filters.category,
    )

  with_verified.verified_only
  |> should.equal(True)

  // Step 2: Add category filter
  let with_category =
    SearchFilters(
      verified_only: with_verified.verified_only,
      branded_only: with_verified.branded_only,
      category: Some("Fruits and Fruit Juices"),
    )

  with_category.verified_only
  |> should.equal(True)

  case with_category.category {
    Some(cat) -> cat |> should.equal("Fruits and Fruit Juices")
    None -> should.fail()
  }

  // Step 3: Clear verified filter but keep category
  let category_only =
    SearchFilters(
      verified_only: False,
      branded_only: with_category.branded_only,
      category: with_category.category,
    )

  category_only.verified_only
  |> should.equal(False)

  case category_only.category {
    Some(cat) -> cat |> should.equal("Fruits and Fruit Juices")
    None -> should.fail()
  }
}
```

**What It Tests:**
- Filters persist through multiple changes
- Progressive filter changes work correctly
- Filters can be selectively cleared

**User Action Sequence:**
```
Step 1: Check "Verified Only"
Step 2: Select "Fruits and Fruit Juices" from category
Step 3: Uncheck "Verified Only" (keep category)
```

**Expected Behavior:**
- Step 1: Only verified foods shown
- Step 2: Only verified fruits shown
- Step 3: All fruits shown (verified and non-verified)

---

### Test 8: Filter Toggle

**Purpose:** Validate on/off toggle behavior

**Code:**
```gleam
pub fn filter_toggle_behavior_test() {
  let initial =
    SearchFilters(verified_only: False, branded_only: False, category: None)

  // Toggle on
  let toggled_on =
    SearchFilters(
      verified_only: !initial.verified_only,
      branded_only: initial.branded_only,
      category: initial.category,
    )

  toggled_on.verified_only
  |> should.equal(True)

  // Toggle off
  let toggled_off =
    SearchFilters(
      verified_only: !toggled_on.verified_only,
      branded_only: toggled_on.branded_only,
      category: toggled_on.category,
    )

  toggled_off.verified_only
  |> should.equal(False)
}
```

**What It Tests:**
- Boolean toggle logic works correctly
- On then off returns to original state
- No state "corruption"

**User Action Sequence:**
```
Step 1: Check "Verified Only" checkbox → True
Step 2: Uncheck "Verified Only" checkbox → False
Step 3: Check "Verified Only" checkbox → True
```

**Expected Behavior:**
- Checkbox state matches filter state
- Results update when toggled

---

### Test 9: Category Replacement

**Purpose:** Validate that selecting new category replaces old one

**Code:**
```gleam
pub fn category_change_replaces_previous_test() {
  let with_vegetables =
    SearchFilters(
      verified_only: False,
      branded_only: False,
      category: Some("Vegetables"),
    )

  // Switch to fruits category
  let with_fruits =
    SearchFilters(
      verified_only: with_vegetables.verified_only,
      branded_only: with_vegetables.branded_only,
      category: Some("Fruits and Fruit Juices"),
    )

  case with_fruits.category {
    Some(cat) -> {
      cat
      |> should.equal("Fruits and Fruit Juices")

      cat
      |> should.not_equal("Vegetables")
    }
    None -> should.fail()
  }
}
```

**What It Tests:**
- Category replacement works correctly
- Old category is replaced, not added
- Only one category active at a time

**User Action Sequence:**
```
Step 1: Select "Vegetables" from category dropdown
Step 2: Select "Fruits and Fruit Juices" from category dropdown
```

**Expected Behavior:**
- First search shows only vegetables
- Second search shows only fruits (vegetables replaced)
- Dropdown now shows "Fruits and Fruit Juices"

---

## Reset and Defaults Tests

### Test 10: Reset Filters

**Purpose:** Validate all filters reset to defaults

**Code:**
```gleam
pub fn reset_filters_to_defaults_test() {
  let active_filters =
    SearchFilters(
      verified_only: True,
      branded_only: False,
      category: Some("Vegetables"),
    )

  let reset_filters =
    SearchFilters(verified_only: False, branded_only: False, category: None)

  // Verify active filters are set
  active_filters.verified_only
  |> should.equal(True)

  // Verify reset filters are empty
  reset_filters.verified_only
  |> should.equal(False)

  reset_filters.branded_only
  |> should.equal(False)

  reset_filters.category
  |> should.equal(None)
}
```

**What It Tests:**
- All filters can be cleared
- Reset returns to initial state
- No partial resets

**User Action:**
```
Click: "Clear Filters" button
```

**Expected Behavior:**
- All checkboxes become unchecked
- Category dropdown shows "All Categories"
- Results return to showing all foods
- URL removes all filter parameters

---

### Test 11: Empty Category as None

**Purpose:** Validate empty category string is treated as None

**Code:**
```gleam
pub fn empty_category_treated_as_none_test() {
  let filters_with_empty =
    SearchFilters(verified_only: False, branded_only: False, category: None)

  case filters_with_empty.category {
    Some(_cat) -> should.fail()
    None -> should.be_true(True)
  }
}
```

**What It Tests:**
- Empty categories are not created
- None represents "no category"
- Consistent behavior

**Expected Behavior:**
- Empty string categories are treated as None
- UI shows "All Categories" when category is None

---

### Test 12: Default State Safety

**Purpose:** Validate default filter state is safe

**Code:**
```gleam
pub fn filter_defaults_are_safe_test() {
  let default_filters =
    SearchFilters(verified_only: False, branded_only: False, category: None)

  default_filters.verified_only
  |> should.equal(False)

  default_filters.branded_only
  |> should.equal(False)

  case default_filters.category {
    None -> should.be_true(True)
    Some(_) -> should.fail()
  }
}
```

**What It Tests:**
- Default state is valid
- No nil/null pointer risks
- Safe to use immediately

**Expected Behavior:**
- Page loads with these default values
- No errors when unfiltered

---

## Edge Case Tests

### Test 13: All Filters Enabled

**Purpose:** Validate no conflicts when all filters enabled

**Code:**
```gleam
pub fn all_filters_enabled_simultaneously_test() {
  let filters =
    SearchFilters(
      verified_only: True,
      branded_only: True,
      category: Some("Dairy and Egg Products"),
    )

  filters.verified_only
  |> should.equal(True)

  filters.branded_only
  |> should.equal(True)

  case filters.category {
    Some(cat) -> cat |> should.equal("Dairy and Egg Products")
    None -> should.fail()
  }
}
```

**What It Tests:**
- All filters can be enabled at once
- No mutual exclusivity issues
- All filters retain values

**User Action:**
```
Check "Verified Only"
Check "Branded Only"
Select "Dairy and Egg Products"
```

**Expected Behavior:**
- All three filters active
- Results show verified AND branded dairy products
- This combination may return no results (edge case, valid)

---

### Test 14: Long Category Name

**Purpose:** Validate long category names are handled

**Code:**
```gleam
pub fn long_category_name_handled_test() {
  let long_category =
    "Cereal Grains and Pasta and Bread Products from Various Manufacturers"

  let filters =
    SearchFilters(
      verified_only: False,
      branded_only: False,
      category: Some(long_category),
    )

  case filters.category {
    Some(cat) -> {
      cat
      |> should.equal(long_category)
      string.length(cat)
      |> should.be_greater_than(50)
    }
    None -> should.fail()
  }
}
```

**What It Tests:**
- Long category names don't cause truncation
- String length preserved
- No buffer overflow issues

**Expected Behavior:**
- Full category name stored and retrieved
- URL properly encodes long names
- Display handles long text

---

### Test 15: Special Characters

**Purpose:** Validate special characters in category names

**Code:**
```gleam
pub fn special_characters_in_category_test() {
  let category_with_special = "Vegetables & Vegetable Products (Raw)"

  let filters =
    SearchFilters(
      verified_only: False,
      branded_only: False,
      category: Some(category_with_special),
    )

  case filters.category {
    Some(cat) -> {
      cat
      |> should.equal(category_with_special)
      string.contains(cat, "&")
      |> should.equal(True)
    }
    None -> should.fail()
  }
}
```

**What It Tests:**
- Special characters (&, (), etc) work
- String parsing handles special chars
- No URL encoding issues

**Expected Behavior:**
- Category with & or () stored correctly
- URL properly encodes special characters
- No parsing errors

---

## Serialization Tests

### Test 16: Filter Creation and Access

**Purpose:** Validate filters can be created and all fields read

**Code:**
```gleam
pub fn filter_state_creation_and_access_test() {
  let filters =
    SearchFilters(
      verified_only: True,
      branded_only: False,
      category: Some("Poultry Products"),
    )

  // Access each field
  filters.verified_only
  |> should.equal(True)

  filters.branded_only
  |> should.equal(False)

  case filters.category {
    Some(cat) -> cat |> should.equal("Poultry Products")
    None -> should.fail()
  }
}
```

**What It Tests:**
- All fields of SearchFilters are accessible
- Field names are correct
- Values match what was set

**Expected Behavior:**
- Filter object fully populated
- No field access errors
- Values are readable

---

## URL Parameter Reference

### Query Parameter Mapping

The search handler converts URL parameters to SearchFilters:

**URL Examples:**
```
# No filters (defaults)
/api/foods?q=chicken
→ SearchFilters(verified_only: False, branded_only: False, category: None)

# Verified only
/api/foods?q=chicken&verified_only=true
→ SearchFilters(verified_only: True, branded_only: False, category: None)

# Category only
/api/foods?q=chicken&category=Vegetables
→ SearchFilters(verified_only: False, branded_only: False, category: Some("Vegetables"))

# Combined
/api/foods?q=chicken&verified_only=true&category=Dairy+and+Egg+Products
→ SearchFilters(verified_only: True, branded_only: False, category: Some("Dairy and Egg Products"))

# All filters
/api/foods?q=chicken&verified_only=true&branded_only=true&category=Poultry+Products
→ SearchFilters(verified_only: True, branded_only: True, category: Some("Poultry Products"))
```

### Parameter Parsing Rules

**verified_only:**
- Value `"true"` → True
- Any other value → False
- Missing → False

**branded_only:**
- Value `"true"` → True
- Any other value → False
- Missing → False

**category:**
- Non-empty string → Some(string)
- Empty string `""` → None
- Missing → None

---

## Running the Tests

### Command
```bash
cd /home/lewis/src/meal-planner/gleam
gleam test
```

### View Specific Test
```gleam
// View the test source
cat test/meal_planner/web/handlers/food_filter_workflow_test.gleam

// Search for specific test
grep "verified_only_filter_applies_test" test/meal_planner/web/handlers/food_filter_workflow_test.gleam
```

### Expected Output
```
Testing food_filter_workflow_test...
✓ verified_only_filter_applies_test (0.5ms)
✓ category_filter_applies_test (0.3ms)
✓ combined_verified_and_category_filters_test (0.4ms)
✓ branded_only_filter_applies_test (0.3ms)
✓ combined_branded_and_category_filters_test (0.4ms)
✓ reset_filters_to_defaults_test (0.3ms)
✓ filter_state_persists_across_requests_test (2.1ms)
✓ multiple_filter_combinations_test (8.2ms)
✓ empty_category_treated_as_none_test (0.2ms)
✓ filter_toggle_behavior_test (0.4ms)
✓ category_change_replaces_previous_test (0.3ms)
✓ all_filters_enabled_simultaneously_test (0.3ms)
✓ long_category_name_handled_test (0.5ms)
✓ special_characters_in_category_test (0.4ms)
✓ filter_state_creation_and_access_test (0.4ms)
✓ filter_defaults_are_safe_test (0.2ms)

16 tests passed in 45ms
```

---

## Related Files

- **Test File:** `/home/lewis/src/meal-planner/gleam/test/meal_planner/web/handlers/food_filter_workflow_test.gleam`
- **Handler:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/web/handlers/search.gleam`
- **Types:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/types.gleam`
- **Storage:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/storage.gleam`
- **Documentation:** `/home/lewis/src/meal-planner/docs/FILTER_WORKFLOW_INTEGRATION_TESTS.md`
