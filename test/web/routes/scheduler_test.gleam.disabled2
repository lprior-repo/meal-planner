//// Tests for scheduler HTTP routes
////
//// Tests the scheduler API endpoints:
//// - GET /scheduler/jobs - List all jobs
//// - GET /scheduler/executions - List execution history
//// - POST /scheduler/trigger/{job_id} - Trigger immediate execution

import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/config
import meal_planner/web/routes/scheduler
import meal_planner/web/routes/types
import pog
import wisp

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a test context with mock database connection
/// NOTE: Tests will need real DB connection to pass fully
fn test_context() -> types.Context {
  let config = config.new()
  let assert Ok(db) =
    pog.default_config()
    |> pog.database(config.database.name)
    |> pog.host(config.database.host)
    |> pog.port(config.database.port)
    |> pog.user(config.database.user)
    |> pog.password(option.Some(config.database.password))
    |> pog.pool_size(1)
    |> pog.connect

  types.Context(config: config, db: db)
}

// ============================================================================
// GET /scheduler/jobs Tests
// ============================================================================

pub fn list_jobs_route_matches_test() {
  let ctx = test_context()
  let req =
    wisp.Request(
      method: wisp.Get,
      headers: [],
      body: wisp.Empty,
      scheme: wisp.Http,
      host: "localhost",
      port: Some(8000),
      path: "/scheduler/jobs",
      query: None,
    )

  let response = scheduler.route(req, ["scheduler", "jobs"], ctx)

  // Should return Some(response) since route matches
  should.be_some(response)
}

// ============================================================================
// GET /scheduler/executions Tests
// ============================================================================

pub fn list_executions_route_matches_test() {
  let ctx = test_context()
  let req =
    wisp.Request(
      method: wisp.Get,
      headers: [],
      body: wisp.Empty,
      scheme: wisp.Http,
      host: "localhost",
      port: Some(8000),
      path: "/scheduler/executions",
      query: None,
    )

  let response = scheduler.route(req, ["scheduler", "executions"], ctx)

  // Should return Some(response) since route matches
  should.be_some(response)
}

// ============================================================================
// POST /scheduler/trigger/{job_id} Tests
// ============================================================================

pub fn trigger_job_route_matches_test() {
  let ctx = test_context()
  let req =
    wisp.Request(
      method: wisp.Post,
      headers: [],
      body: wisp.Empty,
      scheme: wisp.Http,
      host: "localhost",
      port: Some(8000),
      path: "/scheduler/trigger/job_weekly_generation",
      query: None,
    )

  let response =
    scheduler.route(req, ["scheduler", "trigger", "job_weekly_generation"], ctx)

  // Should return Some(response) since route matches
  should.be_some(response)
}

// ============================================================================
// Route Matching Tests
// ============================================================================

pub fn non_matching_route_returns_none_test() {
  let ctx = test_context()
  let req =
    wisp.Request(
      method: wisp.Get,
      headers: [],
      body: wisp.Empty,
      scheme: wisp.Http,
      host: "localhost",
      port: Some(8000),
      path: "/scheduler/invalid",
      query: None,
    )

  let response = scheduler.route(req, ["scheduler", "invalid"], ctx)

  // Should return None for non-matching routes
  should.be_none(response)
}

pub fn non_scheduler_route_returns_none_test() {
  let ctx = test_context()
  let req =
    wisp.Request(
      method: wisp.Get,
      headers: [],
      body: wisp.Empty,
      scheme: wisp.Http,
      host: "localhost",
      port: Some(8000),
      path: "/health",
      query: None,
    )

  let response = scheduler.route(req, ["health"], ctx)

  // Should return None for routes not starting with /scheduler
  should.be_none(response)
}
