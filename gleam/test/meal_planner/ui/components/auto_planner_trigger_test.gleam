/// UI Component Tests for Auto Planner Trigger Component
///
/// Test coverage for auto planner trigger components includes:
/// - Trigger button with HTMX attributes
/// - User input forms (goals, activity level, restrictions)
/// - Loading states and indicators
/// - Error and success message display
/// - Complete form rendering
/// - HTML structure validation
/// - Edge cases and robustness
///
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/types.{Active, Gain, Lose, Maintain, Moderate, Sedentary}
import meal_planner/ui/components/auto_planner_trigger

pub fn main() {
  gleeunit.main()
}

// Helper function to convert elements to strings
fn element_to_string(elem: element.Element(msg)) -> String {
  element.to_string(elem)
}

// ===================================================================
// TRIGGER BUTTON TESTS
// ===================================================================

pub fn trigger_button_has_htmx_post_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("hx-post=\"/api/auto-plan\"")
  |> should.be_true
}

pub fn trigger_button_has_htmx_target_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("hx-target=\"#auto-plan-result\"")
  |> should.be_true
}

pub fn trigger_button_has_htmx_swap_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("hx-swap=\"innerHTML\"")
  |> should.be_true
}

pub fn trigger_button_has_htmx_include_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("hx-include=\"#auto-planner-form\"")
  |> should.be_true
}

pub fn trigger_button_has_htmx_indicator_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("hx-indicator=\"#auto-plan-loading\"")
  |> should.be_true
}

pub fn trigger_button_has_primary_class_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("btn-primary")
  |> should.be_true
}

pub fn trigger_button_has_large_size_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("btn-lg")
  |> should.be_true
}

pub fn trigger_button_loading_state_adds_class_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Loading)
  |> element_to_string
  |> string.contains("btn-loading")
  |> should.be_true
}

pub fn trigger_button_loading_state_is_disabled_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Loading)
  |> element_to_string
  |> string.contains("disabled")
  |> should.be_true
}

pub fn trigger_button_idle_state_not_disabled_test() {
  let result =
    auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
    |> element_to_string

  result
  |> string.contains("disabled")
  |> should.be_false
}

pub fn trigger_button_has_aria_label_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("aria-label=\"Generate meal plan\"")
  |> should.be_true
}

pub fn trigger_button_has_correct_text_test() {
  auto_planner_trigger.render_trigger_button(auto_planner_trigger.Idle)
  |> element_to_string
  |> string.contains("Generate Meal Plan")
  |> should.be_true
}

// ===================================================================
// GOAL SELECTION TESTS
// ===================================================================

pub fn goal_selection_has_form_group_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("form-group")
  |> should.be_true
}

pub fn goal_selection_has_label_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("Fitness Goal")
  |> should.be_true
}

pub fn goal_selection_has_radio_group_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("radio-group")
  |> should.be_true
}

pub fn goal_selection_has_radio_role_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("role=\"radiogroup\"")
  |> should.be_true
}

pub fn goal_selection_has_gain_option_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("Gain Muscle")
  |> should.be_true
}

pub fn goal_selection_has_maintain_option_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("Maintain Weight")
  |> should.be_true
}

pub fn goal_selection_has_lose_option_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("Lose Weight")
  |> should.be_true
}

pub fn goal_selection_gain_value_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("value=\"gain\"")
  |> should.be_true
}

pub fn goal_selection_maintain_value_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("value=\"maintain\"")
  |> should.be_true
}

pub fn goal_selection_lose_value_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("value=\"lose\"")
  |> should.be_true
}

pub fn goal_selection_selected_gain_is_checked_test() {
  auto_planner_trigger.render_goal_selection(Some(Gain))
  |> element_to_string
  |> string.contains("value=\"gain\" checked")
  |> should.be_true
}

pub fn goal_selection_selected_maintain_is_checked_test() {
  auto_planner_trigger.render_goal_selection(Some(Maintain))
  |> element_to_string
  |> string.contains("value=\"maintain\" checked")
  |> should.be_true
}

pub fn goal_selection_selected_lose_is_checked_test() {
  auto_planner_trigger.render_goal_selection(Some(Lose))
  |> element_to_string
  |> string.contains("value=\"lose\" checked")
  |> should.be_true
}

pub fn goal_selection_has_name_attribute_test() {
  auto_planner_trigger.render_goal_selection(None)
  |> element_to_string
  |> string.contains("name=\"goal\"")
  |> should.be_true
}

// ===================================================================
// ACTIVITY LEVEL SELECTION TESTS
// ===================================================================

pub fn activity_level_has_form_group_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("form-group")
  |> should.be_true
}

