import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/ui/components/food_search

pub fn main() {
  gleeunit.main()
}

pub fn filter_type_to_string_all_test() {
  let chip = food_search.FilterChip("All", food_search.All, True)
  chip.filter_type
  |> food_search.update_selected_filter([chip], _)
  |> list.length
  |> should.equal(1)
}

pub fn default_filter_chips_has_four_chips_test() {
  food_search.default_filter_chips()
  |> list.length
  |> should.equal(4)
}

pub fn default_filter_chips_all_selected_test() {
  food_search.default_filter_chips()
  |> list.find(fn(chip) { chip.selected })
  |> should.be_ok
}

pub fn default_categories_has_items_test() {
  let categories = food_search.default_categories()
  should.be_true(list.length(categories) > 0)
}

pub fn update_selected_filter_changes_selection_test() {
  let chips = food_search.default_filter_chips()
  let updated = food_search.update_selected_filter(chips, food_search.Branded)

  // Find Branded chip and verify it's selected
  list.find(updated, fn(chip) { chip.filter_type == food_search.Branded })
  |> should.be_ok
}

pub fn render_filter_chip_htmx_attributes_test() {
  // Test that filter chip has correct HTMX attributes
  let chip = food_search.FilterChip("All", food_search.All, True)
  let rendered = food_search.render_filter_chip(chip)
  let html = element.to_string(rendered)

  // Verify HTMX attributes are present
  should.be_true(string.contains(
    html,
    "hx-get=\"/api/foods/search?filter=all\"",
  ))
  should.be_true(string.contains(html, "hx-target=\"#search-results\""))
  should.be_true(string.contains(html, "hx-swap=\"innerHTML\""))
  should.be_true(string.contains(html, "hx-push-url=\"true\""))
  should.be_true(string.contains(html, "hx-include=\"[name='q']\""))
}

pub fn render_filter_chip_verified_htmx_test() {
  // Test Verified Only chip has correct filter parameter
  let chip =
    food_search.FilterChip("Verified Only", food_search.VerifiedOnly, False)
  let rendered = food_search.render_filter_chip(chip)
  let html = element.to_string(rendered)

  should.be_true(string.contains(
    html,
    "hx-get=\"/api/foods/search?filter=verified\"",
  ))
  should.be_true(string.contains(html, "data-filter=\"verified\""))
}

pub fn render_filter_chip_branded_htmx_test() {
  // Test Branded chip has correct filter parameter
  let chip = food_search.FilterChip("Branded", food_search.Branded, False)
  let rendered = food_search.render_filter_chip(chip)
  let html = element.to_string(rendered)

  should.be_true(string.contains(
    html,
    "hx-get=\"/api/foods/search?filter=branded\"",
  ))
  should.be_true(string.contains(html, "data-filter=\"branded\""))
}

pub fn render_filter_chip_category_htmx_test() {
  // Test By Category chip has correct filter parameter
  let chip =
    food_search.FilterChip("By Category", food_search.ByCategory, False)
  let rendered = food_search.render_filter_chip(chip)
  let html = element.to_string(rendered)

  should.be_true(string.contains(
    html,
    "hx-get=\"/api/foods/search?filter=category\"",
  ))
  should.be_true(string.contains(html, "data-filter=\"category\""))
}

pub fn render_filter_chip_selected_class_test() {
  // Test selected chip has correct CSS class
  let chip = food_search.FilterChip("All", food_search.All, True)
  let rendered = food_search.render_filter_chip(chip)
  let html = element.to_string(rendered)

  should.be_true(string.contains(html, "filter-chip-selected"))
  should.be_true(string.contains(html, "aria-selected=\"true\""))
}

pub fn render_filter_chip_unselected_class_test() {
  // Test unselected chip doesn't have selected class
  let chip = food_search.FilterChip("Branded", food_search.Branded, False)
  let rendered = food_search.render_filter_chip(chip)
  let html = element.to_string(rendered)

  should.be_false(string.contains(html, "filter-chip-selected"))
  should.be_true(string.contains(html, "aria-selected=\"false\""))
}

pub fn render_category_dropdown_htmx_test() {
  // Test category dropdown has correct HTMX attributes
  let chips = food_search.default_filter_chips()
  let categories = ["Vegetables", "Fruits"]
  let rendered =
    food_search.render_filter_chips_with_dropdown(chips, categories)
  let html = element.to_string(rendered)

  // Dropdown should have HTMX attributes
  should.be_true(string.contains(html, "hx-get=\"/api/foods/search\""))
  should.be_true(string.contains(html, "hx-trigger=\"change\""))
  should.be_true(string.contains(html, "hx-target=\"#search-results\""))
  should.be_true(string.contains(html, "hx-swap=\"innerHTML\""))
  should.be_true(string.contains(html, "hx-push-url=\"true\""))
  should.be_true(string.contains(
    html,
    "hx-include=\"[name='q'], [name='filter']\"",
  ))

  // Should have hidden filter input
  should.be_true(string.contains(html, "name=\"filter\""))
  should.be_true(string.contains(html, "value=\"category\""))
}
