//// Scheduler HTTP handlers
////
//// Provides HTTP endpoints for scheduler API:
//// - List all scheduled jobs
//// - List execution history
//// - Trigger immediate job execution

import gleam/json
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
  case scheduler_storage.list_all_executions(db, 50) {
    Ok(executions) -> {
      let executions_json =
        json.array(executions, fn(exec) {
          json.object([
            #("id", json.int(exec.id)),
            #("job_id", json.string(id.job_id_to_string(exec.job_id))),
            #("started_at", json.string(exec.started_at)),
            #("completed_at", case exec.completed_at {
              Some(time) -> json.string(time)
              None -> json.null()
            }),
            #("status", encode_job_status(exec.status)),
            #("attempt_number", json.int(exec.attempt_number)),
            #("duration_ms", case exec.duration_ms {
              Some(ms) -> json.int(ms)
              None -> json.null()
            }),
            #("error_message", case exec.error_message {
              Some(msg) -> json.string(msg)
              None -> json.null()
            }),
          ])
        })

      let body =
        json.object([#("executions", executions_json)])
        |> json.to_string

      wisp.json_response(body, 200)
    }
    Error(_) -> responses.internal_error("Failed to fetch execution history")
  }
}

/// Handle POST /scheduler/trigger/{job_id} - Trigger immediate execution
pub fn handle_trigger_job(db: pog.Connection, job_id: String) -> wisp.Response {
  // Parse job_id
  let job_id = id.job_id(job_id)

  // Validate that job exists
  case scheduler_storage.get_scheduled_job(db, job_id) {
    Ok(job) -> {
      // Reset job to pending so it can be triggered
      case scheduler_storage.reset_job_to_pending(conn: db, job_id: job_id) {
        Ok(_) -> {
          // Mark as running and create execution record
          case
            scheduler_storage.mark_job_running(
              conn: db,
              job_id: job_id,
              trigger_type: "manual",
            )
          {
            Ok(execution) -> {
              let body =
                json.object([
                  #("status", json.string("accepted")),
                  #("job_id", json.string(id.job_id_to_string(job.id))),
                  #("execution_id", json.int(execution.id)),
                  #("message", json.string("Job execution triggered")),
                ])
                |> json.to_string

              wisp.json_response(body, 202)
            }
            Error(_) ->
              responses.internal_error("Failed to start job execution")
          }
        }
        Error(_) -> responses.internal_error("Failed to reset job status")
      }
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
    scheduler_types.AgentWorkStream -> json.string("agent_work_stream")
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
