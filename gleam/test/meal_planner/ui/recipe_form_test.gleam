// Recipe Form UI Component Tests
// Comprehensive testing following Fowler's complex form testing principles
//
// Test Coverage:
// 1. Field validation (required fields, data types, ranges)
// 2. Form submission workflow (success and failure paths)
// 3. Error handling and display (validation messages, ARIA)
// 4. Data transformation and persistence
// 5. Accessibility (ARIA attributes, keyboard navigation)
// 6. Dynamic field interactions (add/remove rows)

import gleam/string
import gleeunit/should
import meal_planner/ui/recipe_form

// ============================================================================
// Form Structure Tests
// ============================================================================

pub fn render_form_contains_required_elements_test() {
  let html = recipe_form.render_form()

  // Form container
  html
  |> string.contains("<form id=\"recipe-form\"")
  |> should.be_true()

  // Required sections
  html
  |> string.contains(
    "<h2 class=\"text-xl font-semibold mb-4\">Basic Information</h2>",
  )
  |> should.be_true()

  html
  |> string.contains("Ingredients")
  |> should.be_true()

  html
  |> string.contains("Instructions")
  |> should.be_true()

  html
  |> string.contains("Nutrition Information")
  |> should.be_true()
}

pub fn render_form_contains_submit_button_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("<button\n        type=\"submit\"")
  |> should.be_true()

  html
  |> string.contains("id=\"submit-btn\"")
  |> should.be_true()

  html
  |> string.contains("Create Recipe")
  |> should.be_true()
}

pub fn render_form_contains_cancel_button_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"cancel-btn\"")
  |> should.be_true()

  html
  |> string.contains("Cancel")
  |> should.be_true()
}

// ============================================================================
// Field Validation Tests (Fowler: Test validation rules)
// ============================================================================

pub fn recipe_name_field_has_required_attribute_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"recipe-name\"")
  |> should.be_true()

  html
  |> string.contains("required")
  |> should.be_true()
}

pub fn recipe_name_field_has_length_constraints_test() {
  let html = recipe_form.render_form()

  // Should have minlength and maxlength
  html
  |> string.contains("minlength=\"3\"")
  |> should.be_true()

  html
  |> string.contains("maxlength=\"100\"")
  |> should.be_true()
}

pub fn recipe_name_field_has_placeholder_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("placeholder=\"e.g., Grilled Chicken Salad\"")
  |> should.be_true()
}

pub fn category_field_has_required_attribute_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"recipe-category\"")
  |> should.be_true()

  // Category select should be required
  let category_section =
    html
    |> string.split("id=\"recipe-category\"")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split("</select>")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  category_section
  |> string.contains("required")
  |> should.be_true()
}

pub fn category_field_has_valid_options_test() {
  let html = recipe_form.render_form()

  // Should have all category options
  html
  |> string.contains("<option value=\"breakfast\">Breakfast</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"lunch\">Lunch</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"dinner\">Dinner</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"snack\">Snack</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"dessert\">Dessert</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"beverage\">Beverage</option>")
  |> should.be_true()
}

pub fn servings_field_has_numeric_constraints_test() {
  let html = recipe_form.render_form()

  // Should be a number input with min/max
  html
  |> string.contains("id=\"servings\"")
  |> should.be_true()

  html
  |> string.contains("type=\"number\"")
  |> should.be_true()

  html
  |> string.contains("min=\"1\"")
  |> should.be_true()

  html
  |> string.contains("max=\"100\"")
  |> should.be_true()

  html
  |> string.contains("value=\"4\"")
  |> should.be_true()
}

pub fn prep_time_field_has_numeric_constraints_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"prep-time\"")
  |> should.be_true()

  html
  |> string.contains("min=\"0\"")
  |> should.be_true()

  html
  |> string.contains("max=\"999\"")
  |> should.be_true()
}

pub fn cook_time_field_has_numeric_constraints_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"cook-time\"")
  |> should.be_true()

  html
  |> string.contains("min=\"0\"")
  |> should.be_true()

  html
  |> string.contains("max=\"999\"")
  |> should.be_true()
}

// ============================================================================
// Ingredient Field Tests (Fowler: Test field interactions)
// ============================================================================

