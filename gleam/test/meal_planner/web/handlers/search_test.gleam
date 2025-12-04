//// Tests for search handlers

import gleeunit/should
import meal_planner/types.{SearchFilters}
import gleam/option.{None}

pub fn search_filters_creation_test() {
  let filters = SearchFilters(
    verified_only: True,
    branded_only: False,
    category: None,
  )

  filters.verified_only
  |> should.equal(True)

  filters.branded_only
  |> should.equal(False)
}

pub fn search_filters_with_category_test() {
  let filters = SearchFilters(
    verified_only: False,
    branded_only: False,
    category: option.Some("Vegetables"),
  )

  case filters.category {
    option.Some(cat) -> {
      cat
      |> should.equal("Vegetables")
    }
    option.None -> should.fail()
  }
}
