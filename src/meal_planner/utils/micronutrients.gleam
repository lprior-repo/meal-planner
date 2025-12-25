/// Shared utility functions for micronutrient handling
///
/// This module consolidates duplicate micronutrient logic that was previously
/// scattered across storage/logs/queries.gleam, storage/logs/entries.gleam,
/// and storage/foods.gleam
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/types/food.{type FoodLogEntry}
import meal_planner/types/micronutrients as types

/// Calculate total micronutrients from food log entries
pub fn calculate_total_micronutrients(
  entries: List(FoodLogEntry),
) -> Option(types.Micronutrients) {
  let micros_list =
    list.filter_map(entries, fn(entry) {
      case entry.micronutrients {
        Some(m) -> Ok(m)
        None -> Error(Nil)
      }
    })

  case micros_list {
    [] -> None
    _ -> Some(types.sum(micros_list))
  }
}

/// Check if all micronutrient values are None
/// This is the common pattern for determining if micronutrients should be Some or None
pub fn all_micronutrients_none(
  fiber: Option(Float),
  sugar: Option(Float),
  sodium: Option(Float),
  cholesterol: Option(Float),
  vitamin_a: Option(Float),
  vitamin_c: Option(Float),
  vitamin_d: Option(Float),
  vitamin_e: Option(Float),
  vitamin_k: Option(Float),
  vitamin_b6: Option(Float),
  vitamin_b12: Option(Float),
  folate: Option(Float),
  thiamin: Option(Float),
  riboflavin: Option(Float),
  niacin: Option(Float),
  calcium: Option(Float),
  iron: Option(Float),
  magnesium: Option(Float),
  phosphorus: Option(Float),
  potassium: Option(Float),
  zinc: Option(Float),
) -> Bool {
  case
    fiber,
    sugar,
    sodium,
    cholesterol,
    vitamin_a,
    vitamin_c,
    vitamin_d,
    vitamin_e,
    vitamin_k,
    vitamin_b6,
    vitamin_b12,
    folate,
    thiamin,
    riboflavin,
    niacin,
    calcium,
    iron,
    magnesium,
    phosphorus,
    potassium,
    zinc
  {
    None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None
    -> True
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ -> False
  }
}

/// Build Micronutrients type from individual optional values
/// Returns None if all values are None, otherwise returns Some
pub fn build_micronutrients(
  fiber: Option(Float),
  sugar: Option(Float),
  sodium: Option(Float),
  cholesterol: Option(Float),
  vitamin_a: Option(Float),
  vitamin_c: Option(Float),
  vitamin_d: Option(Float),
  vitamin_e: Option(Float),
  vitamin_k: Option(Float),
  vitamin_b6: Option(Float),
  vitamin_b12: Option(Float),
  folate: Option(Float),
  thiamin: Option(Float),
  riboflavin: Option(Float),
  niacin: Option(Float),
  calcium: Option(Float),
  iron: Option(Float),
  magnesium: Option(Float),
  phosphorus: Option(Float),
  potassium: Option(Float),
  zinc: Option(Float),
) -> Option(types.Micronutrients) {
  case
    all_micronutrients_none(
      fiber,
      sugar,
      sodium,
      cholesterol,
      vitamin_a,
      vitamin_c,
      vitamin_d,
      vitamin_e,
      vitamin_k,
      vitamin_b6,
      vitamin_b12,
      folate,
      thiamin,
      riboflavin,
      niacin,
      calcium,
      iron,
      magnesium,
      phosphorus,
      potassium,
      zinc,
    )
  {
    True -> None
    False ->
      Some(types.new_unchecked(
        fiber,
        sugar,
        sodium,
        cholesterol,
        vitamin_a,
        vitamin_c,
        vitamin_d,
        vitamin_e,
        vitamin_k,
        vitamin_b6,
        vitamin_b12,
        folate,
        thiamin,
        riboflavin,
        niacin,
        calcium,
        iron,
        magnesium,
        phosphorus,
        potassium,
        zinc,
      ))
  }
}

/// Extract micronutrient tuple from Option(Micronutrients)
/// Returns a 21-tuple of optional floats
pub fn extract_micronutrient_values(
  micronutrients: Option(types.Micronutrients),
) -> #(
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
  Option(Float),
) {
  case micronutrients {
    Some(m) -> #(
      types.fiber(m),
      types.sugar(m),
      types.sodium(m),
      types.cholesterol(m),
      types.vitamin_a(m),
      types.vitamin_c(m),
      types.vitamin_d(m),
      types.vitamin_e(m),
      types.vitamin_k(m),
      types.vitamin_b6(m),
      types.vitamin_b12(m),
      types.folate(m),
      types.thiamin(m),
      types.riboflavin(m),
      types.niacin(m),
      types.calcium(m),
      types.iron(m),
      types.magnesium(m),
      types.phosphorus(m),
      types.potassium(m),
      types.zinc(m),
    )

    None -> #(
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
      None,
    )
  }
}
