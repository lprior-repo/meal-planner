//// TDD Tests for CLI advisor command

import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/advisor

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Recommendation Formatting Tests
// ============================================================================

pub fn format_recommendation_test() {
  let rec =
    advisor.Recommendation(
      category: "Protein",
      suggestion: "Increase intake",
      reason: "Below target",
    )
  let output = advisor.format_recommendation(rec)

  string.contains(output, "Protein")
  |> should.be_true()

  string.contains(output, "Increase intake")
  |> should.be_true()

  string.contains(output, "Below target")
  |> should.be_true()
}

// ============================================================================
// Trend Formatting Tests
// ============================================================================

pub fn format_trend_point_test() {
  let trend =
    advisor.TrendData(
      day: "Monday",
      calories: 2050.0,
      protein: 155.0,
      carbs: 210.0,
      fat: 68.0,
    )
  let output = advisor.format_trend_point(trend)

  string.contains(output, "Monday")
  |> should.be_true()

  string.contains(output, "2050")
  |> should.be_true()

  string.contains(output, "155")
  |> should.be_true()
}

// ============================================================================
// Recommendation Generation Tests
// ============================================================================

pub fn generate_recommendations_low_protein_test() {
  let recs = advisor.generate_recommendations(2000.0, 80.0)

  recs
  |> list.length
  |> should.be_greater_than(0)

  let first_rec = list.first(recs)
  case first_rec {
    Ok(rec) -> {
      string.contains(rec.suggestion, "Increase")
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_recommendations_high_protein_test() {
  let recs = advisor.generate_recommendations(2000.0, 250.0)

  recs
  |> list.length
  |> should.be_greater_than(0)

  let first_rec = list.first(recs)
  case first_rec {
    Ok(rec) -> {
      string.contains(rec.category, "Protein")
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

pub fn generate_recommendations_balanced_test() {
  let recs = advisor.generate_recommendations(2000.0, 150.0)

  recs
  |> list.length
  |> should.be_greater_than(2)
}

// ============================================================================
// Trend Generation Tests
// ============================================================================

pub fn generate_sample_trends_test() {
  let trends = advisor.generate_sample_trends()

  trends
  |> list.length
  |> should.equal(7)
}

pub fn generate_sample_trends_has_all_days_test() {
  let trends = advisor.generate_sample_trends()

  let days =
    trends
    |> list.map(fn(t) { t.day })

  string.contains(list.fold(days, "", fn(acc, d) { acc <> d }), "Monday")
  |> should.be_true()

  string.contains(list.fold(days, "", fn(acc, d) { acc <> d }), "Sunday")
  |> should.be_true()
}