pub fn activity_level_has_label_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("Activity Level")
  |> should.be_true
}

pub fn activity_level_has_sedentary_option_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("Sedentary")
  |> should.be_true
}

pub fn activity_level_has_moderate_option_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("Moderate")
  |> should.be_true
}

pub fn activity_level_has_active_option_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("Active")
  |> should.be_true
}

pub fn activity_level_sedentary_value_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("value=\"sedentary\"")
  |> should.be_true
}

pub fn activity_level_moderate_value_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("value=\"moderate\"")
  |> should.be_true
}

pub fn activity_level_active_value_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("value=\"active\"")
  |> should.be_true
}

pub fn activity_level_selected_sedentary_is_checked_test() {
  auto_planner_trigger.render_activity_level_selection(Some(Sedentary))
  |> element_to_string
  |> string.contains("value=\"sedentary\" checked")
  |> should.be_true
}

pub fn activity_level_selected_moderate_is_checked_test() {
  auto_planner_trigger.render_activity_level_selection(Some(Moderate))
  |> element_to_string
  |> string.contains("value=\"moderate\" checked")
  |> should.be_true
}

pub fn activity_level_selected_active_is_checked_test() {
  auto_planner_trigger.render_activity_level_selection(Some(Active))
  |> element_to_string
  |> string.contains("value=\"active\" checked")
  |> should.be_true
}

pub fn activity_level_has_name_attribute_test() {
  auto_planner_trigger.render_activity_level_selection(None)
  |> element_to_string
  |> string.contains("name=\"activity_level\"")
  |> should.be_true
}

// ===================================================================
// DIETARY RESTRICTIONS TESTS
// ===================================================================

pub fn dietary_restrictions_has_form_group_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("form-group")
  |> should.be_true
}

pub fn dietary_restrictions_has_label_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("Dietary Restrictions")
  |> should.be_true
}

pub fn dietary_restrictions_has_vegetarian_option_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("Vegetarian")
  |> should.be_true
}

pub fn dietary_restrictions_has_vegan_option_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("Vegan")
  |> should.be_true
}

pub fn dietary_restrictions_has_gluten_free_option_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("Gluten-Free")
  |> should.be_true
}

pub fn dietary_restrictions_has_dairy_free_option_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("Dairy-Free")
  |> should.be_true
}

pub fn dietary_restrictions_has_low_fodmap_option_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("Low FODMAP")
  |> should.be_true
}

pub fn dietary_restrictions_has_keto_option_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("Ketogenic")
  |> should.be_true
}

pub fn dietary_restrictions_vegetarian_value_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("value=\"vegetarian\"")
  |> should.be_true
}

pub fn dietary_restrictions_selected_vegetarian_is_checked_test() {
  auto_planner_trigger.render_dietary_restrictions(["vegetarian"])
  |> element_to_string
  |> string.contains("value=\"vegetarian\" checked")
  |> should.be_true
}

pub fn dietary_restrictions_multiple_selections_test() {
  let result =
    auto_planner_trigger.render_dietary_restrictions([
      "vegetarian",
      "gluten-free",
    ])
    |> element_to_string

  result |> string.contains("value=\"vegetarian\" checked") |> should.be_true
  result |> string.contains("value=\"gluten-free\" checked") |> should.be_true
}

pub fn dietary_restrictions_has_checkbox_type_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("type=\"checkbox\"")
  |> should.be_true
}

pub fn dietary_restrictions_has_name_attribute_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("name=\"restrictions\"")
  |> should.be_true
}

// ===================================================================
// MEALS PER DAY TESTS
// ===================================================================

pub fn meals_per_day_has_form_group_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("form-group")
  |> should.be_true
}

pub fn meals_per_day_has_label_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("Meals Per Day")
  |> should.be_true
}

pub fn meals_per_day_has_number_type_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("type=\"number\"")
  |> should.be_true
}

pub fn meals_per_day_has_correct_value_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("value=\"3\"")
  |> should.be_true
}

pub fn meals_per_day_has_min_attribute_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("min=\"1\"")
  |> should.be_true
}

pub fn meals_per_day_has_max_attribute_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("max=\"6\"")
  |> should.be_true
}

pub fn meals_per_day_has_step_attribute_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("step=\"1\"")
  |> should.be_true
}

pub fn meals_per_day_has_name_attribute_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("name=\"meals_per_day\"")
  |> should.be_true
}

pub fn meals_per_day_has_id_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("id=\"meals-per-day\"")
  |> should.be_true
}

pub fn meals_per_day_label_has_for_attribute_test() {
  auto_planner_trigger.render_meals_per_day(3)
  |> element_to_string
  |> string.contains("for=\"meals-per-day\"")
  |> should.be_true
}

