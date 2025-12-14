/// Tests for FatSecret diary types
///
/// Focuses on date conversion functions which are critical for
/// the FatSecret API integration.
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/diary/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Date Conversion Tests - Critical Functionality
// ============================================================================

pub fn date_to_int_epoch_test() {
  // Unix epoch should be day 0
  types.date_to_int("1970-01-01")
  |> should.equal(Ok(0))
}

pub fn date_to_int_day_after_epoch_test() {
  // Day after epoch
  types.date_to_int("1970-01-02")
  |> should.equal(Ok(1))
}

pub fn date_to_int_week_after_epoch_test() {
  // One week after epoch
  types.date_to_int("1970-01-08")
  |> should.equal(Ok(7))
}

pub fn date_to_int_current_dates_test() {
  // Test with recent dates (2024)
  // 2024-01-01 = 19,723 days since epoch
  let result = types.date_to_int("2024-01-01")
  case result {
    Ok(days) -> {
      // Should be around 19,723 (54 years * 365.25 days)
      { days >= 19_700 && days <= 19_750 } |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn date_to_int_leap_year_test() {
  // 2024 is a leap year, test Feb 29
  let result = types.date_to_int("2024-02-29")
  case result {
    Ok(days) -> {
      // Should be valid
      { days > 19_700 } |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

pub fn date_to_int_invalid_format_test() {
  // Invalid format
  types.date_to_int("2024/01/01")
  |> should.equal(Error(Nil))

  types.date_to_int("01-01-2024")
  |> should.equal(Error(Nil))

  types.date_to_int("2024-1-1")
  |> should.equal(Error(Nil))
}

pub fn date_to_int_invalid_ranges_test() {
  // Invalid month
  types.date_to_int("2024-13-01")
  |> should.equal(Error(Nil))

  // Invalid day
  types.date_to_int("2024-01-32")
  |> should.equal(Error(Nil))

  // Year too early
  types.date_to_int("1969-12-31")
  |> should.equal(Error(Nil))

  // Year too far future
  types.date_to_int("2101-01-01")
  |> should.equal(Error(Nil))
}

pub fn int_to_date_epoch_test() {
  // Day 0 should be Unix epoch
  types.int_to_date(0)
  |> should.equal("1970-01-01")
}

pub fn int_to_date_day_after_epoch_test() {
  types.int_to_date(1)
  |> should.equal("1970-01-02")
}

pub fn int_to_date_week_after_epoch_test() {
  types.int_to_date(7)
  |> should.equal("1970-01-08")
}

pub fn int_to_date_year_boundary_test() {
  // Test year boundaries
  types.int_to_date(365)
  |> should.equal("1971-01-01")
}

pub fn int_to_date_recent_dates_test() {
  // Test with a known date
  // Should produce a valid YYYY-MM-DD format
  let date = types.int_to_date(19_723)
  // Should be a date in 2024
  string.starts_with(date, "2024") |> should.be_true
}

pub fn int_to_date_format_test() {
  // Check format is always YYYY-MM-DD with zero padding
  let date = types.int_to_date(100)

  // Should be 1970-04-11 or similar (around day 100)
  // Check format matches YYYY-MM-DD with proper zero padding
  string.length(date) |> should.equal(10)
}

// ============================================================================
// Round Trip Tests - Most Important
// ============================================================================

pub fn round_trip_epoch_test() {
  // Epoch should round-trip perfectly
  let date = "1970-01-01"
  case types.date_to_int(date) {
    Ok(days) -> {
      types.int_to_date(days)
      |> should.equal(date)
    }
    Error(_) -> should.fail()
  }
}

pub fn round_trip_recent_date_test() {
  // Recent dates should round-trip
  let date = "2024-06-15"
  case types.date_to_int(date) {
    Ok(days) -> {
      types.int_to_date(days)
      |> should.equal(date)
    }
    Error(_) -> should.fail()
  }
}

pub fn round_trip_leap_day_test() {
  // Leap day should round-trip
  let date = "2024-02-29"
  case types.date_to_int(date) {
    Ok(days) -> {
      types.int_to_date(days)
      |> should.equal(date)
    }
    Error(_) -> should.fail()
  }
}

pub fn round_trip_year_boundaries_test() {
  // Test various year boundaries
  let dates = [
    "1970-12-31", "1971-01-01", "2000-01-01", "2000-12-31", "2024-01-01",
    "2024-12-31",
  ]

  list.each(dates, fn(date) {
    case types.date_to_int(date) {
      Ok(days) -> {
        types.int_to_date(days)
        |> should.equal(date)
      }
      Error(_) -> should.fail()
    }
  })
}

pub fn round_trip_month_boundaries_test() {
  // Test month boundaries in a year
  let dates = [
    "2024-01-31", "2024-02-29", "2024-03-31", "2024-04-30", "2024-05-31",
    "2024-06-30", "2024-07-31", "2024-08-31", "2024-09-30", "2024-10-31",
    "2024-11-30", "2024-12-31",
  ]

  list.each(dates, fn(date) {
    case types.date_to_int(date) {
      Ok(days) -> {
        let recovered = types.int_to_date(days)
        should.equal(recovered, date)
      }
      Error(_) -> should.fail()
    }
  })
}

// ============================================================================
// MealType Tests
// ============================================================================

pub fn meal_type_to_string_test() {
  types.meal_type_to_string(types.Breakfast)
  |> should.equal("breakfast")

  types.meal_type_to_string(types.Lunch)
  |> should.equal("lunch")

  types.meal_type_to_string(types.Dinner)
  |> should.equal("dinner")

  types.meal_type_to_string(types.Snack)
  |> should.equal("other")
}

pub fn meal_type_from_string_test() {
  types.meal_type_from_string("breakfast")
  |> should.equal(Ok(types.Breakfast))

  types.meal_type_from_string("lunch")
  |> should.equal(Ok(types.Lunch))

  types.meal_type_from_string("dinner")
  |> should.equal(Ok(types.Dinner))

  types.meal_type_from_string("other")
  |> should.equal(Ok(types.Snack))

  types.meal_type_from_string("snack")
  |> should.equal(Ok(types.Snack))

  types.meal_type_from_string("invalid")
  |> should.equal(Error(Nil))
}

pub fn meal_type_round_trip_test() {
  // Test round-trip conversion
  let meal_types = [types.Breakfast, types.Lunch, types.Dinner, types.Snack]

  list.each(meal_types, fn(meal) {
    let str = types.meal_type_to_string(meal)
    case types.meal_type_from_string(str) {
      Ok(recovered) -> should.equal(recovered, meal)
      Error(_) -> should.fail()
    }
  })
}

// ============================================================================
// FoodEntryId Tests
// ============================================================================

pub fn food_entry_id_round_trip_test() {
  let id_str = "123456"
  let id = types.food_entry_id(id_str)
  types.food_entry_id_to_string(id)
  |> should.equal(id_str)
}

pub fn food_entry_id_opaque_test() {
  // This shouldn't compile if we try to access the internal value directly
  // types.food_entry_id("123").0 // Would be a compile error
  let id = types.food_entry_id("test123")
  types.food_entry_id_to_string(id)
  |> should.equal("test123")
}
