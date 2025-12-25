/// List View Component - Reusable TUI Scrollable List
///
/// This module provides a reusable scrollable list component for Shore TUI
/// following Elm Architecture patterns.
///
/// FEATURES:
/// - Scrollable list with keyboard navigation
/// - Single and multi-select modes
/// - Search/filter functionality
/// - Pagination support
/// - Custom item rendering
/// - Visual selection indicators
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import shore
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

// ============================================================================
// Helper Functions
// ============================================================================

/// Get item at index from list
fn get_at(items: List(a), index: Int) -> Result(a, Nil) {
  items
  |> list.drop(index)
  |> list.first
}

/// List view model (generic over item type)
pub type ListViewModel(item) {
  ListViewModel(
    /// All items in the list
    items: List(item),
    /// Currently selected index
    selected_index: Int,
    /// Scroll offset (first visible item index)
    scroll_offset: Int,
    /// Number of visible items
    visible_count: Int,
    /// Multi-selection mode
    multi_select: Bool,
    /// Selected indices (for multi-select)
    selected_indices: List(Int),
    /// Search/filter query
    filter_query: String,
    /// Whether filter is active
    filter_active: Bool,
    /// Loading state
    is_loading: Bool,
    /// Error message
    error: Option(String),
    /// Empty message
    empty_message: String,
    /// Title
    title: Option(String),
  )
}

/// List view messages
pub type ListViewMsg {
  // Navigation
  SelectPrevious
  SelectNext
  SelectFirst
  SelectLast
  PageUp
  PageDown

  // Selection
  ToggleSelection
  SelectAll
  DeselectAll
  Confirm

  // Filter
  FilterQueryChanged(query: String)
  ToggleFilter
  ClearFilter

  // State - Note: SetItems removed as it requires a parameterized message type
  // Use init() or direct model updates instead
  SetLoading(loading: Bool)
  SetError(error: Option(String))
  ClearError
}