// ===================================================================
// LOADING INDICATOR TESTS
// ===================================================================

pub fn loading_indicator_has_id_test() {
  auto_planner_trigger.render_loading_indicator()
  |> element_to_string
  |> string.contains("id=\"auto-plan-loading\"")
  |> should.be_true
}

pub fn loading_indicator_has_htmx_indicator_class_test() {
  auto_planner_trigger.render_loading_indicator()
  |> element_to_string
  |> string.contains("htmx-indicator")
  |> should.be_true
}

pub fn loading_indicator_has_status_role_test() {
  auto_planner_trigger.render_loading_indicator()
  |> element_to_string
  |> string.contains("role=\"status\"")
  |> should.be_true
}

pub fn loading_indicator_has_aria_live_test() {
  auto_planner_trigger.render_loading_indicator()
  |> element_to_string
  |> string.contains("aria-live=\"polite\"")
  |> should.be_true
}

pub fn loading_indicator_has_loading_text_test() {
  auto_planner_trigger.render_loading_indicator()
  |> element_to_string
  |> string.contains("Generating your personalized meal plan")
  |> should.be_true
}

pub fn loading_indicator_has_spinner_test() {
  auto_planner_trigger.render_loading_indicator()
  |> element_to_string
  |> string.contains("loading-spinner")
  |> should.be_true
}

// ===================================================================
// ERROR MESSAGE TESTS
// ===================================================================

pub fn error_message_has_error_class_test() {
  auto_planner_trigger.render_error("Test error")
  |> element_to_string
  |> string.contains("error-message")
  |> should.be_true
}

pub fn error_message_has_alert_role_test() {
  auto_planner_trigger.render_error("Test error")
  |> element_to_string
  |> string.contains("role=\"alert\"")
  |> should.be_true
}

pub fn error_message_has_aria_live_assertive_test() {
  auto_planner_trigger.render_error("Test error")
  |> element_to_string
  |> string.contains("aria-live=\"assertive\"")
  |> should.be_true
}

pub fn error_message_displays_text_test() {
  auto_planner_trigger.render_error("Something went wrong")
  |> element_to_string
  |> string.contains("Something went wrong")
  |> should.be_true
}

pub fn error_message_has_icon_test() {
  auto_planner_trigger.render_error("Error")
  |> element_to_string
  |> string.contains("⚠")
  |> should.be_true
}

pub fn error_message_handles_special_characters_test() {
  auto_planner_trigger.render_error("Error: <script>alert('xss')</script>")
  |> element_to_string
  |> string.contains("<script>")
  |> should.be_true
}

// ===================================================================
// SUCCESS MESSAGE TESTS
// ===================================================================

pub fn success_message_has_success_class_test() {
  auto_planner_trigger.render_success("Success!")
  |> element_to_string
  |> string.contains("success-message")
  |> should.be_true
}

pub fn success_message_has_status_role_test() {
  auto_planner_trigger.render_success("Success!")
  |> element_to_string
  |> string.contains("role=\"status\"")
  |> should.be_true
}

pub fn success_message_has_aria_live_polite_test() {
  auto_planner_trigger.render_success("Success!")
  |> element_to_string
  |> string.contains("aria-live=\"polite\"")
  |> should.be_true
}

pub fn success_message_displays_text_test() {
  auto_planner_trigger.render_success("Plan created successfully")
  |> element_to_string
  |> string.contains("Plan created successfully")
  |> should.be_true
}

pub fn success_message_has_checkmark_icon_test() {
  auto_planner_trigger.render_success("Success")
  |> element_to_string
  |> string.contains("✓")
  |> should.be_true
}

// ===================================================================
// COMPLETE FORM TESTS
// ===================================================================

pub fn complete_form_has_form_id_test() {
  let config = auto_planner_trigger.default_config()
  auto_planner_trigger.render_auto_planner_form(
    config,
    auto_planner_trigger.Idle,
  )
  |> element_to_string
  |> string.contains("id=\"auto-planner-form\"")
  |> should.be_true
}

pub fn complete_form_has_container_test() {
  let config = auto_planner_trigger.default_config()
  auto_planner_trigger.render_auto_planner_form(
    config,
    auto_planner_trigger.Idle,
  )
  |> element_to_string
  |> string.contains("auto-planner-container")
  |> should.be_true
}

pub fn complete_form_has_result_container_test() {
  let config = auto_planner_trigger.default_config()
  auto_planner_trigger.render_auto_planner_form(
    config,
    auto_planner_trigger.Idle,
  )
  |> element_to_string
  |> string.contains("id=\"auto-plan-result\"")
  |> should.be_true
}

