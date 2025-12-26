/// Diary View Update - Message Handling Logic
///
/// This module contains the update function and all message handling logic
/// for the diary view screen, following the Elm Architecture pattern.
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import meal_planner/cli/screens/diary_view/messages.{
  type DiaryEffect, type DiaryMsg,
}
import meal_planner/cli/screens/diary_view/model
import meal_planner/cli/screens/fatsecret_diary.{
  type DiaryModel, type MealSection, CreateEntry, DeleteEntry, DiaryModel,
  FetchEntries, MainView, None as NoEffect, SearchFoods, SearchPopup,
  SearchState, UpdateEntry,
}
import meal_planner/fatsecret/diary/types as diary_types

// ============================================================================
// Constants
// ============================================================================

/// Maximum search results to display
const max_search_results = 15

// ============================================================================
// Update Function - Message Handling
// ============================================================================

/// Main update function for diary view
/// Returns updated model and effects to execute
pub fn diary_update(
  model: DiaryModel,
  msg: DiaryMsg,
) -> #(DiaryModel, DiaryEffect) {
  case msg {
    // === Date Navigation ===
    fatsecret_diary.DateNavigatePrevious -> {
      let new_date = model.current_date - 1
      let updated = DiaryModel(..model, current_date: new_date)
      #(updated, FetchEntries(new_date))
    }

    fatsecret_diary.DateNavigateNext -> {
      let new_date = model.current_date + 1
      let updated = DiaryModel(..model, current_date: new_date)
      #(updated, FetchEntries(new_date))
    }

    fatsecret_diary.DateJumpToToday -> {
      let today = model.today_as_date_int()
      let updated = DiaryModel(..model, current_date: today)
      #(updated, FetchEntries(today))
    }

    fatsecret_diary.DateShowPicker -> {
      let current_date_str = model.date_int_to_string(model.current_date)
      let updated =
        DiaryModel(
          ..model,
          view_state: fatsecret_diary.DatePicker(current_date_str),
        )
      #(updated, NoEffect)
    }

    fatsecret_diary.DateConfirmPicker(date_input) -> {
      case model.parse_date_string(date_input) {
        Ok(date_int) -> {
          let updated =
            DiaryModel(..model, current_date: date_int, view_state: MainView)
          #(updated, FetchEntries(date_int))
        }
        Error(err) -> {
          let updated =
            DiaryModel(
              ..model,
              error_message: option.Some(err),
              view_state: MainView,
            )
          #(updated, NoEffect)
        }
      }
    }

    fatsecret_diary.DateCancelPicker -> {
      let updated = DiaryModel(..model, view_state: MainView)
      #(updated, NoEffect)
    }

    // === Add Entry ===
    fatsecret_diary.AddEntryStart -> {
      let updated =
        DiaryModel(
          ..model,
          view_state: SearchPopup,
          search_state: SearchState(
            query: "",
            results: [],
            selected_index: 0,
            is_loading: False,
            search_error: option.None,
          ),
        )
      #(updated, NoEffect)
    }

    fatsecret_diary.SearchQueryChanged(query) -> {
      let search_state =
        SearchState(..model.search_state, query: query, is_loading: False)
      let updated = DiaryModel(..model, search_state: search_state)
      #(updated, NoEffect)
    }

    fatsecret_diary.SearchFoodStarted -> {
      let search_state =
        SearchState(
          ..model.search_state,
          is_loading: True,
          search_error: option.None,
        )
      let updated = DiaryModel(..model, search_state: search_state)
      #(updated, SearchFoods(model.search_state.query))
    }

    fatsecret_diary.GotFoodSearchResults(result) -> {
      case result {
        Ok(foods) -> {
          let limited_foods = list.take(foods, max_search_results)
          let search_state =
            SearchState(
              ..model.search_state,
              results: limited_foods,
              is_loading: False,
              selected_index: 0,
            )
          let updated = DiaryModel(..model, search_state: search_state)
          #(updated, NoEffect)
        }
        Error(err) -> {
          let search_state =
            SearchState(
              ..model.search_state,
              is_loading: False,
              search_error: option.Some(err),
            )
          let updated = DiaryModel(..model, search_state: search_state)
          #(updated, NoEffect)
        }
      }
    }

    fatsecret_diary.FoodSelected(food) -> {
      // For now, just close the popup - in full impl would show serving picker
      let updated = DiaryModel(..model, view_state: MainView)
      // Store selected food for serving selection
      let _ = food
      #(updated, NoEffect)
    }

    fatsecret_diary.ConfirmAddEntry(servings, meal) -> {
      // Create entry input and submit
      let input =
        diary_types.FromFood(
          food_id: "placeholder",
          food_entry_name: "Food Entry",
          serving_id: "placeholder",
          number_of_units: servings,
          meal: meal,
          date_int: model.current_date,
        )
      let updated = DiaryModel(..model, view_state: MainView)
      #(updated, CreateEntry(input))
    }

    fatsecret_diary.CancelAddEntry -> {
      let updated =
        DiaryModel(
          ..model,
          view_state: MainView,
          search_state: SearchState(
            query: "",
            results: [],
            selected_index: 0,
            is_loading: False,
            search_error: option.None,
          ),
        )
      #(updated, NoEffect)
    }

    // === Edit Entry ===
    fatsecret_diary.EditEntryStart(entry) -> {
      let edit_state =
        fatsecret_diary.EditState(
          entry: entry,
          new_number_of_units: entry.number_of_units,
          original_number_of_units: entry.number_of_units,
        )
      let updated =
        DiaryModel(
          ..model,
          view_state: fatsecret_diary.EditAmount(edit_state),
          edit_state: option.Some(edit_state),
        )
      #(updated, NoEffect)
    }

    fatsecret_diary.EditEntryServingsChanged(new_servings) -> {
      case model.edit_state {
        option.Some(edit_state) -> {
          let updated_edit =
            fatsecret_diary.EditState(
              ..edit_state,
              new_number_of_units: new_servings,
            )
          let updated =
            DiaryModel(
              ..model,
              edit_state: option.Some(updated_edit),
              view_state: fatsecret_diary.EditAmount(updated_edit),
            )
          #(updated, NoEffect)
        }
        option.None -> #(model, NoEffect)
      }
    }

    fatsecret_diary.EditEntryConfirm -> {
      case model.edit_state {
        option.Some(edit_state) -> {
          let update =
            diary_types.FoodEntryUpdate(
              number_of_units: option.Some(edit_state.new_number_of_units),
              meal: option.None,
            )
          let effect = UpdateEntry(edit_state.entry.food_entry_id, update)
          let updated =
            DiaryModel(..model, view_state: MainView, edit_state: option.None)
          #(updated, effect)
        }
        option.None -> #(DiaryModel(..model, view_state: MainView), NoEffect)
      }
    }

    fatsecret_diary.EditEntryCancel -> {
      let updated =
        DiaryModel(..model, view_state: MainView, edit_state: option.None)
      #(updated, NoEffect)
    }

    // === Delete Entry ===
    fatsecret_diary.DeleteEntryStart(entry_id) -> {
      let updated =
        DiaryModel(..model, view_state: fatsecret_diary.ConfirmDelete(entry_id))
      #(updated, NoEffect)
    }

    fatsecret_diary.DeleteEntryConfirm -> {
      case model.view_state {
        fatsecret_diary.ConfirmDelete(entry_id) -> {
          let updated = DiaryModel(..model, view_state: MainView)
          #(updated, DeleteEntry(entry_id))
        }
        _ -> #(model, NoEffect)
      }
    }

    fatsecret_diary.DeleteEntryCancel -> {
      let updated = DiaryModel(..model, view_state: MainView)
      #(updated, NoEffect)
    }

    // === Copy Meal ===
    fatsecret_diary.CopyMealStart -> {
      // TODO: Implement copy meal flow
      #(model, NoEffect)
    }

    fatsecret_diary.CopyMealSelectSource(_meal) -> {
      #(model, NoEffect)
    }

    fatsecret_diary.CopyMealSelectDate(_date_int) -> {
      #(model, NoEffect)
    }

    fatsecret_diary.CopyMealSelectDestMeal(_meal) -> {
      #(model, NoEffect)
    }

    fatsecret_diary.CopyMealConfirm -> {
      #(model, NoEffect)
    }

    fatsecret_diary.CopyMealCancel -> {
      #(model, NoEffect)
    }

    // === Server Responses ===
    fatsecret_diary.FetchEntriesForDate(date_int) -> {
      #(model, FetchEntries(date_int))
    }

    fatsecret_diary.GotDailyEntries(result) -> {
      case result {
        Ok(entries) -> {
          let sections = group_entries_by_meal(entries)
          let updated =
            DiaryModel(
              ..model,
              entries_by_meal: sections,
              error_message: option.None,
            )
          #(updated, NoEffect)
        }
        Error(err) -> {
          let updated = DiaryModel(..model, error_message: option.Some(err))
          #(updated, NoEffect)
        }
      }
    }

    fatsecret_diary.GotNutritionTargets(result) -> {
      case result {
        Ok(targets) -> {
          let updated =
            DiaryModel(..model, nutrition_targets: option.Some(targets))
          #(updated, NoEffect)
        }
        Error(_) -> #(model, NoEffect)
      }
    }

    fatsecret_diary.EntryCreated(result) -> {
      case result {
        Ok(_entry_id) -> {
          // Refresh entries for current date
          #(model, FetchEntries(model.current_date))
        }
        Error(err) -> {
          let updated = DiaryModel(..model, error_message: option.Some(err))
          #(updated, NoEffect)
        }
      }
    }

    fatsecret_diary.EntryUpdated(result) -> {
      case result {
        Ok(_) -> {
          #(model, FetchEntries(model.current_date))
        }
        Error(err) -> {
          let updated = DiaryModel(..model, error_message: option.Some(err))
          #(updated, NoEffect)
        }
      }
    }

    fatsecret_diary.EntryDeleted(result) -> {
      case result {
        Ok(_) -> {
          #(model, FetchEntries(model.current_date))
        }
        Error(err) -> {
          let updated = DiaryModel(..model, error_message: option.Some(err))
          #(updated, NoEffect)
        }
      }
    }

    // === UI State ===
    fatsecret_diary.ClearError -> {
      let updated = DiaryModel(..model, error_message: option.None)
      #(updated, NoEffect)
    }

    fatsecret_diary.KeyPressed(key) -> {
      handle_key_press(model, key)
    }

    fatsecret_diary.NoOp -> {
      #(model, NoEffect)
    }
  }
}

