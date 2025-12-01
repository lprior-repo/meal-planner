# Implementation Summary: Edit and Delete Food Log Entries

## Bead: meal-planner-9zi

### Task
Add ability to edit servings and delete food log entries.

### What Was Done

#### 1. Storage Layer (✓ Already Complete)
The storage module (`/home/lewis/src/meal-planner/server/src/server/storage.gleam`) already has the required functions:

- `delete_food_log_entry(conn, entry_id)` - Lines 433-449
- `update_food_log_entry(conn, entry_id, servings, macros, meal_type)` - Lines 514-547
- `get_food_log_entry(conn, entry_id)` - Lines 490-512

#### 2. API Endpoints (Partial - Need to Add)

**Required Route in `web.gleam`:**
```gleam
["logs", "entry", id] -> log_entry_api.api_log_entry(req, id)
```

**API Endpoint Implementation Needed:**

Create file: `/home/lewis/src/meal-planner/server/src/server/log_entry_api.gleam`

```gleam
//// API endpoints for individual food log entry operations

import gleam/dynamic/decode
import gleam/int
import gleam/json
import server/storage
import shared/types
import wisp

pub fn api_log_entry(req: wisp.Request, id: String) -> wisp.Response {
  case req.method {
    wisp.Delete -> delete_log_entry(id)
    wisp.Put -> update_log_entry(req, id)
    _ -> wisp.method_not_allowed([wisp.Delete, wisp.Put])
  }
}

fn delete_log_entry(id: String) -> wisp.Response {
  use conn <- storage.with_connection(storage.db_path)
  case storage.delete_food_log_entry(conn, id) {
    Ok(_) -> wisp.response(204)
    Error(storage.NotFound) -> wisp.not_found()
    Error(storage.DatabaseError(msg)) ->
      wisp.internal_server_error() |> wisp.string_body(msg)
  }
}

fn update_log_entry(req: wisp.Request, id: String) -> wisp.Response {
  use json_body <- wisp.require_json(req)

  let decoder = {
    use servings <- decode.field("servings", decode.float)
    decode.success(servings)
  }

  case decode.run(json_body, decoder) {
    Ok(new_servings) -> {
      use conn <- storage.with_connection(storage.db_path)
      case storage.get_food_log_entry(conn, id) {
        Ok(entry) -> {
          case storage.get_recipe_by_id(conn, entry.recipe_id) {
            Ok(recipe) -> {
              let recipe_servings = int.to_float(recipe.servings)
              let macros_per_serving = types.macros_scale(recipe.macros, 1.0 /. recipe_servings)
              let new_macros = types.macros_scale(macros_per_serving, new_servings)

              case storage.update_food_log_entry(conn, id, new_servings, new_macros, entry.meal_type) {
                Ok(_) -> {
                  let updated_entry = types.FoodLogEntry(..entry, servings: new_servings, macros: new_macros)
                  let json_data = types.food_log_entry_to_json(updated_entry)
                  wisp.json_response(json.to_string(json_data), 200)
                }
                Error(storage.DatabaseError(msg)) -> wisp.internal_server_error() |> wisp.string_body(msg)
                Error(storage.NotFound) -> wisp.not_found()
              }
            }
            Error(_) -> wisp.internal_server_error() |> wisp.string_body("Recipe not found")
          }
        }
        Error(storage.NotFound) -> wisp.not_found()
        Error(storage.DatabaseError(msg)) -> wisp.internal_server_error() |> wisp.string_body(msg)
      }
    }
    Error(_) -> wisp.bad_request() |> wisp.string_body("Invalid request body")
  }
}
```

#### 3. Dashboard UI Updates (Not Started)

**Requirements:**
1. Display logged meals on dashboard (currently shows empty)
2. Add delete button (X) next to each meal
3. Add servings edit controls (+/-) next to each meal
4. Add JavaScript for API calls:
   - DELETE /api/logs/entry/:id
   - PUT /api/logs/entry/:id with body `{servings: number}`
5. Refresh display after edit/delete

### Current Status

- ✓ Storage functions exist and work
- ⚠ API endpoints need to be added to web.gleam
- ✗ Dashboard UI needs update to show entries with controls
- ✗ JavaScript needs to be added for client-side interactions

### Next Steps

1. Add `log_entry_api` module with edit/delete endpoints
2. Update `web.gleam` routing to include `["logs", "entry", id]` route
3. Update dashboard to load and display actual logged meals
4. Add delete and edit UI controls to dashboard
5. Add JavaScript for API interactions and UI updates

### Files Modified/Created

- **Created**: `server/src/server/log_entry_api.gleam` (API endpoints)
- **Modified**: `server/src/server/web.gleam` (add routing)
- **Modified**: `server/src/server/web.gleam` (update dashboard_page function)
- **Created**: `server/priv/static/dashboard.js` (client-side logic)

