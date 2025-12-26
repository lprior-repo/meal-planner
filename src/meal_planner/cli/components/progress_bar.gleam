/// Progress Bar Component - Reusable TUI Progress Indicator
///
/// This module provides reusable progress bar components for Shore TUI
/// following Elm Architecture patterns.
///
/// FEATURES:
/// - Multiple progress bar styles (solid, gradient, segmented)
/// - Percentage and value display
/// - Color coding based on value ranges
/// - Animation support
/// - Macro progress bars for nutrition tracking
/// - Custom labels and suffixes
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shore
import shore/style
import shore/ui

// ============================================================================
// Types
// ============================================================================

/// Progress bar configuration
pub type ProgressBarConfig {
  ProgressBarConfig(
    /// Width in characters
    width: Int,
    /// Fill style
    fill_style: FillStyle,
    /// Color scheme
    color_scheme: ColorScheme,
    /// Show percentage
    show_percentage: Bool,
    /// Show value
    show_value: Bool,
    /// Value suffix (e.g., "cal", "g", "%")
    value_suffix: String,
    /// Label (appears before bar)
    label: Option(String),
    /// Thresholds for color changes
    thresholds: List(Threshold),
  )
}

/// Fill style for progress bar
pub type FillStyle {
  /// Solid block fill
  SolidFill
  /// Gradient fill using different characters
  GradientFill
  /// Segmented bars
  SegmentedFill
  /// ASCII style
  AsciiFill
  /// Unicode block elements
  UnicodeFill
}

/// Color scheme for progress bar
pub type ColorScheme {
  /// Single color
  Monochrome(color: style.Color)
  /// Color based on thresholds
  ThresholdBased
  /// Gradient from start to end color
  GradientColor(start: style.Color, end: style.Color)
  /// Traffic light (red/yellow/green)
  TrafficLight
  /// Inverse traffic light (green/yellow/red)
  InverseTrafficLight
}

/// Threshold for color changes
pub type Threshold {
  Threshold(
    /// Percentage at which this threshold triggers
    percentage: Float,
    /// Color for this range
    color: style.Color,
  )
}

/// Progress bar state
pub type ProgressBarState {
  ProgressBarState(
    /// Current value
    current: Float,
    /// Maximum value (for percentage calculation)
    max: Float,
    /// Optional target value (shows target indicator)
    target: Option(Float),
    /// Animation frame (0-3)
    animation_frame: Int,
  )
}

/// Macro progress bar (for nutrition tracking)
pub type MacroProgressBar {
  MacroProgressBar(
    /// Macro name
    name: String,
    /// Current value
    current: Float,
    /// Target value
    target: Float,
    /// Unit (g, cal, mg)
    unit: String,
    /// Bar width
    width: Int,
    /// Color when under target
    under_color: style.Color,
    /// Color when at target
    target_color: style.Color,
    /// Color when over target
    over_color: style.Color,
    /// Tolerance percentage for "at target"
    tolerance: Float,
  )
}

// ============================================================================
// Default Configurations
// ============================================================================

/// Default progress bar config
pub fn default_config() -> ProgressBarConfig {
  ProgressBarConfig(
    width: 30,
    fill_style: UnicodeFill,
    color_scheme: TrafficLight,
    show_percentage: True,
    show_value: False,
    value_suffix: "",
    label: None,
    thresholds: default_thresholds(),
  )
}

/// Default thresholds (traffic light)
fn default_thresholds() -> List(Threshold) {
  [
    Threshold(percentage: 0.0, color: style.Red),
    Threshold(percentage: 33.0, color: style.Yellow),
    Threshold(percentage: 66.0, color: style.Green),
  ]
}

/// Inverse thresholds (good at low, bad at high)
pub fn inverse_thresholds() -> List(Threshold) {
  [
    Threshold(percentage: 0.0, color: style.Green),
    Threshold(percentage: 80.0, color: style.Yellow),
    Threshold(percentage: 100.0, color: style.Red),
  ]
}