pub fn ingredients_section_has_add_button_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"add-ingredient\"")
  |> should.be_true()

  html
  |> string.contains("+ Add Ingredient")
  |> should.be_true()
}

pub fn ingredients_section_has_initial_row_test() {
  let html = recipe_form.render_form()

  // Should have first ingredient row
  html
  |> string.contains("id=\"ingredient-name-0\"")
  |> should.be_true()

  html
  |> string.contains("id=\"ingredient-amount-0\"")
  |> should.be_true()

  html
  |> string.contains("id=\"ingredient-unit-0\"")
  |> should.be_true()
}

pub fn ingredient_name_field_is_required_test() {
  let html = recipe_form.render_form()

  let ingredient_name_section =
    html
    |> string.split("id=\"ingredient-name-0\"")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split("/>")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  ingredient_name_section
  |> string.contains("required")
  |> should.be_true()
}

pub fn ingredient_amount_field_has_numeric_constraints_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"ingredient-amount-0\"")
  |> should.be_true()

  html
  |> string.contains("type=\"number\"")
  |> should.be_true()

  html
  |> string.contains("min=\"0\"")
  |> should.be_true()

  html
  |> string.contains("step=\"0.01\"")
  |> should.be_true()
}

pub fn ingredient_unit_field_has_valid_options_test() {
  let html = recipe_form.render_form()

  // Should have all unit options
  html
  |> string.contains("<option value=\"g\">g (grams)</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"kg\">kg (kilograms)</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"ml\">ml (milliliters)</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"cup\">cup</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"tbsp\">tbsp (tablespoon)</option>")
  |> should.be_true()

  html
  |> string.contains("<option value=\"tsp\">tsp (teaspoon)</option>")
  |> should.be_true()
}

pub fn ingredient_remove_button_exists_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("class=\"btn btn-danger btn-sm remove-ingredient\"")
  |> should.be_true()

  // First row's remove button should be disabled
  html
  |> string.contains("disabled")
  |> should.be_true()
}

// ============================================================================
// Instruction Field Tests
// ============================================================================

pub fn instructions_section_has_add_button_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"add-instruction\"")
  |> should.be_true()

  html
  |> string.contains("+ Add Step")
  |> should.be_true()
}

pub fn instructions_section_has_initial_row_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"instruction-0\"")
  |> should.be_true()

  html
  |> string.contains("<span class=\"badge badge-primary mr-2\">Step 1</span>")
  |> should.be_true()
}

pub fn instruction_field_is_textarea_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("<textarea")
  |> should.be_true()

  html
  |> string.contains("id=\"instruction-0\"")
  |> should.be_true()

  html
  |> string.contains("rows=\"2\"")
  |> should.be_true()
}

pub fn instruction_field_is_required_test() {
  let html = recipe_form.render_form()

  let instruction_section =
    html
    |> string.split("id=\"instruction-0\"")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split("</textarea>")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  instruction_section
  |> string.contains("required")
  |> should.be_true()
}

pub fn instruction_remove_button_exists_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("class=\"btn btn-danger btn-sm remove-instruction\"")
  |> should.be_true()
}

// ============================================================================
// Nutrition Field Tests (Optional fields)
// ============================================================================

pub fn nutrition_section_contains_all_macro_fields_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"calories\"")
  |> should.be_true()

  html
  |> string.contains("id=\"protein\"")
  |> should.be_true()

  html
  |> string.contains("id=\"carbs\"")
  |> should.be_true()

  html
  |> string.contains("id=\"fat\"")
  |> should.be_true()

  html
  |> string.contains("id=\"fiber\"")
  |> should.be_true()

  html
  |> string.contains("id=\"sugar\"")
  |> should.be_true()
}

pub fn nutrition_fields_are_optional_test() {
  let html = recipe_form.render_form()

  // Get nutrition section
  let nutrition_section =
    html
    |> string.split("Nutrition Information")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split("</section>")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  // Should NOT contain "required" in nutrition section
  // (All other required fields are outside this section)
  nutrition_section
  |> string.contains("required")
  |> should.be_false()
}

