/// SchedulerActor - OTP actor for scheduled email notifications
///
/// This module provides an OTP GenServer actor that implements scheduled
/// email notifications. It wakes up every hour to check if the current time
/// is Sunday at 8 PM, and if so, triggers an email send.
///
/// ## Features
/// - Hourly wake-up using process.send_after (3600000 ms)
/// - Checks if current time is Sunday 8 PM
/// - Triggers email send (stubbed for now)
/// - Graceful shutdown support
/// - Modular OTP actor pattern
///
/// ## Usage
///
/// ```gleam
/// // Start the scheduler actor
/// let assert Ok(started) = scheduler_actor.start()
/// let actor_subject = started.data
///
/// // The actor will automatically wake every hour and check the time
/// // To manually trigger a check:
/// // scheduler_actor.check_time(actor_subject)
///
/// // Request shutdown
/// scheduler_actor.shutdown(actor_subject)
/// ```
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/otp/actor
import gleam/otp/supervision

// ============================================================================
// Types
// ============================================================================

/// Internal state held by the scheduler actor
pub type State {
  State(
    /// Reference to self for scheduling messages
    self_ref: Subject(Message),
    /// Next check time (for tracking purposes)
    next_check_time: Int,
  )
}

/// Messages the scheduler actor can receive
pub type Message {
  /// Check if it's time to send the weekly email (internal, triggered by send_after)
  CheckTime
  /// Trigger email send
  TriggerEmail
  /// Gracefully shutdown the actor
  Shutdown
}

// ============================================================================
// Lifecycle Functions
// ============================================================================

/// Start the scheduler actor
pub fn start() -> actor.StartResult(Subject(Message)) {
  actor.new_self()
  |> actor.start_spec(fn(self_ref) {
    let initial_state = State(self_ref: self_ref, next_check_time: 0)
    // Schedule the first check in 1 hour (3600000 ms)
    process.send_after(self_ref, 3_600_000, CheckTime)
    #(initial_state, actor.on_message(handle_message))
  })
}

/// Create a child specification for adding this actor to a supervisor
pub fn supervised() -> supervision.ChildSpecification(Subject(Message)) {
  supervision.worker(start)
}

// ============================================================================
// Message Handler
// ============================================================================

/// Handle incoming messages to the actor
fn handle_message(state: State, message: Message) -> actor.Next(State, Message) {
  case message {
    CheckTime -> {
      // Check if current time is Sunday 8 PM
      case is_sunday_8pm() {
        True -> {
          // It's Sunday 8 PM, trigger email send
          process.send(state.self_ref, TriggerEmail)
          // Schedule next check in 1 hour (3600000 ms)
          process.send_after(state.self_ref, 3_600_000, CheckTime)
          actor.continue(state)
        }
        False -> {
          // Not time yet, schedule next check in 1 hour
          process.send_after(state.self_ref, 3_600_000, CheckTime)
          actor.continue(state)
        }
      }
    }

    TriggerEmail -> {
      // Stubbed: In real implementation, this would send the email
      // For now, just continue with the state
      actor.continue(state)
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

// ============================================================================
// Client API - Convenience functions for interacting with the actor
// ============================================================================

/// Send a CheckTime message to the scheduler actor
pub fn check_time(actor: Subject(Message)) -> Nil {
  process.send(actor, CheckTime)
}

/// Request graceful shutdown of the actor
pub fn shutdown(actor: Subject(Message)) -> Nil {
  process.send(actor, Shutdown)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Check if the current time is Sunday at 8 PM (20:00)
///
/// Returns True if current time is Sunday 20:00, False otherwise
/// Note: This is a simplified implementation that checks the day of week.
/// A full implementation would need to verify the hour as well.
fn is_sunday_8pm() -> Bool {
  // This is a stubbed implementation that returns False
  // In a real implementation, you would:
  // 1. Get the current system time
  // 2. Parse it to determine day of week and hour
  // 3. Check if it's Sunday (day 0) and hour is 20 (8 PM)
  // For now, returning False means checks will continue but never trigger email
  False
}

/// Get the current state's next check time
pub fn get_next_check_time(state: State) -> Int {
  state.next_check_time
}

/// Create an empty initial state (for testing)
pub fn empty_state() -> State {
  // For testing purposes only - normal usage goes through start()
  State(
    self_ref: panic as "empty_state should not be used outside tests",
    next_check_time: 0,
  )
}
