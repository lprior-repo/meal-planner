//// Web routing module - delegates to domain-specific routers
////
//// Refactored to follow CUPID principles:
//// - Composable: Piping through domain routers
//// - Unix: Each router has single responsibility
//// - Predictable: Clear routing flow
//// - Idiomatic: Uses Gleam patterns
//// - Domain-based: Organized by domain

import gleam/option.{None, Some}
import meal_planner/web/routes/auth
import meal_planner/web/routes/fatsecret
import meal_planner/web/routes/health
import meal_planner/web/routes/meal_planning
import meal_planner/web/routes/misc
import meal_planner/web/routes/nutrition
import meal_planner/web/routes/scheduler
import meal_planner/web/routes/tandoor
import meal_planner/web/routes/types.{type Context}
import wisp

/// Route request to appropriate domain router
///
/// Tries each domain router in sequence until one handles the request.
/// Falls back to 404 if no router matches.
pub fn route(req: wisp.Request, ctx: Context) -> wisp.Response {
  let segments = wisp.path_segments(req)

  // Try each router in order: health -> auth -> scheduler -> nutrition -> meal_planning -> fatsecret -> tandoor -> misc -> 404
  case health.route(req, segments, ctx) {
    Some(resp) -> resp
    None ->
      case auth.route(req, segments, ctx) {
        Some(resp) -> resp
        None ->
          case scheduler.route(req, segments, ctx) {
            Some(resp) -> resp
            None ->
              case nutrition.route(req, segments, ctx) {
                Some(resp) -> resp
                None ->
                  case meal_planning.route(req, segments, ctx) {
                    Some(resp) -> resp
                    None ->
                      case fatsecret.route(req, segments, ctx) {
                        Some(resp) -> resp
                        None ->
                          case tandoor.route(req, segments, ctx) {
                            Some(resp) -> resp
                            None ->
                              case misc.route(req, segments, ctx) {
                                Some(resp) -> resp
                                None -> wisp.not_found()
                              }
                          }
                      }
                  }
              }
          }
      }
  }
}
