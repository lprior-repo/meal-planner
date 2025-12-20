/// Food search popup component (stub implementation)
///
/// This is a minimal stub to allow tests to compile.
/// Full implementation pending.
import gleam/option.{type Option}
import meal_planner/fatsecret/foods/types

/// Search state for the popup
pub type SearchState {
  SearchState(
    active: Bool,
    query: String,
    results: List(types.FoodSearchResult),
    error: Option(String),
    loading: Bool,
    selected_index: Int,
  )
}

/// Effect type (stub for Elm Architecture) - function that returns a Msg
pub type Effect =
  fn() -> Msg

/// Messages for the search popup
pub type Msg {
  SearchActivate
  SearchQuery(String)
  GotSearchResults(Result(List(types.FoodSearchResult), String))
  SelectByNumber(Int)
  SelectByArrow(Direction)
  SearchConfirm
  SearchCancel
  ClearError
  FoodSelected(food_id: String, food_name: String)
}

/// Arrow direction for navigation
pub type Direction {
  Up
  Down
}

/// Initialize search state
pub fn init() -> SearchState {
  SearchState(
    active: False,
    query: "",
    results: [],
    error: option.None,
    loading: False,
    selected_index: 0,
  )
}

/// No effects stub
fn no_effects() -> List(Effect) {
  []
}

/// Get element at index (helper function)
fn get_result_at(
  results: List(types.FoodSearchResult),
  index: Int,
) -> Option(types.FoodSearchResult) {
  case results, index {
    [], _ -> option.None
    [head, ..], 0 -> option.Some(head)
    [_, ..tail], n -> get_result_at(tail, n - 1)
  }
}

/// Update function (stub) - returns tuple for Elm Architecture
pub fn update(state: SearchState, msg: Msg) -> #(SearchState, List(Effect)) {
  case msg {
    SearchActivate -> #(SearchState(..state, active: True), no_effects())

    SearchQuery(query) -> #(
      SearchState(..state, query: query, loading: True),
      no_effects(),
    )

    GotSearchResults(Ok(results)) -> #(
      SearchState(..state, results: results, loading: False, error: option.None),
      no_effects(),
    )

    GotSearchResults(Error(err)) -> #(
      SearchState(..state, loading: False, error: option.Some(err)),
      no_effects(),
    )

    SelectByNumber(index) -> #(
      SearchState(..state, selected_index: index),
      no_effects(),
    )

    SelectByArrow(_direction) -> #(state, no_effects())

    // Stub: implement arrow navigation
    SearchConfirm ->
      // Stub: Return effect that selects the current food if results exist
      case get_result_at(state.results, state.selected_index) {
        option.Some(types.FoodSearchResult(food_id, food_name, _, _, _, _)) -> {
          let effect = fn() {
            FoodSelected(
              food_id: types.food_id_to_string(food_id),
              food_name: food_name,
            )
          }
          #(SearchState(..state, active: False), [effect])
        }
        option.None -> #(SearchState(..state, active: False), no_effects())
      }

    SearchCancel -> #(init(), no_effects())

    ClearError -> #(SearchState(..state, error: option.None), no_effects())

    FoodSelected(_, _) -> #(state, no_effects())
    // This message is produced by effects, not handled directly
  }
}
