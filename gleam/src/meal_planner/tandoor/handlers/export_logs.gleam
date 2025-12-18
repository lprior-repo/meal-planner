/// Export Logs handler stubs for Tandoor
import wisp

pub fn handle_export_logs_collection(_req: wisp.Request) -> wisp.Response {
  wisp.not_found()
}

pub fn handle_export_log_by_id(
  _req: wisp.Request,
  _log_id: String,
) -> wisp.Response {
  wisp.not_found()
}
