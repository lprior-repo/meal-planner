/// Helper module for enriching food log entries with Mealie recipe data
import gleam/dict
import gleam/float
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/config
import meal_planner/mealie/client as mealie
import meal_planner/mealie/types as mealie_types
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
/// Updates recipe_name if the entry is from a Mealie recipe
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
          // Return entry with updated recipe name from Mealie
          FoodLogEntry(..entry, recipe_name: recipe.name)
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

/// Batch enrich multiple entries with Mealie data using single API call
/// Fetches all unique recipes in one batch call instead of individual calls
/// This significantly improves performance when enriching weekly summaries
pub fn enrich_entries_with_mealie_data_batch(
  entries: List(FoodLogEntry),
  cfg: config.Config,
) -> List(FoodLogEntry) {
  // Collect all unique recipe slugs from Mealie entries
  let mealie_entries =
    list.filter(entries, fn(entry) { entry.source_type == "mealie_recipe" })

  let recipe_slugs =
    mealie_entries
    |> list.map(fn(entry) { entry.source_id })
    |> list.unique

  // Skip batch fetch if no Mealie entries
  case recipe_slugs {
    [] -> entries
    _ -> {
      // Fetch all recipes in batch with single API call
      case mealie.get_recipes_batch(cfg, recipe_slugs) {
        Ok(#(recipes, _failed_slugs)) -> {
          // Build a map of slug -> recipe for O(1) lookup
          let recipe_map =
            list.fold(recipes, dict.new(), fn(acc, recipe) {
              dict.insert(acc, recipe.id, recipe)
            })

          // Enrich entries using fetched recipes
          list.map(entries, fn(entry) {
            case entry.source_type {
              "mealie_recipe" -> {
                case dict.get(recipe_map, entry.source_id) {
                  Ok(recipe) ->
                    FoodLogEntry(..entry, recipe_name: recipe.name)

                  Error(_) -> entry
                }
              }
              _ -> entry
            }
          })
        }
        Error(_) -> {
          // Batch fetch failed, fall back to individual fetching
          list.map(entries, fn(entry) {
            enrich_entry_with_mealie_data(entry, cfg)
          })
        }
      }
    }
  }
}
