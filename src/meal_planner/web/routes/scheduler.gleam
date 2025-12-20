//// Scheduler routing module
////
//// Routes:
//// - GET /scheduler/jobs -> List all scheduled jobs
//// - GET /scheduler/executions -> List execution history
//// - POST /scheduler/trigger/{job_id} -> Trigger immediate execution

import gleam/http
import gleam/option.{type Option, None, Some}
import meal_planner/web/handlers/scheduler as scheduler_handlers
import meal_planner/web/routes/types
import wisp

/// Route scheduler requests
pub fn route(
  req: wisp.Request,
  segments: List(String),
  ctx: types.Context,
) -> Option(wisp.Response) {
  case segments {
    ["scheduler", "jobs"] ->
      case req.method {
        http.Get -> Some(scheduler_handlers.handle_list_jobs(ctx.db))
        _ -> Some(wisp.method_not_allowed([http.Get]))
      }

    ["scheduler", "executions"] ->
      case req.method {
        http.Get -> Some(scheduler_handlers.handle_list_executions(ctx.db))
        _ -> Some(wisp.method_not_allowed([http.Get]))
      }

    ["scheduler", "trigger", job_id] ->
      case req.method {
        http.Post -> Some(scheduler_handlers.handle_trigger_job(ctx.db, job_id))
        _ -> Some(wisp.method_not_allowed([http.Post]))
      }

    _ -> None
  }
}
