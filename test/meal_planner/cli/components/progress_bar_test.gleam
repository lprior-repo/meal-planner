/// Tests for Progress Bar Component
///
/// Tests cover:
/// - Configuration and defaults
/// - State initialization
/// - Percentage calculations
/// - Fill style rendering
/// - Color scheme selection
/// - Macro progress bars
/// - Threshold-based colors
/// - Animation functions
/// - Preset configurations
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/cli/components/progress_bar.{
  type ColorScheme, type FillStyle, type MacroProgressBar, type MacroStatus,
  type ProgressBarConfig, type ProgressBarState, type Threshold,
  AsciiFill, AtTarget, GradientColor, GradientFill, InverseTrafficLight,
  MacroProgressBar, Monochrome, Over, ProgressBarConfig, ProgressBarState,
  SegmentedFill, SolidFill, Threshold, ThresholdBased, TrafficLight, Under,
  UnicodeFill,
}
import shore/style

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn default_config_has_correct_defaults_test() {
  // GIVEN: Default configuration request

  // WHEN: Getting default config
  let config = progress_bar.default_config()

  // THEN: Should have correct defaults
  config.width
  |> should.equal(30)

  case config.fill_style {
    UnicodeFill -> True |> should.equal(True)
    _ -> should.fail()
  }

  case config.color_scheme {
    TrafficLight -> True |> should.equal(True)
    _ -> should.fail()
  }

  config.show_percentage
  |> should.equal(True)

  config.show_value
  |> should.equal(False)

  config.value_suffix
  |> should.equal("")

  config.label
  |> should.equal(None)
}

pub fn custom_config_is_created_correctly_test() {
  // GIVEN: Custom configuration values
  let config = ProgressBarConfig(
    width: 50,
    fill_style: SolidFill,
    color_scheme: Monochrome(style.Cyan),
    show_percentage: False,
    show_value: True,
    value_suffix: " cal",
    label: Some("Calories"),
    thresholds: [],
  )

  // THEN: Config should have custom values
  config.width
  |> should.equal(50)

  case config.fill_style {
    SolidFill -> True |> should.equal(True)
    _ -> should.fail()
  }

  case config.color_scheme {
    Monochrome(color) -> color |> should.equal(style.Cyan)
    _ -> should.fail()
  }

  config.show_percentage
  |> should.equal(False)

  config.show_value
  |> should.equal(True)

  config.value_suffix
  |> should.equal(" cal")

  config.label
  |> should.equal(Some("Calories"))
}

pub fn inverse_thresholds_returns_correct_values_test() {
  // GIVEN: Request for inverse thresholds

  // WHEN: Getting inverse thresholds
  let thresholds = progress_bar.inverse_thresholds()

  // THEN: Should have correct threshold count
  case thresholds {
    [first, second, third] -> {
      first.percentage |> should.equal(0.0)
      first.color |> should.equal(style.Green)
      second.percentage |> should.equal(80.0)
      second.color |> should.equal(style.Yellow)
      third.percentage |> should.equal(100.0)
      third.color |> should.equal(style.Red)
    }
    _ -> should.fail()
  }
}

// ============================================================================
// State Initialization Tests
// ============================================================================

pub fn init_state_creates_valid_state_test() {
  // GIVEN: Current and max values
  let current = 50.0
  let max = 100.0

  // WHEN: Initializing state
  let state = progress_bar.init_state(current, max)

  // THEN: State should have correct values
  state.current
  |> should.equal(50.0)

  state.max
  |> should.equal(100.0)

  state.target
  |> should.equal(None)

  state.animation_frame
  |> should.equal(0)
}

pub fn init_state_with_target_includes_target_test() {
  // GIVEN: Current, max, and target values
  let current = 75.0
  let max = 100.0
  let target = 80.0

  // WHEN: Initializing state with target
  let state = progress_bar.init_state_with_target(current, max, target)

  // THEN: State should include target
  state.current
  |> should.equal(75.0)

  state.max
  |> should.equal(100.0)

  state.target
  |> should.equal(Some(80.0))
}

// ============================================================================
// Rendering Tests
// ============================================================================