// ============================================================================
// Keyboard Handling
// ============================================================================

/// Handle keyboard input for diary view
fn handle_key_press(
  model: DiaryModel,
  key: String,
) -> #(DiaryModel, DiaryEffect) {
  case model.view_state {
    MainView -> {
      case key {
        "[" -> diary_update(model, fatsecret_diary.DateNavigatePrevious)
        "]" -> diary_update(model, fatsecret_diary.DateNavigateNext)
        "t" -> diary_update(model, fatsecret_diary.DateJumpToToday)
        "g" -> diary_update(model, fatsecret_diary.DateShowPicker)
        "a" -> diary_update(model, fatsecret_diary.AddEntryStart)
        "c" -> diary_update(model, fatsecret_diary.CopyMealStart)
        "r" -> #(model, FetchEntries(model.current_date))
        _ -> #(model, NoEffect)
      }
    }
    SearchPopup -> {
      case key {
        "\u{001B}" -> diary_update(model, fatsecret_diary.CancelAddEntry)
        "\r" -> diary_update(model, fatsecret_diary.SearchFoodStarted)
        _ -> #(model, NoEffect)
      }
    }
    fatsecret_diary.DatePicker(_) -> {
      case key {
        "\u{001B}" -> diary_update(model, fatsecret_diary.DateCancelPicker)
        _ -> #(model, NoEffect)
      }
    }
    fatsecret_diary.ConfirmDelete(_) -> {
      case key {
        "y" -> diary_update(model, fatsecret_diary.DeleteEntryConfirm)
        "n" -> diary_update(model, fatsecret_diary.DeleteEntryCancel)
        "\u{001B}" -> diary_update(model, fatsecret_diary.DeleteEntryCancel)
        _ -> #(model, NoEffect)
      }
    }
    fatsecret_diary.EditAmount(_) -> {
      case key {
        "\u{001B}" -> diary_update(model, fatsecret_diary.EditEntryCancel)
        "\r" -> diary_update(model, fatsecret_diary.EditEntryConfirm)
        _ -> #(model, NoEffect)
      }
    }
  }
}

