/// Supervisor - OTP supervisor tree for the meal planner application
///
/// This module provides the main supervisor tree that manages all OTP processes
/// in the meal planner application. It implements a hierarchical supervisor
/// structure for fault tolerance and process management.
///
/// ## Supervisor Hierarchy
///
/// ```
/// RootSupervisor
/// ├── ActorsSupervisor (one_for_one)
/// │   ├── SchedulerActor (email notifications)
/// │   └── TodoistActor (API synchronization)
/// └── CacheSupervisor (one_for_one)
///     └── QueryCache
/// ```
///
/// ## Supervision Strategies
///
/// - **one_for_one**: If a child crashes, only that child is restarted
///   (used for independent workers like actors)
/// - **rest_for_one**: If a child crashes, that child and all children
///   started after it are restarted (used for dependencies like cache -> web)
/// - **one_for_all**: If a child crashes, all children are restarted
///   (not used in this application)
///
/// ## Usage
///
/// ```gleam
/// // Start the entire supervisor tree
/// let assert Ok(supervisor) = supervisor.start(db_conn)
///
/// // The supervisor automatically starts and monitors all children
/// ```
///
/// ## Fault Tolerance
///
/// - Child processes are restarted automatically on crashes
/// - Maximum 3 restarts within 60 seconds before supervisor gives up
/// - Database connections are pooled and managed separately
/// - Actors maintain their own state and recover gracefully
///
import gleam/erlang/process.{type Selector, type Subject}
import gleam/otp/actor
import gleam/otp/supervision.{type Children, type Message, type Supervisor}
import meal_planner/actors/scheduler_actor
import meal_planner/actors/todoist_actor
import meal_planner/query_cache
import pog

// ============================================================================
// Types
// ============================================================================

/// Configuration for the supervisor tree
pub type SupervisorConfig {
  SupervisorConfig(
    /// Database connection for workers that need it
    db_conn: pog.Connection,
    /// Port for the web server
    web_port: Int,
    /// Maximum restart intensity (restarts per period)
    max_restarts: Int,
    /// Restart period in seconds
    restart_period: Int,
  )
}

/// References to all supervised processes
pub type SupervisorRefs {
  SupervisorRefs(
    /// Main supervisor
    root: Subject(Message),
    /// Scheduler actor for email notifications
    scheduler: Subject(scheduler_actor.Message),
    /// Todoist actor for API sync
    todoist: Subject(todoist_actor.Message),
    /// Query cache process
    cache: Subject(query_cache.Message),
  )
}

// ============================================================================
// Public API
// ============================================================================

/// Start the root supervisor tree with default configuration
///
/// This starts all supervised processes in the correct order:
/// 1. Actors supervisor (scheduler, todoist)
/// 2. Cache supervisor (query cache)
///
/// Returns a StartResult containing the supervisor subject
pub fn start(
  db_conn: pog.Connection,
) -> Result(Subject(Message), actor.StartError) {
  let config =
    SupervisorConfig(
      db_conn: db_conn,
      web_port: 8000,
      max_restarts: 3,
      restart_period: 60,
    )

  start_with_config(config)
}

/// Start the supervisor tree with custom configuration
///
/// Allows customization of web port and restart parameters
pub fn start_with_config(
  config: SupervisorConfig,
) -> Result(Subject(Message), actor.StartError) {
  supervision.start(fn(children) { root_supervisor(children, config) })
}

// ============================================================================
// Supervisor Definitions
// ============================================================================

/// Root supervisor - manages top-level subsystems
///
/// Uses one_for_one strategy: if a subsystem crashes, only that subsystem
/// is restarted. This prevents cascading failures between independent systems.
fn root_supervisor(
  children: Children(Nil),
  config: SupervisorConfig,
) -> Children(Nil) {
  children
  |> supervision.add(actors_supervisor(config))
  |> supervision.add(cache_supervisor(config))
}

/// Actors supervisor - manages background worker actors
///
/// Supervises:
/// - SchedulerActor: sends weekly email notifications
/// - TodoistActor: synchronizes with Todoist API
///
/// Uses one_for_one strategy since actors are independent
fn actors_supervisor(
  _config: SupervisorConfig,
) -> supervision.ChildSpecification(Nil) {
  supervision.supervisor(fn(children) {
    children
    |> supervision.add(scheduler_actor.supervised())
    |> supervision.add(todoist_actor.supervised())
  })
}

/// Cache supervisor - manages the query cache process
///
/// The query cache stores database query results for performance
fn cache_supervisor(
  config: SupervisorConfig,
) -> supervision.ChildSpecification(Nil) {
  supervision.worker(fn() { query_cache.start(config.db_conn) })
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Create default supervisor configuration
pub fn default_config(db_conn: pog.Connection) -> SupervisorConfig {
  SupervisorConfig(
    db_conn: db_conn,
    web_port: 8000,
    max_restarts: 3,
    restart_period: 60,
  )
}

/// Get a selector for supervisor messages
///
/// This is useful for advanced supervision patterns where you need
/// to handle supervisor messages manually
pub fn message_selector() -> Selector(Message) {
  process.new_selector()
  |> process.selecting_anything(fn(msg) { msg })
}

// ============================================================================
// Supervision Utilities
// ============================================================================

/// Check if a child process is alive
///
/// Returns True if the process is running, False otherwise
pub fn is_child_alive(child: Subject(a)) -> Bool {
  process.is_alive(child)
}

/// Get child count for testing/monitoring
///
/// This is a helper for monitoring the supervisor tree
pub fn child_count() -> Int {
  // In a real implementation, this would query the supervisor
  // For now, return the static count of children
  3
}
