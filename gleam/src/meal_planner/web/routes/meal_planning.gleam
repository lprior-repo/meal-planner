/// Meal Planning Routes
///
/// Handles all meal planning endpoints:
/// - GET /api/meal-planning/recipes - List available MVP recipes
/// - POST /api/meal-planning/generate - Generate a complete meal plan
/// - POST /api/meal-planning/sync - Sync meals to FatSecret diary
import gleam/option.{None, Some}
import meal_planner/config
import meal_planner/tandoor/client.{type ClientConfig, bearer_config}
import meal_planner/web/handlers/meal_planning
import meal_planner/web/routes/types.{type Context}
import wisp

/// Route meal planning requests
/// Returns Some(response) if this router handles the request, None otherwise
pub fn route(
  req: wisp.Request,
  segments: List(String),
  ctx: Context,
) -> option.Option(wisp.Response) {
  case segments {
    // GET /api/meal-planning/recipes
    ["api", "meal-planning", "recipes"] -> {
      Some(meal_planning.handle_get_recipes(req))
    }

    // POST /api/meal-planning/generate
    ["api", "meal-planning", "generate"] -> {
      // Convert Config.TandoorConfig to client.ClientConfig
      let tandoor_client_config = build_tandoor_client_config(ctx.config)
      Some(meal_planning.handle_generate(req, tandoor_client_config))
    }

    // POST /api/meal-planning/sync
    ["api", "meal-planning", "sync"] -> {
      let tandoor_client_config = build_tandoor_client_config(ctx.config)
      Some(meal_planning.handle_sync_meals(req, tandoor_client_config))
    }

    // No match
    _ -> None
  }
}

fn build_tandoor_client_config(cfg: config.Config) -> ClientConfig {
  bearer_config(cfg.tandoor.base_url, cfg.tandoor.api_token)
}