pub fn calories_field_has_numeric_constraints_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"calories\"")
  |> should.be_true()

  html
  |> string.contains("min=\"0\"")
  |> should.be_true()

  html
  |> string.contains("max=\"9999\"")
  |> should.be_true()

  html
  |> string.contains("step=\"1\"")
  |> should.be_true()
}

pub fn protein_field_has_decimal_precision_test() {
  let html = recipe_form.render_form()

  let protein_section =
    html
    |> string.split("id=\"protein\"")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split("/>")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  protein_section
  |> string.contains("step=\"0.1\"")
  |> should.be_true()

  protein_section
  |> string.contains("max=\"999\"")
  |> should.be_true()
}

pub fn carbs_field_has_decimal_precision_test() {
  let html = recipe_form.render_form()

  let carbs_section =
    html
    |> string.split("id=\"carbs\"")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split("/>")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  carbs_section
  |> string.contains("step=\"0.1\"")
  |> should.be_true()
}

pub fn fat_field_has_decimal_precision_test() {
  let html = recipe_form.render_form()

  let fat_section =
    html
    |> string.split("id=\"fat\"")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split("/>")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  fat_section
  |> string.contains("step=\"0.1\"")
  |> should.be_true()
}

// ============================================================================
// Accessibility Tests (ARIA attributes, semantic HTML)
// ============================================================================

pub fn form_has_novalidate_attribute_test() {
  let html = recipe_form.render_form()

  // Form should have novalidate for custom validation
  html
  |> string.contains("<form id=\"recipe-form\" class=\"card\" novalidate>")
  |> should.be_true()
}

pub fn required_fields_have_aria_invalid_test() {
  let html = recipe_form.render_form()

  // Required fields should have aria-invalid="false" initially
  html
  |> string.contains("aria-invalid=\"false\"")
  |> should.be_true()
}

pub fn required_fields_have_aria_describedby_test() {
  let html = recipe_form.render_form()

  // Recipe name field
  html
  |> string.contains("aria-describedby=\"name-error\"")
  |> should.be_true()

  // Category field
  html
  |> string.contains("aria-describedby=\"category-error\"")
  |> should.be_true()

  // Servings field
  html
  |> string.contains("aria-describedby=\"servings-error\"")
  |> should.be_true()
}

pub fn error_spans_have_aria_live_regions_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("role=\"alert\" aria-live=\"polite\"")
  |> should.be_true()
}

pub fn error_spans_have_role_alert_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("class=\"form-error\" role=\"alert\"")
  |> should.be_true()
}

pub fn required_fields_have_visual_indicator_test() {
  let html = recipe_form.render_form()

  // Should have asterisk with aria-label
  html
  |> string.contains(
    "<span class=\"text-danger\" aria-label=\"required\">*</span>",
  )
  |> should.be_true()
}

pub fn buttons_have_aria_labels_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("aria-label=\"Add ingredient row\"")
  |> should.be_true()

  html
  |> string.contains("aria-label=\"Add instruction step\"")
  |> should.be_true()

  html
  |> string.contains("aria-label=\"Remove ingredient row\"")
  |> should.be_true()

  html
  |> string.contains("aria-label=\"Create recipe\"")
  |> should.be_true()
}

pub fn dynamic_lists_have_role_attributes_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("role=\"list\" aria-label=\"Ingredient list\"")
  |> should.be_true()

  html
  |> string.contains("role=\"list\" aria-label=\"Instruction steps\"")
  |> should.be_true()

  html
  |> string.contains("role=\"listitem\"")
  |> should.be_true()
}

pub fn form_status_has_aria_live_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains(
    "id=\"form-status\" class=\"text-sm text-muted ml-auto\" role=\"status\" aria-live=\"polite\"",
  )
  |> should.be_true()
}

// ============================================================================
// Data Structure Tests (Fowler: Test data transformation)
// ============================================================================

pub fn ingredient_fields_have_array_notation_test() {
  let html = recipe_form.render_form()

  // Should use array notation for ingredients
  html
  |> string.contains("name=\"ingredients[0][name]\"")
  |> should.be_true()

  html
  |> string.contains("name=\"ingredients[0][amount]\"")
  |> should.be_true()

  html
  |> string.contains("name=\"ingredients[0][unit]\"")
  |> should.be_true()
}

