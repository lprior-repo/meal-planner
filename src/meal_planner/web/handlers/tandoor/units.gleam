/// Units handler for Tandoor API
///
/// Handles GET requests for the /api/tandoor/units endpoint.
/// Extracted from the main tandoor.gleam handler following TDD/TCR workflow.
import gleam/json
import gleam/option
import meal_planner/tandoor/api/unit/list as unit_list
import meal_planner/tandoor/handlers/helpers
import wisp

/// Handle units endpoint requests
///
/// Supports GET method only to list all units from Tandoor.
/// Returns paginated response with unit data including id, name, and plural_name.
pub fn handle_units(_req: wisp.Request) -> wisp.Response {
  case helpers.get_authenticated_client() {
    Ok(config) -> {
      case unit_list.list_units(config, limit: option.None, page: option.None) {
        Ok(response) -> {
          let results_json =
            json.array(response.results, fn(unit) {
              json.object([
                #("id", json.int(unit.id)),
                #("name", json.string(unit.name)),
                #(
                  "plural_name",
                  helpers.encode_optional_string(unit.plural_name),
                ),
              ])
            })

          json.object([
            #("count", json.int(response.count)),
            #("next", helpers.encode_optional_string(response.next)),
            #("previous", helpers.encode_optional_string(response.previous)),
            #("results", results_json),
          ])
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(_) -> wisp.not_found()
      }
    }
    Error(resp) -> resp
  }
}
