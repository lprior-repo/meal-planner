/// Rotation Tracker Tests - TDD RED Phase
///
/// Tests for 30-day meal rotation eligibility checking.
/// Part of meal-planner-918 (rotation logic).
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/generation/rotation_tracker.{
  MealRotationHistory, days_between_dates, is_eligible_for_selection,
  update_rotation_history,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Eligibility Tests
// ============================================================================

pub fn is_eligible_for_selection_new_meal_always_eligible_test() {
  // New meal (not in history) should always be eligible
  let history = []
  let meal_id = "recipe-123"
  let min_days = 30

  is_eligible_for_selection(meal_id, history, min_days)
  |> should.be_true
}

pub fn is_eligible_for_selection_meal_served_31_days_ago_eligible_test() {
  // Meal served 31 days ago should be eligible (min_days = 30)
  let history = [
    MealRotationHistory(
      meal_id: "recipe-123",
      last_served: "2024-01-01",
      days_since: 31,
    ),
  ]
  let meal_id = "recipe-123"
  let min_days = 30

  is_eligible_for_selection(meal_id, history, min_days)
  |> should.be_true
}

pub fn is_eligible_for_selection_meal_served_29_days_ago_not_eligible_test() {
  // Meal served 29 days ago should NOT be eligible (min_days = 30)
  let history = [
    MealRotationHistory(
      meal_id: "recipe-123",
      last_served: "2024-01-01",
      days_since: 29,
    ),
  ]
  let meal_id = "recipe-123"
  let min_days = 30

  is_eligible_for_selection(meal_id, history, min_days)
  |> should.be_false
}

pub fn is_eligible_for_selection_exactly_30_days_eligible_test() {
  // Meal served exactly 30 days ago should be eligible
  let history = [
    MealRotationHistory(
      meal_id: "recipe-456",
      last_served: "2024-01-01",
      days_since: 30,
    ),
  ]
  let meal_id = "recipe-456"
  let min_days = 30

  is_eligible_for_selection(meal_id, history, min_days)
  |> should.be_true
}

pub fn is_eligible_for_selection_multiple_meals_in_history_test() {
  // Should correctly find the target meal in a list
  let history = [
    MealRotationHistory(
      meal_id: "recipe-111",
      last_served: "2024-01-01",
      days_since: 40,
    ),
    MealRotationHistory(
      meal_id: "recipe-222",
      last_served: "2024-01-15",
      days_since: 25,
    ),
    MealRotationHistory(
      meal_id: "recipe-333",
      last_served: "2024-01-20",
      days_since: 35,
    ),
  ]

  // Recipe 111 (40 days) should be eligible
  is_eligible_for_selection("recipe-111", history, 30)
  |> should.be_true

  // Recipe 222 (25 days) should NOT be eligible
  is_eligible_for_selection("recipe-222", history, 30)
  |> should.be_false

  // Recipe 333 (35 days) should be eligible
  is_eligible_for_selection("recipe-333", history, 30)
  |> should.be_true
}

// ============================================================================
// Date Calculation Tests
// ============================================================================

pub fn days_between_dates_same_day_test() {
  days_between_dates("2024-01-01", "2024-01-01")
  |> should.be_ok
  |> should.equal(0)
}

pub fn days_between_dates_one_day_apart_test() {
  days_between_dates("2024-01-01", "2024-01-02")
  |> should.be_ok
  |> should.equal(1)
}

pub fn days_between_dates_30_days_apart_test() {
  days_between_dates("2024-01-01", "2024-01-31")
  |> should.be_ok
  |> should.equal(30)
}

pub fn days_between_dates_leap_year_test() {
  // 2024 is a leap year
  days_between_dates("2024-02-28", "2024-03-01")
  |> should.be_ok
  |> should.equal(2)
}

pub fn days_between_dates_invalid_from_date_test() {
  days_between_dates("invalid-date", "2024-01-01")
  |> should.be_error
}

pub fn days_between_dates_invalid_to_date_test() {
  days_between_dates("2024-01-01", "not-a-date")
  |> should.be_error
}

// ============================================================================
// History Update Tests
// ============================================================================

pub fn update_rotation_history_adds_new_meal_test() {
  let history = []
  let meal_id = "recipe-123"
  let date = "2024-01-15"

  let updated = update_rotation_history(history, meal_id, date)

  // Should have one entry
  list.length(updated)
  |> should.equal(1)

  // Should have correct meal_id and date
  case list.first(updated) {
    Ok(entry) -> {
      entry.meal_id
      |> should.equal(meal_id)

      entry.last_served
      |> should.equal(date)
    }
    Error(_) -> should.fail()
  }
}

pub fn update_rotation_history_updates_existing_meal_test() {
  let history = [
    MealRotationHistory(
      meal_id: "recipe-123",
      last_served: "2024-01-01",
      days_since: 10,
    ),
    MealRotationHistory(
      meal_id: "recipe-456",
      last_served: "2024-01-05",
      days_since: 5,
    ),
  ]

  let meal_id = "recipe-123"
  let new_date = "2024-02-01"

  let updated = update_rotation_history(history, meal_id, new_date)

  // Should still have 2 entries
  list.length(updated)
  |> should.equal(2)

  // Find the updated entry
  let updated_entry =
    list.find(updated, fn(e) { e.meal_id == meal_id })
    |> should.be_ok

  // Should have new date
  updated_entry.last_served
  |> should.equal(new_date)
}

pub fn update_rotation_history_preserves_other_meals_test() {
  let history = [
    MealRotationHistory(
      meal_id: "recipe-111",
      last_served: "2024-01-01",
      days_since: 20,
    ),
    MealRotationHistory(
      meal_id: "recipe-222",
      last_served: "2024-01-10",
      days_since: 10,
    ),
  ]

  let updated = update_rotation_history(history, "recipe-333", "2024-01-20")

  // Should now have 3 entries
  list.length(updated)
  |> should.equal(3)

  // Original entries should still exist
  list.find(updated, fn(e) { e.meal_id == "recipe-111" })
  |> should.be_ok

  list.find(updated, fn(e) { e.meal_id == "recipe-222" })
  |> should.be_ok

  // New entry should exist
  list.find(updated, fn(e) { e.meal_id == "recipe-333" })
  |> should.be_ok
}