/// Default macro progress bar
pub fn default_macro_bar(
  name: String,
  current: Float,
  target: Float,
  unit: String,
) -> MacroProgressBar {
  MacroProgressBar(
    name: name,
    current: current,
    target: target,
    unit: unit,
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Red,
    tolerance: 10.0,
  )
}

// ============================================================================
// Initialization
// ============================================================================

/// Create progress bar state
pub fn init_state(current: Float, max: Float) -> ProgressBarState {
  ProgressBarState(current: current, max: max, target: None, animation_frame: 0)
}

/// Create progress bar state with target
pub fn init_state_with_target(
  current: Float,
  max: Float,
  target: Float,
) -> ProgressBarState {
  ProgressBarState(
    current: current,
    max: max,
    target: Some(target),
    animation_frame: 0,
  )
}

// ============================================================================
// Rendering Functions
// ============================================================================

/// Render a progress bar as a string
pub fn render(config: ProgressBarConfig, state: ProgressBarState) -> String {
  let percentage = calculate_percentage(state.current, state.max)
  let filled_width =
    float.truncate(percentage /. 100.0 *. int.to_float(config.width))
  let empty_width = config.width - filled_width

  // Get color based on scheme
  let _color = get_color(config.color_scheme, percentage, config.thresholds)

  // Build bar content
  let bar_content = case config.fill_style {
    SolidFill -> render_solid(filled_width, empty_width)
    GradientFill -> render_gradient(filled_width, empty_width)
    SegmentedFill -> render_segmented(filled_width, empty_width, config.width)
    AsciiFill -> render_ascii(filled_width, empty_width)
    UnicodeFill -> render_unicode(filled_width, empty_width)
  }

  // Build full line
  let label_part = case config.label {
    Some(l) -> l <> ": "
    None -> ""
  }

  let value_part = case config.show_value {
    True -> " " <> float_to_string(state.current) <> config.value_suffix
    False -> ""
  }

  let pct_part = case config.show_percentage {
    True -> " " <> float_to_string(percentage) <> "%"
    False -> ""
  }

  label_part <> bar_content <> value_part <> pct_part
}

/// Render as Shore node
pub fn render_node(
  config: ProgressBarConfig,
  state: ProgressBarState,
) -> shore.Node(msg) {
  let percentage = calculate_percentage(state.current, state.max)
  let color = get_color(config.color_scheme, percentage, config.thresholds)
  let text = render(config, state)

  ui.text_styled(text, Some(color), None)
}

/// Render macro progress bar
pub fn render_macro(bar: MacroProgressBar) -> String {
  let percentage = calculate_percentage(bar.current, bar.target)
  let filled_width =
    float.truncate(percentage /. 100.0 *. int.to_float(bar.width))
  let clamped_width = int.clamp(filled_width, 0, bar.width)
  let empty_width = bar.width - clamped_width

  // Determine color based on status
  let status = get_macro_status(bar.current, bar.target, bar.tolerance)
  let _color = case status {
    Under -> bar.under_color
    AtTarget -> bar.target_color
    Over -> bar.over_color
  }

  // Build bar
  let filled = string.repeat("█", clamped_width)
  let empty = string.repeat("░", empty_width)

  // Build overflow indicator if over 100%
  let overflow = case percentage >. 100.0 {
    True -> "▶"
    False -> ""
  }

  let bar_str = "[" <> filled <> empty <> "]" <> overflow

  // Build info
  let current_str = float_to_string(bar.current)
  let target_str = float_to_string(bar.target)
  let pct_str = float_to_string(percentage)

  bar.name
  <> ": "
  <> bar_str
  <> " "
  <> current_str
  <> "/"
  <> target_str
  <> bar.unit
  <> " ("
  <> pct_str
  <> "%)"
}

/// Render macro progress bar as Shore node
pub fn render_macro_node(bar: MacroProgressBar) -> shore.Node(msg) {
  let _percentage = calculate_percentage(bar.current, bar.target)
  let status = get_macro_status(bar.current, bar.target, bar.tolerance)
  let color = case status {
    Under -> bar.under_color
    AtTarget -> bar.target_color
    Over -> bar.over_color
  }
  let text = render_macro(bar)

  ui.text_styled(text, Some(color), None)
}

