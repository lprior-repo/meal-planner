/// Food Search Popup - Reusable TUI Component
///
/// Encapsulates food search state, rendering, keyboard handling (1-9 selection,
/// arrow navigation), and async food API calls. Designed to be imported by
/// multiple screens (Diary, FatSecret domain, etc).
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/env
import meal_planner/fatsecret/foods/client as foods_client
import meal_planner/fatsecret/foods/types as foods_types
import shore/key.{type Key}
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

/// Search component state
pub type SearchState {
  SearchState(
    active: Bool,
    query: String,
    results: List(FoodSearchResult),
    selected_index: Int,
    loading: Bool,
    error: Option(String),
  )
}

/// Lightweight search result for display
pub type FoodSearchResult {
  FoodSearchResult(
    food_id: String,
    food_name: String,
    food_type: String,
    brand_name: Option(String),
    food_description: String,
  )
}

/// Component messages
pub type FoodSearchMsg {
  SearchActivate
  SearchQuery(String)
  GotSearchResults(Result(List(foods_types.FoodSearchResult), String))
  SelectByNumber(Int)
  SelectByArrow(Direction)
  SearchConfirm
  SearchCancel
  ClearError
  FoodSelected(food_id: String, food_name: String)
}

/// Arrow key direction for navigation
pub type Direction {
  Up
  Down
}

// ============================================================================
// Initial State
// ============================================================================

pub fn init() -> SearchState {
  SearchState(
    active: False,
    query: "",
    results: [],
    selected_index: 0,
    loading: False,
    error: None,
  )
}

// ============================================================================
// View (Rendering)
// ============================================================================

pub fn render(state: SearchState) -> ui.Node(FoodSearchMsg) {
  case state.active {
    False -> ui.text("")
    True -> render_popup(state)
  }
}

fn render_popup(state: SearchState) -> ui.Node(FoodSearchMsg) {
  ui.col([
    ui.br(),
    ui.text_styled("FOOD SEARCH", Some(style.Green), None),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.input("Query:", state.query, style.Pct(80), SearchQuery),
    ui.br(),
    case state.loading {
      True -> ui.text_styled("Searching...", Some(style.Yellow), None)
      False ->
        case state.results {
          [] -> ui.text("(no results)")
          results -> render_results(results, state.selected_index)
        }
    },
    ui.br(),
    case state.error {
      None -> ui.text("")
      Some(err) -> ui.text_styled("Error: " <> err, Some(style.Red), None)
    },
    ui.br(),
    ui.text_styled(
      "[1-9] Select | [↑↓] Navigate | [Enter] Confirm | [Esc] Cancel",
      Some(style.Cyan),
      None,
    ),
  ])
}

fn render_results(
  results: List(FoodSearchResult),
  selected_index: Int,
) -> ui.Node(FoodSearchMsg) {
  results
  |> list.index_map(fn(idx, result) {
    let is_selected = idx == selected_index
    let number = idx + 1 |> int.to_string
    let fg = case is_selected {
      True -> Some(style.Black)
      False -> Some(style.White)
    }
    let bg = case is_selected {
      True -> Some(style.Blue)
      False -> None
    }

    let display_text =
      number
      <> ". "
      <> result.food_name
      <> case result.brand_name {
        Some(brand) -> " (" <> brand <> ")"
        None -> ""
      }

    ui.button_id_styled(
      id: "food_" <> number,
      text: display_text,
      key: key.Char(number),
      event: SelectByNumber(idx + 1),
      fg: fg,
      bg: bg,
      focus_fg: Some(style.Black),
      focus_bg: Some(style.Green),
    )
  })
  |> list.intersperse(ui.br())
  |> ui.col
}

// ============================================================================
// Update (State Machine)
// ============================================================================

pub fn update(
  state: SearchState,
  msg: FoodSearchMsg,
) -> #(SearchState, List(fn() -> FoodSearchMsg)) {
  case msg {
    SearchActivate -> {
      let new_state =
        SearchState(
          ..state,
          active: True,
          query: "",
          results: [],
          selected_index: 0,
          error: None,
        )
      #(new_state, [])
    }

    SearchQuery(q) -> {
      let new_state = SearchState(..state, query: q, loading: True)
      let effect = fn() { search_foods_effect(q) }
      #(new_state, [effect])
    }

    GotSearchResults(Ok(foods)) -> {
      let results =
        foods
        |> list.take(9)
        |> list.map(fn(food) {
          FoodSearchResult(
            food_id: foods_types.food_id_to_string(food.food_id),
            food_name: food.food_name,
            food_type: food.food_type,
            brand_name: food.brand_name,
            food_description: food.food_description,
          )
        })

      let new_state =
        SearchState(
          ..state,
          results: results,
          loading: False,
          selected_index: 0,
          error: None,
        )
      #(new_state, [])
    }

    GotSearchResults(Err(err)) -> {
      let new_state = SearchState(..state, error: Some(err), loading: False)
      #(new_state, [])
    }

    SelectByNumber(n) -> {
      let new_state = SearchState(..state, selected_index: n - 1)
      #(new_state, [])
    }

    SelectByArrow(Up) -> {
      let max_index = list.length(state.results) - 1
      let idx = case state.selected_index {
        0 -> max_index
        n -> n - 1
      }
      let new_state = SearchState(..state, selected_index: idx)
      #(new_state, [])
    }

    SelectByArrow(Down) -> {
      let max_index = list.length(state.results) - 1
      let idx = case state.selected_index < max_index {
        True -> state.selected_index + 1
        False -> 0
      }
      let new_state = SearchState(..state, selected_index: idx)
      #(new_state, [])
    }

    SearchConfirm -> {
      case list.at(state.results, state.selected_index) {
        Ok(selected) -> {
          let effect = fn() {
            FoodSelected(
              food_id: selected.food_id,
              food_name: selected.food_name,
            )
          }
          let new_state = SearchState(..state, active: False)
          #(new_state, [effect])
        }
        Error(_) -> #(state, [])
      }
    }

    SearchCancel -> {
      let new_state =
        SearchState(..state, active: False, query: "", results: [], error: None)
      #(new_state, [])
    }

    ClearError -> {
      let new_state = SearchState(..state, error: None)
      #(new_state, [])
    }

    FoodSelected(_food_id, _food_name) -> {
      // Parent screen should handle this message
      #(state, [])
    }
  }
}

// ============================================================================
// Effects
// ============================================================================

fn search_foods_effect(query: String) -> FoodSearchMsg {
  case query {
    "" -> GotSearchResults(Ok([]))
    _ -> {
      case env.load_fatsecret_config() {
        Some(config) -> {
          case foods_client.search_foods(config, query, 0, 9) {
            Ok(response) -> GotSearchResults(Ok(response.foods))
            Error(err) ->
              GotSearchResults(Err(foods_client.error_to_string(err)))
          }
        }
        None -> GotSearchResults(Err("FatSecret API not configured"))
      }
    }
  }
}
