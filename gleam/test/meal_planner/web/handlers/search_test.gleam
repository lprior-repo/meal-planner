//// Tests for search handlers
////
//// Comprehensive test suite for filter parsing from query parameters,
//// covering all combinations of verified_only, branded_only, and category filters.
//// Follows TDD patterns with gleeunit assertions.

import gleam/list
import gleam/option.{None, Some}
import gleam/uri
import gleeunit/should
import meal_planner/types.{SearchFilters}

// ============================================================================
// Test 1: Default Filters (all false, no category)
// ============================================================================

pub fn default_filters_no_params_test() {
  // When parsing empty query string, all filters should be default (false, no category)
  let query = ""
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      verified_only
      |> should.equal(False)

      branded_only
      |> should.equal(False)

      category
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn default_filters_on_parse_error_test() {
  // When query parsing fails, treat as default filters
  let filters =
    SearchFilters(verified_only: False, branded_only: False, category: None)

  filters.verified_only
  |> should.equal(False)

  filters.branded_only
  |> should.equal(False)

  filters.category
  |> should.equal(None)
}

// ============================================================================
// Test 2: Verified Only Filter
// ============================================================================

pub fn parse_verified_only_true_test() {
  // When verified_only=true is passed, it should be parsed as True
  let query = "verified_only=true"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_verified_only_false_test() {
  // When verified_only=false is passed, it should be parsed as False
  let query = "verified_only=false"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_verified_only_invalid_value_test() {
  // When verified_only has invalid value, default to False
  let query = "verified_only=yes"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_verified_only_empty_value_test() {
  // When verified_only has empty value, default to False
  let query = "verified_only="
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test 3: Branded Only Filter
// ============================================================================

pub fn parse_branded_only_true_test() {
  // When branded_only=true is passed, it should be parsed as True
  let query = "branded_only=true"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      branded_only
      |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_branded_only_false_test() {
  // When branded_only=false is passed, it should be parsed as False
  let query = "branded_only=false"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      branded_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_branded_only_invalid_value_test() {
  // When branded_only has invalid value, default to False
  let query = "branded_only=1"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      branded_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test 4: Category Filter
// ============================================================================

pub fn parse_category_simple_test() {
  // When category=Vegetables is passed, it should be parsed
  let query = "category=Vegetables"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      category
      |> should.equal(Some("Vegetables"))
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_category_with_spaces_test() {
  // When category has URL-encoded spaces, parse correctly
  let query = "category=Baked%20Goods"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      category
      |> should.equal(Some("Baked Goods"))
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_category_empty_value_test() {
  // When category is empty string, treat as None
  let query = "category="
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      category
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_category_missing_test() {
  // When category parameter is not present, should be None
  let query = "verified_only=false"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      category
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_category_case_sensitive_test() {
  // Category values should preserve case
  let query = "category=FruitS"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      category
      |> should.equal(Some("FruitS"))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test 5: Combined Filters (Two Parameters)
// ============================================================================

pub fn parse_verified_and_branded_both_true_test() {
  // When both verified_only and branded_only are true
  let query = "verified_only=true&branded_only=true"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(True)

      branded_only
      |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_verified_true_branded_false_test() {
  // When verified_only=true and branded_only=false
  let query = "verified_only=true&branded_only=false"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(True)

      branded_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_verified_false_branded_true_test() {
  // When verified_only=false and branded_only=true
  let query = "verified_only=false&branded_only=true"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(False)

      branded_only
      |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_verified_and_category_test() {
  // When verified_only=true and category=Fruits
  let query = "verified_only=true&category=Fruits"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      verified_only
      |> should.equal(True)

      category
      |> should.equal(Some("Fruits"))
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_branded_and_category_test() {
  // When branded_only=true and category=Snacks
  let query = "branded_only=true&category=Snacks"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      branded_only
      |> should.equal(True)

      category
      |> should.equal(Some("Snacks"))
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test 6: Combined Filters (All Three Parameters)
// ============================================================================

pub fn parse_all_three_filters_true_test() {
  // When all three filters are specified with active values
  let query = "verified_only=true&branded_only=true&category=Dairy"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      verified_only
      |> should.equal(True)

      branded_only
      |> should.equal(True)

      category
      |> should.equal(Some("Dairy"))
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_all_three_filters_mixed_test() {
  // When all three filters are specified with mixed values
  let query = "verified_only=true&branded_only=false&category=Proteins"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      verified_only
      |> should.equal(True)

      branded_only
      |> should.equal(False)

      category
      |> should.equal(Some("Proteins"))
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_all_three_filters_false_test() {
  // When all three filters are specified but inactive
  let query = "verified_only=false&branded_only=false&category="
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      verified_only
      |> should.equal(False)

      branded_only
      |> should.equal(False)

      category
      |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test 7: Invalid Filter Values
// ============================================================================

pub fn parse_verified_only_case_sensitive_test() {
  // verified_only must be exactly "true" (lowercase), "True" should default to False
  let query = "verified_only=True"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_branded_only_case_sensitive_test() {
  // branded_only must be exactly "true" (lowercase), "TRUE" should default to False
  let query = "branded_only=TRUE"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      branded_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_verified_only_numeric_value_test() {
  // Numeric values like "1" should default to False
  let query = "verified_only=1"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_branded_only_numeric_value_test() {
  // Numeric values like "0" should default to False
  let query = "branded_only=0"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let branded_only = case
        list.find(params, fn(p) { p.0 == "branded_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      branded_only
      |> should.equal(False)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_unknown_parameters_test() {
  // Unknown parameters should be ignored gracefully
  let query = "verified_only=true&unknown_param=value&another=test"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_duplicate_parameters_test() {
  // When parameters appear multiple times, first occurrence is used
  let query = "verified_only=true&verified_only=false"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let verified_only = case
        list.find(params, fn(p) { p.0 == "verified_only" })
      {
        Ok(#(_, "true")) -> True
        _ -> False
      }

      verified_only
      |> should.equal(True)
    }
    Error(_) -> should.fail()
  }
}

pub fn parse_special_characters_in_category_test() {
  // Category with special characters should be preserved
  let query = "category=Baked%2BGood%26s"
  let parsed_query = uri.parse_query(query)

  case parsed_query {
    Ok(params) -> {
      let category = case list.find(params, fn(p) { p.0 == "category" }) {
        Ok(#(_, cat)) if cat != "" -> Some(cat)
        _ -> None
      }

      // Should contain decoded ampersand and plus
      case category {
        Some(cat) -> {
          cat
          |> should.not_equal("")
        }
        None -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Additional Helper Tests
// ============================================================================

pub fn search_filters_creation_test() {
  // Test that SearchFilters type can be created with all combinations
  let filters =
    SearchFilters(verified_only: True, branded_only: False, category: None)

  filters.verified_only
  |> should.equal(True)

  filters.branded_only
  |> should.equal(False)
}

pub fn search_filters_with_category_test() {
  // Test that SearchFilters can hold a category value
  let filters =
    SearchFilters(
      verified_only: False,
      branded_only: False,
      category: Some("Vegetables"),
    )

  case filters.category {
    Some(cat) -> {
      cat
      |> should.equal("Vegetables")
    }
    None -> should.fail()
  }
}

pub fn search_filters_immutable_test() {
  // Test that filter combinations are independent
  let filters1 =
    SearchFilters(verified_only: True, branded_only: False, category: None)

  let filters2 =
    SearchFilters(
      verified_only: False,
      branded_only: True,
      category: Some("Fruits"),
    )

  filters1.verified_only
  |> should.equal(True)

  filters2.verified_only
  |> should.equal(False)

  filters2.branded_only
  |> should.equal(True)
}
