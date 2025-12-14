/// Edge case tests for date navigation fixes
import gleeunit/should
import meal_planner/fatsecret/diary/types

// Test Feb 1 -> Jan 31 boundary
pub fn feb_to_jan_test() {
  let feb1 = types.date_to_int("2024-02-01") |> should.be_ok
  let prev_day = feb1 - 1
  let jan31 = types.int_to_date(prev_day)
  jan31 |> should.equal("2024-01-31")
}

// Test Jan 1 -> Dec 31 (previous year)
pub fn jan_to_dec_test() {
  let jan1 = types.date_to_int("2024-01-01") |> should.be_ok
  let prev_day = jan1 - 1
  let dec31 = types.int_to_date(prev_day)
  dec31 |> should.equal("2023-12-31")
}

// Test leap year Feb 28 -> Feb 29 -> Mar 1
pub fn leap_year_feb_test() {
  let feb28 = types.date_to_int("2024-02-28") |> should.be_ok
  let feb29 = types.date_to_int("2024-02-29") |> should.be_ok
  let mar1 = types.int_to_date(feb29 + 1)

  feb29 |> should.equal(feb28 + 1)
  mar1 |> should.equal("2024-03-01")
}

// Test non-leap year Feb 28 -> Mar 1
pub fn non_leap_year_feb_test() {
  let feb28 = types.date_to_int("2023-02-28") |> should.be_ok
  let mar1 = types.int_to_date(feb28 + 1)
  mar1 |> should.equal("2023-03-01")
}

// Test March 31 -> April 1
pub fn mar_to_apr_test() {
  let mar31 = types.date_to_int("2024-03-31") |> should.be_ok
  let apr1 = types.int_to_date(mar31 + 1)
  apr1 |> should.equal("2024-04-01")
}

// Test April 30 -> May 1 (30-day month)
pub fn apr_to_may_test() {
  let apr30 = types.date_to_int("2024-04-30") |> should.be_ok
  let may1 = types.int_to_date(apr30 + 1)
  may1 |> should.equal("2024-05-01")
}

// Test November 30 -> December 1
pub fn nov_to_dec_test() {
  let nov30 = types.date_to_int("2024-11-30") |> should.be_ok
  let dec1 = types.int_to_date(nov30 + 1)
  dec1 |> should.equal("2024-12-01")
}

// Test December 31 -> January 1 (year boundary)
pub fn dec_to_jan_test() {
  let dec31 = types.date_to_int("2024-12-31") |> should.be_ok
  let jan1 = types.int_to_date(dec31 + 1)
  jan1 |> should.equal("2025-01-01")
}
