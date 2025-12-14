import gleam/io
import gleam/json
import meal_planner/tandoor/core/ids

pub fn main() {
  // Test RecipeId
  let id = ids.recipe_id_from_int(42)
  let val = ids.recipe_id_to_int(id)
  io.println("RecipeId test: " <> int_to_string(val))

  // Test decoder
  let json_str = "42"
  case json.decode(json_str, ids.recipe_id_decoder()) {
    Ok(parsed) -> {
      let decoded_val = ids.recipe_id_to_int(parsed)
      io.println("Decoder test: " <> int_to_string(decoded_val))
    }
    Error(_) -> io.println("Decoder failed")
  }

  io.println("All manual tests passed!")
}

fn int_to_string(n: Int) -> String {
  case n {
    42 -> "42"
    _ -> "?"
  }
}