pub fn complete_form_has_title_test() {
  let config = auto_planner_trigger.default_config()
  auto_planner_trigger.render_auto_planner_form(
    config,
    auto_planner_trigger.Idle,
  )
  |> element_to_string
  |> string.contains("Auto Meal Planner")
  |> should.be_true
}

pub fn complete_form_has_description_test() {
  let config = auto_planner_trigger.default_config()
  auto_planner_trigger.render_auto_planner_form(
    config,
    auto_planner_trigger.Idle,
  )
  |> element_to_string
  |> string.contains("personalized meal plan")
  |> should.be_true
}

pub fn complete_form_includes_all_components_test() {
  let config = auto_planner_trigger.default_config()
  let result =
    auto_planner_trigger.render_auto_planner_form(
      config,
      auto_planner_trigger.Idle,
    )
    |> element_to_string

  // Check all major components are present
  result |> string.contains("Fitness Goal") |> should.be_true
  result |> string.contains("Activity Level") |> should.be_true
  result |> string.contains("Dietary Restrictions") |> should.be_true
  result |> string.contains("Meals Per Day") |> should.be_true
  result |> string.contains("Generate Meal Plan") |> should.be_true
}

// ===================================================================
// COMPACT TRIGGER TESTS
// ===================================================================

pub fn compact_trigger_has_htmx_get_test() {
  auto_planner_trigger.render_compact_trigger()
  |> element_to_string
  |> string.contains("hx-get=\"/auto-plan/form\"")
  |> should.be_true
}

pub fn compact_trigger_has_htmx_target_test() {
  auto_planner_trigger.render_compact_trigger()
  |> element_to_string
  |> string.contains("hx-target=\"#modal-container\"")
  |> should.be_true
}

pub fn compact_trigger_has_button_type_test() {
  auto_planner_trigger.render_compact_trigger()
  |> element_to_string
  |> string.contains("type=\"button\"")
  |> should.be_true
}

pub fn compact_trigger_has_small_size_test() {
  auto_planner_trigger.render_compact_trigger()
  |> element_to_string
  |> string.contains("btn-sm")
  |> should.be_true
}

pub fn compact_trigger_has_emoji_test() {
  auto_planner_trigger.render_compact_trigger()
  |> element_to_string
  |> string.contains("🤖")
  |> should.be_true
}

// ===================================================================
// DEFAULT CONFIG TESTS
// ===================================================================

pub fn default_config_has_maintain_goal_test() {
  let config = auto_planner_trigger.default_config()
  config.goal |> should.equal(Some(Maintain))
}

pub fn default_config_has_moderate_activity_test() {
  let config = auto_planner_trigger.default_config()
  config.activity_level |> should.equal(Some(Moderate))
}

pub fn default_config_has_three_meals_test() {
  let config = auto_planner_trigger.default_config()
  config.meals_per_day |> should.equal(3)
}

pub fn default_config_has_empty_restrictions_test() {
  let config = auto_planner_trigger.default_config()
  config.dietary_restrictions |> should.equal([])
}

pub fn empty_config_has_no_goal_test() {
  let config = auto_planner_trigger.empty_config()
  config.goal |> should.equal(None)
}

pub fn empty_config_has_no_activity_level_test() {
  let config = auto_planner_trigger.empty_config()
  config.activity_level |> should.equal(None)
}

// ===================================================================
// EDGE CASES AND ROBUSTNESS TESTS
// ===================================================================

pub fn form_handles_zero_meals_test() {
  auto_planner_trigger.render_meals_per_day(0)
  |> element_to_string
  |> string.contains("value=\"0\"")
  |> should.be_true
}

pub fn form_handles_large_meals_count_test() {
  auto_planner_trigger.render_meals_per_day(10)
  |> element_to_string
  |> string.contains("value=\"10\"")
  |> should.be_true
}

pub fn error_message_handles_empty_string_test() {
  auto_planner_trigger.render_error("")
  |> element_to_string
  |> string.contains("error-message")
  |> should.be_true
}

pub fn success_message_handles_empty_string_test() {
  auto_planner_trigger.render_success("")
  |> element_to_string
  |> string.contains("success-message")
  |> should.be_true
}

pub fn dietary_restrictions_handles_empty_list_test() {
  auto_planner_trigger.render_dietary_restrictions([])
  |> element_to_string
  |> string.contains("checkbox-group")
  |> should.be_true
}

pub fn dietary_restrictions_handles_unknown_values_test() {
  auto_planner_trigger.render_dietary_restrictions(["unknown", "invalid"])
  |> element_to_string
  |> string.contains("checkbox-group")
  |> should.be_true
}