/// Render multiple macro bars as a nutrition summary
pub fn render_nutrition_summary(
  calories: MacroProgressBar,
  protein: MacroProgressBar,
  carbs: MacroProgressBar,
  fat: MacroProgressBar,
) -> List(shore.Node(msg)) {
  [
    render_macro_node(calories),
    render_macro_node(protein),
    render_macro_node(carbs),
    render_macro_node(fat),
  ]
}

// ============================================================================
// Fill Style Renderers
// ============================================================================

/// Render solid fill
fn render_solid(filled: Int, empty: Int) -> String {
  let filled_str = string.repeat("█", int.max(0, filled))
  let empty_str = string.repeat(" ", int.max(0, empty))
  "[" <> filled_str <> empty_str <> "]"
}

/// Render gradient fill
fn render_gradient(filled: Int, empty: Int) -> String {
  let filled_str = case filled {
    0 -> ""
    n -> {
      let full_blocks = n - 1
      let gradient_block = "▓"
      string.repeat("█", int.max(0, full_blocks)) <> gradient_block
    }
  }
  let empty_str = string.repeat("░", int.max(0, empty))
  "[" <> filled_str <> empty_str <> "]"
}

/// Render segmented fill
fn render_segmented(filled: Int, _empty: Int, total: Int) -> String {
  let segment_count = 10
  let segment_width = total / segment_count
  let filled_segments = filled / int.max(1, segment_width)

  list.range(0, segment_count - 1)
  |> list.map(fn(i) {
    case i < filled_segments {
      True -> "█"
      False -> "░"
    }
  })
  |> string.join("")
  |> fn(s) { "[" <> s <> "]" }
}

/// Render ASCII fill
fn render_ascii(filled: Int, empty: Int) -> String {
  let filled_str = string.repeat("#", int.max(0, filled))
  let empty_str = string.repeat("-", int.max(0, empty))
  "[" <> filled_str <> empty_str <> "]"
}

/// Render Unicode fill with sub-character precision
fn render_unicode(filled: Int, empty: Int) -> String {
  let filled_str = string.repeat("█", int.max(0, filled))
  let empty_str = string.repeat("░", int.max(0, empty))
  "[" <> filled_str <> empty_str <> "]"
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate percentage
fn calculate_percentage(current: Float, max: Float) -> Float {
  case max >. 0.0 {
    True -> current /. max *. 100.0
    False -> 0.0
  }
}

/// Get color based on color scheme and percentage
fn get_color(
  scheme: ColorScheme,
  percentage: Float,
  thresholds: List(Threshold),
) -> style.Color {
  case scheme {
    Monochrome(color) -> color
    ThresholdBased -> get_threshold_color(percentage, thresholds)
    GradientColor(start, _end) -> start
    // Simplified - just use start color
    TrafficLight -> get_traffic_light_color(percentage)
    InverseTrafficLight -> get_inverse_traffic_light_color(percentage)
  }
}

/// Get color from thresholds
fn get_threshold_color(
  percentage: Float,
  thresholds: List(Threshold),
) -> style.Color {
  let sorted =
    list.sort(thresholds, fn(a, b) { float.compare(b.percentage, a.percentage) })

  list.find(sorted, fn(t) { percentage >=. t.percentage })
  |> result.map(fn(t) { t.color })
  |> result.unwrap(style.White)
}

/// Traffic light colors
fn get_traffic_light_color(percentage: Float) -> style.Color {
  case percentage <. 33.0, percentage <. 66.0 {
    True, _ -> style.Red
    False, True -> style.Yellow
    False, False -> style.Green
  }
}

/// Inverse traffic light colors
fn get_inverse_traffic_light_color(percentage: Float) -> style.Color {
  case percentage <. 80.0, percentage <. 100.0 {
    True, _ -> style.Green
    False, True -> style.Yellow
    False, False -> style.Red
  }
}

/// Macro status type
pub type MacroStatus {
  Under
  AtTarget
  Over
}

/// Get macro status
fn get_macro_status(
  current: Float,
  target: Float,
  tolerance: Float,
) -> MacroStatus {
  let lower = target *. { 1.0 -. tolerance /. 100.0 }
  let upper = target *. { 1.0 +. tolerance /. 100.0 }

  case current <. lower, current >. upper {
    True, _ -> Under
    _, True -> Over
    False, False -> AtTarget
  }
}

/// Format float to string
fn float_to_string(value: Float) -> String {
  let rounded = float.truncate(value *. 10.0) |> int.to_float
  float.to_string(rounded /. 10.0)
}

// ============================================================================
// Animation Functions
// ============================================================================

/// Animate the progress bar (for loading states)
pub fn animate(state: ProgressBarState) -> ProgressBarState {
  let next_frame = { state.animation_frame + 1 } % 4
  ProgressBarState(..state, animation_frame: next_frame)
}

/// Render loading animation
pub fn render_loading(width: Int, frame: Int) -> String {
  let animation_chars = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]
  let index = frame % 10
  let char =
    animation_chars
    |> list.drop(index)
    |> list.first
    |> result.unwrap("⠋")

  let dots = string.repeat("·", width - 2)
  "[" <> char <> dots <> "]"
}

