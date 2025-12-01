//// Meal type suggestion based on time of day

import shared/types

@external(erlang, "calendar", "local_time")
fn erlang_local_time() -> #(#(Int, Int, Int), #(Int, Int, Int))

/// Suggest a meal type based on the current time of day
/// Returns: Breakfast (5:00-10:59), Lunch (11:00-14:59),
///          Dinner (15:00-20:59), Snack (21:00-4:59)
pub fn suggest_meal_type_from_time() -> types.MealType {
  let #(_, #(hour, _, _)) = erlang_local_time()
  case hour {
    5 | 6 | 7 | 8 | 9 | 10 -> types.Breakfast
    11 | 12 | 13 | 14 -> types.Lunch
    15 | 16 | 17 | 18 | 19 | 20 -> types.Dinner
    _ -> types.Snack
  }
}
