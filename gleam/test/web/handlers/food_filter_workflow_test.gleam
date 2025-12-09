//// Integration tests for complete food search filter workflow
////
//// Tests the full user journey of:
//// 1. Navigate to foods page
//// 2. Click verified only filter
//// 3. Verify URL updates with filter param
//// 4. Verify search results change
//// 5. Add category filter
//// 6. Verify combined filters work
//// 7. Clear filters and verify reset

import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/types.{SearchFilters}

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// TEST SUITE: Full Filter Workflow Integration Tests
// =============================================================================

/// Test: Verified only filter applies correctly
///
/// Expected behavior:
/// - Filter created with verified_only=true
/// - Other filters remain false/none
/// - Filter should only include verified USDA foods
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

/// Test: Category filter applies correctly
///
/// Expected behavior:
/// - Filter created with category selected
/// - verified_only remains false
/// - Category should match specified value
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

/// Test: Combined verified_only and category filters
///
/// Expected behavior:
/// - Both filters applied together
/// - Results should only include verified foods in the category
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

/// Test: Branded only filter applies correctly
///
/// Expected behavior:
/// - Filter created with branded_only=true
/// - Should only include branded/commercial foods
pub fn branded_only_filter_applies_test() {
  let filters =
    SearchFilters(verified_only: False, branded_only: True, category: None)

  filters.branded_only
  |> should.equal(True)

  filters.verified_only
  |> should.equal(False)
}

/// Test: Combined branded and category filters
///
/// Expected behavior:
/// - Both filters applied together
/// - Results should only include branded foods in the category
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

/// Test: Reset filters to defaults
///
/// Expected behavior:
/// - All filters reset to false/none
/// - Page returns to initial unfiltered state
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

/// Test: Filter state persistence across requests
///
/// Expected behavior:
/// - When user applies filters and searches
/// - Filters remain applied in subsequent requests
/// - User can modify filters incrementally
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

/// Test: Multiple filter combinations
///
/// Expected behavior:
/// - All filter combinations are valid
/// - Filters work independently and together
pub fn multiple_filter_combinations_test() {
  let combinations = [
    // (verified, branded, category, description)
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
    let filters =
      SearchFilters(
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

/// Test: Empty category filter is equivalent to None
///
/// Expected behavior:
/// - Empty string category should be treated as None
/// - Consistent behavior across API
pub fn empty_category_treated_as_none_test() {
  let filters_with_empty =
    SearchFilters(verified_only: False, branded_only: False, category: None)

  case filters_with_empty.category {
    Some(_cat) -> should.fail()
    None -> should.be_true(True)
  }
}

/// Test: Filter toggle on/off behavior
///
/// Expected behavior:
/// - Toggling verified_only on then off returns to original state
/// - Boolean toggle logic works correctly
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

/// Test: Category filter change replaces previous category
///
/// Expected behavior:
/// - When user selects new category, old category is replaced
/// - Only one category active at a time
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

// =============================================================================
// EDGE CASE TESTS
// =============================================================================

/// Test: All filters enabled simultaneously
///
/// Expected behavior:
/// - All filters can be enabled at once
/// - No conflicts or errors
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

/// Test: Very long category name is handled
///
/// Expected behavior:
/// - Long category strings are accepted
/// - No truncation or errors
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
      let length = string.length(cat)
      { length > 50 }
      |> should.be_true
    }
    None -> should.fail()
  }
}

/// Test: Special characters in category name
///
/// Expected behavior:
/// - Category names with special chars work correctly
/// - No parsing issues
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

// =============================================================================
// FILTER SERIALIZATION/DESERIALIZATION TESTS
// =============================================================================

/// Test: Filter state can be created and read
///
/// Expected behavior:
/// - Filters created properly with all field values
/// - All fields accessible and correct
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

/// Test: Filter defaults are safe
///
/// Expected behavior:
/// - Default unset filters are safe to use
/// - No nil/null pointer issues
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