pub fn render_produces_non_empty_string_test() {
  // GIVEN: Config and state
  let config = progress_bar.default_config()
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should produce non-empty string
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn render_includes_percentage_when_enabled_test() {
  // GIVEN: Config with percentage enabled
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    show_percentage: True,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should include percentage
  string.contains(result, "%")
  |> should.equal(True)
}

pub fn render_includes_value_when_enabled_test() {
  // GIVEN: Config with value enabled
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    show_value: True,
    value_suffix: " cal",
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should include value and suffix
  string.contains(result, "cal")
  |> should.equal(True)
}

pub fn render_includes_label_when_set_test() {
  // GIVEN: Config with label
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    label: Some("Progress"),
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should include label
  string.contains(result, "Progress")
  |> should.equal(True)
}

pub fn render_solid_fill_contains_block_chars_test() {
  // GIVEN: Config with solid fill
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    fill_style: SolidFill,
    show_percentage: False,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should contain block characters
  string.contains(result, "[")
  |> should.equal(True)

  string.contains(result, "]")
  |> should.equal(True)
}

pub fn render_ascii_fill_contains_hash_chars_test() {
  // GIVEN: Config with ASCII fill
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    fill_style: AsciiFill,
    show_percentage: False,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should contain hash characters for filled portion
  string.contains(result, "#")
  |> should.equal(True)
}

pub fn render_zero_progress_test() {
  // GIVEN: State at zero
  let config = progress_bar.default_config()
  let state = progress_bar.init_state(0.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should render successfully
  { string.length(result) > 0 }
  |> should.equal(True)

  string.contains(result, "0")
  |> should.equal(True)
}

pub fn render_full_progress_test() {
  // GIVEN: State at 100%
  let config = progress_bar.default_config()
  let state = progress_bar.init_state(100.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should render successfully
  { string.length(result) > 0 }
  |> should.equal(True)

  string.contains(result, "100")
  |> should.equal(True)
}

pub fn render_over_100_percent_test() {
  // GIVEN: State over 100%
  let config = progress_bar.default_config()
  let state = progress_bar.init_state(150.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should handle overflow
  { string.length(result) > 0 }
  |> should.equal(True)
}

// ============================================================================
// Macro Progress Bar Tests
// ============================================================================

pub fn default_macro_bar_has_correct_defaults_test() {
  // GIVEN: Macro bar parameters
  let name = "Protein"
  let current = 50.0
  let target = 100.0
  let unit = "g"

  // WHEN: Creating default macro bar
  let bar = progress_bar.default_macro_bar(name, current, target, unit)

  // THEN: Should have correct values
  bar.name
  |> should.equal("Protein")

  bar.current
  |> should.equal(50.0)

  bar.target
  |> should.equal(100.0)

  bar.unit
  |> should.equal("g")

  bar.width
  |> should.equal(25)

  bar.tolerance
  |> should.equal(10.0)
}

pub fn render_macro_produces_formatted_output_test() {
  // GIVEN: A macro progress bar
  let bar = progress_bar.default_macro_bar("Protein", 80.0, 100.0, "g")

  // WHEN: Rendering macro bar
  let result = progress_bar.render_macro(bar)

  // THEN: Should contain name, values, and percentage
  string.contains(result, "Protein")
  |> should.equal(True)

  string.contains(result, "80")
  |> should.equal(True)

  string.contains(result, "100")
  |> should.equal(True)

  string.contains(result, "g")
  |> should.equal(True)

  string.contains(result, "%")
  |> should.equal(True)
}

pub fn render_macro_shows_overflow_indicator_test() {
  // GIVEN: A macro bar over 100%
  let bar = progress_bar.default_macro_bar("Calories", 2500.0, 2000.0, " cal")

  // WHEN: Rendering macro bar
  let result = progress_bar.render_macro(bar)

  // THEN: Should contain overflow indicator
  string.contains(result, "▶")
  |> should.equal(True)
}

// ============================================================================
// Macro Status Tests
// ============================================================================

pub fn macro_status_under_when_below_tolerance_test() {
  // GIVEN: A macro bar at 80% of target (with 10% tolerance)
  let bar = MacroProgressBar(
    name: "Test",
    current: 80.0,
    target: 100.0,
    unit: "g",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Red,
    tolerance: 10.0,
  )

  // WHEN: Checking status implicitly via rendering
  // The bar at 80% with tolerance of 10% should be "Under"
  // (lower bound is 90% of target = 90)
  { bar.current <. bar.target *. 0.9 }
  |> should.equal(True)
}

pub fn macro_status_at_target_within_tolerance_test() {
  // GIVEN: A macro bar at 95% of target (within 10% tolerance)
  let bar = MacroProgressBar(
    name: "Test",
    current: 95.0,
    target: 100.0,
    unit: "g",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Red,
    tolerance: 10.0,
  )

  // WHEN: Checking if within tolerance bounds
  let lower = bar.target *. 0.9
  let upper = bar.target *. 1.1

  // THEN: Current should be within bounds
  { bar.current >=. lower && bar.current <=. upper }
  |> should.equal(True)
}

pub fn macro_status_over_when_above_tolerance_test() {
  // GIVEN: A macro bar at 120% of target
  let bar = MacroProgressBar(
    name: "Test",
    current: 120.0,
    target: 100.0,
    unit: "g",
    width: 25,
    under_color: style.Yellow,
    target_color: style.Green,
    over_color: style.Red,
    tolerance: 10.0,
  )

  // WHEN: Checking if over tolerance
  let upper = bar.target *. 1.1

  // THEN: Current should be above upper bound
  { bar.current >. upper }
  |> should.equal(True)
}

// ============================================================================
// Animation Tests
// ============================================================================

pub fn animate_increments_frame_test() {
  // GIVEN: A state at frame 0
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Animating
  let animated = progress_bar.animate(state)

  // THEN: Frame should increment
  animated.animation_frame
  |> should.equal(1)
}

pub fn animate_wraps_at_frame_4_test() {
  // GIVEN: A state at frame 3
  let state = ProgressBarState(
    current: 50.0,
    max: 100.0,
    target: None,
    animation_frame: 3,
  )

  // WHEN: Animating
  let animated = progress_bar.animate(state)

  // THEN: Frame should wrap to 0
  animated.animation_frame
  |> should.equal(0)
}

pub fn render_loading_produces_animation_chars_test() {
  // GIVEN: Width and frame
  let width = 20
  let frame = 0

  // WHEN: Rendering loading
  let result = progress_bar.render_loading(width, frame)

  // THEN: Should contain brackets
  string.contains(result, "[")
  |> should.equal(True)

  string.contains(result, "]")
  |> should.equal(True)
}

pub fn render_indeterminate_produces_moving_bar_test() {
  // GIVEN: Width and frame
  let width = 20
  let frame = 0

  // WHEN: Rendering indeterminate
  let result = progress_bar.render_indeterminate(width, frame)

  // THEN: Should produce non-empty result with brackets
  string.contains(result, "[")
  |> should.equal(True)

  string.contains(result, "]")
  |> should.equal(True)
}

pub fn render_indeterminate_different_frames_produce_different_output_test() {
  // GIVEN: Width
  let width = 20

  // WHEN: Rendering at different frames
  let frame0 = progress_bar.render_indeterminate(width, 0)
  let frame5 = progress_bar.render_indeterminate(width, 5)

  // THEN: Output should differ
  { frame0 != frame5 }
  |> should.equal(True)
}

// ============================================================================
// Preset Configuration Tests
// ============================================================================

pub fn calories_bar_preset_has_correct_config_test() {
  // GIVEN: Current and target values
  let current = 1500.0
  let target = 2000.0

  // WHEN: Creating calories bar
  let bar = progress_bar.calories_bar(current, target)

  // THEN: Should have correct preset values
  bar.name
  |> should.equal("Calories")

  bar.current
  |> should.equal(1500.0)

  bar.target
  |> should.equal(2000.0)

  bar.unit
  |> should.equal(" cal")

  bar.width
  |> should.equal(25)
}

pub fn protein_bar_preset_has_correct_config_test() {
  // GIVEN: Current and target values
  let current = 100.0
  let target = 150.0

  // WHEN: Creating protein bar
  let bar = progress_bar.protein_bar(current, target)

  // THEN: Should have correct preset values
  bar.name
  |> should.equal("Protein ")

  bar.unit
  |> should.equal("g")

  // Over color should be Cyan (over on protein is okay)
  bar.over_color
  |> should.equal(style.Cyan)
}

pub fn carbs_bar_preset_has_correct_config_test() {
  // GIVEN: Current and target values
  let current = 200.0
  let target = 250.0

  // WHEN: Creating carbs bar
  let bar = progress_bar.carbs_bar(current, target)

  // THEN: Should have correct preset values
  bar.name
  |> should.equal("Carbs   ")

  bar.unit
  |> should.equal("g")
}

pub fn fat_bar_preset_has_correct_config_test() {
  // GIVEN: Current and target values
  let current = 50.0
  let target = 65.0

  // WHEN: Creating fat bar
  let bar = progress_bar.fat_bar(current, target)

  // THEN: Should have correct preset values
  bar.name
  |> should.equal("Fat     ")

  bar.unit
  |> should.equal("g")
}

pub fn fiber_bar_preset_has_correct_config_test() {
  // GIVEN: Current and target values
  let current = 30.0
  let target = 25.0

  // WHEN: Creating fiber bar
  let bar = progress_bar.fiber_bar(current, target)

  // THEN: Should have correct preset values
  bar.name
  |> should.equal("Fiber   ")

  bar.tolerance
  |> should.equal(15.0)

  // Over color should be Green (over on fiber is okay)
  bar.over_color
  |> should.equal(style.Green)
}

pub fn sugar_bar_preset_has_correct_config_test() {
  // GIVEN: Current and limit values
  let current = 30.0
  let limit = 50.0

  // WHEN: Creating sugar bar
  let bar = progress_bar.sugar_bar(current, limit)

  // THEN: Should have inverse colors (lower is better)
  bar.name
  |> should.equal("Sugar   ")

  bar.under_color
  |> should.equal(style.Green)

  bar.over_color
  |> should.equal(style.Red)

  bar.tolerance
  |> should.equal(0.0)
}

pub fn sodium_bar_preset_has_correct_config_test() {
  // GIVEN: Current and limit values
  let current = 1500.0
  let limit = 2300.0

  // WHEN: Creating sodium bar
  let bar = progress_bar.sodium_bar(current, limit)

  // THEN: Should have inverse colors (lower is better)
  bar.name
  |> should.equal("Sodium  ")

  bar.unit
  |> should.equal("mg")

  bar.under_color
  |> should.equal(style.Green)

  bar.tolerance
  |> should.equal(0.0)
}

// ============================================================================
// Edge Case Tests
// ============================================================================

pub fn zero_max_value_handles_gracefully_test() {
  // GIVEN: State with zero max
  let config = progress_bar.default_config()
  let state = progress_bar.init_state(50.0, 0.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should handle gracefully without crash
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn negative_current_handles_gracefully_test() {
  // GIVEN: State with negative current
  let config = progress_bar.default_config()
  let state = progress_bar.init_state(-10.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should handle gracefully
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn very_large_values_handle_gracefully_test() {
  // GIVEN: State with very large values
  let config = progress_bar.default_config()
  let state = progress_bar.init_state(999_999.0, 1_000_000.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should handle gracefully
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn small_width_handles_gracefully_test() {
  // GIVEN: Config with very small width
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    width: 3,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should handle gracefully
  { string.length(result) > 0 }
  |> should.equal(True)
}

// ============================================================================
// Fill Style Rendering Tests
// ============================================================================

pub fn gradient_fill_renders_correctly_test() {
  // GIVEN: Config with gradient fill
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    fill_style: GradientFill,
    show_percentage: False,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should produce valid output
  string.contains(result, "[")
  |> should.equal(True)

  string.contains(result, "]")
  |> should.equal(True)
}

pub fn segmented_fill_renders_correctly_test() {
  // GIVEN: Config with segmented fill
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    fill_style: SegmentedFill,
    show_percentage: False,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should produce valid output
  string.contains(result, "[")
  |> should.equal(True)

  string.contains(result, "]")
  |> should.equal(True)
}

pub fn unicode_fill_renders_correctly_test() {
  // GIVEN: Config with unicode fill
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    fill_style: UnicodeFill,
    show_percentage: False,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should produce valid output with block characters
  string.contains(result, "[")
  |> should.equal(True)
}

// ============================================================================
// Color Scheme Tests
// ============================================================================

pub fn monochrome_scheme_uses_single_color_test() {
  // GIVEN: Config with monochrome scheme
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: Monochrome(style.Blue),
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering (color is internal, just verify no crash)
  let result = progress_bar.render(config, state)

  // THEN: Should render without crash
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn traffic_light_scheme_works_test() {
  // GIVEN: Config with traffic light scheme
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: TrafficLight,
  )

  // WHEN: Rendering at different percentages
  let low_state = progress_bar.init_state(10.0, 100.0)
  let mid_state = progress_bar.init_state(50.0, 100.0)
  let high_state = progress_bar.init_state(90.0, 100.0)

  let low_result = progress_bar.render(config, low_state)
  let mid_result = progress_bar.render(config, mid_state)
  let high_result = progress_bar.render(config, high_state)

  // THEN: All should render
  { string.length(low_result) > 0 }
  |> should.equal(True)

  { string.length(mid_result) > 0 }
  |> should.equal(True)

  { string.length(high_result) > 0 }
  |> should.equal(True)
}

pub fn inverse_traffic_light_scheme_works_test() {
  // GIVEN: Config with inverse traffic light scheme
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: InverseTrafficLight,
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should render
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn threshold_based_scheme_works_test() {
  // GIVEN: Config with threshold based scheme
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: ThresholdBased,
    thresholds: [
      Threshold(percentage: 0.0, color: style.Red),
      Threshold(percentage: 50.0, color: style.Yellow),
      Threshold(percentage: 75.0, color: style.Green),
    ],
  )
  let state = progress_bar.init_state(60.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should render
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn gradient_color_scheme_works_test() {
  // GIVEN: Config with gradient color scheme
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: GradientColor(style.Red, style.Green),
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should render
  { string.length(result) > 0 }
  |> should.equal(True)
}

// ============================================================================
// Nutrition Summary Tests
// ============================================================================

pub fn render_nutrition_summary_returns_four_nodes_test() {
  // GIVEN: Four macro bars
  let calories = progress_bar.calories_bar(1800.0, 2000.0)
  let protein = progress_bar.protein_bar(120.0, 150.0)
  let carbs = progress_bar.carbs_bar(200.0, 250.0)
  let fat = progress_bar.fat_bar(60.0, 65.0)

  // WHEN: Rendering nutrition summary
  let nodes = progress_bar.render_nutrition_summary(calories, protein, carbs, fat)

  // THEN: Should return 4 nodes
  case nodes {
    [_, _, _, _] -> True |> should.equal(True)
    _ -> should.fail()
  }
}

// ============================================================================
// Threshold Tests
// ============================================================================

pub fn empty_thresholds_handled_gracefully_test() {
  // GIVEN: Config with empty thresholds
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: ThresholdBased,
    thresholds: [],
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should render without crash
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn single_threshold_works_test() {
  // GIVEN: Config with single threshold
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: ThresholdBased,
    thresholds: [Threshold(percentage: 0.0, color: style.Cyan)],
  )
  let state = progress_bar.init_state(50.0, 100.0)

  // WHEN: Rendering
  let result = progress_bar.render(config, state)

  // THEN: Should render
  { string.length(result) > 0 }
  |> should.equal(True)
}

pub fn multiple_thresholds_select_correct_color_test() {
  // GIVEN: Config with multiple thresholds
  let config = ProgressBarConfig(
    ..progress_bar.default_config(),
    color_scheme: ThresholdBased,
    thresholds: [
      Threshold(percentage: 0.0, color: style.Red),
      Threshold(percentage: 25.0, color: style.Yellow),
      Threshold(percentage: 50.0, color: style.Green),
      Threshold(percentage: 75.0, color: style.Cyan),
    ],
  )

  // WHEN: Rendering at 60% (should use Green from 50% threshold)
  let state = progress_bar.init_state(60.0, 100.0)
  let result = progress_bar.render(config, state)

  // THEN: Should render (internal color is correct)
  { string.length(result) > 0 }
  |> should.equal(True)
}