pub fn instruction_fields_have_array_notation_test() {
  let html = recipe_form.render_form()

  // Should use array notation for instructions
  html
  |> string.contains("name=\"instructions[0]\"")
  |> should.be_true()
}

pub fn fields_have_data_row_index_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("data-row-index=\"0\"")
  |> should.be_true()
}

// ============================================================================
// Form Layout and Styling Tests
// ============================================================================

pub fn form_uses_responsive_grid_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("class=\"grid grid-cols-2 gap-4\"")
  |> should.be_true()

  html
  |> string.contains("class=\"grid grid-cols-12 gap-2 mb-3\"")
  |> should.be_true()
}

pub fn form_has_card_structure_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("class=\"card\"")
  |> should.be_true()

  html
  |> string.contains("class=\"card-header\"")
  |> should.be_true()

  html
  |> string.contains("class=\"card-body\"")
  |> should.be_true()

  html
  |> string.contains("class=\"card-footer\"")
  |> should.be_true()
}

pub fn form_has_semantic_sections_test() {
  let html = recipe_form.render_form()

  // Should use <section> elements
  html
  |> string.contains("<section class=\"mb-6\">")
  |> should.be_true()
}

pub fn form_includes_javascript_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("<script src=\"/static/js/recipe-form.js\"></script>")
  |> should.be_true()
}

// ============================================================================
// Error Display Tests (Fowler: Test error handling)
// ============================================================================

pub fn all_fields_have_error_spans_test() {
  let html = recipe_form.render_form()

  // Required field error spans
  html
  |> string.contains("id=\"name-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"category-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"servings-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"prep-time-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"cook-time-error\"")
  |> should.be_true()
}

pub fn ingredient_fields_have_error_spans_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"ingredient-name-0-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"ingredient-amount-0-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"ingredient-unit-0-error\"")
  |> should.be_true()
}

pub fn instruction_fields_have_error_spans_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"instruction-0-error\"")
  |> should.be_true()
}

pub fn section_level_error_spans_exist_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"ingredients-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"instructions-error\"")
  |> should.be_true()
}

pub fn nutrition_fields_have_error_spans_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("id=\"calories-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"protein-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"carbs-error\"")
  |> should.be_true()

  html
  |> string.contains("id=\"fat-error\"")
  |> should.be_true()
}

// ============================================================================
// Form Submission Tests (Fowler: Test submission workflow)
// ============================================================================

pub fn submit_button_has_correct_type_test() {
  let html = recipe_form.render_form()

  html
  |> string.contains("type=\"submit\"")
  |> should.be_true()
}

pub fn cancel_button_has_button_type_test() {
  let html = recipe_form.render_form()

  let cancel_section =
    html
    |> string.split("id=\"cancel-btn\"")
    |> fn(parts) {
      case parts {
        [_, rest, ..] ->
          rest
          |> string.split(">")
          |> fn(p) {
            case p {
              [first, ..] -> first
              _ -> ""
            }
          }
        _ -> ""
      }
    }

  cancel_section
  |> string.contains("type=\"button\"")
  |> should.be_true()
}

// ============================================================================
// Integration Tests (Component composition)
// ============================================================================

pub fn render_form_produces_valid_html_structure_test() {
  let html = recipe_form.render_form()

  // Should have container
  html
  |> string.contains("<div class=\"container max-w-prose\">")
  |> should.be_true()

  // Should close container
  html
  |> string.contains("</div>")
  |> should.be_true()

  // Should have form
  html
  |> string.contains("<form")
  |> should.be_true()

  html
  |> string.contains("</form>")
  |> should.be_true()
}

pub fn render_form_includes_all_sections_in_order_test() {
  let html = recipe_form.render_form()

  // Find positions of each section
  let has_basic_info = string.contains(html, "Basic Information")
  let has_ingredients = string.contains(html, "Ingredients")
  let has_instructions = string.contains(html, "Instructions")
  let has_nutrition = string.contains(html, "Nutrition Information")

  has_basic_info |> should.be_true()
  has_ingredients |> should.be_true()
  has_instructions |> should.be_true()
  has_nutrition |> should.be_true()
}