// ============================================================================
// Entry Grouping
// ============================================================================

/// Group food entries by meal type
fn group_entries_by_meal(
  entries: List(diary_types.FoodEntry),
) -> List(MealSection) {
  let breakfast_entries =
    entries
    |> list.filter(fn(e) { e.meal == diary_types.Breakfast })
  let lunch_entries =
    entries
    |> list.filter(fn(e) { e.meal == diary_types.Lunch })
  let dinner_entries =
    entries
    |> list.filter(fn(e) { e.meal == diary_types.Dinner })
  let snack_entries =
    entries
    |> list.filter(fn(e) { e.meal == diary_types.Snack })

  [
    build_meal_section(diary_types.Breakfast, breakfast_entries),
    build_meal_section(diary_types.Lunch, lunch_entries),
    build_meal_section(diary_types.Dinner, dinner_entries),
    build_meal_section(diary_types.Snack, snack_entries),
  ]
  |> list.filter(fn(section) { !list.is_empty(section.entries) })
}

/// Build a meal section with calculated totals
fn build_meal_section(
  meal_type: diary_types.MealType,
  entries: List(diary_types.FoodEntry),
) -> MealSection {
  let display_entries =
    entries
    |> list.map(fn(entry) {
      fatsecret_diary.DisplayEntry(
        entry: entry,
        display_text: format_entry_text(entry),
        macros_display: format_entry_macros(entry),
      )
    })

  let totals = calculate_section_totals(entries)

  fatsecret_diary.MealSection(
    meal_type: meal_type,
    entries: display_entries,
    section_totals: totals,
  )
}

