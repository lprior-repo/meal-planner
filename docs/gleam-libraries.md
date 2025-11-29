# Gleam Library Research for Meal Planner Migration

Research completed for bead `meal-planner-5wh`.

## Summary Table

| Category | Library | Version | Notes |
|----------|---------|---------|-------|
| HTTP | gleam_httpc | v5.0.0 | Official, uses Erlang httpc |
| HTTP (alt) | gleam_hackney | v1.3.1 | Better TLS handling |
| JSON | gleam_json | v3.1.0 | Official, uses Jason/Thoas |
| YAML | glaml | v3.0.2 | Wrapper around yamerl |
| YAML (alt) | tom (TOML) | - | Consider switching to TOML |
| Database | sqlight | - | SQLite, recommended |
| Database (alt) | database (DETS) | - | Pure BEAM key-value |
| In-Memory | bravo (ETS) | - | Fast concurrent access |

## HTTP Client: gleam_httpc

```bash
gleam add gleam_httpc@5
```

```gleam
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json

pub fn send_email(payload: String) -> Result(String, httpc.HttpError) {
  let assert Ok(base_req) = request.to("https://send.api.mailtrap.io/api/send")

  let req = base_req
    |> request.set_method(http.Post)
    |> request.set_body(payload)
    |> request.prepend_header("content-type", "application/json")
    |> request.prepend_header("authorization", "Bearer TOKEN")

  use resp <- result.try(httpc.send(req))
  Ok(resp.body)
}
```

## JSON: gleam_json

```bash
gleam add gleam_json
```

### Encoding
```gleam
import gleam/json

pub type Recipe {
  Recipe(name: String, servings: Int)
}

pub fn recipe_to_json(recipe: Recipe) -> String {
  json.object([
    #("name", json.string(recipe.name)),
    #("servings", json.int(recipe.servings)),
  ])
  |> json.to_string
}
```

### Decoding
```gleam
import gleam/json
import gleam/dynamic/decode

pub fn recipe_from_json(json_str: String) -> Result(Recipe, json.DecodeError) {
  let decoder = {
    use name <- decode.field("name", decode.string)
    use servings <- decode.field("servings", decode.int)
    decode.success(Recipe(name:, servings:))
  }
  json.parse(json_str, decoder)
}
```

## YAML: glaml

```bash
gleam add glaml
```

```gleam
import glaml

pub fn parse_recipe_yaml(yaml_str: String) {
  let assert Ok([doc]) = glaml.parse_string(yaml_str)
  let root = glaml.document_root(doc)

  // Access with dot notation
  glaml.select_sugar(root, "name")
  glaml.select_sugar(root, "ingredients.#0")
}
```

### Alternative: Switch to TOML
```bash
gleam add tom
```

```gleam
import tom

pub fn parse_config(toml_str: String) {
  tom.parse(toml_str)
  |> tom.get_string(["recipe", "name"])
}
```

## Database: sqlight (SQLite)

```bash
gleam add sqlight
```

```gleam
import sqlight
import gleam/dynamic/decode

pub fn init_db() {
  use conn <- sqlight.with_connection("meal_planner.db")

  let sql = "
    create table if not exists nutrition_state (
      date text primary key,
      protein real,
      fat real,
      carbs real,
      calories real,
      synced_at text
    );"
  sqlight.exec(sql, conn)
}

pub fn save_state(conn, state: NutritionState) {
  let sql = "insert or replace into nutrition_state values (?, ?, ?, ?, ?, ?)"
  sqlight.query(sql, on: conn, with: [
    sqlight.text(state.date),
    sqlight.float(state.protein),
    sqlight.float(state.fat),
    sqlight.float(state.carbs),
    sqlight.float(state.calories),
    sqlight.text(state.synced_at),
  ], expecting: decode.success(Nil))
}
```

## Alternative: DETS via database library

```bash
gleam add database
```

```gleam
import database
import gleam/dynamic/decode

pub fn init_nutrition_table() {
  let table_name = atom.create("nutrition_state")
  database.create_table(table_name, state_decoder())
}

pub fn save_state(table, state: NutritionState) {
  use transac <- database.transaction(table)
  database.insert(transac, state)
}
```

## gleam.toml Dependencies

```toml
[dependencies]
gleam_stdlib = ">= 0.65.0"
gleam_httpc = ">= 5.0.0 and < 6.0.0"
gleam_json = ">= 3.0.0 and < 4.0.0"
gleam_http = ">= 3.0.0"
glaml = ">= 3.0.0"
sqlight = ">= 0.0.0"

[dev-dependencies]
gleeunit = ">= 1.0.0 and < 2.0.0"
```

## Decision Summary

1. **HTTP**: Use `gleam_httpc` (official, built-in Erlang)
2. **JSON**: Use `gleam_json` (official, fast)
3. **YAML**: Use `glaml` OR consider migrating recipes to TOML
4. **Database**: Use `sqlight` (SQLite) to replace BadgerDB
   - Better query capabilities
   - Standard SQL
   - Good for nutrition state storage
