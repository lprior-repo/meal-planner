import lustre/element/html as h
import lustre/element/attribute as a
import gleam/int

pub fn progress_bar(current: Int, target: Int) {
  let percent = int.to_string(current * 100 / target) <> "%"
  h.div([a.class("w-full bg-gray-200 rounded")], [
    h.div([
      a.class("bg-green-500 h-2 rounded"),
      a.style([#("width", percent)])
    ], [])
  ])
}
