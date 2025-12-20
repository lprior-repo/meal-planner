//// Scheduler HTTP handlers
////
//// Provides HTTP endpoints for scheduler API:
//// - List all scheduled jobs
//// - List execution history
//// - Trigger immediate job execution

import gleam/json
import gleam/list
import gleam/option.{None, Some}
import meal_planner/id
import meal_planner/scheduler/types as scheduler_types
import meal_planner/storage/scheduler as scheduler_storage
import meal_planner/web/responses
import pog
import wisp

// ============================================================================
// Handler Functions
// ============================================================================

/// Handle GET /scheduler/jobs - List all scheduled jobs
pub fn handle_list_jobs(db: pog.Connection) -> wisp.Response {
  case scheduler_storage.list_scheduled_jobs(db) {
    Ok(jobs) -> {
      let jobs_json =
        json.array(jobs, fn(job) {
          json.object([
            #("id", json.string(id.job_id_to_string(job.id))),
            #("job_type", encode_job_type(job.job_type)),
            #("status", encode_job_status(job.status)),
            #("priority", encode_job_priority(job.priority)),
            #("scheduled_for", case job.scheduled_for {
              Some(time) -> json.string(time)
              None -> json.null()
            }),
            #("enabled", json.bool(job.enabled)),
          ])
        })

      let body =
        json.object([#("jobs", jobs_json)])
        |> json.to_string

      wisp.json_response(body, 200)
    }
    Error(_) -> responses.internal_error("Failed to fetch scheduled jobs")
  }
}

/// Handle GET /scheduler/executions - List execution history
pub fn handle_list_executions(db: pog.Connection) -> wisp.Response {
  // For now, return empty array since we need to implement a query that lists all executions
  // TODO: Implement scheduler_storage.list_all_executions()
  let body =
    json.object([#("executions", json.array([], fn(_) { json.null() }))])
    |> json.to_string

  wisp.json_response(body, 200)
}

/// Handle POST /scheduler/trigger/{job_id} - Trigger immediate execution
pub fn handle_trigger_job(db: pog.Connection, job_id: String) -> wisp.Response {
  // Parse job_id
  let job_id = id.job_id(job_id)

  // Validate that job exists
  case scheduler_storage.get_scheduled_job(db, job_id) {
    Ok(job) -> {
      // Return 202 Accepted with job_id
      // TODO: Actually trigger the job execution via scheduler/executor
      let body =
        json.object([
          #("status", json.string("accepted")),
          #("job_id", json.string(id.job_id_to_string(job.id))),
          #("message", json.string("Job execution triggered")),
        ])
        |> json.to_string

      wisp.json_response(body, 202)
    }
    Error(_) -> responses.not_found("Job not found")
  }
}

// ============================================================================
// JSON Encoders
// ============================================================================

/// Encode JobType to JSON string
fn encode_job_type(job_type: scheduler_types.JobType) -> json.Json {
  case job_type {
    scheduler_types.WeeklyGeneration -> json.string("weekly_generation")
    scheduler_types.AutoSync -> json.string("auto_sync")
    scheduler_types.DailyAdvisor -> json.string("daily_advisor")
    scheduler_types.WeeklyTrends -> json.string("weekly_trends")
  }
}

/// Encode JobStatus to JSON string
fn encode_job_status(status: scheduler_types.JobStatus) -> json.Json {
  case status {
    scheduler_types.Pending -> json.string("pending")
    scheduler_types.Running -> json.string("running")
    scheduler_types.Completed -> json.string("completed")
    scheduler_types.Failed -> json.string("failed")
  }
}

/// Encode JobPriority to JSON string
fn encode_job_priority(priority: scheduler_types.JobPriority) -> json.Json {
  case priority {
    scheduler_types.Low -> json.string("low")
    scheduler_types.Medium -> json.string("medium")
    scheduler_types.High -> json.string("high")
    scheduler_types.Critical -> json.string("critical")
  }
}
