/// Weight Screen View Functions - MVC Architecture
///
/// This module contains all view/rendering functions for the weight tracking screen.
/// Following the Model-View-Controller pattern, this is the View layer.
///
/// FUNCTIONS:
/// - weight_view: Main view dispatcher
/// - view_*: Individual view functions for each screen state
/// - Helper functions for rendering components
import gleam/list
import gleam/option.{None, Some}
import meal_planner/cli/screens/weight/components/chart
import meal_planner/cli/screens/weight/messages.{
  type WeightMsg, CancelAddEntry, CancelDelete, CancelEditEntry, ClearError,
  CommentInputChanged, ConfirmAddEntry, ConfirmDelete, ConfirmEditEntry,
  DateConfirm, EditCommentChanged, EditWeightChanged, GoBack, KeyPressed,
  Refresh, WeightInputChanged,
}
import meal_planner/cli/screens/weight/model.{
  type WeightDisplayEntry, type WeightGoalType, type WeightModel, AddEntryView,
  ChartView, ConfirmDeleteView, DatePicker, EditEntryView, Female, GainWeight,
  GoalsView, ListView, LoseWeight, MaintainWeight, Male, Other, ProfileView,
  StatsView,
}
import meal_planner/cli/screens/weight/update.{
  date_int_to_string, float_to_string,
}
import meal_planner/fatsecret/weight/types as weight_types
import shore
import shore/style
import shore/ui

// ============================================================================
// Main View Dispatcher
// ============================================================================

/// Render the weight view screen
pub fn weight_view(model: WeightModel) -> shore.Node(WeightMsg) {
  case model.view_state {
    ListView -> view_list(model)
    AddEntryView -> view_add_entry(model)
    EditEntryView -> view_edit_entry(model)
    ConfirmDeleteView(entry_id) -> view_delete_confirm(model, entry_id)
    GoalsView -> view_goals(model)
    StatsView -> view_stats(model)
    ChartView -> view_chart(model)
    ProfileView -> view_profile(model)
    DatePicker(date_input) -> view_date_picker(model, date_input)
  }
}

// ============================================================================
// View Functions
// ============================================================================

/// Render weight list view
fn view_list(model: WeightModel) -> shore.Node(WeightMsg) {
  let current_weight_row = case model.current_weight {
    Some(w) -> [
      ui.br(),
      ui.text_styled(
        "Current Weight: " <> float_to_string(w) <> " kg",
        Some(style.Yellow),
        None,
      ),
    ]
    None -> []
  }

  let error_row = case model.error_message {
    Some(err) -> [ui.text_styled("⚠ " <> err, Some(style.Red), None)]
    None -> []
  }

  let loading_row = case model.is_loading {
    True -> [ui.text_styled("Loading...", Some(style.Yellow), None)]
    False -> []
  }

  let entry_rows = case model.entries {
    [] -> [ui.text("No weight entries recorded.")]
    entries -> list.take(entries, 10) |> list.map(render_weight_entry)
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("⚖ Weight Tracker", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
      ],
      current_weight_row,
      error_row,
      [
        ui.br(),
        ui.text_styled(
          "[a] Add  [g] Goals  [s] Stats  [c] Chart  [p] Profile  [r] Refresh",
          Some(style.Cyan),
          None,
        ),
        ui.hr(),
        ui.br(),
      ],
      loading_row,
      [ui.text_styled("Recent Entries:", Some(style.Yellow), None)],
      entry_rows,
      [
        ui.br(),
        ui.text_styled(
          "[e] Edit  [d] Delete  [Enter] View",
          Some(style.Cyan),
          None,
        ),
      ],
    ]),
  )
}

/// Render a weight entry
fn render_weight_entry(entry: WeightDisplayEntry) -> shore.Node(WeightMsg) {
  let bmi_str = case entry.bmi_display {
    Some(b) -> " (BMI: " <> b <> ")"
    None -> ""
  }
  ui.text(
    "  "
    <> entry.date_display
    <> ": "
    <> entry.weight_display
    <> " "
    <> entry.change_display
    <> bmi_str,
  )
}

/// Render add entry view
fn view_add_entry(model: WeightModel) -> shore.Node(WeightMsg) {
  let input = model.entry_input

  let parsed_row = case input.parsed_weight {
    Some(w) -> [
      ui.text_styled(
        "Parsed: " <> float_to_string(w) <> " kg",
        Some(style.Green),
        None,
      ),
    ]
    None ->
      case input.weight_str {
        "" -> []
        _ -> [ui.text_styled("Invalid weight", Some(style.Red), None)]
      }
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("➕ Add Weight Entry", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
        ui.text("Date: " <> date_int_to_string(input.date_int)),
        ui.br(),
        ui.input("Weight (kg):", input.weight_str, style.Pct(30), fn(w) {
          WeightInputChanged(w)
        }),
        ui.br(),
        ui.input("Comment:", input.comment, style.Pct(60), fn(c) {
          CommentInputChanged(c)
        }),
        ui.br(),
      ],
      parsed_row,
      [
        ui.br(),
        ui.hr(),
        ui.text_styled("[Enter] Save  [Esc] Cancel", Some(style.Cyan), None),
      ],
    ]),
  )
}

