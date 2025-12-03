/// GenServer for managing application runtime state
///
/// This module provides a stateful actor for caching and managing
/// application state like user profiles and nutrition goals.
/// It reduces database reads by keeping frequently-accessed data in memory.
///
/// ## Usage
///
/// ```gleam
/// // Start the state server
/// let assert Ok(started) = state.start()
/// let state_subject = started.data
///
/// // Set and get user profile
/// state.set_profile(state_subject, profile)
/// let profile = state.get_profile(state_subject)
/// ```
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervision
import meal_planner/ncp
import shared/types.{type UserProfile}

/// Internal state held by the GenServer
pub type State {
  State(
    /// Cached user profile
    profile: Option(UserProfile),
    /// Cached nutrition goals
    goals: Option(ncp.NutritionGoals),
  )
}

/// Messages the state server can receive
pub type Message {
  /// Set the user profile in cache
  SetProfile(UserProfile)
  /// Get the cached user profile
  GetProfile(Subject(Option(UserProfile)))
  /// Set nutrition goals in cache
  SetGoals(ncp.NutritionGoals)
  /// Get cached nutrition goals
  GetGoals(Subject(Option(ncp.NutritionGoals)))
  /// Clear all cached state
  ClearCache
  /// Gracefully shutdown the server
  Shutdown
}

/// Start the state server
pub fn start() -> actor.StartResult(Subject(Message)) {
  actor.new(State(profile: None, goals: None))
  |> actor.on_message(handle_message)
  |> actor.start
}

/// Create a child specification for adding this server to a supervisor
pub fn supervised() -> supervision.ChildSpecification(Subject(Message)) {
  supervision.worker(start)
}

/// Handle incoming messages
fn handle_message(state: State, message: Message) -> actor.Next(State, Message) {
  case message {
    SetProfile(profile) -> {
      actor.continue(State(..state, profile: Some(profile)))
    }

    GetProfile(reply_to) -> {
      process.send(reply_to, state.profile)
      actor.continue(state)
    }

    SetGoals(goals) -> {
      actor.continue(State(..state, goals: Some(goals)))
    }

    GetGoals(reply_to) -> {
      process.send(reply_to, state.goals)
      actor.continue(state)
    }

    ClearCache -> {
      actor.continue(State(profile: None, goals: None))
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

// ============================================================================
// Client API - Convenience functions for interacting with the state server
// ============================================================================

/// Set the user profile in the state cache
pub fn set_profile(server: Subject(Message), profile: UserProfile) -> Nil {
  process.send(server, SetProfile(profile))
}

/// Get the cached user profile (with timeout)
pub fn get_profile(server: Subject(Message)) -> Option(UserProfile) {
  actor.call(server, 1000, GetProfile)
}

/// Set nutrition goals in the state cache
pub fn set_goals(server: Subject(Message), goals: ncp.NutritionGoals) -> Nil {
  process.send(server, SetGoals(goals))
}

/// Get cached nutrition goals (with timeout)
pub fn get_goals(server: Subject(Message)) -> Option(ncp.NutritionGoals) {
  actor.call(server, 1000, GetGoals)
}

/// Clear all cached state
pub fn clear_cache(server: Subject(Message)) -> Nil {
  process.send(server, ClearCache)
}

/// Request graceful shutdown
pub fn shutdown(server: Subject(Message)) -> Nil {
  process.send(server, Shutdown)
}

// ============================================================================
// Helper functions
// ============================================================================

/// Create initial empty state
pub fn empty_state() -> State {
  State(profile: None, goals: None)
}

/// Check if profile is cached
pub fn has_profile(state: State) -> Bool {
  option.is_some(state.profile)
}

/// Check if goals are cached
pub fn has_goals(state: State) -> Bool {
  option.is_some(state.goals)
}
