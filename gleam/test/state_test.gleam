import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/ncp
import meal_planner/state
import meal_planner/types.{Active, Gain, Moderate, UserProfile}

/// Test that state server starts successfully
pub fn state_server_starts_test() {
  let result = state.start()
  result |> should.be_ok
}

/// Test setting and getting user profile
pub fn set_and_get_profile_test() {
  let assert Ok(started) = state.start()
  let server = started.data

  let profile =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 4,
    )

  // Initially no profile
  state.get_profile(server) |> should.equal(None)

  // Set profile
  state.set_profile(server, profile)

  // Get profile back
  let result = state.get_profile(server)
  result |> should.equal(Some(profile))

  // Cleanup
  state.shutdown(server)
}

/// Test setting and getting nutrition goals
pub fn set_and_get_goals_test() {
  let assert Ok(started) = state.start()
  let server = started.data

  let goals =
    ncp.NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 80.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  // Initially no goals
  state.get_goals(server) |> should.equal(None)

  // Set goals
  state.set_goals(server, goals)

  // Get goals back
  let result = state.get_goals(server)
  result |> should.equal(Some(goals))

  // Cleanup
  state.shutdown(server)
}

/// Test clearing the cache
pub fn clear_cache_test() {
  let assert Ok(started) = state.start()
  let server = started.data

  let profile =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 5,
    )

  let goals =
    ncp.NutritionGoals(
      daily_protein: 200.0,
      daily_fat: 90.0,
      daily_carbs: 300.0,
      daily_calories: 3000.0,
    )

  // Set both
  state.set_profile(server, profile)
  state.set_goals(server, goals)

  // Verify both are set
  state.get_profile(server) |> should.equal(Some(profile))
  state.get_goals(server) |> should.equal(Some(goals))

  // Clear cache
  state.clear_cache(server)

  // Both should be None now
  state.get_profile(server) |> should.equal(None)
  state.get_goals(server) |> should.equal(None)

  // Cleanup
  state.shutdown(server)
}

/// Test empty state helper
pub fn empty_state_test() {
  let empty = state.empty_state()

  state.has_profile(empty) |> should.be_false
  state.has_goals(empty) |> should.be_false
}

/// Test has_profile and has_goals helpers
pub fn state_helpers_test() {
  let empty = state.empty_state()

  // Empty state
  state.has_profile(empty) |> should.be_false
  state.has_goals(empty) |> should.be_false

  // State with profile
  let with_profile =
    state.State(
      profile: Some(UserProfile(
        bodyweight: 180.0,
        activity_level: Moderate,
        goal: Gain,
        meals_per_day: 4,
      )),
      goals: None,
    )
  state.has_profile(with_profile) |> should.be_true
  state.has_goals(with_profile) |> should.be_false

  // State with goals
  let with_goals =
    state.State(
      profile: None,
      goals: Some(ncp.NutritionGoals(
        daily_protein: 180.0,
        daily_fat: 80.0,
        daily_carbs: 250.0,
        daily_calories: 2500.0,
      )),
    )
  state.has_profile(with_goals) |> should.be_false
  state.has_goals(with_goals) |> should.be_true
}

/// Test multiple state servers can run independently
pub fn independent_state_servers_test() {
  let assert Ok(started1) = state.start()
  let server1 = started1.data

  let assert Ok(started2) = state.start()
  let server2 = started2.data

  let profile1 =
    UserProfile(
      bodyweight: 180.0,
      activity_level: Moderate,
      goal: Gain,
      meals_per_day: 4,
    )

  let profile2 =
    UserProfile(
      bodyweight: 150.0,
      activity_level: Active,
      goal: Gain,
      meals_per_day: 5,
    )

  // Set different profiles on each server
  state.set_profile(server1, profile1)
  state.set_profile(server2, profile2)

  // Each should have its own state
  state.get_profile(server1) |> should.equal(Some(profile1))
  state.get_profile(server2) |> should.equal(Some(profile2))

  // Cleanup
  state.shutdown(server1)
  state.shutdown(server2)
}

/// Test creating child specification for supervisor
pub fn supervised_child_spec_test() {
  let _child_spec = state.supervised()
  should.be_true(True)
}
