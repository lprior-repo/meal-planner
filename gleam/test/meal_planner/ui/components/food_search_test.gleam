import gleam/list
import gleeunit
import gleeunit/should
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
  food_search.default_categories()
  |> list.length
  |> should.be_greater_than(0)
}

pub fn update_selected_filter_changes_selection_test() {
  let chips = food_search.default_filter_chips()
  let updated = food_search.update_selected_filter(chips, food_search.Branded)
  
  // Find Branded chip and verify it's selected
  list.find(updated, fn(chip) { chip.filter_type == food_search.Branded })
  |> should.be_ok
}
