import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/api/query_builders

pub fn main() {
  gleeunit.main()
}

pub fn test_build_recipe_list_params_with_pagination() {
  let params = query_builders.build_recipe_list_params(Some(25), Some(5))

  params
  |> should.equal([#("offset", "5"), #("limit", "25")])
}

pub fn test_build_recipe_list_params_with_none_values() {
  let params = query_builders.build_recipe_list_params(None, None)

  params
  |> should.equal([])
}

pub fn test_build_recipe_filter_params_with_all_filters() {
  let params =
    query_builders.build_recipe_filter_params(
      Some(20),
      Some(0),
      Some(1),
      Some("easy"),
      Some("5,6"),
    )

  // Check that list length is 5 (all parameters present)
  params
  |> list.length
  |> should.equal(5)

  // Verify all parameters are present by checking list contains them
  let has_limit =
    params
    |> list.any(fn(p) { p.0 == "limit" && p.1 == "20" })
  has_limit
  |> should.be_true()

  let has_author =
    params
    |> list.any(fn(p) { p.0 == "author_id" && p.1 == "1" })
  has_author
  |> should.be_true()
}

pub fn test_build_recipe_filter_params_with_partial_filters() {
  let params =
    query_builders.build_recipe_filter_params(
      Some(20),
      Some(0),
      None,
      Some("medium"),
      None,
    )

  // Should contain 3 params: limit, offset, difficulty
  params
  |> list.length
  |> should.equal(3)

  // Should NOT contain author_id
  let has_author_id =
    params
    |> list.any(fn(p) { p.0 == "author_id" })
  has_author_id
  |> should.be_false()
}

pub fn test_build_recipe_search_params() {
  let params =
    query_builders.build_recipe_search_params(
      Some("chicken"),
      Some(20),
      Some(0),
    )

  // Should contain 3 params
  params
  |> list.length
  |> should.equal(3)

  let has_query =
    params
    |> list.any(fn(p) { p.0 == "query" && p.1 == "chicken" })
  has_query
  |> should.be_true()
}

pub fn test_build_recipe_search_params_without_query() {
  let params =
    query_builders.build_recipe_search_params(None, Some(20), Some(0))

  // Should contain 2 params (no query)
  params
  |> list.length
  |> should.equal(2)

  let has_query =
    params
    |> list.any(fn(p) { p.0 == "query" })
  has_query
  |> should.be_false()
}

pub fn test_merge_recipe_filters_combines_parameters() {
  let base = query_builders.build_recipe_list_params(Some(20), Some(0))
  let filters = [#("author_id", "1"), #("difficulty", "easy")]

  let merged = query_builders.merge_recipe_filters(base, filters)

  // Should combine base (2 items) and filters (2 items) = 4 total
  merged
  |> list.length
  |> should.equal(4)

  let has_limit =
    merged
    |> list.any(fn(p) { p.0 == "limit" })
  has_limit
  |> should.be_true()

  let has_author =
    merged
    |> list.any(fn(p) { p.0 == "author_id" })
  has_author
  |> should.be_true()
}

pub fn test_merge_recipe_filters_overrides_duplicate_keys() {
  let base = [#("limit", "20"), #("offset", "0")]
  let filters = [#("limit", "50")]

  let merged = query_builders.merge_recipe_filters(base, filters)

  // Should have 2 items: the overridden limit and kept offset
  merged
  |> list.length
  |> should.equal(2)

  // Verify limit is 50 (from filters, not base)
  let limit_value =
    merged
    |> list.find(fn(p) { p.0 == "limit" })
  case limit_value {
    Ok(#("limit", val)) -> val |> should.equal("50")
    _ -> should.fail()
  }

  // Verify offset is still 0
  let offset_value =
    merged
    |> list.find(fn(p) { p.0 == "offset" })
  case offset_value {
    Ok(#("offset", val)) -> val |> should.equal("0")
    _ -> should.fail()
  }
}
