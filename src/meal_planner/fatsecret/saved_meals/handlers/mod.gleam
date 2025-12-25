/// FatSecret Saved Meals HTTP Handler Router
///
/// Routes requests to appropriate handler modules:
/// - POST   /api/fatsecret/saved-meals          -> create
/// - GET    /api/fatsecret/saved-meals          -> list
/// - PUT    /api/fatsecret/saved-meals/:id      -> update
/// - DELETE /api/fatsecret/saved-meals/:id      -> delete
/// - GET    /api/fatsecret/saved-meals/:id/items -> items/list
/// - POST   /api/fatsecret/saved-meals/:id/items -> items/create
/// - PUT    /api/fatsecret/saved-meals/:id/items/:item_id -> items/update
/// - DELETE /api/fatsecret/saved-meals/:id/items/:item_id -> items/delete
import gleam/http
import meal_planner/fatsecret/saved_meals/handlers/create
import meal_planner/fatsecret/saved_meals/handlers/delete
import meal_planner/fatsecret/saved_meals/handlers/items/create as items_create
import meal_planner/fatsecret/saved_meals/handlers/items/delete as items_delete
import meal_planner/fatsecret/saved_meals/handlers/items/list as items_list
import meal_planner/fatsecret/saved_meals/handlers/items/update as items_update
import meal_planner/fatsecret/saved_meals/handlers/list
import meal_planner/fatsecret/saved_meals/handlers/update
import pog
import wisp

/// Route saved meals requests to appropriate handler
pub fn route(
  req: wisp.Request,
  segments: List(String),
  db: pog.Connection,
) -> wisp.Response {
  case segments {
    // POST/GET /api/fatsecret/saved-meals
    [] ->
      case req.method {
        http.Get -> list.handle(req, db)
        http.Post -> create.handle(req, db)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }

    // PUT/DELETE /api/fatsecret/saved-meals/:id
    [meal_id] ->
      case req.method {
        http.Put -> update.handle(req, db, meal_id)
        http.Delete -> delete.handle(req, db, meal_id)
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }

    // GET/POST /api/fatsecret/saved-meals/:id/items
    [meal_id, "items"] ->
      case req.method {
        http.Get -> items_list.handle(req, db, meal_id)
        http.Post -> items_create.handle(req, db, meal_id)
        _ -> wisp.method_not_allowed([http.Get, http.Post])
      }

    // PUT/DELETE /api/fatsecret/saved-meals/:id/items/:item_id
    [meal_id, "items", item_id] ->
      case req.method {
        http.Put -> items_update.handle(req, db, meal_id, item_id)
        http.Delete -> items_delete.handle(req, db, meal_id, item_id)
        _ -> wisp.method_not_allowed([http.Put, http.Delete])
      }

    _ -> wisp.not_found()
  }
}
