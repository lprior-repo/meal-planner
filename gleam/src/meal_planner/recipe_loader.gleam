import glaml
import gleam/list
import gleam/result
import gleam/string
import meal_planner/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, High, Ingredient,
  Low, Macros, Medium, Recipe,
}
import simplifile

/// Parse YAML content into a list of recipes
pub fn parse_yaml(content: String) -> Result(List(Recipe), String) {
  use docs <- result.try(
    glaml.parse_string(content)
    |> result.map_error(fn(_) { "Failed to parse YAML" }),
  )

  case docs {
    [] -> Ok([])
    [doc, ..] -> {
      let root = glaml.document_root(doc)
      parse_recipes_node(root)
    }
  }
}

/// Parse the recipes node (expects a map with "recipes" key)
fn parse_recipes_node(node: glaml.Node) -> Result(List(Recipe), String) {
  case node {
    glaml.NodeMap(pairs) -> {
      // Find the "recipes" key
      case find_map_value(pairs, "recipes") {
        Ok(glaml.NodeSeq(recipe_nodes)) ->
          recipe_nodes
          |> list.try_map(parse_recipe)
        Ok(_) -> Error("Expected 'recipes' to be a sequence")
        Error(_) -> Error("Missing 'recipes' key in YAML")
      }
    }
    _ -> Error("Expected YAML root to be a map")
  }
}

