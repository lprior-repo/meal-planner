/// Tests for query parameter builder consolidation (meal-planner-r2q)
/// 
/// This test suite validates the query parameter builder helpers that consolidate
/// repeated pagination and optional parameter logic across all list handlers.
///
/// RED PHASE: These tests must FAIL because the helpers don't exist yet.
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/api/query_builders

pub fn main() {
  gleeunit.main()
}

/// Test: build_pagination_params with limit and offset
pub fn test_build_pagination_params_with_both() {
  let params = query_builders.build_pagination_params(Some(20), Some(10))
  params
  |> should.equal([#("limit", "20"), #("offset", "10")])
}

/// Test: build_pagination_params with only limit
pub fn test_build_pagination_params_limit_only() {
  let params = query_builders.build_pagination_params(Some(20), None)
  params
  |> should.equal([#("limit", "20")])
}

/// Test: build_pagination_params with only offset
pub fn test_build_pagination_params_offset_only() {
  let params = query_builders.build_pagination_params(None, Some(10))
  params
  |> should.equal([#("offset", "10")])
}

/// Test: build_pagination_params with neither
pub fn test_build_pagination_params_with_neither() {
  let params = query_builders.build_pagination_params(None, None)
  params
  |> should.equal([])
}

/// Test: build_query_params - single parameter
pub fn test_build_query_params_single() {
  let params = query_builders.build_query_params([#("query", "tomato")])
  params
  |> should.equal([#("query", "tomato")])
}

/// Test: build_query_params - multiple parameters
pub fn test_build_query_params_multiple() {
  let params =
    query_builders.build_query_params([
      #("limit", "20"),
      #("offset", "10"),
      #("query", "tomato"),
    ])
  params
  |> list.length
  |> should.equal(3)
}

/// Test: add_optional_string_param - with Some value
pub fn test_add_optional_string_param_some() {
  let params = []
  let result =
    query_builders.add_optional_string_param(params, "search", Some("tomato"))
  result
  |> should.equal([#("search", "tomato")])
}

/// Test: add_optional_string_param - with None value
pub fn test_add_optional_string_param_none() {
  let params = []
  let result = query_builders.add_optional_string_param(params, "search", None)
  result
  |> should.equal([])
}

/// Test: add_optional_int_param - with Some value
pub fn test_add_optional_int_param_some() {
  let params = []
  let result = query_builders.add_optional_int_param(params, "limit", Some(20))
  result
  |> should.equal([#("limit", "20")])
}

/// Test: add_optional_int_param - with None value
pub fn test_add_optional_int_param_none() {
  let params = []
  let result = query_builders.add_optional_int_param(params, "limit", None)
  result
  |> should.equal([])
}

/// Test: build_food_list_params - full parameters
pub fn test_build_food_list_params_full() {
  let params =
    query_builders.build_food_list_params(Some(20), Some(10), Some("tomato"))
  params
  |> list.length
  |> should.equal(3)
}

/// Test: build_food_list_params - minimal parameters
pub fn test_build_food_list_params_minimal() {
  let params = query_builders.build_food_list_params(None, None, None)
  params
  |> should.equal([])
}

/// Test: build_recipe_list_params - validates limit/offset only
pub fn test_build_recipe_list_params() {
  let params = query_builders.build_recipe_list_params(Some(25), Some(5))
  params
  |> list.length
  |> should.equal(2)
}
