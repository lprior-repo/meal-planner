/// TodoistActor - OTP actor for managing Todoist synchronization
///
/// This module provides an OTP GenServer actor that handles asynchronous
/// synchronization with the Todoist API. It manages a queue of sync requests
/// and retry logic for failed synchronizations.
///
/// ## Features
/// - Sync message handling for scheduled synchronization
/// - Retry mechanism with configurable retry count
/// - Graceful shutdown support
/// - Modular design following OTP patterns
///
/// ## Usage
///
/// ```gleam
/// // Start the Todoist actor
/// let assert Ok(started) = todoist_actor.start()
/// let actor_subject = started.data
///
/// // Send a sync request
/// todoist_actor.sync(actor_subject, user_id)
///
/// // Request shutdown
/// todoist_actor.shutdown(actor_subject)
/// ```
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import gleam/otp/supervision

// ============================================================================
// Types
// ============================================================================

/// Internal state held by the Todoist actor
pub type State {
  State(
    /// Queue of pending sync operations
    sync_queue: List(SyncItem),
    /// Current retry count for failed operations
    retry_count: Int,
  )
}

/// Represents a single sync item in the queue
pub type SyncItem {
  SyncItem(user_id: String, timestamp: Int)
}

/// Messages the Todoist actor can receive
pub type Message {
  /// Initiate synchronization with Todoist API for a user
  Sync(user_id: String)
  /// Retry a failed synchronization operation
  Retry(user_id: String)
  /// Gracefully shutdown the actor
  Shutdown
  /// Internal: Process the sync queue
  ProcessQueue
}

// ============================================================================
// Lifecycle Functions
// ============================================================================

/// Start the Todoist actor
pub fn start() -> actor.StartResult(Subject(Message)) {
  actor.new(State(sync_queue: [], retry_count: 0))
  |> actor.on_message(handle_message)
  |> actor.start
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
    Sync(user_id) -> {
      let new_state =
        State(
          ..state,
          sync_queue: list.append(state.sync_queue, [
            SyncItem(user_id: user_id, timestamp: 0),
          ]),
        )
      actor.continue(new_state)
    }

    Retry(_user_id) -> {
      let max_retries = 3
      case state.retry_count < max_retries {
        True -> {
          let new_state = State(..state, retry_count: state.retry_count + 1)
          // In a real implementation, this would call the HTTP client
          // to retry synchronization for the given user_id
          actor.continue(new_state)
        }
        False -> {
          // Max retries exceeded, give up and continue
          let new_state = State(..state, retry_count: 0)
          actor.continue(new_state)
        }
      }
    }

    ProcessQueue -> {
      case state.sync_queue {
        [] -> {
          // Queue is empty, continue with state unchanged
          actor.continue(state)
        }
        [_first, ..rest] -> {
          // Process the first item in queue
          // In a real implementation, this would call the HTTP client
          // to sync the user's data with Todoist API
          let new_state = State(..state, sync_queue: rest)
          actor.continue(new_state)
        }
      }
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

/// Handle Sync message: add to queue and trigger processing
/// Handle Retry message: retry failed sync with incremented counter
/// Handle ProcessQueue message: process pending sync items
/// Handle Shutdown message: gracefully stop the actor
// ============================================================================
// Client API - Convenience functions for interacting with the actor
// ============================================================================

/// Send a synchronization request for a user
pub fn sync(actor: Subject(Message), user_id: String) -> Nil {
  process.send(actor, Sync(user_id))
}

/// Request a retry of a failed synchronization
pub fn retry(actor: Subject(Message), user_id: String) -> Nil {
  process.send(actor, Retry(user_id))
}

/// Trigger processing of the sync queue
pub fn process_queue(actor: Subject(Message)) -> Nil {
  process.send(actor, ProcessQueue)
}

/// Request graceful shutdown of the actor
pub fn shutdown(actor: Subject(Message)) -> Nil {
  process.send(actor, Shutdown)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Create an empty initial state
pub fn empty_state() -> State {
  State(sync_queue: [], retry_count: 0)
}

/// Check if the sync queue has pending items
pub fn has_pending_items(state: State) -> Bool {
  !list.is_empty(state.sync_queue)
}

/// Get the length of the sync queue
pub fn queue_length(state: State) -> Int {
  list.length(state.sync_queue)
}

/// Get the current retry count
pub fn get_retry_count(state: State) -> Int {
  state.retry_count
}

/// Reset the retry counter
pub fn reset_retry_count(state: State) -> State {
  State(..state, retry_count: 0)
}
