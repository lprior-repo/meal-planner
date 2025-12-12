/// Helper module for enriching food log entries with Mealie recipe data
import gleam/float
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/config
import meal_planner/mealie/client as mealie
import meal_planner/types.{type FoodLogEntry, FoodLogEntry, Macros}

/// Parse a nutrition string from Mealie (e.g., "150 kcal" or "15.5 g")
/// Returns the numeric value as a Float, or None if parsing fails
fn parse_nutrition_value(value_opt: Option(String)) -> Option(Float) {
  case value_opt {
    None -> None
    Some(value_str) -> {
      // Extract numeric part from strings like "150 kcal" or "15.5 g"
      let numeric_part =
        value_str
        |> string.trim
        |> string.split(" ")
        |> list.first
        |> result.unwrap("")

      case float.parse(numeric_part) {
        Ok(val) -> Some(val)
        Error(_) -> None
      }
    }
  }
}

/// Enrich a food log entry with recipe details from Mealie API
/// Updates macros and micronutrients if the entry is from a Mealie recipe
pub fn enrich_entry_with_mealie_data(
  entry: FoodLogEntry,
  cfg: config.Config,
) -> FoodLogEntry {
  // Only enrich entries that are from Mealie recipes
  case entry.source_type {
    "mealie_recipe" -> {
      // Fetch recipe details from Mealie
      let recipe_slug = entry.source_id
      case mealie.get_recipe(cfg, recipe_slug) {
        Ok(recipe) -> {
          // Update entry with fresh Mealie data
          case recipe.nutrition {
            Some(nutrition) -> {
              // Parse macros from nutrition data
              let protein = parse_nutrition_value(nutrition.protein_content)
              let fat = parse_nutrition_value(nutrition.fat_content)
              let carbs = parse_nutrition_value(nutrition.carbohydrate_content)

              // Parse micronutrients
              let fiber = parse_nutrition_value(nutrition.fiber_content)
              let sugar = parse_nutrition_value(nutrition.sugar_content)
              let sodium = parse_nutrition_value(nutrition.sodium_content)

              // Create updated macros (scale by servings)
              let updated_macros = case protein, fat, carbs {
                Some(p), Some(f), Some(c) ->
                  Macros(
                    protein: p *. entry.servings,
                    fat: f *. entry.servings,
                    carbs: c *. entry.servings,
                  )
                _, _, _ -> entry.macros
              }

              // Create updated micronutrients
              let updated_micros = case fiber, sugar, sodium {
                Some(_), _, _ | _, Some(_), _ | _, _, Some(_) -> {
                  // Merge with existing micronutrients
                  let base_micros = case entry.micronutrients {
                    Some(m) -> m
                    None ->
                      types.Micronutrients(
                        fiber: None,
                        sugar: None,
                        sodium: None,
                        cholesterol: None,
                        vitamin_a: None,
                        vitamin_c: None,
                        vitamin_d: None,
                        vitamin_e: None,
                        vitamin_k: None,
                        vitamin_b6: None,
                        vitamin_b12: None,
                        folate: None,
                        thiamin: None,
                        riboflavin: None,
                        niacin: None,
                        calcium: None,
                        iron: None,
                        magnesium: None,
                        phosphorus: None,
                        potassium: None,
                        zinc: None,
                      )
                  }

                  Some(types.Micronutrients(
                    fiber: case fiber {
                      Some(f) -> Some(f *. entry.servings)
                      None -> base_micros.fiber
                    },
                    sugar: case sugar {
                      Some(s) -> Some(s *. entry.servings)
                      None -> base_micros.sugar
                    },
                    sodium: case sodium {
                      Some(s) -> Some(s *. entry.servings)
                      None -> base_micros.sodium
                    },
                    cholesterol: base_micros.cholesterol,
                    vitamin_a: base_micros.vitamin_a,
                    vitamin_c: base_micros.vitamin_c,
                    vitamin_d: base_micros.vitamin_d,
                    vitamin_e: base_micros.vitamin_e,
                    vitamin_k: base_micros.vitamin_k,
                    vitamin_b6: base_micros.vitamin_b6,
                    vitamin_b12: base_micros.vitamin_b12,
                    folate: base_micros.folate,
                    thiamin: base_micros.thiamin,
                    riboflavin: base_micros.riboflavin,
                    niacin: base_micros.niacin,
                    calcium: base_micros.calcium,
                    iron: base_micros.iron,
                    magnesium: base_micros.magnesium,
                    phosphorus: base_micros.phosphorus,
                    potassium: base_micros.potassium,
                    zinc: base_micros.zinc,
                  ))
                }
                _, _, _ -> entry.micronutrients
              }

              // Return updated entry
              FoodLogEntry(
                ..entry,
                recipe_name: recipe.name,
                macros: updated_macros,
                micronutrients: updated_micros,
              )
            }
            None -> entry
          }
        }
        Error(_) -> {
          // Mealie API call failed, return entry as-is
          entry
        }
      }
    }
    _ -> entry
  }
}

/// Batch enrich multiple entries with Mealie data
pub fn enrich_entries_with_mealie_data(
  entries: List(FoodLogEntry),
  cfg: config.Config,
) -> List(FoodLogEntry) {
  list.map(entries, fn(entry) { enrich_entry_with_mealie_data(entry, cfg) })
}
