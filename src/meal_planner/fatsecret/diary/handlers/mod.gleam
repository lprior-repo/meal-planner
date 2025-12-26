/// Route dispatcher for FatSecret Diary handlers
///
/// This module provides a centralized way to route requests to the appropriate
/// handler functions based on HTTP method and path.
import gleam/http.{Delete, Get, Patch}
import meal_planner/fatsecret/diary/handlers/copy
import meal_planner/fatsecret/diary/handlers/create
import meal_planner/fatsecret/diary/handlers/delete
import meal_planner/fatsecret/diary/handlers/get
import meal_planner/fatsecret/diary/handlers/list
import meal_planner/fatsecret/diary/handlers/summary
import meal_planner/fatsecret/diary/handlers/update
import pog
import wisp.{type Request, type Response}

/// Route diary requests to appropriate handler
pub fn handle_diary_routes(req: Request, conn: pog.Connection) -> Response {
  case wisp.path_segments(req) {
    ["api", "fatsecret", "diary", "entries"] -> create.create_entry(req, conn)
    ["api", "fatsecret", "diary", "entries", entry_id] ->
      case req.method {
        Get -> get.get_entry(req, conn, entry_id)
        Patch -> update.update_entry(req, conn, entry_id)
        Delete -> delete.delete_entry(req, conn, entry_id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }
    ["api", "fatsecret", "diary", "day", date_int] ->
      list.get_day(req, conn, date_int)
    ["api", "fatsecret", "diary", "month", date_int] ->
      summary.get_month(req, conn, date_int)
    ["api", "fatsecret", "diary", "copy-entries"] ->
      copy.copy_entries(req, conn)
    ["api", "fatsecret", "diary", "copy-meal"] -> copy.copy_meal(req, conn)
    ["api", "fatsecret", "diary", "commit-day"] -> copy.commit_day(req, conn)
    ["api", "fatsecret", "diary", "save-template"] ->
      copy.save_template(req, conn)
    _ -> wisp.not_found()
  }
}
