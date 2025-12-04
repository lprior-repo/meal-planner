/// Todoist API HTTP client module
///
/// Handles synchronization with Todoist API for meal planning tasks.
/// Provides a clean abstraction for sending meal plan tasks to Todoist.
///
/// ## Features
/// - Type-safe task representation
/// - Result-based error handling
/// - Stub implementation for integration testing
///
/// ## Future Implementation
/// - Use gleam_httpc to make POST requests to Todoist API
/// - Implement proper authentication with API tokens
/// - Handle retries and rate limiting
/// - Add request/response logging
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

// ============================================================================
// Types
// ============================================================================

/// Represents a task to be synced with Todoist
pub type Task {
  Task(
    /// Unique task identifier
    id: String,
    /// Task name/title
    name: String,
    /// Optional task description
    description: Option(String),
    /// Todoist project ID (if already synced)
    todoist_id: Option(String),
  )
}

/// Error types for Todoist operations
pub type Error {
  /// API request failed (e.g., network error, invalid response)
  ApiError(String)
  /// Authentication failed with provided token
  AuthenticationError(String)
  /// Invalid task data provided
  ValidationError(String)
  /// Unexpected error during sync
  SyncError(String)
}

// ============================================================================
// Task Management
// ============================================================================

/// Create a new task for Todoist sync
///
/// # Arguments
/// * `id` - Unique task identifier
/// * `name` - Task name/title
/// * `description` - Optional task description
///
/// # Returns
/// A new Task with no Todoist ID yet (to be assigned on first sync)
pub fn new_task(id: String, name: String, description: Option(String)) -> Task {
  Task(id: id, name: name, description: description, todoist_id: None)
}

/// Create a task with an existing Todoist ID (from prior sync)
pub fn task_with_todoist_id(
  id: String,
  name: String,
  description: Option(String),
  todoist_id: String,
) -> Task {
  Task(
    id: id,
    name: name,
    description: description,
    todoist_id: Some(todoist_id),
  )
}

// ============================================================================
// Todoist API Sync
// ============================================================================

/// Sync a list of meal plan tasks with Todoist API
///
/// Sends task data to Todoist for synchronization. Tasks can be new or updates
/// to existing tasks. The function handles authentication, request formatting,
/// and error handling.
///
/// # Arguments
/// * `api_token` - Todoist API token for authentication
/// * `tasks` - List of tasks to synchronize
///
/// # Returns
/// * `Ok(Nil)` - All tasks synced successfully
/// * `Error(...)` - If sync failed
///
/// # Errors
/// * `AuthenticationError` - If the API token is invalid or expired
/// * `ValidationError` - If task data is malformed
/// * `ApiError` - If the API request failed
/// * `SyncError` - For other synchronization failures
///
/// # TODO
/// - Implement actual HTTP POST to Todoist API
///   Endpoint: https://api.todoist.com/rest/v2/tasks
///   Headers: Authorization: Bearer {api_token}
///   Body: JSON array of tasks
/// - Add batch processing for large task lists (max 200 per request)
/// - Implement exponential backoff retry logic for transient failures
/// - Add request/response logging for debugging
/// - Parse Todoist API response and update task todoist_ids
/// - Handle rate limiting (120 requests/minute)
/// - Add support for task updates (PUT) vs creates (POST)
///
/// # Example
/// ```gleam
/// let task1 = new_task("task-1", "Buy groceries", Some("Weekly shopping"))
/// let task2 = new_task("task-2", "Prep meals", None)
/// let result = sync_tasks("my-api-token", [task1, task2])
/// case result {
///   Ok(Nil) -> io.println("Tasks synced!")
///   Error(err) -> handle_error(err)
/// }
/// ```
pub fn sync_tasks(api_token: String, tasks: List(Task)) -> Result(Nil, Error) {
  // Validate inputs
  let _api_token = api_token
  let _tasks = tasks

  // TODO: Implement actual Todoist API synchronization
  // For now, this is a stub that validates inputs and succeeds
  // Implementation options:
  // 1. Use gleam_httpc HTTP client
  // 2. Format tasks as JSON using gleam_json
  // 3. Make POST request to Todoist API endpoint
  // 4. Handle API response and errors

  case api_token {
    "" -> Error(ValidationError("API token cannot be empty"))
    _ -> {
      case list.length(tasks) {
        0 -> Error(ValidationError("No tasks provided"))
        _ -> Ok(Nil)
      }
    }
  }
}

// ============================================================================
// JSON Serialization
// ============================================================================

/// Convert a Task to JSON for Todoist API request
///
/// Formats task data according to Todoist API v2 schema.
/// The JSON structure matches Todoist's task creation/update format.
pub fn task_to_json(task: Task) -> Json {
  let description_json = case task.description {
    Some(desc) -> json.string(desc)
    None -> json.null()
  }

  json.object([
    #("id", json.string(task.id)),
    #("content", json.string(task.name)),
    #("description", description_json),
  ])
}

/// Convert a list of tasks to JSON array for batch requests
pub fn tasks_to_json_array(tasks: List(Task)) -> Json {
  json.array(tasks, task_to_json)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Check if a task has been synced to Todoist already
pub fn is_synced(task: Task) -> Bool {
  option.is_some(task.todoist_id)
}

/// Update task with Todoist ID after successful sync
pub fn mark_synced(task: Task, todoist_id: String) -> Task {
  Task(..task, todoist_id: Some(todoist_id))
}

/// Filter tasks to only those not yet synced
pub fn unsynced_tasks(tasks: List(Task)) -> List(Task) {
  list.filter(tasks, fn(task) { !is_synced(task) })
}

/// Filter tasks to only those already synced
pub fn synced_tasks(tasks: List(Task)) -> List(Task) {
  list.filter(tasks, fn(task) { is_synced(task) })
}

/// Error message for logging/display
pub fn error_message(error: Error) -> String {
  case error {
    ApiError(msg) -> "API Error: " <> msg
    AuthenticationError(msg) -> "Authentication Error: " <> msg
    ValidationError(msg) -> "Validation Error: " <> msg
    SyncError(msg) -> "Sync Error: " <> msg
  }
}
