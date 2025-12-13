/// USDA nutrient parser
///
/// Converts USDA nutrient lists (List(FoodNutrientValue)) into our typed
/// Macros and Micronutrients structures.
///
/// USDA nutrient database uses standardized names like "Protein", "Total lipid (fat)",
/// "Carbohydrate, by difference", etc. This module maps those to our schema.
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/types.{
  type Macros, type Micronutrients, Macros, Micronutrients,
}

pub type UsdaNutrient {
  UsdaNutrient(name: String, amount: Float, unit: String)
}

pub fn parse_usda_nutrients(
  nutrients: List(UsdaNutrient),
) -> #(Macros, Option(Micronutrients), Option(Float)) {
  let protein = find_nutrient(nutrients, "Protein") |> convert_to_grams
  let fat = find_nutrient(nutrients, "Total lipid (fat)") |> convert_to_grams
  let carbs =
    find_nutrient(nutrients, "Carbohydrate, by difference") |> convert_to_grams
  let energy = find_nutrient(nutrients, "Energy")

  let macros = Macros(protein: protein, fat: fat, carbs: carbs)

  let fiber =
    find_nutrient(nutrients, "Fiber, total dietary")
    |> convert_to_grams_opt

  let sugar = find_nutrient(nutrients, "Sugars, total") |> convert_to_grams_opt

  let sodium = find_nutrient(nutrients, "Sodium, Na") |> convert_to_mg_opt

  let cholesterol = find_nutrient(nutrients, "Cholesterol") |> convert_to_mg_opt

  let vitamin_a =
    find_nutrient(nutrients, "Vitamin A, RAE") |> convert_to_ug_opt

  let vitamin_c =
    find_nutrient(nutrients, "Vitamin C, total ascorbic acid")
    |> convert_to_mg_opt

  let vitamin_d = find_nutrient(nutrients, "Vitamin D") |> convert_to_ug_opt

  let vitamin_e =
    find_nutrient(nutrients, "Vitamin E (alpha-tocopherol)")
    |> convert_to_mg_opt

  let vitamin_k = find_nutrient(nutrients, "Vitamin K") |> convert_to_ug_opt

  let vitamin_b6 = find_nutrient(nutrients, "Vitamin B-6") |> convert_to_mg_opt

  let vitamin_b12 =
    find_nutrient(nutrients, "Vitamin B-12") |> convert_to_ug_opt

  let folate = find_nutrient(nutrients, "Folate, total") |> convert_to_ug_opt

  let thiamin = find_nutrient(nutrients, "Thiamin") |> convert_to_mg_opt

  let riboflavin = find_nutrient(nutrients, "Riboflavin") |> convert_to_mg_opt

  let niacin = find_nutrient(nutrients, "Niacin") |> convert_to_mg_opt

  let calcium = find_nutrient(nutrients, "Calcium, Ca") |> convert_to_mg_opt

  let iron = find_nutrient(nutrients, "Iron, Fe") |> convert_to_mg_opt

  let magnesium = find_nutrient(nutrients, "Magnesium, Mg") |> convert_to_mg_opt

  let phosphorus =
    find_nutrient(nutrients, "Phosphorus, P") |> convert_to_mg_opt

  let potassium = find_nutrient(nutrients, "Potassium, K") |> convert_to_mg_opt

  let zinc = find_nutrient(nutrients, "Zinc, Zn") |> convert_to_mg_opt

  let micronutrients = case
    has_any_value([
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
    ])
  {
    True ->
      Some(Micronutrients(
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
        cholesterol: cholesterol,
        vitamin_a: vitamin_a,
        vitamin_c: vitamin_c,
        vitamin_d: vitamin_d,
        vitamin_e: vitamin_e,
        vitamin_k: vitamin_k,
        vitamin_b6: vitamin_b6,
        vitamin_b12: vitamin_b12,
        folate: folate,
        thiamin: thiamin,
        riboflavin: riboflavin,
        niacin: niacin,
        calcium: calcium,
        iron: iron,
        magnesium: magnesium,
        phosphorus: phosphorus,
        potassium: potassium,
        zinc: zinc,
      ))
    False -> None
  }

  #(macros, micronutrients, energy)
}

fn find_nutrient(nutrients: List(UsdaNutrient), name: String) -> Option(Float) {
  let lower_name = string.lowercase(name)

  nutrients
  |> list.find(fn(n) { string.contains(string.lowercase(n.name), lower_name) })
  |> option.from_result
  |> option.map(fn(n) { n.amount })
}

fn convert_to_grams(value: Option(Float)) -> Float {
  case value {
    Some(v) -> v
    None -> 0.0
  }
}

fn convert_to_grams_opt(value: Option(Float)) -> Option(Float) {
  value
}

fn convert_to_mg_opt(value: Option(Float)) -> Option(Float) {
  value
}

fn convert_to_ug_opt(value: Option(Float)) -> Option(Float) {
  value
}

fn has_any_value(values: List(Option(a))) -> Bool {
  values
  |> list.any(fn(v) {
    case v {
      Some(_) -> True
      None -> False
    }
  })
}
