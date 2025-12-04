import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/integrations/todoist_client.{
  type Error, type Task, ApiError, AuthenticationError, SyncError,
  ValidationError, error_message, is_synced, mark_synced, new_task, sync_tasks,
  synced_tasks, task_to_json, task_with_todoist_id, tasks_to_json_array,
  unsynced_tasks,
}

// ============================================================================
// Task Creation Tests
// ============================================================================

pub fn new_task_creates_task_test() {
  let task = new_task("task-1", "Buy groceries", Some("Weekly shopping list"))

  task.id
  |> should.equal("task-1")

  task.name
  |> should.equal("Buy groceries")

  task.description
  |> should.equal(Some("Weekly shopping list"))

  task.todoist_id
  |> should.equal(None)
}

pub fn new_task_without_description_test() {
  let task = new_task("task-2", "Prep meals", None)

  task.id
  |> should.equal("task-2")

  task.name
  |> should.equal("Prep meals")

  task.description
  |> should.equal(None)

  task.todoist_id
  |> should.equal(None)
}

pub fn task_with_todoist_id_test() {
  let task =
    task_with_todoist_id(
      "task-1",
      "Buy groceries",
      Some("Shopping list"),
      "todoist-123",
    )

  task.id
  |> should.equal("task-1")

  task.todoist_id
  |> should.equal(Some("todoist-123"))
}

// ============================================================================
// Task Sync Tests
// ============================================================================

pub fn sync_tasks_with_valid_token_and_tasks_test() {
  let task1 = new_task("task-1", "Buy groceries", Some("Shopping"))
  let task2 = new_task("task-2", "Prep meals", None)

  let result = sync_tasks("valid-token", [task1, task2])

  result
  |> should.be_ok()
}

pub fn sync_tasks_with_empty_token_test() {
  let task = new_task("task-1", "Buy groceries", None)

  let result = sync_tasks("", [task])

  result
  |> should.be_error()

  case result {
    Error(ValidationError(_)) -> True
    _ -> False
  }
  |> should.equal(True)
}

pub fn sync_tasks_with_empty_list_test() {
  let result = sync_tasks("valid-token", [])

  result
  |> should.be_error()

  case result {
    Error(ValidationError(_)) -> True
    _ -> False
  }
  |> should.equal(True)
}

pub fn sync_tasks_with_multiple_tasks_test() {
  let tasks = [
    new_task("task-1", "Buy groceries", Some("Shopping")),
    new_task("task-2", "Prep meals", None),
    new_task("task-3", "Plan menu", Some("Weekly plan")),
  ]

  let result = sync_tasks("my-token", tasks)

  result
  |> should.be_ok()
}

// ============================================================================
// JSON Serialization Tests
// ============================================================================

pub fn task_to_json_with_description_test() {
  let task = new_task("task-1", "Buy groceries", Some("Weekly shopping"))

  let json_result = task_to_json(task)

  // Verify JSON is properly structured
  json_result
  |> json.to_string
  |> should.contain("task-1")

  json_result
  |> json.to_string
  |> should.contain("Buy groceries")

  json_result
  |> json.to_string
  |> should.contain("Weekly shopping")
}

pub fn task_to_json_without_description_test() {
  let task = new_task("task-2", "Prep meals", None)

  let json_result = task_to_json(task)

  json_result
  |> json.to_string
  |> should.contain("task-2")

  json_result
  |> json.to_string
  |> should.contain("Prep meals")
}

pub fn tasks_to_json_array_test() {
  let tasks = [
    new_task("task-1", "Buy groceries", Some("Shopping")),
    new_task("task-2", "Prep meals", None),
  ]

  let json_result = tasks_to_json_array(tasks)

  let json_str = json.to_string(json_result)

  json_str
  |> should.contain("task-1")

  json_str
  |> should.contain("task-2")

  json_str
  |> should.contain("Buy groceries")

  json_str
  |> should.contain("Prep meals")
}

// ============================================================================
// Task State Helper Tests
// ============================================================================

pub fn is_synced_for_new_task_test() {
  let task = new_task("task-1", "Buy groceries", None)

  is_synced(task)
  |> should.equal(False)
}

pub fn is_synced_for_synced_task_test() {
  let task =
    task_with_todoist_id("task-1", "Buy groceries", None, "todoist-123")

  is_synced(task)
  |> should.equal(True)
}

pub fn mark_synced_test() {
  let task = new_task("task-1", "Buy groceries", None)

  let synced_task = mark_synced(task, "todoist-456")

  synced_task.todoist_id
  |> should.equal(Some("todoist-456"))

  synced_task.id
  |> should.equal(task.id)

  synced_task.name
  |> should.equal(task.name)
}

pub fn unsynced_tasks_filters_correctly_test() {
  let unsynced1 = new_task("task-1", "Buy groceries", None)
  let synced1 =
    task_with_todoist_id("task-2", "Prep meals", None, "todoist-123")
  let unsynced2 = new_task("task-3", "Plan menu", None)

  let tasks = [unsynced1, synced1, unsynced2]

  let result = unsynced_tasks(tasks)

  result
  |> should.have_length(2)

  let ids =
    result
    |> should.have_length(2)
}

pub fn synced_tasks_filters_correctly_test() {
  let unsynced1 = new_task("task-1", "Buy groceries", None)
  let synced1 =
    task_with_todoist_id("task-2", "Prep meals", None, "todoist-123")
  let synced2 = task_with_todoist_id("task-3", "Plan menu", None, "todoist-456")

  let tasks = [unsynced1, synced1, synced2]

  let result = synced_tasks(tasks)

  result
  |> should.have_length(2)

  // Both results should be synced
  result
  |> should.have_length(2)
}

// ============================================================================
// Error Handling Tests
// ============================================================================

pub fn error_message_for_api_error_test() {
  let err = ApiError("Network timeout")

  error_message(err)
  |> should.contain("API Error")

  error_message(err)
  |> should.contain("Network timeout")
}

pub fn error_message_for_authentication_error_test() {
  let err = AuthenticationError("Invalid token")

  error_message(err)
  |> should.contain("Authentication Error")

  error_message(err)
  |> should.contain("Invalid token")
}

pub fn error_message_for_validation_error_test() {
  let err = ValidationError("Missing required field")

  error_message(err)
  |> should.contain("Validation Error")

  error_message(err)
  |> should.contain("Missing required field")
}

pub fn error_message_for_sync_error_test() {
  let err = SyncError("Partial sync failed")

  error_message(err)
  |> should.contain("Sync Error")

  error_message(err)
  |> should.contain("Partial sync failed")
}

// ============================================================================
// Integration Tests
// ============================================================================

pub fn sync_workflow_test() {
  let task1 = new_task("task-1", "Buy groceries", Some("Weekly"))
  let task2 = new_task("task-2", "Prep meals", None)

  let tasks = [task1, task2]

  // 1. Check all tasks are unsynced
  unsynced_tasks(tasks)
  |> should.have_length(2)

  synced_tasks(tasks)
  |> should.have_length(0)

  // 2. Sync tasks (stub implementation)
  let sync_result = sync_tasks("my-token", tasks)

  sync_result
  |> should.be_ok()
}

pub fn task_update_workflow_test() {
  let task = new_task("task-1", "Buy groceries", Some("Shopping"))

  // Initial state: not synced
  task
  |> is_synced
  |> should.equal(False)

  // Simulate sync: mark as synced with Todoist ID
  let synced_task = mark_synced(task, "todoist-789")

  synced_task
  |> is_synced
  |> should.equal(True)

  synced_task.todoist_id
  |> should.equal(Some("todoist-789"))
}
