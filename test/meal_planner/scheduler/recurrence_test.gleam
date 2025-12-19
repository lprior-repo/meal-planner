//// Tests for recurrence engine
////
//// These tests verify:
//// - Recurrence pattern calculation
//// - Next occurrence determination
//// - Date range generation
//// - Validation logic

import gleam/list
import gleam/option
import gleeunit/should
import meal_planner/scheduler/advanced
import meal_planner/scheduler/recurrence

pub fn next_occurrence_every_n_days_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(7),
      start_date: "2025-01-01",
      end_date: option.None,
      max_occurrences: option.None,
    )

  recurrence.next_occurrence(rule, "2025-01-01")
  |> should.equal(option.Some("2025-01-08"))
}

pub fn next_occurrence_weekly_on_days_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.WeeklyOnDays([1, 3, 5]),
      start_date: "2025-01-01",
      end_date: option.None,
      max_occurrences: option.None,
    )

  recurrence.next_occurrence(rule, "2025-01-01")
  |> should.be_some
}

pub fn generate_occurrences_with_max_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(1),
      start_date: "2025-01-01",
      end_date: option.Some("2025-01-31"),
      max_occurrences: option.Some(7),
    )

  let occurrences =
    recurrence.generate_occurrences(rule, "2025-01-01", "2025-01-31")

  occurrences
  |> list.length
  |> should.equal(7)
}

pub fn generate_occurrences_within_date_range_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(7),
      start_date: "2025-01-01",
      end_date: option.Some("2025-01-31"),
      max_occurrences: option.None,
    )

  let occurrences =
    recurrence.generate_occurrences(rule, "2025-01-01", "2025-01-31")

  occurrences
  |> list.length
  |> should.be_true(fn(len) { len >= 4 && len <= 5 })
}

pub fn validate_rule_valid_every_n_days_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(7),
      start_date: "2025-01-01",
      end_date: option.Some("2025-12-31"),
      max_occurrences: option.Some(52),
    )

  recurrence.validate_rule(rule)
  |> should.be_true
}

pub fn validate_rule_invalid_days_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(0),
      start_date: "2025-01-01",
      end_date: option.None,
      max_occurrences: option.None,
    )

  recurrence.validate_rule(rule)
  |> should.be_false
}

pub fn validate_rule_invalid_date_range_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(7),
      start_date: "2025-12-31",
      end_date: option.Some("2025-01-01"),
      max_occurrences: option.None,
    )

  recurrence.validate_rule(rule)
  |> should.be_false
}

pub fn is_active_before_start_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(7),
      start_date: "2025-06-01",
      end_date: option.None,
      max_occurrences: option.None,
    )

  recurrence.is_active(rule, "2025-01-01")
  |> should.be_false
}

pub fn is_active_during_period_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(7),
      start_date: "2025-01-01",
      end_date: option.Some("2025-12-31"),
      max_occurrences: option.None,
    )

  recurrence.is_active(rule, "2025-06-15")
  |> should.be_true
}

pub fn is_active_after_end_test() {
  let rule =
    advanced.RecurrenceRule(
      pattern: advanced.EveryNDays(7),
      start_date: "2025-01-01",
      end_date: option.Some("2025-06-30"),
      max_occurrences: option.None,
    )

  recurrence.is_active(rule, "2025-12-31")
  |> should.be_false
}
