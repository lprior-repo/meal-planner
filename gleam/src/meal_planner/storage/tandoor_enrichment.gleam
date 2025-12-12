/// Helper module for enriching food log entries with Tandoor recipe data
import gleam/dict
import gleam/list
import meal_planner/config
import meal_planner/tandoor/client as tandoor
import meal_planner/types.{type FoodLogEntry, FoodLogEntry}

/// Enrich a food log entry with recipe details from Tandoor API
/// Updates recipe_name if the entry is from a Tandoor recipe
pub fn enrich_entry_with_tandoor_data(
  entry: FoodLogEntry,
  cfg: config.Config,
) -> FoodLogEntry {
  // Only enrich entries that are from Tandoor recipes
  case entry.source_type {
    "tandoor_recipe" -> {
      // Fetch recipe details from Tandoor
      let recipe_slug = entry.source_id
      case tandoor.get_recipe(cfg, recipe_slug) {
        Ok(recipe) -> {
          // Return entry with updated recipe name from Tandoor
          FoodLogEntry(..entry, recipe_name: recipe.name)
        }
        Error(_) -> {
          // Tandoor API call failed, return entry as-is
          entry
        }
      }
    }
    _ -> entry
  }
}

/// Batch enrich multiple entries with Tandoor data
pub fn enrich_entries_with_tandoor_data(
  entries: List(FoodLogEntry),
  cfg: config.Config,
) -> List(FoodLogEntry) {
  list.map(entries, fn(entry) { enrich_entry_with_tandoor_data(entry, cfg) })
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
                  Ok(recipe) -> FoodLogEntry(..entry, recipe_name: recipe.name)

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
