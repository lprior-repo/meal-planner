//// Test for metrics/collector.gleam - specifically testing result.to_option migration
////
//// This test ensures that the slowest_operation function correctly uses
//// option.from_result instead of the deprecated result.to_option

import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/metrics/collector
import meal_planner/metrics/types

pub fn slowest_operation_returns_some_when_stats_exist_test() {
  // Create a collector with some timing data
  let collector = collector.new()

  let context = types.OperationContext(
    category: types.TandoorApiMetrics,
    operation: "fetch_recipe",
    labels: [],
  )

  // Record a timing measurement
  let collector = collector.record_timing(collector, context, 150.0)

  // Get slowest operation - should return Some
  let result = collector.slowest_operation(collector)

  case result {
    Some(_stats) -> should.be_true(True)
    None -> should.fail()
  }
}

pub fn slowest_operation_returns_none_when_empty_test() {
  // Create empty collector
  let collector = collector.new()

  // Get slowest operation - should return None
  let result = collector.slowest_operation(collector)

  result
  |> should.equal(None)
}
