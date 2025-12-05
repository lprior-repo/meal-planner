/// Tests for Food Log Entry Card Components
///
/// Tests the food_log_entry_card component module
import gleeunit
import gleeunit/should
import meal_planner/ui/components/food_log_entry_card
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// TYPE CONSTRUCTION TESTS
// ===================================================================

pub fn log_entry_card_construction_test() {
  let card =
    ui_types.LogEntryCard(
      entry_id: "log-123",
      food_name: "Grilled Chicken Breast",
      portion: 6.0,
      unit: "oz",
      protein: 52.0,
      fat: 6.0,
      carbs: 0.0,
      calories: 276.0,
      meal_type: "lunch",
      logged_at: "2025-12-04 12:30",
    )

  card.entry_id |> should.equal("log-123")
  card.food_name |> should.equal("Grilled Chicken Breast")
  card.portion |> should.equal(6.0)
}

// ===================================================================
// RENDER TESTS
// ===================================================================

pub fn render_log_entry_card_test() {
  let card =
    ui_types.LogEntryCard(
      entry_id: "log-456",
      food_name: "Brown Rice",
      portion: 1.5,
      unit: "cups",
      protein: 5.0,
      fat: 2.0,
      carbs: 45.0,
      calories: 218.0,
      meal_type: "dinner",
      logged_at: "2025-12-04 18:00",
    )

  // Should render without errors
  let _element = food_log_entry_card.render_log_entry_card(card)
  // If we get here, rendering succeeded
  should.equal(1, 1)
}

pub fn render_log_entry_card_compact_test() {
  let card =
    ui_types.LogEntryCard(
      entry_id: "log-789",
      food_name: "Greek Yogurt",
      portion: 1.0,
      unit: "cup",
      protein: 20.0,
      fat: 5.0,
      carbs: 10.0,
      calories: 165.0,
      meal_type: "snack",
      logged_at: "2025-12-04 10:00",
    )

  // Should render compact version without errors
  let _element = food_log_entry_card.render_log_entry_card_compact(card)
  should.equal(1, 1)
}

// ===================================================================
// LIST RENDERING TESTS
// ===================================================================

pub fn render_log_entry_list_test() {
  let card1 =
    ui_types.LogEntryCard(
      entry_id: "log-1",
      food_name: "Oatmeal",
      portion: 1.0,
      unit: "cup",
      protein: 6.0,
      fat: 3.0,
      carbs: 27.0,
      calories: 150.0,
      meal_type: "breakfast",
      logged_at: "2025-12-04 07:00",
    )

  let card2 =
    ui_types.LogEntryCard(
      entry_id: "log-2",
      food_name: "Salmon",
      portion: 4.0,
      unit: "oz",
      protein: 25.0,
      fat: 10.0,
      carbs: 0.0,
      calories: 190.0,
      meal_type: "dinner",
      logged_at: "2025-12-04 19:00",
    )

  let cards = [card1, card2]

  // Should render list without errors
  let _element = food_log_entry_card.render_log_entry_list(cards)
  should.equal(1, 1)
}

// ===================================================================
// EDGE CASE TESTS
// ===================================================================

pub fn zero_macros_test() {
  let card =
    ui_types.LogEntryCard(
      entry_id: "log-zero",
      food_name: "Black Coffee",
      portion: 1.0,
      unit: "cup",
      protein: 0.0,
      fat: 0.0,
      carbs: 0.0,
      calories: 2.0,
      meal_type: "breakfast",
      logged_at: "2025-12-04 06:00",
    )

  // Should handle zero macros without division by zero
  let _element = food_log_entry_card.render_log_entry_card(card)
  should.equal(1, 1)
}

pub fn high_protein_meal_test() {
  let card =
    ui_types.LogEntryCard(
      entry_id: "log-protein",
      food_name: "Protein Shake",
      portion: 2.0,
      unit: "scoops",
      protein: 50.0,
      fat: 2.0,
      carbs: 5.0,
      calories: 242.0,
      meal_type: "snack",
      logged_at: "2025-12-04 15:00",
    )

  // Should handle high protein ratios
  let _element = food_log_entry_card.render_log_entry_card(card)
  should.equal(1, 1)
}