/// Find a value in a map by string key
fn find_map_value(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(glaml.Node, Nil) {
  list.find_map(pairs, fn(pair) {
    case pair {
      #(glaml.NodeStr(k), value) if k == key -> Ok(value)
      _ -> Error(Nil)
    }
  })
}

/// Parse a single recipe node
fn parse_recipe(node: glaml.Node) -> Result(Recipe, String) {
  case node {
    glaml.NodeMap(pairs) -> {
      use name <- result.try(get_string(pairs, "name"))
      use ingredients <- result.try(get_ingredients(pairs, "ingredients"))
      use instructions <- result.try(get_string_list(pairs, "instructions"))
      use macros <- result.try(get_macros(pairs, "macros"))
      use servings <- result.try(get_int(pairs, "servings"))
      use category <- result.try(get_string(pairs, "category"))
      use fodmap_level <- result.try(get_fodmap_level(pairs, "fodmap_level"))
      use vertical_compliant <- result.try(get_bool(pairs, "vertical_compliant"))

      Ok(Recipe(
        name: name,
        ingredients: ingredients,
        instructions: instructions,
        macros: macros,
        servings: servings,
        category: category,
        fodmap_level: fodmap_level,
        vertical_compliant: vertical_compliant,
      ))
    }
    _ -> Error("Expected recipe to be a map")
  }
}

/// Get a string value from a map
fn get_string(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(String, String) {
  use node <- result.try(
    find_map_value(pairs, key)
    |> result.replace_error("Missing key: " <> key),
  )

  case node {
    glaml.NodeStr(s) -> Ok(s)
    _ -> Error("Expected string for key: " <> key)
  }
}

/// Get an int value from a map
fn get_int(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(Int, String) {
  use node <- result.try(
    find_map_value(pairs, key)
    |> result.replace_error("Missing key: " <> key),
  )

  case node {
    glaml.NodeInt(i) -> Ok(i)
    _ -> Error("Expected int for key: " <> key)
  }
}

/// Get a bool value from a map
fn get_bool(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(Bool, String) {
  use node <- result.try(
    find_map_value(pairs, key)
    |> result.replace_error("Missing key: " <> key),
  )

  case node {
    glaml.NodeBool(b) -> Ok(b)
    _ -> Error("Expected bool for key: " <> key)
  }
}

/// Get a list of strings from a map
fn get_string_list(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(List(String), String) {
  use node <- result.try(
    find_map_value(pairs, key)
    |> result.replace_error("Missing key: " <> key),
  )

  case node {
    glaml.NodeSeq(items) ->
      items
      |> list.try_map(fn(item) {
        case item {
          glaml.NodeStr(s) -> Ok(s)
          _ -> Error("Expected string in list for key: " <> key)
        }
      })
    _ -> Error("Expected sequence for key: " <> key)
  }
}

/// Get a list of ingredients from a map
fn get_ingredients(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(List(Ingredient), String) {
  use node <- result.try(
    find_map_value(pairs, key)
    |> result.replace_error("Missing key: " <> key),
  )

  case node {
    glaml.NodeSeq(items) ->
      items
      |> list.try_map(parse_ingredient)
    _ -> Error("Expected sequence for key: " <> key)
  }
}

/// Parse a single ingredient node
fn parse_ingredient(node: glaml.Node) -> Result(Ingredient, String) {
  case node {
    glaml.NodeMap(pairs) -> {
      use name <- result.try(get_string(pairs, "name"))
      use quantity <- result.try(get_string(pairs, "quantity"))
      Ok(Ingredient(name: name, quantity: quantity))
    }
    _ -> Error("Expected ingredient to be a map")
  }
}

/// Get macros from a map
fn get_macros(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(Macros, String) {
  use node <- result.try(
    find_map_value(pairs, key)
    |> result.replace_error("Missing key: " <> key),
  )

  case node {
    glaml.NodeMap(macro_pairs) -> {
      use protein <- result.try(get_float(macro_pairs, "protein"))
      use fat <- result.try(get_float(macro_pairs, "fat"))
      use carbs <- result.try(get_float(macro_pairs, "carbs"))
      Ok(Macros(protein: protein, fat: fat, carbs: carbs))
    }
    _ -> Error("Expected map for key: " <> key)
  }
}

/// Get a float value from a map
fn get_float(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(Float, String) {
  use node <- result.try(
    find_map_value(pairs, key)
    |> result.replace_error("Missing key: " <> key),
  )

  case node {
    glaml.NodeFloat(f) -> Ok(f)
    glaml.NodeInt(i) -> Ok(int_to_float(i))
    _ -> Error("Expected float for key: " <> key)
  }
}

@external(erlang, "erlang", "float")
fn int_to_float(i: Int) -> Float

/// Get FODMAP level from a map
fn get_fodmap_level(
  pairs: List(#(glaml.Node, glaml.Node)),
  key: String,
) -> Result(FodmapLevel, String) {
  use s <- result.try(get_string(pairs, key))

  case string.lowercase(s) {
    "low" -> Ok(Low)
    "medium" -> Ok(Medium)
    "high" -> Ok(High)
    _ -> Error("Invalid FODMAP level: " <> s)
  }
}

/// Load recipes from a directory, excluding a specific file
pub fn load_recipes(
  dir: String,
  exclude_file: String,
) -> Result(List(Recipe), String) {
  use entries <- result.try(
    simplifile.read_directory(dir)
    |> result.map_error(fn(_) { "Failed to read directory: " <> dir }),
  )

  // Filter for .yaml and .yml files, excluding the specified file
  let yaml_files =
    entries
    |> list.filter(fn(filename) {
      let is_yaml =
        string.ends_with(filename, ".yaml")
        || string.ends_with(filename, ".yml")
      let not_excluded = filename != exclude_file
      is_yaml && not_excluded
    })
    |> list.map(fn(filename) { dir <> "/" <> filename })

  // Load each file and parse recipes
  yaml_files
  |> list.try_fold([], fn(acc, file) {
    case load_recipe_file(file) {
      Ok(recipes) -> Ok(list.append(acc, recipes))
      Error(_) -> Ok(acc)
    }
  })
}

/// Load recipes from a single file
fn load_recipe_file(filepath: String) -> Result(List(Recipe), String) {
  use content <- result.try(
    simplifile.read(filepath)
    |> result.map_error(fn(_) { "Failed to read file: " <> filepath }),
  )

  parse_yaml(content)
}

/// Load all recipes from directory and combine them
pub fn load_all_recipes(
  dir: String,
  exclude_file: String,
) -> Result(List(Recipe), String) {
  load_recipes(dir, exclude_file)
}
