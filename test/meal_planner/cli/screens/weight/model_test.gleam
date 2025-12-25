/// Tests for weight screen model types and initialization
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/screens/weight/model

pub fn init_creates_valid_model_test() {
  let today = 19_723
  let m = model.init(today)

  // Verify initial state
  m.current_date |> should.equal(today)
  m.entries |> should.equal([])
  m.current_weight |> should.equal(None)
  m.is_loading |> should.equal(False)
  m.error_message |> should.equal(None)
  m.edit_state |> should.equal(None)

  // Verify view state
  case m.view_state {
    model.ListView -> True
    _ -> False
  }
  |> should.be_true
}

pub fn default_goals_has_sensible_defaults_test() {
  let today = 19_723
  let m = model.init(today)
  let g = m.goals

  g.target_weight |> should.equal(70.0)
  g.starting_weight |> should.equal(70.0)
  g.weekly_target |> should.equal(-0.5)

  case g.goal_type {
    model.MaintainWeight -> True
  }
  |> should.be_true
}

pub fn empty_entry_input_initializes_correctly_test() {
  let today = 19_723
  let m = model.init(today)
  let input = m.entry_input

  input.weight_str |> should.equal("")
  input.date_int |> should.equal(today)
  input.comment |> should.equal("")
  input.parsed_weight |> should.equal(None)
}

pub fn empty_statistics_initializes_to_zero_test() {
  let today = 19_723
  let m = model.init(today)
  let s = m.statistics

  s.total_change |> should.equal(0.0)
  s.average_weight |> should.equal(0.0)
  s.min_weight |> should.equal(0.0)
  s.max_weight |> should.equal(0.0)
  s.week_change |> should.equal(0.0)
  s.month_change |> should.equal(0.0)
  s.current_bmi |> should.equal(None)
  s.bmi_category |> should.equal(None)
  s.goal_progress |> should.equal(0.0)
  s.days_to_goal |> should.equal(None)
}

pub fn empty_profile_has_no_data_test() {
  let today = 19_723
  let m = model.init(today)
  let p = m.user_profile

  p.height_cm |> should.equal(None)
  p.birth_date |> should.equal(None)
  p.gender |> should.equal(None)
}
