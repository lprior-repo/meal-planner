import gleam/int

/// Renders a progress bar showing current/target progress
pub fn progress_bar(current: Int, target: Int) -> String {
  let percent = int.to_string(current * 100 / target)
  "<div class=\"w-full bg-gray-200 rounded\">"
  <> "<div class=\"bg-green-500 h-2 rounded\" style=\"width: "
  <> percent
  <> "%\"></div>"
  <> "</div>"
}