/// Render edit entry view
fn view_edit_entry(model: WeightModel) -> shore.Node(WeightMsg) {
  case model.edit_state {
    None -> ui.col([ui.text("No entry being edited")])
    Some(edit) -> {
      ui.col([
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("✏ Edit Weight Entry", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
        ui.text("Date: " <> date_int_to_string(edit.entry.date_int)),
        ui.text("Original: " <> float_to_string(edit.original_weight) <> " kg"),
        ui.br(),
        ui.input("New Weight (kg):", edit.new_weight_str, style.Pct(30), fn(w) {
          EditWeightChanged(w)
        }),
        ui.br(),
        ui.input("Comment:", edit.new_comment, style.Pct(60), fn(c) {
          EditCommentChanged(c)
        }),
        ui.br(),
        ui.hr(),
        ui.text_styled("[Enter] Save  [Esc] Cancel", Some(style.Cyan), None),
      ])
    }
  }
}

/// Render delete confirmation
fn view_delete_confirm(
  _model: WeightModel,
  entry_id: weight_types.WeightEntryId,
) -> shore.Node(WeightMsg) {
  let id_str = weight_types.weight_entry_id_to_string(entry_id)

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("⚠ Confirm Delete", Some(style.Red), None),
    ),
    ui.hr_styled(style.Red),
    ui.br(),
    ui.text("Delete this weight entry?"),
    ui.text("Entry ID: " <> id_str),
    ui.br(),
    ui.text_styled("[y] Yes  [n] No", Some(style.Yellow), None),
  ])
}

/// Render goals view
fn view_goals(model: WeightModel) -> shore.Node(WeightMsg) {
  let g = model.goals

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("🎯 Weight Goals", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text("Goal Type: " <> goal_type_to_string(g.goal_type)),
    ui.text("Target Weight: " <> float_to_string(g.target_weight) <> " kg"),
    ui.text("Starting Weight: " <> float_to_string(g.starting_weight) <> " kg"),
    ui.text("Weekly Target: " <> float_to_string(g.weekly_target) <> " kg/week"),
    ui.br(),
    case model.current_weight {
      Some(current) -> {
        let remaining = g.target_weight -. current
        ui.text("Remaining: " <> float_to_string(remaining) <> " kg")
      }
      None -> ui.text("")
    },
    ui.br(),
    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Convert goal type to string
fn goal_type_to_string(gt: WeightGoalType) -> String {
  case gt {
    LoseWeight -> "Lose Weight"
    MaintainWeight -> "Maintain Weight"
    GainWeight -> "Gain Weight"
  }
}

/// Render stats view
fn view_stats(model: WeightModel) -> shore.Node(WeightMsg) {
  let s = model.statistics

  let bmi_row = case s.current_bmi, s.bmi_category {
    Some(bmi), Some(cat) -> [
      ui.text("BMI: " <> float_to_string(bmi) <> " (" <> cat <> ")"),
    ]
    _, _ -> []
  }

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📊 Statistics", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
        ui.text("Total Change: " <> float_to_string(s.total_change) <> " kg"),
        ui.text("Average: " <> float_to_string(s.average_weight) <> " kg"),
        ui.text("Min: " <> float_to_string(s.min_weight) <> " kg"),
        ui.text("Max: " <> float_to_string(s.max_weight) <> " kg"),
        ui.br(),
        ui.text("7-Day Change: " <> float_to_string(s.week_change) <> " kg"),
        ui.text("30-Day Change: " <> float_to_string(s.month_change) <> " kg"),
        ui.br(),
      ],
      bmi_row,
      [
        ui.text("Goal Progress: " <> float_to_string(s.goal_progress) <> "%"),
        ui.br(),
        ui.hr(),
        ui.text_styled("[Esc] Back", Some(style.Cyan), None),
      ],
    ]),
  )
}

/// Render chart view
fn view_chart(model: WeightModel) -> shore.Node(WeightMsg) {
  let chart_lines = chart.render_chart(model.chart_data, 40, 10)
  let chart_rows = list.map(chart_lines, fn(line) { ui.text(line) })

  ui.col(
    list.flatten([
      [
        ui.br(),
        ui.align(
          style.Center,
          ui.text_styled("📈 Weight Chart", Some(style.Green), None),
        ),
        ui.hr_styled(style.Green),
        ui.br(),
        ui.text("Last 30 days:"),
        ui.br(),
      ],
      chart_rows,
      [
        ui.br(),
        ui.hr(),
        ui.text_styled("[Esc] Back", Some(style.Cyan), None),
      ],
    ]),
  )
}

/// Render profile view
fn view_profile(model: WeightModel) -> shore.Node(WeightMsg) {
  let p = model.user_profile

  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("👤 Profile Settings", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.text(
      "Height: "
      <> case p.height_cm {
        Some(h) -> float_to_string(h) <> " cm"
        None -> "Not set"
      },
    ),
    ui.text(
      "Gender: "
      <> case p.gender {
        Some(Male) -> "Male"
        Some(Female) -> "Female"
        Some(Other) -> "Other"
        None -> "Not set"
      },
    ),
    ui.br(),
    ui.text("(Height is used for BMI calculation)"),
    ui.br(),
    ui.hr(),
    ui.text_styled("[Esc] Back", Some(style.Cyan), None),
  ])
}

/// Render date picker
fn view_date_picker(
  model: WeightModel,
  date_input: String,
) -> shore.Node(WeightMsg) {
  ui.col([
    ui.br(),
    ui.align(
      style.Center,
      ui.text_styled("📅 Select Date", Some(style.Green), None),
    ),
    ui.hr_styled(style.Green),
    ui.br(),
    ui.input("Date (YYYY-MM-DD):", date_input, style.Pct(50), fn(d) {
      DateConfirm(d)
    }),
    ui.br(),
    ui.text_styled(
      "Current: " <> date_int_to_string(model.current_date),
      Some(style.Cyan),
      None,
    ),
    ui.hr(),
    ui.text_styled("[Enter] Confirm  [Esc] Cancel", Some(style.Cyan), None),
  ])
}