/// Render indeterminate progress bar
pub fn render_indeterminate(width: Int, frame: Int) -> String {
  let bar_width = 5
  let pos = frame % { width - bar_width }

  let before = string.repeat("░", pos)
  let bar = string.repeat("█", bar_width)
  let after = string.repeat("░", width - pos - bar_width)

  "[" <> before <> bar <> after <> "]"
}

// ============================================================================
// Preset Configurations
// ============================================================================

/// Calorie progress bar preset
pub fn calories_bar(current: Float, target: Float) -> MacroProgressBar {
  MacroProgressBar(
    name: "Calories",
    current: current,
    target: target,
    unit: " cal",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Red,
    tolerance: 10.0,
  )
}

/// Protein progress bar preset
pub fn protein_bar(current: Float, target: Float) -> MacroProgressBar {
  MacroProgressBar(
    name: "Protein ",
    current: current,
    target: target,
    unit: "g",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Cyan,
    // Over on protein is okay
    tolerance: 10.0,
  )
}

/// Carbs progress bar preset
pub fn carbs_bar(current: Float, target: Float) -> MacroProgressBar {
  MacroProgressBar(
    name: "Carbs   ",
    current: current,
    target: target,
    unit: "g",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Red,
    tolerance: 10.0,
  )
}

/// Fat progress bar preset
pub fn fat_bar(current: Float, target: Float) -> MacroProgressBar {
  MacroProgressBar(
    name: "Fat     ",
    current: current,
    target: target,
    unit: "g",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Red,
    tolerance: 10.0,
  )
}

/// Fiber progress bar preset
pub fn fiber_bar(current: Float, target: Float) -> MacroProgressBar {
  MacroProgressBar(
    name: "Fiber   ",
    current: current,
    target: target,
    unit: "g",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Green,
    // Over on fiber is okay
    tolerance: 15.0,
  )
}

/// Sugar progress bar preset (inverse - lower is better)
pub fn sugar_bar(current: Float, limit: Float) -> MacroProgressBar {
  MacroProgressBar(
    name: "Sugar   ",
    current: current,
    target: limit,
    unit: "g",
    width: 25,
    under_color: style.Green,
    target_color: style.Yellow,
    over_color: style.Red,
    tolerance: 0.0,
    // No tolerance for sugar limit
  )
}

/// Sodium progress bar preset (inverse - lower is better)
pub fn sodium_bar(current: Float, limit: Float) -> MacroProgressBar {
  MacroProgressBar(
    name: "Sodium  ",
    current: current,
    target: limit,
    unit: "mg",
    width: 25,
    under_color: style.Green,
    target_color: style.Yellow,
    over_color: style.Red,
    tolerance: 0.0,
  )
}

// ============================================================================
// Result Helpers
// ============================================================================

import gleam/result