/// Format entry text for display
fn format_entry_text(entry: diary_types.FoodEntry) -> String {
  let servings = float.to_string(entry.number_of_units)
  servings <> " × " <> entry.food_entry_name
}

/// Format entry macros for display
fn format_entry_macros(entry: diary_types.FoodEntry) -> String {
  let cal = float.truncate(entry.calories) |> int.to_string
  let p = float.truncate(entry.protein) |> int.to_string
  let c = float.truncate(entry.carbohydrate) |> int.to_string
  let f = float.truncate(entry.fat) |> int.to_string
  cal <> " cal | " <> p <> "g P | " <> c <> "g C | " <> f <> "g F"
}

/// Calculate nutrition totals for a meal section
fn calculate_section_totals(
  entries: List(diary_types.FoodEntry),
) -> fatsecret_diary.MealTotals {
  entries
  |> list.fold(
    fatsecret_diary.MealTotals(
      calories: 0.0,
      carbohydrate: 0.0,
      protein: 0.0,
      fat: 0.0,
    ),
    fn(acc, entry) {
      fatsecret_diary.MealTotals(
        calories: acc.calories +. entry.calories,
        carbohydrate: acc.carbohydrate +. entry.carbohydrate,
        protein: acc.protein +. entry.protein,
        fat: acc.fat +. entry.fat,
      )
    },
  )
}
