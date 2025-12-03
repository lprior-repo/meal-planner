// POST /recipes endpoint implementation for meal_planner/web.gleam

// Replace api_recipes function:
fn api_recipes(req: wisp.Request, ctx: Context) -> wisp.Response {
  case req.method {
    http.Get -> {
      let recipes = load_recipes(ctx)
      let json_data = json.array(recipes, recipe_to_json)
      wisp.json_response(json.to_string(json_data), 200)
    }
    http.Post -> {
      use form_data <- wisp.require_form(req)
      handle_create_recipe(form_data, ctx)
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

// Add this helper function after api_recipe:
/// Handle POST /recipes - Create new recipe
fn handle_create_recipe(
  form_data: wisp.FormData,
  ctx: Context,
) -> wisp.Response {
  // Parse and validate form fields
  case parse_recipe_form(form_data) {
    Ok(recipe) -> {
      // Save to database
      case storage.save_recipe(ctx.db, recipe) {
        Ok(_) -> wisp.redirect("/recipes")
        Error(storage.DatabaseError(msg)) -> {
          let error_json =
            json.object([#("error", json.string("Database error: " <> msg))])
          wisp.json_response(json.to_string(error_json), 500)
        }
        Error(_) -> wisp.internal_server_error()
      }
    }
    Error(errors) -> {
      // Return validation errors as JSON
      let error_json =
        json.object([
          #("error", json.string("Validation failed")),
          #("details", json.array(errors, json.string)),
        ])
      wisp.json_response(json.to_string(error_json), 400)
    }
  }
}

// Add these validation helper functions at the end of the file:

/// Parse and validate recipe form data
fn parse_recipe_form(form: wisp.FormData) -> Result(Recipe, List(String)) {
  let values = form.values
  let errors = []

  // Generate unique ID for the recipe
  let id = "recipe-" <> wisp.random_string(16)

  // Extract and validate name
  let #(name, errors) = case list.key_find(values, "name") {
    Ok(n) if n != "" -> #(n, errors)
    Ok(_) -> #("", ["Name is required", ..errors])
    Error(_) -> #("", ["Name is required", ..errors])
  }

  // Extract and validate category
  let #(category, errors) = case list.key_find(values, "category") {
    Ok(c) if c != "" -> #(c, errors)
    Ok(_) -> #("breakfast", errors)
    Error(_) -> #("breakfast", errors)
  }

  // Extract and validate servings
  let #(servings, errors) = case list.key_find(values, "servings") {
    Ok(s) ->
      case int.parse(s) {
        Ok(n) if n > 0 -> #(n, errors)
        Ok(_) -> #(1, ["Servings must be positive", ..errors])
        Error(_) -> #(1, ["Servings must be a number", ..errors])
      }
    Error(_) -> #(1, ["Servings is required", ..errors])
  }

  // Extract and validate protein
  let #(protein, errors) = case list.key_find(values, "protein") {
    Ok(p) ->
      case float.parse(p) {
        Ok(n) if n >=. 0.0 -> #(n, errors)
        Ok(_) -> #(0.0, ["Protein cannot be negative", ..errors])
        Error(_) -> #(0.0, ["Protein must be a number", ..errors])
      }
    Error(_) -> #(0.0, ["Protein is required", ..errors])
  }

  // Extract and validate fat
  let #(fat, errors) = case list.key_find(values, "fat") {
    Ok(f) ->
      case float.parse(f) {
        Ok(n) if n >=. 0.0 -> #(n, errors)
        Ok(_) -> #(0.0, ["Fat cannot be negative", ..errors])
        Error(_) -> #(0.0, ["Fat must be a number", ..errors])
      }
    Error(_) -> #(0.0, ["Fat is required", ..errors])
  }

  // Extract and validate carbs
  let #(carbs, errors) = case list.key_find(values, "carbs") {
    Ok(c) ->
      case float.parse(c) {
        Ok(n) if n >=. 0.0 -> #(n, errors)
        Ok(_) -> #(0.0, ["Carbs cannot be negative", ..errors])
        Error(_) -> #(0.0, ["Carbs must be a number", ..errors])
      }
    Error(_) -> #(0.0, ["Carbs is required", ..errors])
  }

  // Extract ingredients (pipe-separated: name:quantity|name:quantity)
  let #(ingredients, errors) = case list.key_find(values, "ingredients") {
    Ok(ing_str) if ing_str != "" -> {
      let parsed = parse_ingredients(ing_str)
      case parsed {
        [] -> #([], ["At least one ingredient is required", ..errors])
        items -> #(items, errors)
      }
    }
    Ok(_) -> #([], ["At least one ingredient is required", ..errors])
    Error(_) -> #([], ["Ingredients are required", ..errors])
  }

  // Extract instructions (pipe-separated)
  let #(instructions, errors) = case list.key_find(values, "instructions") {
    Ok(inst_str) if inst_str != "" -> {
      let parsed =
        string.split(inst_str, "|")
        |> list.map(string.trim)
        |> list.filter(fn(s) { s != "" })
      case parsed {
        [] -> #([], ["At least one instruction is required", ..errors])
        items -> #(items, errors)
      }
    }
    Ok(_) -> #([], ["At least one instruction is required", ..errors])
    Error(_) -> #([], ["Instructions are required", ..errors])
  }

  // Extract optional FODMAP level (default to Low)
  let fodmap_level = case list.key_find(values, "fodmap_level") {
    Ok("low") -> types.Low
    Ok("medium") -> types.Medium
    Ok("high") -> types.High
    _ -> types.Low
  }

  // Extract optional vertical_compliant (default to false)
  let vertical_compliant = case list.key_find(values, "vertical_compliant") {
    Ok("true") -> True
    Ok("on") -> True
    _ -> False
  }

  // Return errors or valid recipe
  case errors {
    [] ->
      Ok(types.Recipe(
        id: id,
        name: name,
        ingredients: ingredients,
        instructions: instructions,
        macros: Macros(protein: protein, fat: fat, carbs: carbs),
        servings: servings,
        category: category,
        fodmap_level: fodmap_level,
        vertical_compliant: vertical_compliant,
      ))
    _ -> Error(list.reverse(errors))
  }
}

/// Parse ingredients string (format: "name:quantity|name:quantity")
fn parse_ingredients(ingredients_str: String) -> List(types.Ingredient) {
  string.split(ingredients_str, "|")
  |> list.map(string.trim)
  |> list.filter(fn(s) { s != "" })
  |> list.map(fn(pair) {
    case string.split(pair, ":") {
      [name, quantity] ->
        types.Ingredient(name: string.trim(name), quantity: string.trim(quantity))
      [name] -> types.Ingredient(name: string.trim(name), quantity: "1 unit")
      _ -> types.Ingredient(name: pair, quantity: "1 unit")
    }
  })
}