/// List view effect
pub type ListViewEffect(item) {
  NoEffect
  ItemSelected(item: item, index: Int)
  ItemsSelected(items: List(item), indices: List(Int))
  FilterChanged(query: String)
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial list view model
pub fn init(items: List(item), visible_count: Int) -> ListViewModel(item) {
  ListViewModel(
    items: items,
    selected_index: 0,
    scroll_offset: 0,
    visible_count: visible_count,
    multi_select: False,
    selected_indices: [],
    filter_query: "",
    filter_active: False,
    is_loading: False,
    error: None,
    empty_message: "No items",
    title: None,
  )
}

/// Create with multi-select enabled
pub fn init_multi_select(
  items: List(item),
  visible_count: Int,
) -> ListViewModel(item) {
  let model = init(items, visible_count)
  ListViewModel(..model, multi_select: True)
}

/// Create with title
pub fn init_with_title(
  items: List(item),
  visible_count: Int,
  title: String,
) -> ListViewModel(item) {
  let model = init(items, visible_count)
  ListViewModel(..model, title: Some(title))
}

// ============================================================================
// Update Function
// ============================================================================

/// Update list view state
pub fn update(
  model: ListViewModel(item),
  msg: ListViewMsg,
) -> #(ListViewModel(item), ListViewEffect(item)) {
  let item_count = list.length(model.items)

  case msg {
    // === Navigation ===
    SelectPrevious -> {
      case model.selected_index > 0 {
        True -> {
          let new_index = model.selected_index - 1
          let new_offset =
            adjust_scroll_offset(
              new_index,
              model.scroll_offset,
              model.visible_count,
            )
          let updated =
            ListViewModel(
              ..model,
              selected_index: new_index,
              scroll_offset: new_offset,
            )
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    SelectNext -> {
      case model.selected_index < item_count - 1 {
        True -> {
          let new_index = model.selected_index + 1
          let new_offset =
            adjust_scroll_offset(
              new_index,
              model.scroll_offset,
              model.visible_count,
            )
          let updated =
            ListViewModel(
              ..model,
              selected_index: new_index,
              scroll_offset: new_offset,
            )
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    SelectFirst -> {
      let updated = ListViewModel(..model, selected_index: 0, scroll_offset: 0)
      #(updated, NoEffect)
    }

    SelectLast -> {
      let last_index = int.max(0, item_count - 1)
      let new_offset = int.max(0, last_index - model.visible_count + 1)
      let updated =
        ListViewModel(
          ..model,
          selected_index: last_index,
          scroll_offset: new_offset,
        )
      #(updated, NoEffect)
    }

    PageUp -> {
      let new_index = int.max(0, model.selected_index - model.visible_count)
      let new_offset = int.max(0, model.scroll_offset - model.visible_count)
      let updated =
        ListViewModel(
          ..model,
          selected_index: new_index,
          scroll_offset: new_offset,
        )
      #(updated, NoEffect)
    }

    PageDown -> {
      let new_index =
        int.min(item_count - 1, model.selected_index + model.visible_count)
      let new_offset =
        int.min(
          int.max(0, item_count - model.visible_count),
          model.scroll_offset + model.visible_count,
        )
      let updated =
        ListViewModel(
          ..model,
          selected_index: int.max(0, new_index),
          scroll_offset: new_offset,
        )
      #(updated, NoEffect)
    }

    // === Selection ===
    ToggleSelection -> {
      case model.multi_select {
        True -> {
          let is_selected =
            list.contains(model.selected_indices, model.selected_index)
          let new_indices = case is_selected {
            True ->
              list.filter(model.selected_indices, fn(i) {
                i != model.selected_index
              })
            False -> [model.selected_index, ..model.selected_indices]
          }
          let updated = ListViewModel(..model, selected_indices: new_indices)
          #(updated, NoEffect)
        }
        False -> {
          case get_at(model.items, model.selected_index) {
            Ok(item) -> #(model, ItemSelected(item, model.selected_index))
            Error(_) -> #(model, NoEffect)
          }
        }
      }
    }

    SelectAll -> {
      case model.multi_select {
        True -> {
          let all_indices = list.range(0, item_count - 1)
          let updated = ListViewModel(..model, selected_indices: all_indices)
          #(updated, NoEffect)
        }
        False -> #(model, NoEffect)
      }
    }

    DeselectAll -> {
      let updated = ListViewModel(..model, selected_indices: [])
      #(updated, NoEffect)
    }

    Confirm -> {
      case model.multi_select {
        True -> {
          let selected_items =
            model.selected_indices
            |> list.flat_map(fn(i) {
              case get_at(model.items, i) {
                Ok(item) -> [item]
                Error(_) -> []
              }
            })
          #(model, ItemsSelected(selected_items, model.selected_indices))
        }
        False -> {
          case get_at(model.items, model.selected_index) {
            Ok(item) -> #(model, ItemSelected(item, model.selected_index))
            Error(_) -> #(model, NoEffect)
          }
        }
      }
    }

    // === Filter ===
    FilterQueryChanged(query) -> {
      let updated = ListViewModel(..model, filter_query: query)
      #(updated, FilterChanged(query))
    }

    ToggleFilter -> {
      let updated =
        ListViewModel(
          ..model,
          filter_active: !model.filter_active,
          filter_query: case model.filter_active {
            True -> ""
            False -> model.filter_query
          },
        )
      #(updated, NoEffect)
    }

    ClearFilter -> {
      let updated =
        ListViewModel(..model, filter_query: "", filter_active: False)
      #(updated, FilterChanged(""))
    }

    // === State ===
    SetLoading(loading) -> {
      let updated = ListViewModel(..model, is_loading: loading)
      #(updated, NoEffect)
    }

    SetError(error) -> {
      let updated = ListViewModel(..model, error: error)
      #(updated, NoEffect)
    }

    ClearError -> {
      let updated = ListViewModel(..model, error: None)
      #(updated, NoEffect)
    }
  }
}

/// Handle keyboard input
pub fn handle_key(
  model: ListViewModel(item),
  key: String,
) -> #(ListViewModel(item), ListViewEffect(item)) {
  case model.filter_active {
    True -> {
      case key {
        "\u{001B}" -> update(model, ToggleFilter)
        "\r" -> update(model, ToggleFilter)
        _ -> #(model, NoEffect)
      }
    }
    False -> {
      case key {
        "k" | "\u{001B}[A" -> update(model, SelectPrevious)
        "j" | "\u{001B}[B" -> update(model, SelectNext)
        "g" -> update(model, SelectFirst)
        "G" -> update(model, SelectLast)
        "\u{001B}[5~" -> update(model, PageUp)
        "\u{001B}[6~" -> update(model, PageDown)
        " " -> update(model, ToggleSelection)
        "\r" -> update(model, Confirm)
        "/" -> update(model, ToggleFilter)
        "a" -> update(model, SelectAll)
        "d" -> update(model, DeselectAll)
        _ -> #(model, NoEffect)
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Adjust scroll offset to keep selected item visible
fn adjust_scroll_offset(selected: Int, current_offset: Int, visible: Int) -> Int {
  case selected < current_offset {
    True -> selected
    False ->
      case selected >= current_offset + visible {
        True -> selected - visible + 1
        False -> current_offset
      }
  }
}

/// Get visible items
pub fn get_visible_items(model: ListViewModel(item)) -> List(item) {
  model.items
  |> list.drop(model.scroll_offset)
  |> list.take(model.visible_count)
}

/// Get selected item
pub fn get_selected_item(model: ListViewModel(item)) -> Option(item) {
  case get_at(model.items, model.selected_index) {
    Ok(item) -> Some(item)
    Error(_) -> None
  }
}

/// Get selected items (multi-select)
pub fn get_selected_items(model: ListViewModel(item)) -> List(item) {
  model.selected_indices
  |> list.flat_map(fn(i) {
    case get_at(model.items, i) {
      Ok(item) -> [item]
      Error(_) -> []
    }
  })
}

/// Check if index is selected
pub fn is_index_selected(model: ListViewModel(item), index: Int) -> Bool {
  case model.multi_select {
    True -> list.contains(model.selected_indices, index)
    False -> index == model.selected_index
  }
}

// ============================================================================
// View Functions
// ============================================================================

/// Render the list view with a custom item renderer
pub fn view(
  model: ListViewModel(item),
  render_item: fn(item, Int, Bool, Bool) -> String,
  on_msg: fn(ListViewMsg) -> msg,
) -> shore.Node(msg) {
  let item_count = list.length(model.items)

  // Build all sections as separate lists, then flatten
  let title_section = case model.title {
    Some(t) -> [ui.text_styled(t, Some(style.Green), None), ui.hr()]
    None -> []
  }

  let filter_section = case model.filter_active {
    True -> [
      ui.input("Filter:", model.filter_query, style.Pct(80), fn(q) {
        on_msg(FilterQueryChanged(q))
      }),
      ui.br(),
    ]
    False -> []
  }

  let error_section = case model.error {
    Some(err) -> [ui.text_styled("Error: " <> err, Some(style.Red), None)]
    None -> []
  }

  let loading_section = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let scroll_top_section = case model.scroll_offset > 0 {
    True -> [
      ui.text("  ▲ " <> int.to_string(model.scroll_offset) <> " more above"),
    ]
    False -> []
  }

  let items_section = case model.items {
    [] -> [ui.text(model.empty_message)]
    _ -> {
      let visible = get_visible_items(model)
      list.index_map(visible, fn(item, rel_index) {
        let abs_index = model.scroll_offset + rel_index
        let is_cursor = abs_index == model.selected_index
        let is_selected = is_index_selected(model, abs_index)
        let line = render_item(item, abs_index, is_cursor, is_selected)
        ui.text(line)
      })
    }
  }

  let scroll_bottom_section = case
    model.scroll_offset + model.visible_count < item_count
  {
    True -> {
      let below = item_count - model.scroll_offset - model.visible_count
      [ui.text("  ▼ " <> int.to_string(below) <> " more below")]
    }
    False -> []
  }

  let status_section = [
    ui.br(),
    ui.text(
      "Item "
      <> int.to_string(model.selected_index + 1)
      <> " of "
      <> int.to_string(item_count)
      <> case model.multi_select {
        True ->
          " | Selected: " <> int.to_string(list.length(model.selected_indices))
        False -> ""
      },
    ),
  ]

  ui.col(
    list.flatten([
      title_section,
      filter_section,
      error_section,
      loading_section,
      scroll_top_section,
      items_section,
      scroll_bottom_section,
      status_section,
    ]),
  )
}

/// Default item renderer
pub fn default_item_renderer(
  item: String,
  index: Int,
  is_cursor: Bool,
  is_selected: Bool,
) -> String {
  let cursor = case is_cursor {
    True -> "► "
    False -> "  "
  }
  let checkbox = case is_selected {
    True -> "[✓] "
    False -> "[ ] "
  }
  cursor <> checkbox <> int.to_string(index + 1) <> ". " <> item
}

/// Simple item renderer (no checkbox)
pub fn simple_item_renderer(
  item: String,
  index: Int,
  is_cursor: Bool,
  _is_selected: Bool,
) -> String {
  let cursor = case is_cursor {
    True -> "► "
    False -> "  "
  }
  cursor <> int.to_string(index + 1) <> ". " <> item
}

// ============================================================================
// Public API
// ============================================================================

/// Set items
pub fn set_items(
  model: ListViewModel(item),
  items: List(item),
) -> ListViewModel(item) {
  ListViewModel(
    ..model,
    items: items,
    selected_index: 0,
    scroll_offset: 0,
    selected_indices: [],
  )
}

/// Set title
pub fn set_title(
  model: ListViewModel(item),
  title: String,
) -> ListViewModel(item) {
  ListViewModel(..model, title: Some(title))
}

/// Set empty message
pub fn set_empty_message(
  model: ListViewModel(item),
  message: String,
) -> ListViewModel(item) {
  ListViewModel(..model, empty_message: message)
}

/// Enable multi-select
pub fn enable_multi_select(model: ListViewModel(item)) -> ListViewModel(item) {
  ListViewModel(..model, multi_select: True)
}

/// Disable multi-select
pub fn disable_multi_select(model: ListViewModel(item)) -> ListViewModel(item) {
  ListViewModel(..model, multi_select: False, selected_indices: [])
}

/// Set visible count
pub fn set_visible_count(
  model: ListViewModel(item),
  count: Int,
) -> ListViewModel(item) {
  ListViewModel(..model, visible_count: count)
}

/// Select by index
pub fn select_index(
  model: ListViewModel(item),
  index: Int,
) -> ListViewModel(item) {
  let item_count = list.length(model.items)
  let valid_index = int.clamp(index, 0, int.max(0, item_count - 1))
  let new_offset =
    adjust_scroll_offset(valid_index, model.scroll_offset, model.visible_count)
  ListViewModel(..model, selected_index: valid_index, scroll_offset: new_offset)
}
